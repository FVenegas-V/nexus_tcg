"""
Sistema de permisos personalizados para comunidades.
Controla acceso basado en roles y estado de membresías.
"""
from rest_framework import permissions
from django.shortcuts import get_object_or_404
from .models import Community, CommunityMembership


class IsCommunityMemberOrReadOnly(permissions.BasePermission):
    """
    Permiso personalizado para verificar membresía en comunidad.
    - Lectura: Permite a cualquier usuario autenticado
    - Escritura: Solo miembros de la comunidad
    """
    
    def has_permission(self, request, view):
        # Requiere autenticación para todas las operaciones
        if not request.user.is_authenticated:
            return False
        
        # Métodos de lectura permitidos para usuarios autenticados
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Para operaciones de escritura, verificar membresía
        community_id = view.kwargs.get('pk') or view.kwargs.get('community_id')
        if community_id:
            try:
                community = Community.objects.get(pk=community_id)
                return CommunityMembership.objects.filter(
                    community=community,
                    user=request.user
                ).exists()
            except Community.DoesNotExist:
                return False
        
        return False


class IsCommunityModeratorOrAdmin(permissions.BasePermission):
    """
    Permiso para acciones que requieren rol de moderador o admin.
    Solo moderadores y administradores pueden realizar ciertas acciones.
    """
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Staff del sistema siempre tiene permisos
        if request.user.is_staff:
            return True
        
        community_id = view.kwargs.get('pk') or view.kwargs.get('community_id')
        if community_id:
            try:
                membership = CommunityMembership.objects.get(
                    community_id=community_id,
                    user=request.user
                )
                return membership.role in ['moderator', 'admin']
            except CommunityMembership.DoesNotExist:
                return False
        
        return False


class IsCommunityAdmin(permissions.BasePermission):
    """
    Permiso estricto solo para administradores de comunidad.
    Para acciones críticas como cambio de roles, expulsión, etc.
    """
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Staff del sistema siempre tiene permisos
        if request.user.is_staff:
            return True
        
        community_id = view.kwargs.get('pk') or view.kwargs.get('community_id')
        if community_id:
            try:
                membership = CommunityMembership.objects.get(
                    community_id=community_id,
                    user=request.user
                )
                return membership.role == 'admin'
            except CommunityMembership.DoesNotExist:
                return False
        
        return False


class IsOwnerOrReadOnly(permissions.BasePermission):
    """
    Permiso para que usuarios solo puedan editar sus propias membresías.
    """
    
    def has_object_permission(self, request, view, obj):
        # Permisos de lectura para cualquier request
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Permisos de escritura solo para el dueño del objeto
        return obj.user == request.user


class CanJoinCommunity(permissions.BasePermission):
    """
    Permiso especializado para verificar si un usuario puede unirse a una comunidad.
    Verifica límites, estado de la comunidad, membresía existente, etc.
    """
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Solo verificar para operaciones POST (join)
        if request.method != 'POST':
            return True
        
        community_id = view.kwargs.get('pk')
        if not community_id:
            return False
        
        try:
            community = Community.objects.get(pk=community_id)
            
            # Verificar si la comunidad está activa
            if not community.is_active:
                return False
            
            # Verificar si ya es miembro
            if CommunityMembership.objects.filter(
                community=community,
                user=request.user
            ).exists():
                return False
            
            # Verificar límite de miembros (si está configurado)
            if community.member_limit and community.member_count >= community.member_limit:
                return False
            
            # Si la comunidad es privada, necesita invitación o aprobación
            # (Esta lógica se puede expandir en el futuro)
            if community.is_private:
                # Por ahora, las comunidades privadas requieren aprobación manual
                # En el futuro se puede implementar sistema de invitaciones
                pass
            
            return True
            
        except Community.DoesNotExist:
            return False


class CanLeaveCommunity(permissions.BasePermission):
    """
    Permiso para verificar si un usuario puede salir de una comunidad.
    """
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Solo verificar para operaciones DELETE (leave)
        if request.method != 'DELETE':
            return True
        
        community_id = view.kwargs.get('pk')
        if not community_id:
            return False
        
        try:
            # Verificar que es miembro de la comunidad
            membership = CommunityMembership.objects.get(
                community_id=community_id,
                user=request.user
            )
            
            # Un admin no puede salir si es el único admin
            if membership.role == 'admin':
                admin_count = CommunityMembership.objects.filter(
                    community_id=community_id,
                    role='admin'
                ).count()
                
                if admin_count <= 1:
                    # No permitir si es el único admin
                    return False
            
            return True
            
        except CommunityMembership.DoesNotExist:
            return False
