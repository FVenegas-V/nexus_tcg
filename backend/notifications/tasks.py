# notifications/tasks.py
"""
Tareas de Celery para el sistema de notificaciones por email
Fase 5-0004: Envío automatizado y programado de emails
"""

from celery import shared_task
from django.utils import timezone
from django.contrib.auth import get_user_model
from django.db.models import Q
from datetime import timedelta
import logging

from .models import Notification, NotificationPreferences
from .email_service import NotificationEmailService

User = get_user_model()
logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3)
def send_notification_email_task(self, notification_id):
    """
    Tarea para enviar email de notificación individual
    
    Args:
        notification_id: ID de la notificación a enviar
        
    Returns:
        dict: Resultado del envío
    """
    try:
        notification = Notification.objects.get(id=notification_id)
        
        # Verificar que no se haya enviado ya
        if notification.email_sent:
            return {
                'status': 'skipped',
                'reason': 'Email already sent',
                'notification_id': notification_id
            }
        
        # Intentar enviar
        success = NotificationEmailService.send_notification_email(notification)
        
        if success:
            logger.info(f"Email sent successfully for notification {notification_id}")
            return {
                'status': 'success',
                'notification_id': notification_id,
                'sent_to': notification.user.email
            }
        else:
            # Reintento con backoff exponencial
            countdown = 2 ** self.request.retries * 60  # 1min, 2min, 4min
            raise self.retry(countdown=countdown)
            
    except Notification.DoesNotExist:
        logger.error(f"Notification {notification_id} not found")
        return {
            'status': 'error',
            'reason': 'Notification not found',
            'notification_id': notification_id
        }
        
    except Exception as exc:
        logger.error(f"Failed to send email for notification {notification_id}: {str(exc)}")
        
        # Reintento con backoff exponencial
        if self.request.retries < self.max_retries:
            countdown = 2 ** self.request.retries * 60
            raise self.retry(exc=exc, countdown=countdown)
        else:
            # Falló definitivamente
            return {
                'status': 'failed',
                'reason': str(exc),
                'notification_id': notification_id
            }


@shared_task
def send_daily_digest_task():
    """
    Tarea para enviar digest diario a todos los usuarios que lo tienen habilitado
    
    Se ejecuta diariamente a las 19:00 (horario del usuario)
    """
    sent_count = 0
    error_count = 0
    
    # Buscar usuarios con digest diario habilitado
    users_with_digest = User.objects.filter(
        notification_preferences__email_enabled=True,
        notification_preferences__email_frequency='daily',
        email_verified=True
    ).select_related('notification_preferences')
    
    logger.info(f"Starting daily digest for {users_with_digest.count()} users")
    
    for user in users_with_digest:
        try:
            success = NotificationEmailService.send_daily_digest(user)
            if success:
                sent_count += 1
                logger.debug(f"Daily digest sent to {user.email}")
            else:
                logger.debug(f"No digest needed for {user.email} (no unread notifications)")
                
        except Exception as e:
            error_count += 1
            logger.error(f"Error sending daily digest to {user.email}: {str(e)}")
    
    result = {
        'total_users': users_with_digest.count(),
        'sent_count': sent_count,
        'error_count': error_count,
        'timestamp': timezone.now().isoformat()
    }
    
    logger.info(f"Daily digest completed: {result}")
    return result


