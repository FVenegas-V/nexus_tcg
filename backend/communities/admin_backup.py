"""
Configuración simple del panel de administración para depuración.
TEMPORALMENTE DESHABILITADO - usar admin_safe.py
"""
from django.contrib import admin
from django.utils.html import format_html
from .models import (
    CommunityCategory, Community, CommunityMembership, CommunityTag,
    Post, Comment, Reaction
)

# Todo el contenido del admin está temporalmente comentado para debugging
# Usar communities/admin_safe.py para operaciones básicas

# Importar el admin seguro
from .admin_safe import *


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
    
    # Simplificar para evitar errores de relaciones
    def get_queryset(self, request):
        """Optimizar queries y evitar errores de relaciones."""
        return super().get_queryset(request).select_related('game_type', 'created_by')


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


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    """Admin para posts de comunidades (Fase 3)."""
    list_display = [
        'title_or_excerpt', 'author', 'community', 'comment_count', 
        'reaction_count', 'is_active', 'created_at'
    ]
    list_filter = ['is_active', 'community', 'created_at']
    search_fields = ['title', 'content', 'author__username', 'community__name']
    ordering = ['-created_at']
    readonly_fields = ['created_at', 'updated_at', 'comment_count', 'reaction_count']
    
    fieldsets = (
        ('Contenido', {
            'fields': ('title', 'content', 'image_urls_json')
        }),
        ('Relaciones', {
            'fields': ('author', 'community')
        }),
        ('Estado', {
            'fields': ('is_active',)
        }),
        ('Estadísticas', {
            'fields': ('comment_count', 'reaction_count'),
            'classes': ('collapse',)
        }),
        ('Metadatos', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def title_or_excerpt(self, obj):
        """Muestra título o extracto del contenido."""
        if obj.title:
            return obj.title
        return obj.excerpt
    title_or_excerpt.short_description = 'Título/Contenido'
    
    def get_queryset(self, request):
        """Optimizar queries con select_related."""
        return super().get_queryset(request).select_related('author', 'community')


# Temporalmente deshabilitado para debugging
# @admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    """Admin para comentarios con threading (Fase 3)."""
    list_display = [
        'thread_display', 'author', 'post_title', 'reaction_count', 
        'is_active', 'created_at'
    ]
    list_filter = ['is_active', 'thread_level', 'created_at']
    search_fields = ['content', 'author__username', 'post__title']
    ordering = ['post', 'thread_path', 'created_at']
    readonly_fields = ['created_at', 'updated_at', 'thread_level', 'thread_path', 'reaction_count']
    
    fieldsets = (
        ('Contenido', {
            'fields': ('content',)
        }),
        ('Relaciones', {
            'fields': ('post', 'author', 'parent')
        }),
        ('Threading', {
            'fields': ('thread_level', 'thread_path'),
            'classes': ('collapse',)
        }),
        ('Estado', {
            'fields': ('is_active', 'reaction_count')
        }),
        ('Metadatos', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def thread_display(self, obj):
        """Muestra el comentario con indicador de nivel."""
        return format_html(
            '<span style="margin-left: {}px;">{}</span>',
            obj.thread_level * 20,
            obj.excerpt
        )
    thread_display.short_description = 'Comentario'
    
    def post_title(self, obj):
        """Muestra el título del post."""
        return obj.post.title or obj.post.excerpt
    post_title.short_description = 'Post'
    
    def get_queryset(self, request):
        """Optimizar queries con select_related."""
        return super().get_queryset(request).select_related('author', 'post', 'parent')


# Temporalmente deshabilitado para debugging
# @admin.register(Reaction)
class ReactionAdmin(admin.ModelAdmin):
    """Admin para reacciones emoji (Fase 3)."""
    list_display = [
        'emoji_display', 'user', 'content_type', 'content_preview', 'created_at'
    ]
    list_filter = ['reaction_type', 'content_type', 'created_at']
    search_fields = ['user__username']
    ordering = ['-created_at']
    readonly_fields = ['created_at']
    
    fieldsets = (
        ('Reacción', {
            'fields': ('user', 'reaction_type')
        }),
        ('Contenido', {
            'fields': ('content_type', 'object_id'),
            'description': 'El contenido al que se reacciona (post o comentario)'
        }),
        ('Metadatos', {
            'fields': ('created_at',)
        }),
    )
    
    def emoji_display(self, obj):
        """Muestra el emoji y tipo de reacción."""
        return f"{obj.get_emoji()} {obj.get_display_name()}"
    emoji_display.short_description = 'Reacción'
    
    def content_preview(self, obj):
        """Muestra preview del contenido reaccionado."""
        if obj.content_object:
            if hasattr(obj.content_object, 'title') and obj.content_object.title:
                return obj.content_object.title[:50]
            elif hasattr(obj.content_object, 'content'):
                return obj.content_object.content[:50] + "..."
        return "Contenido eliminado"
    content_preview.short_description = 'Contenido'
    
    def get_queryset(self, request):
        """Optimizar queries con select_related."""
        return super().get_queryset(request).select_related('user', 'content_type')
