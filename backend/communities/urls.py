"""
URLs para las APIs de comunidades.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter

# Importar ViewSets disponibles
from .views.game_type import GameTypeViewSet
from .views.tag import CommunityTagViewSet

# Router principal
router = DefaultRouter()
router.register(r'games', GameTypeViewSet)
router.register(r'tags', CommunityTagViewSet)

app_name = 'communities'

urlpatterns = [
    # URLs del router principal
    path('api/', include(router.urls)),
]
