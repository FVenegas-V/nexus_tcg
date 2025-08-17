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
        print(f"🔐 CanJoinCommunity: checking permission for user {request.user.username}")
        
        if not request.user.is_authenticated:
            print("❌ CanJoinCommunity: user not authenticated")
            return False
        
        # Solo verificar para operaciones POST (join)
        if request.method != 'POST':
            print("✅ CanJoinCommunity: not POST method, allowing")
            return True
        
        # Buscar community_id en diferentes lugares
        community_id = view.kwargs.get('pk') or view.kwargs.get('community_pk')
        print(f"🏠 CanJoinCommunity: community_id={community_id}")
        
        if not community_id:
            print("❌ CanJoinCommunity: no community_id found")
            return False
        
        try:
            community = Community.objects.get(pk=community_id)
            print(f"🏠 CanJoinCommunity: found community {community.name}")
            
            # Verificar si la comunidad está disponible públicamente
            if not community.is_public:
                print(f"❌ CanJoinCommunity: community {community.name} is not public")
                return False
            
            # Verificar si ya es miembro
            existing_membership = CommunityMembership.objects.filter(
                community=community,
                user=request.user
            ).exists()
            
            if existing_membership:
                print(f"❌ CanJoinCommunity: user {request.user.username} is already a member of {community.name}")
                return False
            
            # Verificar límite de miembros (si está configurado)
            if community.max_members and community.member_count >= community.max_members:
                print(f"❌ CanJoinCommunity: community {community.name} has reached member limit ({community.member_count}/{community.max_members})")
                return False
            
            # Si la comunidad requiere aprobación
            # (Esta lógica se puede expandir en el futuro)
            if community.requires_approval:
                print(f"⚠️ CanJoinCommunity: community {community.name} requires approval")
                # Por ahora, las comunidades que requieren aprobación deben
                # ser manejadas por un endpoint separado
                pass
            
            print(f"✅ CanJoinCommunity: all checks passed for user {request.user.username} to join {community.name}")
            return True
            
        except Community.DoesNotExist:
            print(f"❌ CanJoinCommunity: community {community_id} does not exist")
            return False


class CanLeaveCommunity(permissions.BasePermission):
    """
    Permiso para verificar si un usuario puede salir de una comunidad.
    """
    
    def has_permission(self, request, view):
        print(f"🚪 CanLeaveCommunity: checking permission for user {request.user.username}")
        
        if not request.user.is_authenticated:
            print("❌ CanLeaveCommunity: user not authenticated")
            return False
        
        # Solo verificar para operaciones DELETE (leave)
        if request.method != 'DELETE':
            print("✅ CanLeaveCommunity: not DELETE method, allowing")
            return True
        
        # Buscar community_id en diferentes lugares
        community_id = view.kwargs.get('pk') or view.kwargs.get('community_pk')
        print(f"🏠 CanLeaveCommunity: community_id={community_id}")
        
        if not community_id:
            print("❌ CanLeaveCommunity: no community_id found")
            return False
        
        try:
            # Verificar que es miembro de la comunidad
            membership = CommunityMembership.objects.get(
                community_id=community_id,
                user=request.user
            )
            print(f"👤 CanLeaveCommunity: found membership with role {membership.role}")
            
            # Un admin no puede salir si es el único admin
            if membership.role == 'admin':
                admin_count = CommunityMembership.objects.filter(
                    community_id=community_id,
                    role='admin'
                ).count()
                
                if admin_count <= 1:
                    print(f"❌ CanLeaveCommunity: user {request.user.username} is the only admin, cannot leave")
                    # No permitir si es el único admin
                    return False
                else:
                    print(f"✅ CanLeaveCommunity: admin can leave, there are {admin_count} admins")
            
            print(f"✅ CanLeaveCommunity: user {request.user.username} can leave community {community_id}")
            return True
            
        except CommunityMembership.DoesNotExist:
            print(f"❌ CanLeaveCommunity: user {request.user.username} is not a member of community {community_id}")
            return False
