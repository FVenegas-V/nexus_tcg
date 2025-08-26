"""
Sistema de permisos para moderadores de Nexus TCG
"""

from rest_framework.permissions import BasePermission
from django.contrib.auth.models import Group

class IsModeratorOrAdmin(BasePermission):
    """
    Permiso personalizado para moderadores y administradores
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and (
            request.user.is_staff or 
            request.user.groups.filter(name__in=['moderators', 'rating_moderators', 'community_moderators']).exists()
        )

class IsRatingModerator(BasePermission):
    """
    Permiso específico para moderadores de valoraciones
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and (
            request.user.is_staff or 
            request.user.groups.filter(name='rating_moderators').exists()
        )

class IsCommunityModerator(BasePermission):
    """
    Permiso específico para moderadores de comunidades
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and (
            request.user.is_staff or 
            request.user.groups.filter(name='community_moderators').exists()
        )

class IsAdminOnly(BasePermission):
    """
    Permiso solo para administradores
    """
    def has_permission(self, request, view):
        return request.user and request.user.is_authenticated and request.user.is_staff

# Funciones auxiliares para verificar roles
def is_rating_moderator(user):
    """Verifica si un usuario es moderador de valoraciones"""
    return user.is_staff or user.groups.filter(name='rating_moderators').exists()

def is_community_moderator(user):
    """Verifica si un usuario es moderador de comunidades"""
    return user.is_staff or user.groups.filter(name='community_moderators').exists()

def is_any_moderator(user):
    """Verifica si un usuario tiene cualquier rol de moderador"""
    return user.is_staff or user.groups.filter(
        name__in=['moderators', 'rating_moderators', 'community_moderators']
    ).exists()

def get_user_moderation_level(user):
    """
    Retorna el nivel de moderación del usuario
    """
    if user.is_staff:
        return 'admin'
    elif user.groups.filter(name='rating_moderators').exists():
        return 'rating_moderator'
    elif user.groups.filter(name='community_moderators').exists():
        return 'community_moderator'
    elif user.groups.filter(name='moderators').exists():
        return 'general_moderator'
    else:
        return 'user'
