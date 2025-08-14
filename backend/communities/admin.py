"""
Configuración simple del panel de administración para depuración.
"""
from django.contrib import admin
from .models import CommunityCategory, Community, CommunityMembership


@admin.register(CommunityCategory)
class CommunityCategoryAdminSimple(admin.ModelAdmin):
    """Admin simple para categorías."""
    list_display = ['name', 'community_count', 'is_active']
    list_filter = ['is_active']
    search_fields = ['name']


@admin.register(Community)
class CommunityAdminSimple(admin.ModelAdmin):
    """Admin simple para comunidades."""
    list_display = ['name', 'game_type', 'member_count', 'is_public']
    list_filter = ['game_type', 'is_public']
    search_fields = ['name', 'description']


@admin.register(CommunityMembership)
class CommunityMembershipAdminSimple(admin.ModelAdmin):
    """Admin simple para membresías."""
    list_display = ['user', 'community', 'role', 'status']
    list_filter = ['role', 'status']
    search_fields = ['user__username', 'community__name']
