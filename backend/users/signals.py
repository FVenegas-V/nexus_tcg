"""
Señales para la app de usuarios.
Maneja la creación automática de perfiles y actualización de estadísticas.
"""
from django.db.models.signals import post_save, post_delete, pre_delete
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from django.conf import settings
from .models import UserProfile
import logging

User = get_user_model()
logger = logging.getLogger(__name__)


@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    """
    Crea automáticamente un perfil de usuario cuando se registra un nuevo usuario
    """
    if created:
        UserProfile.objects.create(user=instance)


@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    """
    Guarda el perfil del usuario cuando se actualiza el usuario
    """
    if hasattr(instance, 'profile'):
        instance.profile.save()
    else:
        # Si por alguna razón no existe el perfil, lo crea
        UserProfile.objects.create(user=instance)


# Señales para actualizar estadísticas del perfil
# Estas se activarían cuando se implementen las funcionalidades de comunidades y posts

def update_user_communities_count(user):
    """
    Actualiza el contador de comunidades del usuario
    """
    if hasattr(user, 'profile'):
        # Cuando se implemente la funcionalidad de membresías
        # communities_count = user.memberships.filter(is_active=True).count()
        # user.profile.communities_count = communities_count
        # user.profile.save(update_fields=['communities_count'])
        pass


def update_user_posts_count(user):
    """
    Actualiza el contador de posts del usuario
    """
    if hasattr(user, 'profile'):
        # Cuando se implemente la funcionalidad de posts
        # posts_count = user.posts.count()
        # user.profile.posts_count = posts_count
        # user.profile.save(update_fields=['posts_count'])
        pass


def update_user_likes_received(user):
    """
    Actualiza el contador de likes recibidos del usuario
    """
    if hasattr(user, 'profile'):
        # Cuando se implemente la funcionalidad de likes
        # likes_count = sum(post.likes.count() for post in user.posts.all())
        # user.profile.likes_received = likes_count
        # user.profile.save(update_fields=['likes_received'])
        pass


# Futuras señales para implementar cuando estén disponibles las funcionalidades

# @receiver(post_save, sender='communities.CommunityMembership')
# def membership_created(sender, instance, created, **kwargs):
#     """Actualiza contador cuando se crea una membresía"""
#     if created:
#         update_user_communities_count(instance.user)

# @receiver(post_delete, sender='communities.CommunityMembership')
# def membership_deleted(sender, instance, **kwargs):
#     """Actualiza contador cuando se elimina una membresía"""
#     update_user_communities_count(instance.user)

# @receiver(post_save, sender='posts.Post')
# def post_created(sender, instance, created, **kwargs):
#     """Actualiza contador cuando se crea un post"""
#     if created:
#         update_user_posts_count(instance.author)

# @receiver(post_delete, sender='posts.Post')
# def post_deleted(sender, instance, **kwargs):
#     """Actualiza contador cuando se elimina un post"""
#     update_user_posts_count(instance.author)

# @receiver(post_save, sender='posts.Like')
# def like_created(sender, instance, created, **kwargs):
#     """Actualiza contador cuando se crea un like"""
#     if created:
#         update_user_likes_received(instance.post.author)

# @receiver(post_delete, sender='posts.Like')
# def like_deleted(sender, instance, **kwargs):
#     """Actualiza contador cuando se elimina un like"""
#     update_user_likes_received(instance.post.author)


# ============================================================================
# SIGNALS PARA SISTEMA DE REPUTACIÓN (FASE 4.3)
# ============================================================================

