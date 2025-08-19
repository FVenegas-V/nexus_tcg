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


class PostPermission(permissions.BasePermission):
    """
    Permisos para operaciones con Posts.
    - Ver posts: Usuarios autenticados
    - Crear posts: Miembros de la comunidad
    - Editar/Eliminar: Solo el autor o moderadores/admins
    """
    
    def has_permission(self, request, view):
        # Requiere autenticación
        if not request.user.is_authenticated:
            return False
        
        # Para lectura, permitir a usuarios autenticados
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Para crear posts, verificar membresía en la comunidad
        if request.method == 'POST':
            community_id = request.data.get('community')
            if community_id:
                try:
                    return CommunityMembership.objects.filter(
                        community_id=community_id,
                        user=request.user
                    ).exists()
                except (ValueError, TypeError):
                    return False
        
        return True  # Para otras operaciones, verificar a nivel de objeto
    
    def has_object_permission(self, request, view, obj):
        # Lectura permitida para usuarios autenticados
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # El autor puede editar/eliminar sus posts
        if obj.author == request.user:
            return True
        
        # Moderadores y admins pueden editar/eliminar cualquier post
        try:
            membership = CommunityMembership.objects.get(
                community=obj.community,
                user=request.user
            )
            return membership.role in ['moderator', 'admin']
        except CommunityMembership.DoesNotExist:
            return False


class PostOwnershipPermission(permissions.BasePermission):
    """
    Permiso estricto que solo permite al autor del post modificarlo.
    Útil para endpoints específicos donde no queremos permitir moderación.
    """
    
    def has_object_permission(self, request, view, obj):
        # Lectura permitida
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Solo el autor puede modificar
        return obj.author == request.user


class CanCreatePostInCommunity(permissions.BasePermission):
    """
    Permiso específico para verificar si un usuario puede crear posts
    en una comunidad específica. Verifica membresía y estado de la comunidad.
    """
    
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        
        # Obtener community_id del request
        community_id = None
        if hasattr(view, 'kwargs') and 'community_id' in view.kwargs:
            community_id = view.kwargs['community_id']
        elif request.method == 'POST' and 'community' in request.data:
            community_id = request.data.get('community')
        
        if not community_id:
            return False
        
        try:
            # Verificar que la comunidad existe y está activa
            community = Community.objects.get(pk=community_id, is_active=True)
            
            # Verificar membresía del usuario
            return CommunityMembership.objects.filter(
                community=community,
                user=request.user
            ).exists()
            
        except Community.DoesNotExist:
            return False


class CommentPermission(permissions.BasePermission):
    """
    Permiso personalizado para comentarios con validaciones de threading.
    
    Reglas:
    - Crear: Miembro de la comunidad del post
    - Leer: Acceso a la comunidad del post
    - Editar: Autor (15 min) o moderador/admin de comunidad
    - Eliminar: Autor o moderador/admin de comunidad
    - Responder: Verificar límite de 3 niveles
    """
    
    def has_permission(self, request, view):
        """Verificar permisos generales."""
        if not request.user.is_authenticated:
            return False
        
        # Para acciones de lectura, permitir si está autenticado
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Para creación, verificar datos del request
        if request.method == 'POST':
            # Caso especial para endpoint reply - usar has_object_permission
            if hasattr(view, 'action') and view.action == 'reply':
                return True  # Defer to has_object_permission
            
            return self._check_create_permission(request, view)
        
        return True  # Otros permisos se verifican en has_object_permission
    
    def has_object_permission(self, request, view, obj):
        """Verificar permisos sobre un comentario específico."""
        # Verificar acceso a la comunidad del post
        if not obj.post.community.can_user_access(request.user):
            return False
        
        # Métodos de lectura: acceso garantizado si puede acceder a la comunidad
        if request.method in permissions.SAFE_METHODS:
            return True
        
        # Método POST en endpoint reply
        if request.method == 'POST' and hasattr(view, 'action') and view.action == 'reply':
            return obj.can_reply(request.user)
        
        # Métodos de escritura
        if request.method in ['PUT', 'PATCH']:
            return self._check_edit_permission(request.user, obj)
        
        if request.method == 'DELETE':
            return self._check_delete_permission(request.user, obj)
        
        return False
    
    def _check_create_permission(self, request, view):
        """Verificar permisos para crear comentario o respuesta."""
        # Obtener post_id del request
        post_id = None
        if 'post' in request.data:
            post_id = request.data.get('post')
        elif 'post_id' in request.data:
            post_id = request.data.get('post_id')
        elif hasattr(view, 'kwargs') and 'post_id' in view.kwargs:
            post_id = view.kwargs.get('post_id')
        
        if not post_id:
            return False
        
        try:
            from .models import Post
            post = Post.objects.select_related('community').get(
                pk=post_id, 
                is_active=True
            )
            
            # Verificar acceso a la comunidad
            if not post.community.can_user_access(request.user):
                return False
            
            # Si es una respuesta, verificar límites de threading
            parent_id = request.data.get('parent')
            if parent_id:
                return self._check_reply_permission(request.user, parent_id)
            
            return True
            
        except Post.DoesNotExist:
            return False
    
    def _check_reply_permission(self, user, parent_id):
        """Verificar permisos para responder a un comentario."""
        try:
            from .models import Comment
            parent = Comment.objects.get(pk=parent_id, is_active=True)
            
            # Verificar límite de 3 niveles
            if parent.thread_level >= 2:
                return False
            
            # Verificar que el usuario puede responder usando método del modelo
            return parent.can_reply(user)
            
        except Comment.DoesNotExist:
            return False
    
    def _check_edit_permission(self, user, comment):
        """Verificar permisos para editar comentario."""
        return comment.can_edit(user)
    
    def _check_delete_permission(self, user, comment):
        """Verificar permisos para eliminar comentario."""
        return comment.can_delete(user)
