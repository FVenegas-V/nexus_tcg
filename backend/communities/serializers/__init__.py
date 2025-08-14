"""
Paquete de serializers para comunidades.
"""

# Importar serializers especializados de membresía
from .membership import (
    JoinCommunitySerializer,
    LeaveCommunitySerializer,
    MembershipDetailSerializer,
    MembershipListSerializer,
)

# Importar serializers de GameType y Tags
from .game_type import (
    GameTypeListSerializer,
    GameTypeDetailSerializer,
    GameTypeStatsSerializer,
    FeaturedGameTypesSerializer,
)

from .tag import (
    CommunityTagSerializer,
    TagAutocompleteSerializer,
    PopularTagsSerializer,
    TagStatsSerializer,
)

__all__ = [
    # Serializers de membresía
    'JoinCommunitySerializer',
    'LeaveCommunitySerializer',
    'MembershipDetailSerializer',
    'MembershipListSerializer',
    
    # Serializers de GameType
    'GameTypeListSerializer',
    'GameTypeDetailSerializer',
    'GameTypeStatsSerializer',
    'FeaturedGameTypesSerializer',
    
    # Serializers de Tags
    'CommunityTagSerializer',
    'TagAutocompleteSerializer',
    'PopularTagsSerializer',
    'TagStatsSerializer',
]