@shared_task
def send_weekly_digest_task():
    """
    Tarea para enviar digest semanal a usuarios que lo tienen habilitado
    
    Se ejecuta los domingos a las 10:00
    """
    sent_count = 0
    error_count = 0
    
    # Buscar usuarios con digest semanal habilitado
    users_with_weekly = User.objects.filter(
        notification_preferences__email_enabled=True,
        notification_preferences__email_frequency='weekly',
        email_verified=True
    ).select_related('notification_preferences')
    
    logger.info(f"Starting weekly digest for {users_with_weekly.count()} users")
    
    # Para digest semanal, buscar notificaciones de la última semana
    week_ago = timezone.now() - timedelta(days=7)
    
    for user in users_with_weekly:
        try:
            # Obtener notificaciones no leídas de la semana
            weekly_notifications = Notification.objects.filter(
                user=user,
                is_read=False,
                created_at__gte=week_ago,
                type__in=NotificationEmailService.get_model_types_for_digest()
            ).order_by('-created_at')
            
            if weekly_notifications.exists():
                # Usar la misma lógica del digest diario pero con más notificaciones
                success = NotificationEmailService.send_daily_digest(user)  # Reutilizar función
                if success:
                    sent_count += 1
                    logger.debug(f"Weekly digest sent to {user.email}")
            else:
                logger.debug(f"No weekly digest needed for {user.email}")
                
        except Exception as e:
            error_count += 1
            logger.error(f"Error sending weekly digest to {user.email}: {str(e)}")
    
    result = {
        'total_users': users_with_weekly.count(),
        'sent_count': sent_count,
        'error_count': error_count,
        'timestamp': timezone.now().isoformat()
    }
    
    logger.info(f"Weekly digest completed: {result}")
    return result


@shared_task
def cleanup_old_email_logs_task():
    """
    Tarea de limpieza: elimina logs antiguos de emails enviados
    
    Se ejecuta semanalmente para mantener la base de datos limpia
    """
    # Eliminar notificaciones muy antiguas (más de 3 meses) que ya fueron enviadas por email
    three_months_ago = timezone.now() - timedelta(days=90)
    
    old_notifications = Notification.objects.filter(
        email_sent=True,
        created_at__lt=three_months_ago,
        is_read=True  # Solo eliminar las ya leídas
    )
    
    deleted_count = old_notifications.count()
    old_notifications.delete()
    
    logger.info(f"Cleaned up {deleted_count} old email notification records")
    
    return {
        'deleted_count': deleted_count,
        'cleanup_date': three_months_ago.isoformat(),
        'timestamp': timezone.now().isoformat()
    }


@shared_task
def process_pending_email_notifications_task():
    """
    Tarea para procesar notificaciones pendientes de envío por email
    
    Se ejecuta cada 10 minutos para verificar notificaciones que requieren email
    """
    processed_count = 0
    sent_count = 0
    
    # Buscar notificaciones críticas no enviadas por email (últimas 2 horas)
    two_hours_ago = timezone.now() - timedelta(hours=2)
    
    pending_notifications = Notification.objects.filter(
        email_sent=False,
        created_at__gte=two_hours_ago,
        type__in=NotificationEmailService.get_model_types_for_critical()
    ).select_related('user', 'user__notification_preferences')
    
    logger.info(f"Processing {pending_notifications.count()} pending critical notifications")
    
    for notification in pending_notifications:
        processed_count += 1
        
        try:
            if NotificationEmailService.should_send_email(notification):
                # Enviar de forma síncrona para notificaciones críticas
                success = NotificationEmailService.send_notification_email(notification)
                if success:
                    sent_count += 1
                    
        except Exception as e:
            logger.error(f"Error processing notification {notification.id}: {str(e)}")
    
    result = {
        'processed_count': processed_count,
        'sent_count': sent_count,
        'timestamp': timezone.now().isoformat()
    }
    
    logger.info(f"Pending notifications processed: {result}")
    return result


@shared_task
def test_email_service_task():
    """
    Tarea de prueba para verificar que el servicio de email funciona
    
    Útil para testing y monitoreo
    """
    from django.core.mail import send_mail
    from django.conf import settings
    
    try:
        success = send_mail(
            subject='Test Email - Nexus TCG Notifications',
            message='This is a test email from the notification system.',
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[settings.ADMINS[0][1] if settings.ADMINS else 'test@example.com'],
            fail_silently=False,
        )
        
        if success:
            logger.info("Test email sent successfully")
            return {
                'status': 'success',
                'timestamp': timezone.now().isoformat()
            }
        else:
            logger.error("Test email failed to send")
            return {
                'status': 'failed',
                'reason': 'send_mail returned False',
                'timestamp': timezone.now().isoformat()
            }
            
    except Exception as e:
        logger.error(f"Test email error: {str(e)}")
        return {
            'status': 'error',
            'reason': str(e),
            'timestamp': timezone.now().isoformat()
        }
