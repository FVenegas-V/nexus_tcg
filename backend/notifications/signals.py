"""
Signals automáticos para el sistema de notificaciones + Email fallback
Genera notificaciones automáticamente cuando ocurren eventos importantes
Fase 5-0004: Sistema de email fallback integrado
"""

from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from django.contrib.contenttypes.models import ContentType
from django.conf import settings
import logging

from .models import Notification, NotificationPreferences
from .email_service import NotificationEmailService
from .fcm_service import FCMService  # 🚀 AGREGAR FCM

User = get_user_model()
logger = logging.getLogger(__name__)


def _get_navigation_data(notification):
    """
    Genera datos de navegación específicos según el tipo de notificación
    Para permitir navegación directa desde push notifications
    """
    navigation_data = {}
    
    try:
        # Obtener el objeto relacionado
        related_object = notification.related_object
        notification_type = notification.type
        
        if notification_type == 'NEW_COMMENT' and related_object:
            # Comentario: navegar al post específico
            if hasattr(related_object, 'post'):
                post = related_object.post
                navigation_data.update({
                    'navigate_to': 'post_detail',
                    'community_id': str(post.community.id) if post.community else None,
                    'post_id': str(post.id),
                    'comment_id': str(related_object.id),
                    'highlight': 'comment'  # Para resaltar el comentario nuevo
                })
                
        elif notification_type == 'COMMENT_REPLY' and related_object:
            # Respuesta a comentario: navegar al post y al comentario específico
            if hasattr(related_object, 'post'):
                post = related_object.post
                navigation_data.update({
                    'navigate_to': 'post_detail',
                    'community_id': str(post.community.id) if post.community else None,
                    'post_id': str(post.id),
                    'comment_id': str(related_object.id),
                    'parent_comment_id': str(related_object.parent.id) if related_object.parent else None,
                    'highlight': 'reply'
                })
                
        elif notification_type == 'NEW_RATING' and related_object:
            # Valoración: navegar al perfil del usuario
            navigation_data.update({
                'navigate_to': 'user_profile',
                'target_user_id': str(notification.user.id),
                'rating_id': str(related_object.id) if hasattr(related_object, 'id') else None,
                'highlight': 'rating'
            })
            
        elif notification_type == 'NEW_POST' and related_object:
            # Nuevo post: navegar directamente al post
            navigation_data.update({
                'navigate_to': 'post_detail',
                'community_id': str(related_object.community.id) if related_object.community else None,
                'post_id': str(related_object.id),
                'highlight': 'post'
            })
            
        elif notification_type == 'COMMUNITY_JOIN' and related_object:
            # Nuevo miembro: navegar a la comunidad
            if hasattr(related_object, 'community'):
                navigation_data.update({
                    'navigate_to': 'community_detail',
                    'community_id': str(related_object.community.id),
                    'highlight': 'members'
                })
        
        # Agregar metadatos generales
        navigation_data.update({
            'notification_type': notification_type,
            'created_at': notification.created_at.isoformat()
        })
        
        logger.debug(f"[FCM_NAV] Datos de navegación generados: {navigation_data}")
        
    except Exception as e:
        logger.warning(f"[FCM_NAV] Error generando datos de navegación: {e}")
        # Datos mínimos de fallback
        navigation_data = {
            'navigate_to': 'notifications_list',
            'notification_type': notification.type,
            'fallback': 'true'
        }
    
    return navigation_data


def should_notify_user(user, notification_type):
    """
    Verificar si se debe enviar notificación al usuario
    basado en sus preferencias
    """
    try:
        preferences = user.notification_preferences
        return preferences.allows_notification_type(notification_type)
    except NotificationPreferences.DoesNotExist:
        # Si no tiene preferencias, usar defaults (permitir todas)
        return True


@receiver(post_save, sender='communities.Post')
def notify_new_post_in_community(sender, instance, created, **kwargs):
    """
    Notificar a miembros de la comunidad sobre nuevo post
    Solo a usuarios que han habilitado esta notificación
    """
    if not created:
        return
    
    # Obtener miembros activos de la comunidad (excluyendo autor)
    community_members = instance.community.memberships.filter(
        status='active'
    ).exclude(user=instance.author).select_related('user')
    
    for membership in community_members:
        user = membership.user
        
        # Verificar preferencias del usuario
        if should_notify_user(user, 'NEW_POST'):
            Notification.create_notification(
                user=user,
                notification_type='NEW_POST',
                title=f'Nuevo post en {instance.community.name}',
                message=f'{instance.author.username} publicó: "{instance.title[:100]}..."',
                related_object=instance,
                priority='NORMAL'
            )


