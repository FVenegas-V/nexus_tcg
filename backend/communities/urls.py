"""
URLs para las APIs de comunidades.
"""
from django.urls import path, include
from rest_framework.routers import DefaultRouter

# Importar todos los ViewSets desde el paquete views
from .views import (
    GameTypeViewSet,
    CommunityTagViewSet,
    CommunityMembershipViewSet,
    CommunityViewSet,
    CommunityCategoryViewSet,
)

# Router principal
router = DefaultRouter()
router.register(r'games', GameTypeViewSet)
router.register(r'tags', CommunityTagViewSet)
router.register(r'communities', CommunityViewSet)
router.register(r'categories', CommunityCategoryViewSet)

# Registrar MembershipViewSet con basename personalizado
router.register(r'memberships', CommunityMembershipViewSet, basename='membership')

app_name = 'communities'

urlpatterns = [
    # URLs del router principal
    path('api/', include(router.urls)),
]
