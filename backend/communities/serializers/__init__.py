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

# Importar serializers de Community y Category
from .community import (
    CommunityListSerializer,
    CommunityDetailSerializer,
    CommunityStatsSerializer,
    CommunityMembershipSerializer,
    CommunityMembershipListSerializer,
)

from .category import (
    CommunityCategorySerializer,
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
    
    # Serializers de Community
    'CommunityListSerializer',
    'CommunityDetailSerializer',
    'CommunityStatsSerializer',
    'CommunityMembershipSerializer',
    'CommunityMembershipListSerializer',
    
    # Serializers de Category
    'CommunityCategorySerializer',
]