@receiver(post_save, sender='communities.Comment')
def notify_new_comment(sender, instance, created, **kwargs):
    """
    Notificar al autor del post sobre nuevo comentario
    Y notificar sobre respuestas a comentarios
    """
    if not created:
        return
    
    # Notificar al autor del post (si no es el mismo que comenta)
    if instance.post.author != instance.author:
        if should_notify_user(instance.post.author, 'NEW_COMMENT'):
            # Crear título más descriptivo
            commenter_name = instance.author.username
            post_preview = getattr(instance.post, 'title', None) or instance.post.content[:50] + "..."
            community_name = instance.post.community.name if instance.post.community else "una comunidad"
            
            Notification.create_notification(
                user=instance.post.author,
                notification_type='NEW_COMMENT',
                title=f'{commenter_name} comentó en tu post',
                message=f'{commenter_name} agregó un comentario a tu publicación en {community_name}',
                related_object=instance,
                priority='HIGH'  # Comentarios son más importantes
            )
    
    # Si es respuesta a otro comentario, notificar al autor del comentario padre
    if instance.parent and instance.parent.author != instance.author:
        if should_notify_user(instance.parent.author, 'COMMENT_REPLY'):
            commenter_name = instance.author.username
            post_preview = getattr(instance.post, 'title', None) or instance.post.content[:30] + "..."
            
            Notification.create_notification(
                user=instance.parent.author,
                notification_type='COMMENT_REPLY',
                title=f'{commenter_name} respondió a tu comentario',
                message=f'{commenter_name} respondió a tu comentario en "{post_preview}"',
                related_object=instance,
                priority='HIGH'
            )


@receiver(post_save, sender='users.UserRating')
def notify_new_rating(sender, instance, created, **kwargs):
    """
    Notificar al usuario cuando recibe una nueva valoración
    Esta es crítica para el sistema de reputación
    """
    if not created:
        return
    
    # Solo notificar si no es auto-valoración (aunque debería estar bloqueado)
    if instance.rated_user != instance.rated_by:
        if should_notify_user(instance.rated_user, 'NEW_RATING'):
            stars = '⭐' * instance.rating
            Notification.create_notification(
                user=instance.rated_user,
                notification_type='NEW_RATING',
                title=f'Nueva valoración recibida',
                message=f'{instance.rated_by.username} te valoró con {stars} ({instance.rating}/5)',
                related_object=instance,
                priority='URGENT'  # Valoraciones son críticas para reputación
            )


@receiver(post_save, sender='communities.CommunityMembership')
def notify_community_admin_new_member(sender, instance, created, **kwargs):
    """
    Notificar a administradores cuando alguien se une a su comunidad
    """
    if not created or instance.status != 'active':
        return
    
    # Obtener administradores y moderadores de la comunidad
    admin_memberships = instance.community.memberships.filter(
        role__in=['admin', 'moderator'],
        status='active'
    ).exclude(user=instance.user).select_related('user')
    
    for admin_membership in admin_memberships:
        admin_user = admin_membership.user
        
        # Solo notificar si el admin quiere estas notificaciones
        # (Usamos NEW_POST como placeholder, se puede agregar tipo específico)
        if should_notify_user(admin_user, 'NEW_POST'):
            Notification.create_notification(
                user=admin_user,
                notification_type='COMMUNITY_JOIN',
                title=f'Nuevo miembro en {instance.community.name}',
                message=f'{instance.user.username} se unió a la comunidad',
                related_object=instance,
                priority='LOW'  # Membresías son menos críticas
            )


@receiver(post_save, sender='communities.Reaction')
def notify_reaction_to_content(sender, instance, created, **kwargs):
    """
    Notificar cuando alguien reacciona a tu contenido
    (Solo para reacciones positivas para evitar spam)
    """
    if not created:
        return
    
    # Solo notificar reacciones positivas (like, love, wow)
    positive_reactions = ['like', 'love', 'wow']
    if instance.reaction_type not in positive_reactions:
        return
    
    # Determinar el autor del contenido
    content_author = None
    notification_title = ""
    notification_message = ""
    reaction_emoji = {
        'like': '👍',
        'love': '❤️', 
        'laugh': '😂',
        'wow': '😮',
        'sad': '😢',
        'angry': '😠'
    }.get(instance.reaction_type, '👍')
    
    if instance.content_type.model == 'post':
        content_author = instance.content_object.author
        post_preview = getattr(instance.content_object, 'title', None) or instance.content_object.content[:30] + "..."
        notification_title = f'{instance.user.username} reaccionó a tu post'
        notification_message = f'{instance.user.username} reaccionó {reaction_emoji} a tu publicación "{post_preview}"'
    elif instance.content_type.model == 'comment':
        content_author = instance.content_object.author
        comment_preview = instance.content_object.content[:30] + "..."
        notification_title = f'{instance.user.username} reaccionó a tu comentario'
        notification_message = f'{instance.user.username} reaccionó {reaction_emoji} a tu comentario "{comment_preview}"'
    
    # Solo notificar si no es auto-reacción y el autor quiere notificaciones
    if (content_author and 
        content_author != instance.user and 
        should_notify_user(content_author, 'NEW_COMMENT')):  # Usar NEW_COMMENT como proxy
        
        Notification.create_notification(
            user=content_author,
            notification_type='NEW_COMMENT',  # Usar tipo existente
            title=notification_title,
            message=notification_message,
            related_object=instance.content_object,
            priority='LOW'  # Reacciones son baja prioridad
        )


