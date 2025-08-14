"""
ViewSets y vistas para el modelo GameType.
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db.models import Count, Q
from django_filters.rest_framework import DjangoFilterBackend

from communities.models import GameType
from communities.serializers.game_type import (
    GameTypeListSerializer,
    GameTypeDetailSerializer,
    FeaturedGameTypesSerializer,
    GameTypeStatsSerializer
)


class GameTypeViewSet(viewsets.ModelViewSet):
    """
    ViewSet para tipos de juegos TCG.
    
    Endpoints:
    - GET /api/games/ - Lista todos los juegos con destacados
    - GET /api/games/{id}/ - Detalle de un juego específico
    - GET /api/games/featured/ - Solo juegos destacados
    - GET /api/games/{id}/communities/ - Comunidades del juego
    - GET /api/games/stats/ - Estadísticas de juegos
    """
    
    queryset = GameType.objects.filter(is_active=True).select_related()
    serializer_class = GameTypeListSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['is_featured', 'publisher']
    
    # Solo permitir métodos de lectura
    http_method_names = ['get', 'head', 'options']
    
    def get_serializer_class(self):
        """Retorna el serializer apropiado según la acción."""
        if self.action == 'retrieve':
            return GameTypeDetailSerializer
        elif self.action == 'featured':
            return FeaturedGameTypesSerializer
        elif self.action == 'stats':
            return GameTypeStatsSerializer
        return GameTypeListSerializer
    
    def get_queryset(self):
        """Optimiza queryset con estadísticas."""
        return GameType.objects.filter(is_active=True).order_by('-is_featured', '-community_count', 'name')
    
    def list(self, request, *args, **kwargs):
        """
        Lista tipos de juego con sección de destacados.
        
        Response format:
        {
            "featured": [...],
            "all": [...],
            "stats": {...}
        }
        """
        queryset = self.get_queryset()
        
        # Separar destacados y todos
        featured_games = queryset.filter(is_featured=True)
        all_games = queryset
        
        # Estadísticas
        stats = {
            'total_games': all_games.count(),
            'featured_count': featured_games.count(),
            'total_communities': sum(game.community_count for game in all_games)
        }
        
        # Serializar datos
        featured_data = GameTypeListSerializer(featured_games, many=True).data
        all_data = GameTypeListSerializer(all_games, many=True).data
        
        response_data = {
            'featured': featured_data,
            'all': all_data,
            'stats': stats
        }
        
        return Response(response_data)
    
    @action(detail=False, methods=['get'])
    def featured(self, request):
        """Retorna solo los juegos destacados."""
        featured_games = self.get_queryset().filter(is_featured=True)
        serializer = GameTypeListSerializer(featured_games, many=True)
        return Response({
            'results': serializer.data,
            'count': featured_games.count()
        })
    
    @action(detail=True, methods=['get'])
    def communities(self, request, pk=None):
        """Retorna comunidades públicas asociadas a este GameType."""
        game_type = self.get_object()
        
        # Importar aquí para evitar importación circular
        from communities.models import Community
        
        communities = Community.objects.filter(
            game_type=game_type,
            is_public=True
        ).select_related('creator')
        
        # Serializar comunidades básicas
        communities_data = []
        for community in communities:
            communities_data.append({
                'id': community.id,
                'name': community.name,
                'description': community.description,
                'member_count': community.member_count,
                'created_at': community.created_at,
                'creator': community.creator.username if community.creator else None,
                'tags': community.tags
            })
        
        return Response({
            'game_type': {
                'id': game_type.id,
                'name': game_type.name,
                'slug': game_type.slug
            },
            'communities': communities_data,
            'count': len(communities_data)
        })

    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Retorna estadísticas de tipos de juego."""
        queryset = self.get_queryset()
        
        stats_data = []
        for game in queryset:
            stats_data.append({
                'id': game.id,
                'name': game.name,
                'slug': game.slug,
                'community_count': game.community_count,
                'is_featured': game.is_featured
            })
        
        return Response({
            'total_games': len(stats_data),
            'games': stats_data
        })
    
    @action(detail=True, methods=['get'])
    def communities(self, request, slug=None):
        """Retorna las comunidades de un tipo de juego específico."""
        game_type = self.get_object()
        
        # Importar aquí para evitar circular imports
        from communities.serializers import CommunityListSerializer
        
        communities = game_type.communities.filter(is_public=True)
        serializer = CommunityListSerializer(communities, many=True)
        
        return Response({
            'game_type': GameTypeDetailSerializer(game_type).data,
            'communities': serializer.data,
            'total_communities': communities.count()
        })
