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

# Importar serializers de reacciones
from .reaction import (
    ReactionSerializer,
    ReactionCreateSerializer,
    ReactionBreakdownSerializer,
    ReactionDetailSerializer,
    ReactionResponseSerializer,
    MyReactionsSerializer,
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

# Importar serializers de Posts
from .post import (
    PostListSerializer,
    PostDetailSerializer,
    PostCreateUpdateSerializer,
    AuthorSerializer,
    CommunityInPostSerializer,
)

# Importar serializers de PostImage
from .post_image import (
    PostImageSerializer,
    PostImageListSerializer,
    PostImageUploadSerializer,
)

# Importar serializers de Comments
from .comment import (
    CommentListSerializer,
    CommentDetailSerializer,
    CommentCreateSerializer,
    CommentUpdateSerializer,
    CommentThreadSerializer,
    CommentAuthorSerializer,
    PostInCommentSerializer,
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
    
    # Serializers de Posts
    'PostListSerializer',
    'PostDetailSerializer',
    'PostCreateUpdateSerializer',
    'AuthorSerializer',
    'CommunityInPostSerializer',
    
    # Serializers de PostImage
    'PostImageSerializer',
    'PostImageListSerializer',
    'PostImageUploadSerializer',
    
    # Serializers de Comments
    'CommentListSerializer',
    'CommentDetailSerializer',
    'CommentCreateSerializer',
    'CommentUpdateSerializer',
    'CommentThreadSerializer',
    'CommentAuthorSerializer',
    'PostInCommentSerializer',
]
