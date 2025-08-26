"""
Celery tasks para el sistema de reputación de Nexus TCG.
Maneja el procesamiento en background de cálculos de reputación.
"""

from celery import shared_task
from django.contrib.auth import get_user_model
from django.utils import timezone
import logging

logger = logging.getLogger(__name__)
User = get_user_model()


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def update_user_reputation_task(self, user_id):
    """
    Task de Celery para actualizar la reputación de un usuario.
    
    Args:
        user_id: ID del usuario cuya reputación se debe actualizar
        
    Returns:
        dict: Resultado de la operación
    """
    try:
        # Obtener el usuario
        user = User.objects.get(id=user_id)
        
        # Calcular nueva reputación
        from .reputation import calculate_user_reputation
        
        old_score = user.reputation_score
        new_score, rating_count = calculate_user_reputation(user)
        
        # Actualizar campos en la base de datos
        User.objects.filter(id=user_id).update(
            reputation_score=new_score,
            reputation_count=rating_count,
            updated_at=timezone.now()
        )
        
        # Log del cambio
        logger.info(
            f"Reputation updated for user {user.username}: "
            f"{old_score} → {new_score} ({rating_count} ratings)"
        )
        
        return {
            'success': True,
            'user_id': user_id,
            'username': user.username,
            'old_score': float(old_score),
            'new_score': float(new_score),
            'rating_count': rating_count,
            'updated_at': timezone.now().isoformat()
        }
        
    except User.DoesNotExist:
        error_msg = f"User {user_id} not found for reputation update"
        logger.error(error_msg)
        return {
            'success': False,
            'error': error_msg,
            'user_id': user_id
        }
        
    except Exception as exc:
        error_msg = f"Error updating reputation for user {user_id}: {exc}"
        logger.error(error_msg)
        
        # Retry la tarea si no hemos llegado al máximo
        if self.request.retries < self.max_retries:
            logger.warning(f"Retrying reputation update for user {user_id} (attempt {self.request.retries + 1})")
            raise self.retry(exc=exc)
        
        return {
            'success': False,
            'error': error_msg,
            'user_id': user_id,
            'retries': self.request.retries
        }


@shared_task(bind=True)
def bulk_update_reputations_task(self, user_ids, batch_size=50):
    """
    Task de Celery para actualizar múltiples reputaciones en lotes.
    
    Args:
        user_ids: Lista de IDs de usuarios
        batch_size: Tamaño del lote para procesamiento
        
    Returns:
        dict: Resultado del procesamiento masivo
    """
    try:
        from .reputation import update_user_reputation_sync
        
        total_users = len(user_ids)
        processed = 0
        errors = []
        
        logger.info(f"Starting bulk reputation update for {total_users} users")
        
        # Procesar en lotes
        for i in range(0, len(user_ids), batch_size):
            batch = user_ids[i:i + batch_size]
            
            for user_id in batch:
                try:
                    user = User.objects.get(id=user_id)
                    update_user_reputation_sync(user)
                    processed += 1
                    
                except User.DoesNotExist:
                    error_msg = f"User {user_id} not found"
                    errors.append({'user_id': user_id, 'error': error_msg})
                    logger.warning(error_msg)
                    
                except Exception as e:
                    error_msg = f"Error updating user {user_id}: {e}"
                    errors.append({'user_id': user_id, 'error': str(e)})
                    logger.error(error_msg)
            
            # Log de progreso cada lote
            logger.info(f"Processed {processed}/{total_users} users in bulk reputation update")
        
        success_rate = (processed / total_users * 100) if total_users > 0 else 0
        
        result = {
            'success': True,
            'total_users': total_users,
            'processed': processed,
            'errors': len(errors),
            'success_rate': round(success_rate, 2),
            'error_details': errors[:10],  # Solo los primeros 10 errores
            'completed_at': timezone.now().isoformat()
        }
        
        logger.info(
            f"Bulk reputation update completed: "
            f"{processed}/{total_users} users processed ({success_rate:.1f}% success)"
        )
        
        return result
        
    except Exception as exc:
        error_msg = f"Critical error in bulk reputation update: {exc}"
        logger.error(error_msg)
        
        return {
            'success': False,
            'error': error_msg,
            'total_users': len(user_ids) if user_ids else 0,
            'processed': 0
        }


@shared_task
def recalculate_all_reputations_task():
    """
    Task de Celery para recalcular todas las reputaciones del sistema.
    Útil para mantenimiento y corrección de inconsistencias.
    
    Returns:
        dict: Resultado de la operación
    """
    try:
        # Obtener todos los usuarios que tienen valoraciones
        users_with_ratings = User.objects.filter(
            ratings_received__is_active=True
        ).distinct().values_list('id', flat=True)
        
        user_ids = list(users_with_ratings)
        
        if not user_ids:
            return {
                'success': True,
                'message': 'No users with ratings found',
                'total_users': 0,
                'processed': 0
            }
        
        # Delegar al task de bulk update
        result = bulk_update_reputations_task.apply(args=[user_ids, 100])
        
        logger.info(f"Full reputation recalculation completed for {len(user_ids)} users")
        
        return {
            'success': True,
            'message': 'Full recalculation completed',
            'bulk_result': result.result if result else None
        }
        
    except Exception as exc:
        error_msg = f"Error in full reputation recalculation: {exc}"
        logger.error(error_msg)
        
        return {
            'success': False,
            'error': error_msg
        }


@shared_task
def validate_reputation_consistency_task():
    """
    Task de Celery para validar la consistencia de las reputaciones.
    Genera un reporte de inconsistencias en el sistema.
    
    Returns:
        dict: Reporte de consistencia
    """
    try:
        from .reputation import validate_reputation_consistency
        
        logger.info("Starting reputation consistency validation")
        
        report = validate_reputation_consistency()
        
        # Log de resultados
        if report['is_consistent']:
            logger.info(f"Reputation consistency check passed: {report['total_users_checked']} users checked")
        else:
            logger.warning(
                f"Reputation inconsistencies found: "
                f"{report['inconsistencies_found']}/{report['total_users_checked']} users"
            )
        
        return {
            'success': True,
            'report': report,
            'validated_at': timezone.now().isoformat()
        }
        
    except Exception as exc:
        error_msg = f"Error validating reputation consistency: {exc}"
        logger.error(error_msg)
        
        return {
            'success': False,
            'error': error_msg
        }


@shared_task(bind=True, max_retries=2)
def cleanup_reputation_logs_task(self, days_to_keep=30):
    """
    Task de Celery para limpiar logs antiguos de reputación.
    
    Args:
        days_to_keep: Días de logs a mantener
        
    Returns:
        dict: Resultado de la limpieza
    """
    try:
        # Implementar cuando se agregue modelo de logs de reputación
        logger.info(f"Reputation logs cleanup task executed (keeping {days_to_keep} days)")
        
        return {
            'success': True,
            'message': f'Log cleanup completed (keeping {days_to_keep} days)',
            'days_kept': days_to_keep,
            'cleaned_at': timezone.now().isoformat()
        }
        
    except Exception as exc:
        error_msg = f"Error cleaning reputation logs: {exc}"
        logger.error(error_msg)
        
        if self.request.retries < self.max_retries:
            raise self.retry(exc=exc)
        
        return {
            'success': False,
            'error': error_msg
        }
