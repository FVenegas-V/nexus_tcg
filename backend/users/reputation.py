"""
Módulo de cálculo de reputación para Nexus TCG
Implementa el algoritmo inteligente de reputación con múltiples factores.
"""

from django.utils import timezone
from django.conf import settings
from django.db.models import Avg, Count
import logging
from decimal import Decimal

logger = logging.getLogger(__name__)


def get_reputation_settings():
    """Obtiene la configuración del sistema de reputación."""
    return getattr(settings, 'REPUTATION_SETTINGS', {
        'DECAY_PERIOD_DAYS': 365,       # Días para llegar al peso mínimo
        'MIN_TEMPORAL_WEIGHT': 0.1,     # Peso mínimo temporal
        'CONFIDENCE_THRESHOLD': 10,     # Valoraciones para confianza máxima
        'MAX_RATER_MULTIPLIER': 2.0,    # Multiplicador máximo por credibilidad
        'MIN_RATER_MULTIPLIER': 0.5,    # Multiplicador mínimo por credibilidad
    })


def calculate_user_reputation(user):
    """
    Calcula la reputación de un usuario basada en valoraciones recibidas.
    
    Algoritmo con 5 factores:
    1. Score base de valoraciones (1-5)
    2. Decay temporal lineal (más reciente = más peso)
    3. Credibilidad del evaluador (peso por reputación del rater)
    4. Confianza estadística (penaliza pocas valoraciones)
    5. Distribución de valoraciones (anti-manipulación)
    
    Args:
        user: Instancia del modelo User
        
    Returns:
        tuple: (reputation_score, reputation_count)
               reputation_score: Decimal entre 0.00 y 5.00
               reputation_count: Entero con número de valoraciones activas
    """
    
    try:
        # Importar aquí para evitar circular imports
        from .models import UserRating
        
        # Obtener valoraciones activas
        ratings = UserRating.objects.filter(
            rated_user=user, 
            is_active=True
        ).select_related('rater')
        
        rating_count = ratings.count()
        
        # Si no hay valoraciones, reputación es 0
        if rating_count == 0:
            return Decimal('0.00'), 0
        
        # Variables para cálculo ponderado
        total_weighted_score = 0.0
        total_weight = 0.0
        now = timezone.now()
        
        # Configuración del algoritmo
        settings = get_reputation_settings()
        decay_days = settings['DECAY_PERIOD_DAYS']
        min_weight = settings['MIN_TEMPORAL_WEIGHT']
        max_multiplier = settings['MAX_RATER_MULTIPLIER']
        min_multiplier = settings['MIN_RATER_MULTIPLIER']
        
        for rating in ratings:
            # Factor 1: Score base (1-5)
            base_score = float(rating.rating)
            
            # Factor 2: Decay temporal lineal (MVP)
            days_old = (now - rating.created_at).days
            temporal_weight = max(
                min_weight, 
                1.0 - (days_old / decay_days)
            )
            
            # Factor 3: Credibilidad del evaluador
            rater_reputation = float(rating.rater.reputation_score or 0)
            
            # Calcular multiplicador de credibilidad
            if rater_reputation >= 5.0:
                rater_credibility = max_multiplier
            elif rater_reputation <= 1.0:
                rater_credibility = min_multiplier
            else:
                # Interpolación lineal entre min y max
                credibility_range = max_multiplier - min_multiplier
                reputation_range = 4.0  # De 1.0 a 5.0
                normalized_reputation = (rater_reputation - 1.0) / reputation_range
                rater_credibility = min_multiplier + (credibility_range * normalized_reputation)
            
            # Factor 4: Peso combinado
            combined_weight = temporal_weight * rater_credibility
            
            # Acumular para promedio ponderado
            total_weighted_score += base_score * combined_weight
            total_weight += combined_weight
        
        # Calcular promedio ponderado
        if total_weight > 0:
            weighted_average = total_weighted_score / total_weight
        else:
            weighted_average = 0.0
        
        # Factor 5: Confianza estadística
        confidence_threshold = settings['CONFIDENCE_THRESHOLD']
        confidence_factor = min(1.0, rating_count / confidence_threshold)
        
        # Cálculo final
        final_score = weighted_average * confidence_factor
        
        # Asegurar que esté en rango válido (0.00-5.00)
        final_score = max(0.0, min(5.0, final_score))
        
        return Decimal(str(round(final_score, 2))), rating_count
        
    except Exception as e:
        logger.error(f"Error calculating reputation for user {user.id}: {e}")
        return Decimal('0.00'), 0