# Signal rehabilitado - Sistema de reputación automático
@receiver(post_save, sender='users.UserRating')
def update_reputation_on_rating_save(sender, instance, created, **kwargs):
    """
    Signal que se ejecuta cuando se guarda una valoración.
    Programa la actualización de reputación del usuario valorado.
    """
    try:
        # Solo procesar si la valoración está activa y es válida
        if not (hasattr(instance, 'is_active') and instance.is_active):
            return
            
        if not hasattr(instance, 'rated_user'):
            return
            
        # Log de la operación
        logger.info(
            f"Processing reputation update for user {instance.rated_user.username} "
            f"(rating {instance.id} {'created' if created else 'updated'})"
        )
        
        # Verificar si hay Celery configurado
        if _is_celery_available():
            # Ejecutar en background
            try:
                from .tasks import update_user_reputation_task
                update_user_reputation_task.delay(instance.rated_user.id)
                logger.debug(f"Queued async reputation update for user {instance.rated_user.username}")
            except Exception as celery_error:
                logger.warning(f"Celery failed, falling back to sync: {celery_error}")
                # Fallback a síncrono si Celery falla
                from .reputation import update_user_reputation_sync
                update_user_reputation_sync(instance.rated_user)
        else:
            # Ejecutar sincrónicamente si no hay Celery
            try:
                from .reputation import update_user_reputation_sync
                update_user_reputation_sync(instance.rated_user)
                logger.debug(f"Updated reputation sync for user {instance.rated_user.username}")
            except Exception as sync_error:
                logger.error(f"Sync reputation update failed: {sync_error}")
                # No re-raise para evitar problemas en la creación de valoraciones
                
    except Exception as e:
        logger.error(
            f"Error in reputation update signal for rating {instance.id}: {e}"
        )


# Signal rehabilitado - Sistema de reputación automático
@receiver(pre_delete, sender='users.UserRating')
def update_reputation_on_rating_delete(sender, instance, **kwargs):
    """
    Signal que se ejecuta antes de eliminar una valoración.
    Programa la actualización de reputación del usuario valorado.
    """
    try:
        # Guardar información antes de la eliminación
        if not hasattr(instance, 'rated_user'):
            return
            
        user_id = instance.rated_user.id
        username = instance.rated_user.username
        
        logger.info(f"Processing reputation update for user {username} (rating {instance.id} deleted)")
        
        # Verificar si hay Celery configurado
        if _is_celery_available():
            try:
                # Ejecutar en background
                from .tasks import update_user_reputation_task
                update_user_reputation_task.delay(user_id)
                logger.debug(f"Queued async reputation update for user {username} (delete)")
            except Exception as celery_error:
                logger.warning(f"Celery failed for delete signal, falling back to sync: {celery_error}")
                # Fallback a síncrono
                from .reputation import update_user_reputation_sync
                user = instance.rated_user
                update_user_reputation_sync(user)
        else:
            try:
                # Ejecutar sincrónicamente
                from .reputation import update_user_reputation_sync
                user = instance.rated_user
                update_user_reputation_sync(user)
                logger.debug(f"Updated reputation sync for user {username} (delete)")
            except Exception as sync_error:
                logger.error(f"Sync reputation update failed for delete: {sync_error}")
                # No re-raise para evitar problemas en la eliminación
                update_user_reputation_task.delay(user_id)
                logger.debug(
                    f"Queued reputation update for user ID {user_id} "
                    f"(rating {instance.id} deleted)"
                )
            else:
                # Ejecutar sincrónicamente si no hay Celery
                from .reputation import update_user_reputation_sync
                update_user_reputation_sync(instance.rated_user)
                logger.debug(
                    f"Updated reputation sync for user ID {user_id} "
                    f"(rating {instance.id} deleted)"
                )
                
    except Exception as e:
        logger.error(
            f"Error in reputation update signal for rating deletion {instance.id}: {e}"
        )


def _is_celery_available():
    """
    Verifica si Celery está disponible y configurado.
    
    Returns:
        bool: True si Celery está disponible
    """
    try:
        # Para desarrollo, siempre usar procesamiento síncrono
        # En producción, verificar configuración real
        if hasattr(settings, 'DEBUG') and settings.DEBUG:
            return False
            
        # Verificar si está en settings
        if not getattr(settings, 'CELERY_TASK_ALWAYS_EAGER', False):
            # Verificar si el broker está configurado
            broker_url = getattr(settings, 'CELERY_BROKER_URL', None)
            if broker_url and broker_url != 'memory://':
                return True
        return False
    except:
        return False
