"""
Admin completo pero seguro para todas las funcionalidades.
"""
from django.contrib import admin
from django.utils.html import format_html
from .models import (
    CommunityCategory, Community, CommunityMembership, CommunityTag,
    Post, Comment, Reaction, GameType
)


@admin.register(GameType)
class GameTypeAdmin(admin.ModelAdmin):
    """Admin para tipos de juegos."""
    list_display = ['name', 'description', 'is_active']
    list_filter = ['is_active']
    search_fields = ['name', 'description']


@admin.register(CommunityCategory)
class CommunityCategoryAdmin(admin.ModelAdmin):
    """Admin para categorías de comunidades."""
    list_display = ['name', 'community_count', 'is_active']
    list_filter = ['is_active']
    search_fields = ['name']
    readonly_fields = ['community_count']


@admin.register(Community)
class CommunityAdmin(admin.ModelAdmin):
    """Admin completo pero seguro para comunidades."""
    
    list_display = ['id', 'name', 'game_type', 'member_count', 'post_count', 'is_public', 'created_at']
    list_filter = ['game_type', 'is_public', 'difficulty_level', 'created_at']
    search_fields = ['name', 'description']
    readonly_fields = ['member_count', 'post_count', 'created_at', 'updated_at', 'slug']
    
    fieldsets = (
        ('Información Básica', {
            'fields': ('name', 'slug', 'description', 'game_type')
        }),
        ('Configuración', {
            'fields': ('is_public', 'difficulty_level', 'requires_approval', 'max_members')
        }),
        ('Estadísticas', {
            'fields': ('member_count', 'post_count'),
            'classes': ('collapse',)
        }),
        ('Metadatos', {
            'fields': ('created_by', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    # Permitir eliminación masiva
    actions = ['delete_selected']
    
    def get_queryset(self, request):
        """Optimizar queries."""
        return super().get_queryset(request).select_related('game_type', 'created_by', 'category')


@admin.register(CommunityMembership)
class CommunityMembershipAdmin(admin.ModelAdmin):
    """Admin para membresías de comunidades."""
    
    list_display = ['user', 'community', 'role', 'status', 'joined_at']
    list_filter = ['role', 'status', 'joined_at']
    search_fields = ['user__username', 'user__email', 'community__name']
    readonly_fields = ['joined_at']
    
    fieldsets = (
        ('Membresía', {
            'fields': ('user', 'community', 'role', 'status')
        }),
        ('Metadatos', {
            'fields': ('joined_at',)
        }),
    )
    
    def get_queryset(self, request):
        """Optimizar queries."""
        return super().get_queryset(request).select_related('user', 'community')


@admin.register(CommunityTag)
class CommunityTagAdmin(admin.ModelAdmin):
    """Admin para tags de comunidades."""
    
    list_display = ['name', 'display_name', 'usage_count', 'is_suggested', 'created_at']
    list_filter = ['is_suggested', 'created_at']
    search_fields = ['name', 'display_name', 'description']
    readonly_fields = ['created_at', 'usage_count']
    ordering = ['-usage_count', 'name']


@admin.register(Post)
class PostAdmin(admin.ModelAdmin):
    """Admin para posts."""
    
    list_display = ['title_display', 'author', 'community', 'comment_count', 'reaction_count', 'is_active', 'created_at']
    list_filter = ['is_active', 'community', 'created_at']
    search_fields = ['title', 'content', 'author__username']
    readonly_fields = ['created_at', 'updated_at', 'comment_count', 'reaction_count']
    ordering = ['-created_at']
    
    fieldsets = (
        ('Contenido', {
            'fields': ('title', 'content', 'author', 'community')
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
    
    def title_display(self, obj):
        """Muestra título o excerpt."""
        return obj.title or obj.excerpt[:50] + "..." if obj.content else "Sin título"
    title_display.short_description = 'Título'
    
    def get_queryset(self, request):
        """Optimizar queries."""
        return super().get_queryset(request).select_related('author', 'community')


@admin.register(Comment)
class CommentAdmin(admin.ModelAdmin):
    """Admin básico para comentarios."""
    
    list_display = ['content_preview', 'author', 'post_title', 'is_active', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['content', 'author__username']
    readonly_fields = ['created_at', 'updated_at', 'reaction_count', 'thread_level', 'thread_path']
    ordering = ['-created_at']
    
    fieldsets = (
        ('Contenido', {
            'fields': ('content', 'author', 'post', 'parent')
        }),
        ('Estado', {
            'fields': ('is_active',)
        }),
        ('Threading', {
            'fields': ('thread_level', 'thread_path'),
            'classes': ('collapse',)
        }),
        ('Metadatos', {
            'fields': ('created_at', 'updated_at', 'reaction_count'),
            'classes': ('collapse',)
        }),
    )
    
    def content_preview(self, obj):
        """Preview del contenido."""
        return obj.content[:100] + "..." if len(obj.content) > 100 else obj.content
    content_preview.short_description = 'Contenido'
    
    def post_title(self, obj):
        """Título del post."""
        return obj.post.title or obj.post.excerpt[:30] + "..."
    post_title.short_description = 'Post'
    
    def get_queryset(self, request):
        """Optimizar queries."""
        return super().get_queryset(request).select_related('author', 'post')


@admin.register(Reaction)
class ReactionAdmin(admin.ModelAdmin):
    """Admin para reacciones."""
    
    list_display = ['reaction_display', 'user', 'content_type', 'content_preview', 'created_at']
    list_filter = ['reaction_type', 'content_type', 'created_at']
    search_fields = ['user__username']
    readonly_fields = ['created_at']
    ordering = ['-created_at']
    
    def reaction_display(self, obj):
        """Muestra la reacción."""
        emoji_map = {
            'like': '👍',
            'dislike': '👎',
            'love': '❤️',
            'laugh': '😂',
            'angry': '😠'
        }
        emoji = emoji_map.get(obj.reaction_type, '❓')
        return f"{emoji} {obj.reaction_type}"
    reaction_display.short_description = 'Reacción'
    
    def content_preview(self, obj):
        """Preview del contenido."""
        if obj.content_object:
            if hasattr(obj.content_object, 'title') and obj.content_object.title:
                return obj.content_object.title[:50]
            elif hasattr(obj.content_object, 'content'):
                return obj.content_object.content[:50] + "..."
        return "Contenido eliminado"
    content_preview.short_description = 'Contenido'
    
    def get_queryset(self, request):
        """Optimizar queries."""
        return super().get_queryset(request).select_related('user', 'content_type')
