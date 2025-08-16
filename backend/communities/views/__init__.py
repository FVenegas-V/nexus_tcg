"""
Paquete de views para comunidades.
"""

# Importar todos los ViewSets desde archivos específicos
from .game_type import GameTypeViewSet
from .tag import CommunityTagViewSet
from .membership import CommunityMembershipViewSet
from .community import CommunityViewSet
from .category import CommunityCategoryViewSet

__all__ = [
    'GameTypeViewSet',
    'CommunityTagViewSet',
    'CommunityMembershipViewSet',
    'CommunityViewSet',
    'CommunityCategoryViewSet',
]
