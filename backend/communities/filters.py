"""
Filtros personalizados para las APIs de comunidades.
"""
import django_filters
from django.db.models import Q, F
from .models import Community, CommunityCategory, GameType, Post


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


class PostFilter(django_filters.FilterSet):
    """
    Filtros avanzados para Posts con búsqueda y filtrado por comunidad.
    """
    # === FILTROS BÁSICOS ===
    community = django_filters.NumberFilter(
        field_name='community__id',
        help_text="Filtrar por ID de comunidad"
    )
    community_name = django_filters.CharFilter(
        field_name='community__name',
        lookup_expr='icontains',
        help_text="Filtrar por nombre de comunidad (parcial)"
    )
    author = django_filters.NumberFilter(
        field_name='author__id',
        help_text="Filtrar por ID del autor"
    )
    author_username = django_filters.CharFilter(
        field_name='author__username',
        lookup_expr='icontains',
        help_text="Filtrar por nombre de usuario del autor"
    )
    
    # === FILTROS DE FECHA ===
    created_after = django_filters.DateTimeFilter(
        field_name='created_at',
        lookup_expr='gte',
        help_text="Posts creados después de esta fecha"
    )
    created_before = django_filters.DateTimeFilter(
        field_name='created_at',
        lookup_expr='lte',
        help_text="Posts creados antes de esta fecha"
    )
    updated_after = django_filters.DateTimeFilter(
        field_name='updated_at',
        lookup_expr='gte',
        help_text="Posts actualizados después de esta fecha"
    )
    
    # === FILTROS DE CONTENIDO ===
    has_images = django_filters.BooleanFilter(
        method='filter_has_images',
        help_text="Posts que tienen imágenes"
    )
    min_reactions = django_filters.NumberFilter(
        field_name='total_reactions',
        lookup_expr='gte',
        help_text="Posts con al menos X reacciones"
    )
    
    # === FILTROS DE COMUNIDAD ===
    game_type = django_filters.CharFilter(
        field_name='community__game_type',
        help_text="Filtrar por tipo de juego de la comunidad"
    )
    difficulty_level = django_filters.CharFilter(
        field_name='community__difficulty_level',
        help_text="Filtrar por nivel de dificultad de la comunidad"
    )
    
    # === BÚSQUEDA COMBINADA ===
    search = django_filters.CharFilter(
        method='filter_search',
        help_text="Búsqueda en título, contenido y datos de comunidad"
    )
    
    # === FILTROS DE MEMBRESÍA ===
    my_communities = django_filters.BooleanFilter(
        method='filter_my_communities',
        help_text="Posts solo de comunidades donde soy miembro"
    )
    
    class Meta:
        model = Post
        fields = [
            'community', 'author', 'is_active',
            'created_after', 'created_before', 'updated_after',
            'has_images', 'min_reactions', 'game_type', 'difficulty_level'
        ]
    
    def filter_has_images(self, queryset, name, value):
        """Filtrar posts que tienen imágenes."""
        if value:
            return queryset.filter(images__isnull=False).distinct()
        elif value is False:
            return queryset.filter(images__isnull=True)
        return queryset
    
    def filter_search(self, queryset, name, value):
        """
        Búsqueda combinada en título, contenido, autor y comunidad.
        """
        if not value:
            return queryset
        
        return queryset.filter(
            Q(title__icontains=value) |
            Q(content__icontains=value) |
            Q(author__username__icontains=value) |
            Q(community__name__icontains=value) |
            Q(community__description__icontains=value)
        ).distinct()
    
    def filter_my_communities(self, queryset, name, value):
        """
        Filtrar posts solo de comunidades donde el usuario es miembro.
        """
        if not value or not self.request or not self.request.user.is_authenticated:
            return queryset
        
        # Obtener IDs de comunidades donde el usuario es miembro
        from .models import CommunityMembership
        user_communities = CommunityMembership.objects.filter(
            user=self.request.user,
            status='active'
        ).values_list('community_id', flat=True)
        
        return queryset.filter(community_id__in=user_communities)
