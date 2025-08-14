"""
ViewSets para las APIs de comunidades TCG.
"""
from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.db.models import Q
from django.utils import timezone
from .models import Community, CommunityCategory, CommunityMembership
from .serializers import (
    CommunityListSerializer, CommunityDetailSerializer,
    CommunityCategorySerializer, CommunityMembershipSerializer,
    CommunityMembershipListSerializer, CommunityStatsSerializer
)
from .filters import CommunityFilter


class CommunityCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet para categorías de comunidades.
    Solo lectura - list y retrieve.
    """
    queryset = CommunityCategory.objects.filter(is_active=True).order_by('-community_count', 'name')
    serializer_class = CommunityCategorySerializer
    
    @action(detail=True, methods=['get'])
    def communities(self, request, pk=None):
        """Obtener comunidades de una categoría específica."""
        category = self.get_object()
        communities = Community.objects.filter(
            category=category,
            is_public=True
        ).select_related('category', 'created_by')
        
        serializer = CommunityListSerializer(communities, many=True)
        return Response(serializer.data)


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
    
    @action(detail=True, methods=['get'])
    def members(self, request, pk=None):
        """Obtener miembros de una comunidad."""
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
        from .models import GameType, CommunityTag
        
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
        from .serializers.membership import JoinCommunitySerializer, MembershipDetailSerializer
        from .permissions import CanJoinCommunity
        from django.db import transaction
        
        community = self.get_object()
        
        # Verificar permisos manualmente
        permission = CanJoinCommunity()
        if not permission.has_permission(request, self):
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
                
                return Response({
                    'message': f'Te has unido exitosamente a {community.name}',
                    'membership': response_serializer.data
                }, status=status.HTTP_201_CREATED)
        
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
        from .serializers.membership import LeaveCommunitySerializer
        from .permissions import CanLeaveCommunity
        from django.db import transaction
        
        community = self.get_object()
        
        # Verificar permisos manualmente
        permission = CanLeaveCommunity()
        if not permission.has_permission(request, self):
            return Response(
                {'error': 'No puedes salir de esta comunidad.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        try:
            membership = CommunityMembership.objects.get(
                community=community,
                user=request.user
            )
        except CommunityMembership.DoesNotExist:
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
                
                return Response({
                    'message': f'Has salido exitosamente de {community.name}',
                    'former_role': membership_role
                }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(
        detail=True,
        methods=['get'],
        permission_classes=[IsAuthenticated],
        url_path='members'
    )
    def members(self, request, pk=None):
        """
        Listar miembros de la comunidad.
        GET /api/communities/{id}/members/
        """
        from .serializers.membership import MembershipListSerializer
        
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
        from .serializers.membership import CommunityMemberStatsSerializer
        
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


class CommunityMembershipViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet para membresías de comunidades.
    Solo lectura por ahora.
    """
    queryset = CommunityMembership.objects.filter(
        status='active'
    ).select_related('user', 'community')
    
    serializer_class = CommunityMembershipSerializer
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['role', 'status', 'community__game_type']
    ordering_fields = ['joined_at']
    ordering = ['-joined_at']
    
    @action(detail=False, methods=['get'])
    def by_user(self, request):
        """Obtener membresías de un usuario específico."""
        user_id = request.query_params.get('user_id')
        if not user_id:
            return Response(
                {'error': 'user_id parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        memberships = self.get_queryset().filter(user_id=user_id)
        serializer = self.get_serializer(memberships, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def moderators(self, request):
        """Obtener todos los moderadores y admins."""
        moderators = self.get_queryset().filter(
            role__in=['moderator', 'admin']
        )
        serializer = self.get_serializer(moderators, many=True)
        return Response(serializer.data)
