"""
ViewSet para el sistema de reacciones (likes, emojis) en posts y comentarios.
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.contrib.contenttypes.models import ContentType
from django.shortcuts import get_object_or_404
from django.db import transaction

from ..models import Reaction, Post, Comment
from ..permissions import IsCommunityMemberOrReadOnly
from ..serializers import (
    ReactionSerializer,
    ReactionCreateSerializer,
    ReactionBreakdownSerializer,
    ReactionDetailSerializer,
    ReactionResponseSerializer,
    MyReactionsSerializer,
)


class ReactionViewSet(viewsets.GenericViewSet):
    """
    ViewSet para manejar reacciones en posts y comentarios.
    
    Endpoints principales:
    - POST /api/posts/{id}/react/ - Reaccionar a post
    - DELETE /api/posts/{id}/react/ - Quitar reacción de post
    - GET /api/posts/{id}/reactions/ - Breakdown de reacciones de post
    - POST /api/comments/{id}/react/ - Reaccionar a comentario
    - DELETE /api/comments/{id}/react/ - Quitar reacción de comentario
    - GET /api/comments/{id}/reactions/ - Breakdown de reacciones de comentario
    - GET /api/reactions/my-reactions/ - Mis reacciones
    """
    
    queryset = Reaction.objects.all()
    serializer_class = ReactionSerializer
    permission_classes = [IsAuthenticated]
    
    def get_content_object(self, content_type_name, object_id):
        """
        Obtener el objeto de contenido (post o comentario) y validar permisos.
        """
        if content_type_name == 'post':
            content_object = get_object_or_404(Post, id=object_id)
            
            # Verificar que el usuario es miembro de la comunidad
            membership_permission = IsCommunityMemberOrReadOnly()
            if not membership_permission.has_object_permission(
                self.request, None, content_object.community
            ):
                return None, "No tienes permiso para reaccionar en esta comunidad"
                
        elif content_type_name == 'comment':
            content_object = get_object_or_404(Comment, id=object_id)
            
            # Verificar que el usuario es miembro de la comunidad del post
            membership_permission = IsCommunityMemberOrReadOnly()
            if not membership_permission.has_object_permission(
                self.request, None, content_object.post.community
            ):
                return None, "No tienes permiso para reaccionar en esta comunidad"
                
        else:
            return None, f"Tipo de contenido no soportado: {content_type_name}"
        
        return content_object, None
    
    @action(detail=False, methods=['post'], url_path='posts/(?P<post_id>[^/.]+)/react')
    def react_to_post(self, request, post_id=None):
        """
        Reaccionar a un post específico.
        
        POST /api/reactions/posts/{post_id}/react/
        Body: {"reaction_type": "like|love|laugh|wow|sad|angry"}
        """
        # Obtener y validar el post
        content_object, error = self.get_content_object('post', post_id)
        if error:
            return Response(
                {'error': error}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Validar datos de entrada
        create_serializer = ReactionCreateSerializer(data=request.data)
        if not create_serializer.is_valid():
            return Response(
                create_serializer.errors, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        reaction_type = create_serializer.validated_data['reaction_type']
        
        # Realizar la reacción con transacción atómica
        with transaction.atomic():
            content_type = ContentType.objects.get_for_model(Post)
            
            try:
                # Buscar reacción existente
                existing_reaction = Reaction.objects.get(
                    user=request.user,
                    content_type=content_type,
                    object_id=post_id
                )
                
                # Si es la misma reacción, eliminarla (toggle off)
                if existing_reaction.reaction_type == reaction_type:
                    existing_reaction.delete()
                    action = 'removed'
                    user_reaction = None
                else:
                    # Cambiar tipo de reacción
                    existing_reaction.reaction_type = reaction_type
                    existing_reaction.save()
                    action = 'updated'
                    user_reaction = existing_reaction
                    
            except Reaction.DoesNotExist:
                # Crear nueva reacción
                user_reaction = Reaction.objects.create(
                    user=request.user,
                    content_type=content_type,
                    object_id=post_id,
                    reaction_type=reaction_type
                )
                action = 'added'
        
        # Refrescar el post para obtener contadores actualizados
        content_object.refresh_from_db()
        
        # Preparar respuesta
        response_data = {
            'action': action,
            'user_reaction': user_reaction,
            'content_object': content_object,
            'user': request.user
        }
        
        response_serializer = ReactionResponseSerializer()
        return Response(
            response_serializer.to_representation(response_data),
            status=status.HTTP_200_OK
        )
    
    @action(detail=False, methods=['delete'], url_path='posts/(?P<post_id>[^/.]+)/react')
    def unreact_from_post(self, request, post_id=None):
        """
        Eliminar reacción de un post específico.
        
        DELETE /api/reactions/posts/{post_id}/react/
        """
        # Obtener y validar el post
        content_object, error = self.get_content_object('post', post_id)
        if error:
            return Response(
                {'error': error}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Buscar y eliminar reacción
        content_type = ContentType.objects.get_for_model(Post)
        
        try:
            reaction = Reaction.objects.get(
                user=request.user,
                content_type=content_type,
                object_id=post_id
            )
            
            with transaction.atomic():
                reaction.delete()
            
            # Refrescar el post
            content_object.refresh_from_db()
            
            # Preparar respuesta
            response_data = {
                'action': 'removed',
                'user_reaction': None,
                'content_object': content_object,
                'user': request.user
            }
            
            response_serializer = ReactionResponseSerializer()
            return Response(
                response_serializer.to_representation(response_data),
                status=status.HTTP_200_OK
            )
            
        except Reaction.DoesNotExist:
            return Response(
                {'error': 'No tienes ninguna reacción en este post'},
                status=status.HTTP_404_NOT_FOUND
            )
    
    @action(detail=False, methods=['get'], url_path='posts/(?P<post_id>[^/.]+)/reactions')
    def get_post_reactions(self, request, post_id=None):
        """
        Obtener breakdown detallado de reacciones de un post.
        
        GET /api/reactions/posts/{post_id}/reactions/?include_users=true
        """
        # Obtener y validar el post
        content_object, error = self.get_content_object('post', post_id)
        if error:
            return Response(
                {'error': error}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Parámetros de query
        include_users = request.query_params.get('include_users', 'false').lower() == 'true'
        
        # Generar breakdown
        breakdown_data = {
            'content_object': content_object,
            'user': request.user,
            'include_users': include_users
        }
        
        breakdown_serializer = ReactionBreakdownSerializer()
        breakdown_result = breakdown_serializer.to_representation(breakdown_data)
        
        return Response(breakdown_result, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['post'], url_path='comments/(?P<comment_id>[^/.]+)/react')
    def react_to_comment(self, request, comment_id=None):
        """
        Reaccionar a un comentario específico.
        
        POST /api/reactions/comments/{comment_id}/react/
        Body: {"reaction_type": "like|love|laugh|wow|sad|angry"}
        """
        # Obtener y validar el comentario
        content_object, error = self.get_content_object('comment', comment_id)
        if error:
            return Response(
                {'error': error}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Validar datos de entrada
        create_serializer = ReactionCreateSerializer(data=request.data)
        if not create_serializer.is_valid():
            return Response(
                create_serializer.errors, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        reaction_type = create_serializer.validated_data['reaction_type']
        
        # Realizar la reacción con transacción atómica
        with transaction.atomic():
            content_type = ContentType.objects.get_for_model(Comment)
            
            try:
                # Buscar reacción existente
                existing_reaction = Reaction.objects.get(
                    user=request.user,
                    content_type=content_type,
                    object_id=comment_id
                )
                
                # Si es la misma reacción, eliminarla (toggle off)
                if existing_reaction.reaction_type == reaction_type:
                    existing_reaction.delete()
                    action = 'removed'
                    user_reaction = None
                else:
                    # Cambiar tipo de reacción
                    existing_reaction.reaction_type = reaction_type
                    existing_reaction.save()
                    action = 'updated'
                    user_reaction = existing_reaction
                    
            except Reaction.DoesNotExist:
                # Crear nueva reacción
                user_reaction = Reaction.objects.create(
                    user=request.user,
                    content_type=content_type,
                    object_id=comment_id,
                    reaction_type=reaction_type
                )
                action = 'added'
        
        # Refrescar el comentario para obtener contadores actualizados
        content_object.refresh_from_db()
        
        # Preparar respuesta
        response_data = {
            'action': action,
            'user_reaction': user_reaction,
            'content_object': content_object,
            'user': request.user
        }
        
        response_serializer = ReactionResponseSerializer()
        return Response(
            response_serializer.to_representation(response_data),
            status=status.HTTP_200_OK
        )
    
    @action(detail=False, methods=['delete'], url_path='comments/(?P<comment_id>[^/.]+)/react')
    def unreact_from_comment(self, request, comment_id=None):
        """
        Eliminar reacción de un comentario específico.
        
        DELETE /api/reactions/comments/{comment_id}/react/
        """
        # Obtener y validar el comentario
        content_object, error = self.get_content_object('comment', comment_id)
        if error:
            return Response(
                {'error': error}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Buscar y eliminar reacción
        content_type = ContentType.objects.get_for_model(Comment)
        
        try:
            reaction = Reaction.objects.get(
                user=request.user,
                content_type=content_type,
                object_id=comment_id
            )
            
            with transaction.atomic():
                reaction.delete()
            
            # Refrescar el comentario
            content_object.refresh_from_db()
            
            # Preparar respuesta
            response_data = {
                'action': 'removed',
                'user_reaction': None,
                'content_object': content_object,
                'user': request.user
            }
            
            response_serializer = ReactionResponseSerializer()
            return Response(
                response_serializer.to_representation(response_data),
                status=status.HTTP_200_OK
            )
            
        except Reaction.DoesNotExist:
            return Response(
                {'error': 'No tienes ninguna reacción en este comentario'},
                status=status.HTTP_404_NOT_FOUND
            )
    
    @action(detail=False, methods=['get'], url_path='comments/(?P<comment_id>[^/.]+)/reactions')
    def get_comment_reactions(self, request, comment_id=None):
        """
        Obtener breakdown detallado de reacciones de un comentario.
        
        GET /api/reactions/comments/{comment_id}/reactions/?include_users=true
        """
        # Obtener y validar el comentario
        content_object, error = self.get_content_object('comment', comment_id)
        if error:
            return Response(
                {'error': error}, 
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Parámetros de query
        include_users = request.query_params.get('include_users', 'false').lower() == 'true'
        
        # Generar breakdown
        breakdown_data = {
            'content_object': content_object,
            'user': request.user,
            'include_users': include_users
        }
        
        breakdown_serializer = ReactionBreakdownSerializer()
        breakdown_result = breakdown_serializer.to_representation(breakdown_data)
        
        return Response(breakdown_result, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'])
    def my_reactions(self, request):
        """
        Obtener todas las reacciones del usuario actual con filtros.
        
        GET /api/reactions/my-reactions/?content_type=post&reaction_type=like&page_size=20
        """
        # Validar parámetros de query
        filters = {
            'content_type': request.query_params.get('content_type', 'all'),
            'reaction_type': request.query_params.get('reaction_type', 'all'),
            'page_size': int(request.query_params.get('page_size', 20))
        }
        
        # Validar filtros con serializer
        my_reactions_serializer = MyReactionsSerializer(data=filters)
        if not my_reactions_serializer.is_valid():
            return Response(
                my_reactions_serializer.errors,
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Generar respuesta
        data = {
            'user': request.user,
            'filters': my_reactions_serializer.validated_data
        }
        
        result = my_reactions_serializer.to_representation(data)
        return Response(result, status=status.HTTP_200_OK)
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """
        Obtener estadísticas globales de reacciones.
        
        GET /api/reactions/stats/
        """
        from django.db.models import Count
        
        # Estadísticas por tipo de reacción
        reaction_stats = Reaction.objects.values('reaction_type').annotate(
            count=Count('id')
        ).order_by('-count')
        
        # Estadísticas por tipo de contenido
        content_stats = Reaction.objects.values('content_type__model').annotate(
            count=Count('id')
        ).order_by('-count')
        
        # Usuarios más activos en reacciones
        top_reactors = Reaction.objects.values(
            'user__username'
        ).annotate(
            reactions_count=Count('id')
        ).order_by('-reactions_count')[:10]
        
        # Total de reacciones
        total_reactions = Reaction.objects.count()
        
        return Response({
            'total_reactions': total_reactions,
            'by_type': {
                item['reaction_type']: {
                    'count': item['count'],
                    'emoji': Reaction.EMOJI_MAP.get(item['reaction_type'], '❓')
                }
                for item in reaction_stats
            },
            'by_content_type': {
                item['content_type__model']: item['count']
                for item in content_stats
            },
            'top_reactors': [
                {
                    'username': item['user__username'],
                    'reactions_count': item['reactions_count']
                }
                for item in top_reactors
            ]
        }, status=status.HTTP_200_OK)