# Signal para crear preferencias por defecto al registrar usuario
@receiver(post_save, sender=User)
def create_notification_preferences(sender, instance, created, **kwargs):
    """
    Crear preferencias de notificación por defecto para nuevos usuarios
    """
    if created:
        NotificationPreferences.objects.create(user=instance)


# Limpieza automática de notificaciones antiguas
# (Se puede ejecutar como tarea periódica con Celery en el futuro)
def cleanup_old_notifications():
    """
    Función para limpiar notificaciones leídas antiguas
    Se puede llamar manualmente o programar como tarea
    """
    from datetime import timedelta
    from django.utils import timezone
    
    cutoff_date = timezone.now() - timedelta(days=30)
    deleted_count = Notification.objects.filter(
        is_read=True,
        created_at__lt=cutoff_date
    ).delete()
    
    return deleted_count


# === SIGNALS PARA EMAIL FALLBACK ===

@receiver(post_save, sender=Notification)
def handle_notification_email(sender, instance, created, **kwargs):
    """
    Signal que se ejecuta cuando se crea una nueva notificación
    
    Determina si debe enviar email inmediato o programar para digest
    🚀 AHORA TAMBIÉN ENVÍA FCM AUTOMÁTICAMENTE
    """
    if not created:
        return  # Solo procesar notificaciones nuevas
    
    try:
        # 🚀 ENVIAR FCM AUTOMÁTICAMENTE (USANDO TOKENS DEMO)
        if FCMService.is_available():
            logger.info(f"[FCM_AUTO] Enviando notificación automática para {instance.user.username}")
            
            # 🎯 AGREGAR DATOS DE NAVEGACIÓN ESPECÍFICOS
            navigation_data = _get_navigation_data(instance)
            
            fcm_data = {
                'notification_id': str(instance.id),
                'type': instance.type,
                'user_id': str(instance.user.id),
                'priority': instance.priority,
                'auto_notification': 'true',
                'timestamp': instance.created_at.isoformat(),
                # 🎯 DATOS DE NAVEGACIÓN
                **navigation_data
            }
            
            fcm_result = FCMService.send_to_demo_tokens(
                instance.title,
                instance.message,
                fcm_data
            )
            
            if fcm_result and fcm_result.get('success', 0) > 0:
                logger.info(f"[FCM_AUTO] ✅ FCM enviado exitosamente para notificación {instance.id}")
            else:
                logger.warning(f"[FCM_AUTO] ❌ Error enviando FCM para notificación {instance.id}")
        else:
            logger.debug("[FCM_AUTO] FCM no disponible, saltando envío")
        
        # === CÓDIGO ORIGINAL DE EMAIL ===
        # Verificar si debe enviar email inmediato
        if NotificationEmailService.should_send_email(instance):
            
            # Para notificaciones críticas, enviar inmediatamente
            email_type = NotificationEmailService._map_notification_type(instance.type)
            if email_type in NotificationEmailService.CRITICAL_TYPES:
                success = NotificationEmailService.send_notification_email(instance)
                if success:
                    logger.info(f"Critical notification email sent immediately for {instance.id}")
                else:
                    logger.warning(f"Failed to send critical notification email for {instance.id}")
            
            # Para notificaciones normales, enviar con Celery si está disponible
            else:
                try:
                    # Verificar si Celery está disponible
                    if hasattr(settings, 'CELERY_BROKER_URL') and getattr(settings, 'CELERY_BROKER_URL', None):
                        # Importar la tarea aquí para evitar dependencias circulares
                        from .tasks import send_notification_email_task
                        
                        # Programar envío asíncrono (después de 1 minuto para permitir agrupación)
                        send_notification_email_task.apply_async(
                            args=[instance.id],
                            countdown=60  # Esperar 1 minuto
                        )
                        logger.debug(f"Notification email task scheduled for {instance.id}")
                        
                    else:
                        # Fallback: enviar sincrónicamente si no hay Celery
                        success = NotificationEmailService.send_notification_email(instance)
                        if success:
                            logger.info(f"Notification email sent synchronously for {instance.id}")
                            
                except ImportError:
                    # Celery no está instalado, enviar sincrónicamente
                    success = NotificationEmailService.send_notification_email(instance)
                    if success:
                        logger.info(f"Notification email sent synchronously (no Celery) for {instance.id}")
                        
        else:
            logger.debug(f"Email not needed for notification {instance.id} (user preferences or rate limit)")
            
    except Exception as e:
        logger.error(f"Error handling notification email for {instance.id}: {str(e)}")
        
        # En desarrollo, no fallar silenciosamente  
        if settings.DEBUG:
            logger.exception("Email notification error details:")


@receiver(post_save, sender=Notification)
def log_notification_creation(sender, instance, created, **kwargs):
    """
    Signal auxiliar para logging de notificaciones creadas
    """
    if created:
        logger.info(
            f"Notification created: {instance.id} | "
            f"Type: {instance.type} | "
            f"User: {instance.user.username} | "
            f"Priority: {instance.priority}"
        )
