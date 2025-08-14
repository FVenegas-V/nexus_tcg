"""
ViewSets y vistas para el modelo CommunityTag.
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticatedOrReadOnly
from django.db.models import Q, Count
from django_filters.rest_framework import DjangoFilterBackend

from communities.models import CommunityTag
from communities.serializers.tag import (
    CommunityTagSerializer,
    TagAutocompleteSerializer,
    PopularTagsSerializer,
    TagStatsSerializer
)


class CommunityTagViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet para tags de comunidades.
    
    Endpoints:
    - GET /api/tags/ - Lista todos los tags
    - GET /api/tags/{id}/ - Detalle de un tag específico
    - GET /api/tags/popular/ - Tags más populares
    - GET /api/tags/suggested/ - Tags sugeridos
    - GET /api/tags/search/?q=query - Búsqueda para autocompletado
    """
    
    queryset = CommunityTag.objects.all()
    serializer_class = CommunityTagSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['is_suggested']
    
    def get_serializer_class(self):
        """Retorna el serializer apropiado según la acción."""
        if self.action in ['popular', 'suggested']:
            return PopularTagsSerializer
        elif self.action == 'search':
            return TagAutocompleteSerializer
        return CommunityTagSerializer
    
    def get_queryset(self):
        """Ordena por uso y popularidad."""
        return CommunityTag.objects.all().order_by('-usage_count', 'name')
    
    def list(self, request, *args, **kwargs):
        """Lista tags con paginación."""
        queryset = self.filter_queryset(self.get_queryset())
        
        # Limitar a 50 tags por defecto para evitar respuestas muy grandes
        limit = min(int(request.query_params.get('limit', 50)), 100)
        queryset = queryset[:limit]
        
        serializer = self.get_serializer(queryset, many=True)
        
        return Response({
            'tags': serializer.data,
            'total_count': self.get_queryset().count(),
            'showing': len(serializer.data)
        })
    
    @action(detail=False, methods=['get'])
    def popular(self, request):
        """Retorna los tags más populares."""
        limit = min(int(request.query_params.get('limit', 20)), 50)
        
        popular_tags = self.get_queryset().filter(
            usage_count__gt=0
        ).order_by('-usage_count')[:limit]
        
        serializer = self.get_serializer(popular_tags, many=True)
        
        return Response({
            'popular_tags': serializer.data,
            'total_popular': self.get_queryset().filter(usage_count__gt=0).count()
        })
    
    @action(detail=False, methods=['get'])
    def suggestions(self, request):
        """
        Sugerencias de tags por prefijo para autocompletado.
        
        Query params:
        - prefix: prefijo de búsqueda (requerido)
        - limit: número máximo de resultados (default: 10, max: 20)
        """
        prefix = request.query_params.get('prefix', '').strip()
        
        if not prefix:
            return Response({
                'error': 'Parámetro "prefix" es requerido'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        limit = min(int(request.query_params.get('limit', 10)), 20)
        
        # Búsqueda por prefijo (case-insensitive)
        matching_tags = self.get_queryset().filter(
            name__istartswith=prefix
        ).order_by('-usage_count', 'name')[:limit]
        
        serializer = self.get_serializer(matching_tags, many=True)
        return Response({
            'suggestions': serializer.data,
            'count': matching_tags.count(),
            'prefix': prefix
        })

    @action(detail=False, methods=['get'])
    def suggested(self, request):
        """Retorna tags sugeridos para usar."""
        suggested_tags = self.get_queryset().filter(
            is_suggested=True
        ).order_by('-usage_count', 'name')
        
        serializer = self.get_serializer(suggested_tags, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def search(self, request):
        """
        Búsqueda de tags para autocompletado.
        
        Query params:
        - q: término de búsqueda (puede estar vacío para devolver todos)
        - limit: número máximo de resultados (default: 10, max: 20)
        """
        query = request.query_params.get('q', '').strip()
        limit = min(int(request.query_params.get('limit', 10)), 20)
        
        if not query:
            # Si no hay query, devolver todos los tags ordenados por popularidad
            matching_tags = self.get_queryset().order_by('-usage_count', 'name')[:limit]
        else:
            # Búsqueda por nombre (case-insensitive) - permitir cualquier longitud
            matching_tags = self.get_queryset().filter(
                Q(name__icontains=query) | Q(description__icontains=query)
            ).order_by('-usage_count', 'name')[:limit]
        
        serializer = self.get_serializer(matching_tags, many=True)
        
        return Response({
            'query': query,
            'tags': serializer.data,
            'count': len(serializer.data)
        })
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Retorna estadísticas generales de tags."""
        total_tags = self.get_queryset().count()
        popular_tags = self.get_queryset().filter(usage_count__gt=0).order_by('-usage_count')[:10]
        suggested_tags = self.get_queryset().filter(is_suggested=True).order_by('-usage_count')[:5]
        
        stats_data = {
            'total_tags': total_tags,
            'popular_tags': PopularTagsSerializer(popular_tags, many=True).data,
            'suggested_tags': TagAutocompleteSerializer(suggested_tags, many=True).data,
            'unused_tags': total_tags - self.get_queryset().filter(usage_count__gt=0).count()
        }
        
        return Response(stats_data)
    
    @action(detail=True, methods=['get'])
    def communities(self, request, pk=None):
        """Retorna comunidades que usan este tag."""
        tag = self.get_object()
        
        # Importar aquí para evitar circular imports
        from communities.models import Community
        from communities.serializers import CommunityListSerializer
        
        # Buscar comunidades que contengan este tag en su lista
        communities = Community.objects.filter(
            tags__contains=[tag.name],
            is_public=True
        ).select_related('game_type', 'category', 'created_by')
        
        serializer = CommunityListSerializer(communities, many=True)
        
        return Response({
            'tag': CommunityTagSerializer(tag).data,
            'communities': serializer.data,
            'total_communities': communities.count()
        })
