"""
Paquete de views para comunidades.
"""

# Importar todos los ViewSets desde archivos específicos
from .game_type import GameTypeViewSet
from .tag import CommunityTagViewSet
from .membership import CommunityMembershipViewSet
from .community import CommunityViewSet
from .category import CommunityCategoryViewSet
from .post import PostViewSet
from .post_image import PostImageViewSet
from .comment import CommentViewSet
from .reaction import ReactionViewSet

__all__ = [
    'GameTypeViewSet',
    'CommunityTagViewSet',
    'CommunityMembershipViewSet',
    'CommunityViewSet',
    'CommunityCategoryViewSet',
    'PostViewSet',
    'PostImageViewSet',
    'CommentViewSet',
    'ReactionViewSet',
]
