"""
Configuración simple del panel de administración para depuración.
"""
from django.contrib import admin
from .models import CommunityCategory, Community, CommunityMembership, CommunityTag


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


@admin.register(CommunityTag)
class CommunityTagAdmin(admin.ModelAdmin):
    """Admin para tags de comunidades (Fase 2)."""
    list_display = ['name', 'display_name', 'description', 'usage_count', 'is_suggested', 'created_at']
    list_filter = ['is_suggested', 'created_at']
    search_fields = ['name', 'display_name', 'description']
    ordering = ['-usage_count', 'name']
    readonly_fields = ['created_at', 'usage_count']
    
    fieldsets = (
        ('Información Básica', {
            'fields': ('name', 'display_name', 'description')
        }),
        ('Configuración', {
            'fields': ('is_suggested',)
        }),
        ('Estadísticas', {
            'fields': ('usage_count',)
        }),
        ('Metadatos', {
            'fields': ('created_at', 'created_by'),
            'classes': ('collapse',)
        }),
    )
