"""
ViewSet para Comments con sistema de threading avanzado.
Implementa operaciones CRUD y endpoints especializados para comentarios con hasta 3 niveles.
"""
from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q, Prefetch, Count
from django.shortcuts import get_object_or_404

from ..models import Comment, Post, Community
from ..serializers import (
    CommentListSerializer,
    CommentDetailSerializer,
    CommentCreateSerializer,
    CommentUpdateSerializer,
    CommentThreadSerializer,
)
from ..filters import CommentFilter
from ..permissions import CommentPermission


class CommentViewSet(viewsets.ModelViewSet):
    """
    ViewSet completo para Comments con threading de hasta 3 niveles.
    
    Endpoints disponibles:
    - list: Listar comentarios con filtros avanzados
    - retrieve: Detalle de comentario individual
    - create: Crear nuevo comentario o respuesta
    - update/partial_update: Editar comentario (15 min límite)
    - destroy: Eliminación lógica de comentario
    - by_post: Comentarios de un post específico con threading
    - my_comments: Comentarios del usuario autenticado
    - thread: Thread completo de un comentario con respuestas
    """
    
    serializer_class = CommentDetailSerializer
    permission_classes = [IsAuthenticated, CommentPermission]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_class = CommentFilter
    search_fields = ['content']
    ordering_fields = ['created_at', 'updated_at', 'thread_level', 'reaction_count']
    ordering = ['thread_path', 'created_at']  # Threading-aware ordering
    
    def get_queryset(self):
        """
        Optimizar queryset con prefetch de relaciones relacionadas.
        Incluye optimizaciones específicas para threading.
        """
        return Comment.objects.select_related(
            'author',
            'post',
            'post__community',
            'post__author',
            'parent'
        ).prefetch_related(
            # Prefetch optimizado para respuestas directas
            Prefetch(
                'replies',
                queryset=Comment.objects.filter(is_active=True).select_related('author')
            )
        ).filter(is_active=True).annotate(
            # Contadores optimizados
            active_replies_count=Count('replies', filter=Q(replies__is_active=True))
        )
    
    def get_serializer_class(self):
        """
        Usar diferentes serializers según la acción.
        """
        action_serializers = {
            'list': CommentListSerializer,
            'create': CommentCreateSerializer,
            'update': CommentUpdateSerializer,
            'partial_update': CommentUpdateSerializer,
            'by_post': CommentListSerializer,
            'my_comments': CommentListSerializer,
            'thread': CommentThreadSerializer,
        }
        
        return action_serializers.get(self.action, CommentDetailSerializer)
    
    def perform_create(self, serializer):
        """Crear comentario con autor del request."""
        serializer.save(author=self.request.user)
    
    def create(self, request, *args, **kwargs):
        """
        Crear comentario y devolver respuesta con serializer de detalle.
        """
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        comment = serializer.save(author=request.user)
        
        # Devolver respuesta con detalle completo
        detail_serializer = CommentDetailSerializer(comment, context=self.get_serializer_context())
        headers = self.get_success_headers(detail_serializer.data)
        return Response(detail_serializer.data, status=status.HTTP_201_CREATED, headers=headers)
    
    def perform_destroy(self, instance):
        """
        Eliminación lógica del comentario.
        Preserva la estructura del threading.
        """
        instance.soft_delete()
    
    @action(detail=False, methods=['get'], url_path='by_post/(?P<post_id>[^/.]+)')
    def by_post(self, request, post_id=None):
        """
        Obtener todos los comentarios de un post específico con threading.
        
        Parámetros:
        - post_id: ID del post
        - level: Filtrar por nivel específico (0, 1, 2)
        - max_depth: Profundidad máxima de threading (default: 3)
        
        Ordenamiento optimizado por thread_path para mantener jerarquía.
        """
        # Verificar que el post existe y es accesible
        post = get_object_or_404(Post, pk=post_id, is_active=True)
        
        # Verificar acceso a la comunidad
        if not post.community.can_user_access(request.user):
            return Response(
                {'error': 'No tienes acceso a esta comunidad'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Filtrar comentarios del post
        queryset = self.get_queryset().filter(post=post)
        
        # Filtro opcional por nivel
        level = request.query_params.get('level')
        if level is not None:
            try:
                level = int(level)
                if 0 <= level <= 2:
                    queryset = queryset.filter(thread_level=level)
            except ValueError:
                pass
        
        # Aplicar filtros adicionales
        queryset = self.filter_queryset(queryset)
        
        # Paginación
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def my_comments(self, request):
        """
        Obtener todos los comentarios del usuario autenticado.
        
        Parámetros:
        - post: Filtrar por post específico
        - community: Filtrar por comunidad específica
        - days: Comentarios de los últimos N días
        """
        from django.utils import timezone
        from datetime import timedelta
        
        # Filtrar por usuario autenticado
        queryset = self.get_queryset().filter(author=request.user)
        
        # Filtros opcionales
        post_id = request.query_params.get('post')
        if post_id:
            queryset = queryset.filter(post_id=post_id)
        
        community_id = request.query_params.get('community')
        if community_id:
            queryset = queryset.filter(post__community_id=community_id)
        
        days = request.query_params.get('days')
        if days:
            try:
                days = int(days)
                since_date = timezone.now() - timedelta(days=days)
                queryset = queryset.filter(created_at__gte=since_date)
            except ValueError:
                pass
        
        # Aplicar filtros y ordenamiento
        queryset = self.filter_queryset(queryset)
        
        # Paginación
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def thread(self, request, pk=None):
        """
        Obtener el thread completo de un comentario con todas sus respuestas.
        
        Parámetros:
        - max_depth: Profundidad máxima de respuestas (default: 3)
        - include_inactive: Incluir comentarios eliminados (solo para moderadores)
        
        Retorna el comentario base y todas sus respuestas en estructura jerárquica.
        """
        # Obtener el comentario base
        comment = self.get_object()
        
        # Verificar acceso a la comunidad
        if not comment.post.community.can_user_access(request.user):
            return Response(
                {'error': 'No tienes acceso a esta comunidad'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Configurar contexto para el serializer
        max_depth = int(request.query_params.get('max_depth', 3))
        context = self.get_serializer_context()
        context.update({
            'max_depth': max_depth,
            'include_replies': True,
        })
        
        # Si es comentario principal, obtener todo el thread
        if comment.thread_level == 0:
            # Obtener todas las respuestas del thread
            thread_comments = Comment.objects.filter(
                Q(id=comment.id) | Q(thread_path__startswith=f"{comment.thread_path}/"),
                is_active=True
            ).select_related(
                'author', 'parent'
            ).order_by('thread_path', 'created_at')
            
            # Organizar en estructura jerárquica
            serializer = CommentThreadSerializer(comment, context=context)
            
        else:
            # Si es una respuesta, obtener el thread completo desde la raíz
            root_comment_id = comment.thread_path.split('/')[0]
            root_comment = get_object_or_404(Comment, pk=root_comment_id, is_active=True)
            
            serializer = CommentThreadSerializer(root_comment, context=context)
        
        return Response(serializer.data)
    
    @action(detail=True, methods=['post'])
    def reply(self, request, pk=None):
        """
        Crear una respuesta directa a un comentario específico.
        
        Endpoint especializado que automáticamente configura el parent.
        """
        parent_comment = self.get_object()
        
        # Verificar que se puede responder
        if not parent_comment.can_reply(request.user):
            if parent_comment.thread_level >= 2:
                return Response(
                    {'error': 'No se pueden crear respuestas con más de 3 niveles de profundidad'},
                    status=status.HTTP_400_BAD_REQUEST
                )
            else:
                return Response(
                    {'error': 'No tienes permisos para responder a este comentario'},
                    status=status.HTTP_403_FORBIDDEN
                )
        
        # Preparar datos con parent automático
        data = request.data.copy()
        data['post'] = parent_comment.post.id
        data['parent'] = parent_comment.id
        
        # Crear respuesta
        serializer = CommentCreateSerializer(data=data, context=self.get_serializer_context())
        if serializer.is_valid():
            reply = serializer.save(author=request.user)
            
            # Retornar la respuesta creada con detalle completo
            detail_serializer = CommentDetailSerializer(reply, context=self.get_serializer_context())
            return Response(detail_serializer.data, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'])
    def restore(self, request, pk=None):
        """
        Restaurar un comentario eliminado lógicamente.
        Solo disponible para autores y moderadores.
        """
        comment = get_object_or_404(Comment, pk=pk)  # Incluir eliminados
        
        # Verificar permisos
        if not comment.can_delete(request.user):
            return Response(
                {'error': 'No tienes permisos para restaurar este comentario'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        if comment.is_active:
            return Response(
                {'error': 'El comentario no está eliminado'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Obtener contenido original del request
        original_content = request.data.get('content')
        if not original_content:
            return Response(
                {'error': 'Debe proporcionar el contenido original'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Restaurar comentario
        comment.restore(original_content)
        
        # Retornar comentario restaurado
        serializer = CommentDetailSerializer(comment, context=self.get_serializer_context())
        return Response(serializer.data)
    
    def get_serializer_context(self):
        """Agregar contexto adicional para serializers."""
        context = super().get_serializer_context()
        context.update({
            'include_replies': self.action in ['retrieve', 'thread'],
        })
        return context
