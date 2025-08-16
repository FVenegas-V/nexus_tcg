"""
ViewSets para categorías de comunidades.
"""
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from ..models import CommunityCategory, Community
from ..serializers import CommunityCategorySerializer, CommunityListSerializer


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
