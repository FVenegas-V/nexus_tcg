"""
Configuración del panel de administración para GameType (Fase 2).
"""
from django.contrib import admin
from .models import GameType


@admin.register(GameType)
class GameTypeAdmin(admin.ModelAdmin):
    """Admin para tipos de juego (Fase 2)."""
    list_display = ['name', 'slug', 'release_year', 'min_players', 'max_players', 'community_count', 'is_featured']
    list_filter = ['is_featured', 'release_year', 'min_players', 'max_players']
    search_fields = ['name', 'description']
    ordering = ['name']
    readonly_fields = ['slug', 'community_count', 'created_at', 'updated_at']
    prepopulated_fields = {'slug': ('name',)}
    
    fieldsets = (
        ('Información Básica', {
            'fields': ('name', 'slug', 'description', 'logo_url')
        }),
        ('Detalles del Juego', {
            'fields': ('release_year', 'min_players', 'max_players', 'estimated_game_duration')
        }),
        ('Configuración', {
            'fields': ('is_featured',)
        }),
        ('Estadísticas', {
            'fields': ('community_count',),
            'classes': ('collapse',)
        }),
        ('Fechas', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def save_model(self, request, obj, form, change):
        """Asegurar que el slug se genere automáticamente."""
        if not obj.slug:
            from django.utils.text import slugify
            obj.slug = slugify(obj.name)
        super().save_model(request, obj, form, change)
