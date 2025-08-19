"""
ViewSet para Posts de comunidades TCG.
"""
from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q, Prefetch

from ..models import Post, Community, Reaction
from ..serializers import (
    PostListSerializer, PostDetailSerializer, PostCreateUpdateSerializer
)
from ..filters import PostFilter
from ..permissions import PostPermission


class PostViewSet(viewsets.ModelViewSet):
    """
    ViewSet completo para Posts.
    Proporciona operaciones CRUD y endpoints especializados.
    """
    serializer_class = PostDetailSerializer
    permission_classes = [IsAuthenticated, PostPermission]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_class = PostFilter
    search_fields = ['title', 'content']
    ordering_fields = ['created_at', 'updated_at', 'total_reactions']
    ordering = ['-created_at']
    
    def get_permissions(self):
        """
        Sobrescribir permisos para acciones específicas.
        """
        if self.action == 'toggle_reaction':
            # Solo requiere autenticación para reacciones
            permission_classes = [IsAuthenticated]
        else:
            # Usar permisos por defecto para otras acciones
            permission_classes = self.permission_classes
        
        return [permission() for permission in permission_classes]
    
    def get_queryset(self):
        """
        Optimizar queryset con prefetch de relaciones relacionadas.
        """
        return Post.objects.select_related(
            'author', 'community', 'community__category'
        ).filter(is_active=True)
    
    def get_serializer_class(self):
        """
        Usar diferentes serializers según la acción.
        """
        if self.action == 'list':
            return PostListSerializer
        elif self.action in ['create', 'update', 'partial_update']:
            return PostCreateUpdateSerializer
        return PostDetailSerializer
    
    def perform_create(self, serializer):
        """
        Asignar el autor del post al usuario autenticado.
        """
        serializer.save(author=self.request.user)
    
    @action(detail=False, methods=['get'])
    def feed(self, request):
        """
        Feed personalizado de posts de las comunidades del usuario.
        GET /api/posts/feed/
        """
        # Obtener comunidades donde el usuario es miembro
        user_communities = Community.objects.filter(
            memberships__user=request.user,
            memberships__status='active'
        ).values_list('id', flat=True)
        
        # Filtrar posts de esas comunidades
        posts = self.get_queryset().filter(
            community_id__in=user_communities
        )
        
        # Aplicar filtros de query params
        search_query = request.query_params.get('search')
        if search_query:
            posts = posts.filter(
                Q(title__icontains=search_query) |
                Q(content__icontains=search_query)
            )
        
        # Paginación
        page = self.paginate_queryset(posts)
        if page is not None:
            serializer = PostListSerializer(page, many=True, context={'request': request})
            return self.get_paginated_response(serializer.data)
        
        serializer = PostListSerializer(posts, many=True, context={'request': request})
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def by_community(self, request):
        """
        Posts de una comunidad específica.
        GET /api/posts/by_community/?community_id=X
        """
        community_id = request.query_params.get('community_id')
        if not community_id:
            return Response(
                {'error': 'community_id parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            community = Community.objects.get(pk=community_id)
        except Community.DoesNotExist:
            return Response(
                {'error': 'Community not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        posts = self.get_queryset().filter(community=community)
        
        # Aplicar filtros adicionales
        search_query = request.query_params.get('search')
        if search_query:
            posts = posts.filter(
                Q(title__icontains=search_query) |
                Q(content__icontains=search_query)
            )
        
        page = self.paginate_queryset(posts)
        if page is not None:
            serializer = PostListSerializer(page, many=True, context={'request': request})
            return self.get_paginated_response(serializer.data)
        
        serializer = PostListSerializer(posts, many=True, context={'request': request})
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def toggle_reaction(self, request, pk=None):
        """
        Alternar reacción en un post.
        POST /api/posts/{id}/toggle_reaction/
        Body: {"reaction_type": "like|love|laugh|angry|sad"}
        """
        post = self.get_object()
        reaction_type = request.data.get('reaction_type')
        
        if reaction_type not in ['like', 'love', 'laugh', 'wow', 'sad', 'angry']:
            return Response(
                {'error': 'Invalid reaction_type'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Verificar que el usuario sea miembro de la comunidad
        # (Las reacciones no requieren ser el autor del post)
        from ..models import CommunityMembership
        try:
            CommunityMembership.objects.get(
                community=post.community,
                user=request.user
            )
        except CommunityMembership.DoesNotExist:
            return Response(
                {'error': 'You must be a member of this community to react to posts'}, 
                status=status.HTTP_403_FORBIDDEN
            )

        # Buscar reacción existente
        from django.contrib.contenttypes.models import ContentType
        post_content_type = ContentType.objects.get_for_model(Post)
        
        try:
            existing_reaction = Reaction.objects.get(
                content_type=post_content_type,
                object_id=post.id,
                user=request.user
            )
            
            if existing_reaction.reaction_type == reaction_type:
                # Si es la misma reacción, eliminarla
                existing_reaction.delete()
                action = 'removed'
            else:
                # Si es diferente, actualizarla
                existing_reaction.reaction_type = reaction_type
                existing_reaction.save()
                action = 'updated'
                
        except Reaction.DoesNotExist:
            # Crear nueva reacción
            Reaction.objects.create(
                content_type=post_content_type,
                object_id=post.id,
                user=request.user,
                reaction_type=reaction_type
            )
            action = 'created'
        
        # Refrescar el post con las nuevas reacciones
        post.refresh_from_db()
        serializer = PostDetailSerializer(post, context={'request': request})
        
        return Response({
            'action': action,
            'reaction_type': reaction_type,
            'post': serializer.data
        })
    
    @action(detail=True, methods=['get'])
    def reactions(self, request, pk=None):
        """
        Obtener todas las reacciones de un post agrupadas por tipo.
        GET /api/posts/{id}/reactions/
        """
        post = self.get_object()
        
        # Obtener reacciones usando GenericForeignKey
        from django.contrib.contenttypes.models import ContentType
        post_content_type = ContentType.objects.get_for_model(Post)
        
        reactions = Reaction.objects.filter(
            content_type=post_content_type,
            object_id=post.id
        ).select_related('user')
        
        # Agrupar por tipo de reacción
        grouped_reactions = {}
        for reaction in reactions:
            reaction_type = reaction.reaction_type
            if reaction_type not in grouped_reactions:
                grouped_reactions[reaction_type] = []
            
            grouped_reactions[reaction_type].append({
                'user_id': reaction.user.id,
                'username': reaction.user.username,
                'created_at': reaction.created_at
            })
        
        # Calcular totales
        reaction_counts = {}
        for reaction_type, users in grouped_reactions.items():
            reaction_counts[reaction_type] = len(users)
        
        return Response({
            'total_reactions': len(reactions),
            'reaction_counts': reaction_counts,
            'reactions_by_type': grouped_reactions
        })
    
    @action(detail=False, methods=['get'])
    def my_posts(self, request):
        """
        Posts del usuario autenticado.
        GET /api/posts/my_posts/
        """
        posts = self.get_queryset().filter(author=request.user)
        
        page = self.paginate_queryset(posts)
        if page is not None:
            serializer = PostListSerializer(page, many=True, context={'request': request})
            return self.get_paginated_response(serializer.data)
        
        serializer = PostListSerializer(posts, many=True, context={'request': request})
        return Response(serializer.data)