def get_reputation_breakdown(user, include_ratings=False):
    """
    Obtiene un desglose detallado del cálculo de reputación para debugging/análisis.
    
    Args:
        user: Instancia del modelo User
        include_ratings: Si incluir detalles de cada valoración individual
        
    Returns:
        dict: Desglose completo del cálculo
    """
    
    try:
        from .models import UserRating
        
        ratings = UserRating.objects.filter(
            rated_user=user, 
            is_active=True
        ).select_related('rater').order_by('-created_at')
        
        rating_count = ratings.count()
        
        if rating_count == 0:
            return {
                'final_score': 0.00,
                'rating_count': 0,
                'breakdown': {
                    'message': 'No hay valoraciones activas'
                }
            }
        
        # Calcular breakdown
        now = timezone.now()
        settings = get_reputation_settings()
        decay_days = settings['DECAY_PERIOD_DAYS']
        min_weight = settings['MIN_TEMPORAL_WEIGHT']
        confidence_threshold = settings['CONFIDENCE_THRESHOLD']
        
        total_weighted_score = 0.0
        total_weight = 0.0
        ratings_breakdown = []
        
        for rating in ratings:
            days_old = (now - rating.created_at).days
            temporal_weight = max(min_weight, 1.0 - (days_old / decay_days))
            
            rater_reputation = float(rating.rater.reputation_score or 0)
            rater_credibility = _calculate_rater_credibility(rater_reputation)
            
            combined_weight = temporal_weight * rater_credibility
            weighted_score = rating.rating * combined_weight
            
            total_weighted_score += weighted_score
            total_weight += combined_weight
            
            if include_ratings:
                ratings_breakdown.append({
                    'rating_id': rating.id,
                    'rater': rating.rater.username,
                    'score': rating.rating,
                    'days_old': days_old,
                    'temporal_weight': round(temporal_weight, 3),
                    'rater_reputation': rater_reputation,
                    'rater_credibility': round(rater_credibility, 3),
                    'combined_weight': round(combined_weight, 3),
                    'weighted_score': round(weighted_score, 3),
                    'created_at': rating.created_at,
                })
        
        weighted_average = total_weighted_score / total_weight if total_weight > 0 else 0
        confidence_factor = min(1.0, rating_count / confidence_threshold)
        final_score = weighted_average * confidence_factor
        
        breakdown = {
            'algorithm_settings': settings.copy(),
            'total_ratings': rating_count,
            'weighted_average': round(weighted_average, 4),
            'confidence_factor': round(confidence_factor, 4),
            'confidence_threshold': confidence_threshold,
            'final_score': round(final_score, 2),
            'score_distribution': _get_score_distribution(ratings),
        }
        
        if include_ratings:
            breakdown['ratings_detail'] = ratings_breakdown
        
        return {
            'final_score': round(final_score, 2),
            'rating_count': rating_count,
            'breakdown': breakdown
        }
        
    except Exception as e:
        logger.error(f"Error getting reputation breakdown for user {user.id}: {e}")
        return {
            'final_score': 0.00,
            'rating_count': 0,
            'breakdown': {'error': str(e)}
        }


def _calculate_rater_credibility(rater_reputation):
    """
    Calcula el multiplicador de credibilidad basado en la reputación del evaluador.
    
    Args:
        rater_reputation: Reputación del usuario que evalúa (float)
        
    Returns:
        float: Multiplicador de credibilidad (0.5 - 2.0)
    """
    settings = get_reputation_settings()
    max_multiplier = settings['MAX_RATER_MULTIPLIER']
    min_multiplier = settings['MIN_RATER_MULTIPLIER']
    
    if rater_reputation >= 5.0:
        return max_multiplier
    elif rater_reputation <= 1.0:
        return min_multiplier
    else:
        # Interpolación lineal
        credibility_range = max_multiplier - min_multiplier
        reputation_range = 4.0  # De 1.0 a 5.0
        normalized_reputation = (rater_reputation - 1.0) / reputation_range
        return min_multiplier + (credibility_range * normalized_reputation)


def _get_score_distribution(ratings):
    """
    Obtiene la distribución de puntuaciones para detectar patrones.
    
    Args:
        ratings: QuerySet de UserRating
        
    Returns:
        dict: Distribución de puntuaciones
    """
    distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
    
    for rating in ratings:
        distribution[rating.rating] += 1
    
    total = sum(distribution.values())
    if total > 0:
        percentages = {
            score: round((count / total) * 100, 1) 
            for score, count in distribution.items()
        }
        return {
            'counts': distribution,
            'percentages': percentages,
            'total': total
        }
    
    return distribution


def update_user_reputation_sync(user):
    """
    Actualiza la reputación de un usuario de forma síncrona.
    Útil para management commands y testing.
    
    Args:
        user: Instancia del modelo User
        
    Returns:
        tuple: (old_score, new_score, rating_count)
    """
    old_score = user.reputation_score
    new_score, rating_count = calculate_user_reputation(user)
    
    # Actualizar campos
    user.reputation_score = new_score
    user.reputation_count = rating_count
    user.save(update_fields=['reputation_score', 'reputation_count', 'updated_at'])
    
    # Log del cambio
    logger.info(
        f"Reputation updated for user {user.username}: "
        f"{old_score} → {new_score} ({rating_count} ratings)"
    )
    
    return old_score, new_score, rating_count


