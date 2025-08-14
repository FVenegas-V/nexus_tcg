"""
Señales para la app de usuarios.
Maneja la creación automática de perfiles y actualización de estadísticas.
"""
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.contrib.auth import get_user_model
from .models import UserProfile

User = get_user_model()


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
