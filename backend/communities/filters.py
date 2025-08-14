"""
Filtros personalizados para las APIs de comunidades.
"""
import django_filters
from django.db.models import Q, F
from .models import Community, CommunityCategory, GameType


class CommunityFilter(django_filters.FilterSet):
    """
    Filtros avanzados para comunidades con soporte para GameType y Tags mejorados.
    """
    # === FILTROS DE GAME TYPE ===
    game_type = django_filters.ModelChoiceFilter(
        queryset=GameType.objects.filter(is_active=True),
        help_text="Filtrar por tipo de juego específico (ID)"
    )
    game_type_slug = django_filters.CharFilter(
        field_name='game_type__slug',
        lookup_expr='exact',
        help_text="Filtrar por slug del tipo de juego"
    )
    game_type_name = django_filters.CharFilter(
        field_name='game_type__name',
        lookup_expr='icontains',
        help_text="Búsqueda por nombre del juego (parcial)"
    )
    is_featured_game = django_filters.BooleanFilter(
        field_name='game_type__is_featured',
        help_text="Filtrar por juegos destacados"
    )
    
    # === FILTROS BÁSICOS ===
    difficulty_level = django_filters.ChoiceFilter(
        choices=[
            ('principiante', 'Principiante'),
            ('intermedio', 'Intermedio'),
            ('avanzado', 'Avanzado'),
        ]
    )
    category = django_filters.ModelChoiceFilter(
        queryset=CommunityCategory.objects.filter(is_active=True)
    )
    category_slug = django_filters.CharFilter(
        field_name='category__slug',
        lookup_expr='exact',
        help_text="Filtrar por slug de categoría"
    )
    category_name = django_filters.CharFilter(
        field_name='category__name',
        lookup_expr='icontains'
    )
    
    # === FILTROS DE TAGS ===
    tags = django_filters.CharFilter(
        method='filter_tags',
        help_text="Filtrar por tags (separados por comas para múltiples)"
    )
    has_tag = django_filters.CharFilter(
        method='filter_has_tag',
        help_text="Filtrar comunidades que tienen un tag específico"
    )
    
    # === FILTROS DE CONFIGURACIÓN ===
    is_public = django_filters.BooleanFilter()
    requires_approval = django_filters.BooleanFilter()
    
    # === FILTROS DE CAPACIDAD ===
    has_space = django_filters.BooleanFilter(method='filter_has_space')
    is_full = django_filters.BooleanFilter(method='filter_is_full')
    
    # === FILTROS DE POPULARIDAD ===
    is_popular = django_filters.BooleanFilter(method='filter_is_popular')
    min_members = django_filters.NumberFilter(field_name='member_count', lookup_expr='gte')
    max_members = django_filters.NumberFilter(field_name='member_count', lookup_expr='lte')
    
    # === FILTROS DE TIEMPO ===
    created_after = django_filters.DateTimeFilter(field_name='created_at', lookup_expr='gte')
    created_before = django_filters.DateTimeFilter(field_name='created_at', lookup_expr='lte')
    
    # === FILTRO DE BÚSQUEDA COMBINADA ===
    search = django_filters.CharFilter(method='filter_search')
    
    class Meta:
        model = Community
        fields = [
            # Game Type filters
            'game_type', 'game_type_slug', 'game_type_name', 'is_featured_game',
            # Basic filters
            'difficulty_level', 'category', 'category_slug', 'category_name',
            # Tag filters
            'tags', 'has_tag',
            # Configuration filters
            'is_public', 'requires_approval',
            # Capacity filters
            'has_space', 'is_full', 'is_popular',
            'min_members', 'max_members',
            # Time filters
            'created_after', 'created_before',
            # Search
            'search'
        ]
    
    def filter_tags(self, queryset, name, value):
        """
        Filtrar por múltiples tags (separados por comas).
        Ejemplos: ?tags=competitive,trading
        """
        if not value:
            return queryset
        
        tag_list = [tag.strip().lower() for tag in value.split(',') if tag.strip()]
        if not tag_list:
            return queryset
        
        # Filtrar comunidades que contengan TODOS los tags especificados
        for tag in tag_list:
            queryset = queryset.filter(tags__icontains=tag)
        
        return queryset
    
    def filter_has_tag(self, queryset, name, value):
        """
        Filtrar comunidades que tienen un tag específico.
        Ejemplos: ?has_tag=competitive
        """
        if not value:
            return queryset
        
        tag = value.strip().lower()
        return queryset.filter(tags__icontains=tag)
    
    def filter_has_space(self, queryset, name, value):
        """Filtrar comunidades que tienen espacio disponible."""
        if value:
            return queryset.filter(
                Q(max_members__isnull=True) |
                Q(member_count__lt=F('max_members'))
            )
        return queryset
    
    def filter_is_full(self, queryset, name, value):
        """Filtrar comunidades llenas."""
        if value:
            return queryset.filter(
                max_members__isnull=False,
                member_count__gte=F('max_members')
            )
        elif value is False:
            return queryset.filter(
                Q(max_members__isnull=True) |
                Q(member_count__lt=F('max_members'))
            )
        return queryset
    
    def filter_is_popular(self, queryset, name, value):
        """Filtrar comunidades populares (>100 miembros)."""
        if value:
            return queryset.filter(member_count__gte=100)
        elif value is False:
            return queryset.filter(member_count__lt=100)
        return queryset
    
    def filter_search(self, queryset, name, value):
        """
        Búsqueda combinada en múltiples campos incluyendo GameType.
        """
        if not value:
            return queryset
        
        return queryset.filter(
            Q(name__icontains=value) |
            Q(description__icontains=value) |
            Q(game_type__name__icontains=value) |
            Q(game_type__publisher__icontains=value) |
            Q(tags__icontains=value) |
            Q(category__name__icontains=value)
        )