def validate_reputation_consistency():
    """
    Valida la consistencia de las reputaciones en el sistema.
    Útil para monitoring y debugging.
    
    Returns:
        dict: Reporte de consistencia
    """
    from django.contrib.auth import get_user_model
    
    User = get_user_model()
    
    users_with_ratings = User.objects.filter(
        ratings_received__is_active=True
    ).distinct()
    
    inconsistencies = []
    total_checked = 0
    
    for user in users_with_ratings:
        total_checked += 1
        calculated_score, calculated_count = calculate_user_reputation(user)
        
        # Verificar score
        if abs(float(user.reputation_score) - float(calculated_score)) > 0.01:
            inconsistencies.append({
                'user_id': user.id,
                'username': user.username,
                'stored_score': float(user.reputation_score),
                'calculated_score': float(calculated_score),
                'stored_count': user.reputation_count,
                'calculated_count': calculated_count,
                'issue': 'score_mismatch'
            })
        
        # Verificar count
        elif user.reputation_count != calculated_count:
            inconsistencies.append({
                'user_id': user.id,
                'username': user.username,
                'stored_score': float(user.reputation_score),
                'calculated_score': float(calculated_score),
                'stored_count': user.reputation_count,
                'calculated_count': calculated_count,
                'issue': 'count_mismatch'
            })
    
    return {
        'total_users_checked': total_checked,
        'inconsistencies_found': len(inconsistencies),
        'inconsistencies': inconsistencies,
        'is_consistent': len(inconsistencies) == 0
    }


def update_user_reputation_sync(user):
    """
    Actualiza la reputación de un usuario de forma síncrona.
    Función auxiliar para uso en tasks de Celery.
    
    Args:
        user: Instancia del modelo User
        
    Returns:
        tuple: (nueva_puntuación, cantidad_valoraciones)
    """
    new_score, rating_count = calculate_user_reputation(user)
    
    # Actualizar campos
    user.reputation_score = new_score
    user.reputation_count = rating_count
    user.save(update_fields=['reputation_score', 'reputation_count', 'updated_at'])
    
    logger.info(
        f"Reputation updated synchronously for user {user.username}: "
        f"score={new_score}, count={rating_count}"
    )
    
    return new_score, rating_count


def validate_reputation_consistency(user_batch_size=100):
    """
    Valida la consistencia de las reputaciones en el sistema.
    
    Args:
        user_batch_size: Tamaño del lote para procesamiento
        
    Returns:
        dict: Reporte de consistencia
    """
    from django.contrib.auth import get_user_model
    
    User = get_user_model()
    
    # Obtener usuarios con valoraciones
    users_with_ratings = User.objects.filter(
        ratings_received__is_active=True
    ).distinct()
    
    total_users = users_with_ratings.count()
    inconsistencies = []
    processed = 0
    
    logger.info(f"Validating reputation consistency for {total_users} users")
    
    # Procesar en lotes
    for user in users_with_ratings.iterator(chunk_size=user_batch_size):
        try:
            # Calcular reputación esperada
            expected_score, expected_count = calculate_user_reputation(user)
            
            # Comparar con valores almacenados
            stored_score = user.reputation_score or Decimal('0.0')
            stored_count = user.reputation_count or 0
            
            # Tolerancia para comparación de decimales
            score_diff = abs(expected_score - stored_score)
            
            if score_diff > Decimal('0.01') or expected_count != stored_count:
                inconsistencies.append({
                    'user_id': user.id,
                    'username': user.username,
                    'expected_score': expected_score,
                    'stored_score': stored_score,
                    'expected_count': expected_count,
                    'stored_count': stored_count,
                    'score_difference': score_diff
                })
            
            processed += 1
            
            # Log de progreso cada 100 usuarios
            if processed % 100 == 0:
                logger.info(f"Validated {processed}/{total_users} users")
                
        except Exception as e:
            logger.error(f"Error validating user {user.id}: {e}")
            inconsistencies.append({
                'user_id': user.id,
                'username': user.username,
                'error': str(e)
            })
    
    report = {
        'is_consistent': len(inconsistencies) == 0,
        'total_users_checked': total_users,
        'users_processed': processed,
        'inconsistencies_found': len(inconsistencies),
        'inconsistencies': inconsistencies[:50],  # Limitar para evitar reportes muy grandes
        'validation_timestamp': timezone.now().isoformat()
    }
    
    logger.info(
        f"Consistency validation completed: "
        f"{len(inconsistencies)} inconsistencies in {total_users} users"
    )
    
    return report
