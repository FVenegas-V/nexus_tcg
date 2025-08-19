"""
ViewSets para las APIs de comunidades.
"""
from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q
from django.utils import timezone
from django.shortcuts import get_object_or_404
from ..models import Community, CommunityCategory, CommunityMembership
from ..serializers import (
    CommunityListSerializer, CommunityDetailSerializer,
    CommunityStatsSerializer
)
from ..filters import CommunityFilter


class CommunityViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet para comunidades.
    Solo lectura por ahora - list y retrieve.
    """
    queryset = Community.objects.filter(is_public=True).select_related(
        'category', 'created_by'
    ).prefetch_related('memberships__user')
    
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_class = CommunityFilter
    search_fields = ['name', 'description', 'tags']
    ordering_fields = ['member_count', 'created_at', 'name', 'post_count']
    ordering = ['-member_count', '-created_at']
    
    def get_serializer_class(self):
        """Usar diferentes serializers según la acción."""
        if self.action == 'retrieve':
            return CommunityDetailSerializer
        return CommunityListSerializer
    
    def get_serializer_context(self):
        """Asegurar que el serializer reciba el contexto del request."""
        context = super().get_serializer_context()
        print(f"🔧 CONTEXT DEBUG: Passing context to serializer - request: {self.request}, user: {self.request.user}")
        return context
    
    def list(self, request, *args, **kwargs):
        """Override del método list para agregar logs de debug."""
        print(f"🌐 CommunityViewSet list() called - User: {request.user}")
        print(f"🌐 Serializer class: {self.get_serializer_class()}")
        
        # Obtener queryset y serializer
        queryset = self.filter_queryset(self.get_queryset())
        page = self.paginate_queryset(queryset)
        
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            print(f"🎯 USING SERIALIZER: {type(serializer).__name__}")
            print(f"🎯 SERIALIZER INSTANCE: {serializer}")
            print(f"🎯 CONTEXT: {serializer.context}")
            print(f"🎯 SERIALIZER FIELDS: {serializer.child.fields.keys() if hasattr(serializer, 'child') else 'No child'}")
            serialized_data = serializer.data  # Esto debería trigger los métodos del serializer
            print(f"🔥 SERIALIZER DATA GENERATED: {len(serialized_data)} items")
            result = self.get_paginated_response(serialized_data)
        else:
            serializer = self.get_serializer(queryset, many=True)
            print(f"🎯 USING SERIALIZER: {type(serializer).__name__}")
            print(f"🎯 SERIALIZER INSTANCE: {serializer}")
            print(f"🎯 CONTEXT: {serializer.context}")
            print(f"🎯 SERIALIZER FIELDS: {serializer.child.fields.keys() if hasattr(serializer, 'child') else 'No child'}")
            serialized_data = serializer.data  # Esto debería trigger los métodos del serializer
            print(f"🔥 SERIALIZER DATA GENERATED: {len(serialized_data)} items")
            result = Response(serialized_data)
        
        print(f"🌐 Response data preview: {str(result.data)[:200]}...")
        return result
    
    @action(detail=True, methods=['get'])
    def members(self, request, pk=None):
        """Obtener miembros de una comunidad."""
        from ..serializers import CommunityMembershipListSerializer
        
        community = self.get_object()
        memberships = community.memberships.filter(
            status='active'
        ).select_related('user').order_by('-role', 'joined_at')
        
        serializer = CommunityMembershipListSerializer(memberships, many=True)
        return Response(serializer.data)
    
    @action(detail=True, methods=['get'])
    def stats(self, request, pk=None):
        """Obtener estadísticas detalladas de una comunidad."""
        community = self.get_object()
        serializer = CommunityStatsSerializer(community)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def popular(self, request):
        """Obtener comunidades populares (>100 miembros)."""
        popular_communities = self.get_queryset().filter(member_count__gte=100)
        serializer = self.get_serializer(popular_communities, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def by_game(self, request):
        """Agrupar comunidades por tipo de juego."""
        from django.db.models import Count
        
        games = Community.objects.filter(
            is_public=True
        ).values('game_type').annotate(
            count=Count('id')
        ).order_by('-count')
        
        result = {}
        for game in games:
            game_type = game['game_type']
            communities = self.get_queryset().filter(game_type=game_type)[:5]
            result[game_type] = {
                'total_count': game['count'],
                'communities': CommunityListSerializer(communities, many=True).data
            }
        
        return Response(result)
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """
        Estadísticas generales de comunidades con filtros.
        GET /api/communities/stats/
        """
        from django.db.models import Count
        from ..models import GameType, CommunityTag
        
        # Estadísticas básicas
        total_communities = self.get_queryset().count()
        
        # Estadísticas por GameType
        game_type_stats = GameType.objects.filter(is_active=True).annotate(
            community_count=Count('communities', filter=Q(communities__is_public=True))
        ).order_by('-community_count')[:10]
        
        game_type_data = []
        for gt in game_type_stats:
            game_type_data.append({
                'id': gt.id,
                'name': gt.name,
                'slug': gt.slug,
                'community_count': gt.community_count,
                'is_featured': gt.is_featured
            })
        
        # Estadísticas por Categoría
        category_stats = CommunityCategory.objects.filter(is_active=True).annotate(
            community_count=Count('communities', filter=Q(communities__is_public=True))
        ).order_by('-community_count')
        
        category_data = []
        for cat in category_stats:
            category_data.append({
                'id': cat.id,
                'name': cat.name,
                'slug': cat.slug,
                'community_count': cat.community_count
            })
        
        # Estadísticas por Dificultad
        difficulty_stats = Community.objects.filter(is_public=True).values(
            'difficulty_level'
        ).annotate(count=Count('id')).order_by('-count')
        
        # Tags más populares (contar apariciones en las comunidades)
        popular_tags = []
        all_communities = Community.objects.filter(is_public=True).exclude(tags=[])
        tag_count = {}
        
        for community in all_communities:
            for tag in community.tags:
                tag_count[tag] = tag_count.get(tag, 0) + 1
        
        # Ordenar por popularidad
        sorted_tags = sorted(tag_count.items(), key=lambda x: x[1], reverse=True)[:10]
        popular_tags = [{'name': tag, 'usage_count': count} for tag, count in sorted_tags]
        
        stats_data = {
            'total_communities': total_communities,
            'by_game_type': game_type_data,
            'by_category': category_data,
            'by_difficulty': list(difficulty_stats),
            'popular_tags': popular_tags,
            'featured_games_count': game_type_stats.filter(is_featured=True).count(),
            'last_updated': timezone.now().isoformat()
        }
        
        return Response(stats_data)
    
    # ===== ACCIONES DE MEMBRESÍA =====
    
    @action(
        detail=True, 
        methods=['post'], 
        permission_classes=[IsAuthenticated],
        url_path='join'
    )
    def join(self, request, pk=None):
        """
        Unirse a una comunidad.
        POST /api/communities/{id}/join/
        """
        from ..serializers.membership import JoinCommunitySerializer, MembershipDetailSerializer
        from ..permissions import CanJoinCommunity
        from django.db import transaction
        
        print(f"🎯 JOIN REQUEST: user={request.user.username}, community_id={pk}")
        
        community = self.get_object()
        print(f"🏠 COMMUNITY: {community.name}, is_public={community.is_public}")
        
        # Verificar permisos manualmente
        permission = CanJoinCommunity()
        has_permission = permission.has_permission(request, self)
        print(f"🔐 PERMISSION CHECK: {has_permission}")
        
        if not has_permission:
            print(f"❌ PERMISSION DENIED for user {request.user.username}")
            return Response(
                {'error': 'No tienes permisos para unirte a esta comunidad.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = JoinCommunitySerializer(
            data=request.data,
            context={'request': request, 'community': community}
        )
        
        if serializer.is_valid():
            with transaction.atomic():
                membership = serializer.save()
                
                response_serializer = MembershipDetailSerializer(
                    membership,
                    context={'request': request}
                )
                
                print(f"✅ JOIN SUCCESS: {request.user.username} joined {community.name}")
                return Response({
                    'message': f'Te has unido exitosamente a {community.name}',
                    'membership': response_serializer.data
                }, status=status.HTTP_201_CREATED)
        
        print(f"❌ SERIALIZER ERRORS: {serializer.errors}")
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(
        detail=True,
        methods=['delete'],
        permission_classes=[IsAuthenticated],
        url_path='leave'
    )
    def leave(self, request, pk=None):
        """
        Salir de una comunidad.
        DELETE /api/communities/{id}/leave/
        """
        from ..serializers.membership import LeaveCommunitySerializer
        from ..permissions import CanLeaveCommunity
        from django.db import transaction
        
        print(f"🚪 LEAVE REQUEST: user={request.user.username}, community_id={pk}")
        
        community = self.get_object()
        print(f"🏠 COMMUNITY: {community.name}")
        
        # Verificar permisos manualmente
        permission = CanLeaveCommunity()
        has_permission = permission.has_permission(request, self)
        print(f"🔐 LEAVE PERMISSION CHECK: {has_permission}")
        
        if not has_permission:
            print(f"❌ LEAVE PERMISSION DENIED for user {request.user.username}")
            return Response(
                {'error': 'No puedes salir de esta comunidad.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            membership = CommunityMembership.objects.get(
                community=community,
                user=request.user
            )
            print(f"👤 MEMBERSHIP FOUND: role={membership.role}")
        except CommunityMembership.DoesNotExist:
            print(f"❌ NO MEMBERSHIP FOUND for user {request.user.username}")
            return Response(
                {'error': 'No eres miembro de esta comunidad.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = LeaveCommunitySerializer(
            data={},
            context={'request': request, 'community': community}
        )
        
        if serializer.is_valid():
            with transaction.atomic():
                membership_role = membership.role
                membership.delete()
                
                print(f"✅ LEAVE SUCCESS: {request.user.username} left {community.name}")
                return Response({
                    'message': f'Has salido exitosamente de {community.name}',
                    'former_role': membership_role
                }, status=status.HTTP_200_OK)
        
        print(f"❌ LEAVE SERIALIZER ERRORS: {serializer.errors}")
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(
        detail=True,
        methods=['get'],
        permission_classes=[IsAuthenticated],
        url_path='members'
    )
    def members_detailed(self, request, pk=None):
        """
        Listar miembros de la comunidad.
        GET /api/communities/{id}/members/
        """
        from ..serializers.membership import MembershipListSerializer
        
        community = self.get_object()
        
        # Verificar que es miembro o que la comunidad es pública
        is_member = CommunityMembership.objects.filter(
            community=community,
            user=request.user
        ).exists()
        
        if not (community.is_public or is_member):
            return Response(
                {'error': 'No tienes permisos para ver los miembros de esta comunidad.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        memberships = CommunityMembership.objects.filter(
            community=community
        ).select_related('user').order_by('-joined_at')
        
        serializer = MembershipListSerializer(memberships, many=True)
        
        return Response({
            'community': community.name,
            'total_members': len(memberships),
            'members': serializer.data
        }, status=status.HTTP_200_OK)
    
    @action(
        detail=True,
        methods=['get'],
        permission_classes=[IsAuthenticated],
        url_path='members/stats'
    )
    def member_stats(self, request, pk=None):
        """
        Estadísticas de membresía de la comunidad.
        GET /api/communities/{id}/members/stats/
        """
        from ..serializers.membership import CommunityMemberStatsSerializer
        
        community = self.get_object()
        
        # Verificar que es miembro
        is_member = CommunityMembership.objects.filter(
            community=community,
            user=request.user
        ).exists()
        
        if not is_member:
            return Response(
                {'error': 'Debes ser miembro para ver las estadísticas.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        serializer = CommunityMemberStatsSerializer(community)
        
        return Response({
            'community': {
                'id': community.id,
                'name': community.name
            },
            'stats': serializer.data
        }, status=status.HTTP_200_OK)

    # ===== COMMENT ENDPOINTS =====
    # TEMPORARILY DISABLED FOR DEBUGGING
    #
    # @action(
    #     detail=True,
    #     methods=['get'],
    #     permission_classes=[IsAuthenticated],
    #     url_path='comments'
    # )
    # def comments(self, request, pk=None):
    #     """
    #     Obtener todos los comentarios de una comunidad.
    #     GET /api/communities/{id}/comments/
    #     """
    #     from ..serializers import CommentListSerializer
    #     from ..models import Comment
    #     
    #     community = self.get_object()
    #     
    #     # Obtener comentarios de la comunidad
    #     comments = Comment.objects.filter(
    #         post__community=community,
    #         is_deleted=False
    #     ).select_related(
    #         'author', 'post'
    #     ).order_by('-created_at')
    #     
    #     serializer = CommentListSerializer(comments, many=True)
    #     return Response(serializer.data)
    pass
