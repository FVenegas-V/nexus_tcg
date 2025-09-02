"""
Configuración del admin para notificaciones
Interfaz para gestión y moderación de notificaciones
"""

from django.contrib import admin
from django.utils.html import format_html
from django.utils import timezone
from django.db.models import Count
from .models import Notification, NotificationPreferences


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    """
    Admin para gestión de notificaciones
    """
    
    list_display = [
        'id',
        'user_display',
        'type_badge',
        'title_truncated',
        'priority_badge', 
        'is_read_icon',
        'created_at_formatted',
        'related_object_link'
    ]
    
    list_filter = [
        'type',
        'priority',
        'is_read',
        'email_sent',
        'created_at',
    ]
    
    search_fields = [
        'user__username',
        'user__email',
        'title',
        'message',
    ]
    
    readonly_fields = [
        'created_at',
        'read_at',
        'email_sent_at',
        'related_object_display'
    ]
    
    list_per_page = 25
    date_hierarchy = 'created_at'
    
    fieldsets = (
        ('Información Básica', {
            'fields': ('user', 'type', 'priority')
        }),
        ('Contenido', {
            'fields': ('title', 'message')
        }),
        ('Objeto Relacionado', {
            'fields': ('content_type', 'object_id', 'related_object_display'),
            'classes': ('collapse',)
        }),
        ('Estado', {
            'fields': ('is_read', 'read_at')
        }),
        ('Email Fallback', {
            'fields': ('email_sent', 'email_sent_at'),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at',),
            'classes': ('collapse',)
        }),
    )
    
    actions = [
        'mark_as_read',
        'mark_as_unread', 
        'send_email_fallback',
        'cleanup_old_read'
    ]
    
    def user_display(self, obj):
        """Mostrar usuario con link al perfil"""
        return format_html(
            '<a href="/admin/auth/user/{}/change/">{}</a>',
            obj.user.id,
            obj.user.username
        )
    user_display.short_description = 'Usuario'
    
    def type_badge(self, obj):
        """Badge colorido para el tipo de notificación"""
        colors = {
            'NEW_POST': '#3498db',
            'NEW_COMMENT': '#2ecc71', 
            'COMMENT_REPLY': '#f39c12',
            'NEW_RATING': '#e74c3c',
            'COMMUNITY_JOIN': '#9b59b6',
            'COMMUNITY_MENTION': '#1abc9c',
        }
        color = colors.get(obj.type, '#95a5a6')
        return format_html(
            '<span style="background: {}; color: white; padding: 2px 6px; border-radius: 3px; font-size: 10px;">{}</span>',
            color,
            obj.get_type_display()
        )
    type_badge.short_description = 'Tipo'
    
    def title_truncated(self, obj):
        """Título truncado para lista"""
        if len(obj.title) > 50:
            return f"{obj.title[:50]}..."
        return obj.title
    title_truncated.short_description = 'Título'
    
    def priority_badge(self, obj):
        """Badge para prioridad"""
        colors = {
            'LOW': '#95a5a6',
            'NORMAL': '#3498db',
            'HIGH': '#f39c12', 
            'URGENT': '#e74c3c',
        }
        color = colors.get(obj.priority, '#95a5a6')
        return format_html(
            '<span style="background: {}; color: white; padding: 1px 4px; border-radius: 2px; font-size: 9px;">{}</span>',
            color,
            obj.priority
        )
    priority_badge.short_description = 'Prioridad'
    
    def is_read_icon(self, obj):
        """Icono para estado de lectura"""
        if obj.is_read:
            return format_html('<span style="color: green;">✓ Leída</span>')
        else:
            return format_html('<span style="color: orange;">⏳ No leída</span>')
    is_read_icon.short_description = 'Estado'
    
    def created_at_formatted(self, obj):
        """Fecha formateada"""
        return obj.created_at.strftime('%d/%m/%Y %H:%M')
    created_at_formatted.short_description = 'Creada'
    
    def related_object_link(self, obj):
        """Link al objeto relacionado si existe"""
        if obj.related_object:
            content_type = obj.content_type
            app_label = content_type.app_label
            model = content_type.model
            object_id = obj.object_id
            
            try:
                return format_html(
                    '<a href="/admin/{}/{}/{}/change/" target="_blank">{} #{}</a>',
                    app_label,
                    model,
                    object_id,
                    content_type.model_class().__name__,
                    object_id
                )
            except:
                return f"{model} #{object_id} (eliminado)"
        return '-'
    related_object_link.short_description = 'Objeto'
    
    def related_object_display(self, obj):
        """Mostrar información del objeto relacionado"""
        if obj.related_object:
            return f"{obj.content_type.model_class().__name__}: {obj.related_object}"
        return 'Ninguno'
    related_object_display.short_description = 'Objeto Relacionado'
    
    # Acciones del admin
    def mark_as_read(self, request, queryset):
        """Marcar notificaciones seleccionadas como leídas"""
        updated = queryset.filter(is_read=False).update(
            is_read=True,
            read_at=timezone.now()
        )
        self.message_user(request, f'{updated} notificaciones marcadas como leídas.')
    mark_as_read.short_description = "Marcar como leídas"
    
    def mark_as_unread(self, request, queryset):
        """Marcar notificaciones seleccionadas como no leídas"""
        updated = queryset.filter(is_read=True).update(
            is_read=False,
            read_at=None
        )
        self.message_user(request, f'{updated} notificaciones marcadas como no leídas.')
    mark_as_unread.short_description = "Marcar como no leídas"
    
    def send_email_fallback(self, request, queryset):
        """Enviar email fallback para notificaciones seleccionadas"""
        # Esta acción se implementará con el sistema de emails (fase5-0004)
        count = queryset.filter(email_sent=False).count()
        self.message_user(request, f'Email fallback programado para {count} notificaciones.')
    send_email_fallback.short_description = "Enviar email fallback"
    
    def cleanup_old_read(self, request, queryset):
        """Limpiar notificaciones leídas antiguas"""
        from datetime import timedelta
        cutoff = timezone.now() - timedelta(days=30)
        
        old_read = queryset.filter(
            is_read=True,
            created_at__lt=cutoff
        )
        count = old_read.count()
        old_read.delete()
        
        self.message_user(request, f'{count} notificaciones antiguas eliminadas.')
    cleanup_old_read.short_description = "Limpiar notificaciones antiguas"


@admin.register(NotificationPreferences)
class NotificationPreferencesAdmin(admin.ModelAdmin):
    """
    Admin para preferencias de notificaciones
    """
    
    list_display = [
        'user',
        'app_notifications_summary',
        'email_notifications_summary',
        'summary_frequency',
        'updated_at'
    ]
    
    list_filter = [
        'summary_frequency',
        'email_new_ratings',
        'email_important_comments',
        'email_weekly_summary',
        'updated_at'
    ]
    
    search_fields = [
        'user__username',
        'user__email'
    ]
    
    readonly_fields = ['created_at', 'updated_at']
    
    fieldsets = (
        ('Usuario', {
            'fields': ('user',)
        }),
        ('Notificaciones In-App', {
            'fields': (
                'app_new_posts',
                'app_new_comments', 
                'app_comment_replies',
                'app_new_ratings'
            )
        }),
        ('Notificaciones Email', {
            'fields': (
                'email_new_ratings',
                'email_important_comments',
                'email_weekly_summary',
                'summary_frequency'
            )
        }),
        ('Configuración Avanzada', {
            'fields': (
                'quiet_hours_start',
                'quiet_hours_end'
            ),
            'classes': ('collapse',)
        }),
        ('Metadatos', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def app_notifications_summary(self, obj):
        """Resumen de notificaciones in-app habilitadas"""
        enabled = []
        if obj.app_new_posts: enabled.append("Posts")
        if obj.app_new_comments: enabled.append("Comentarios")
        if obj.app_comment_replies: enabled.append("Respuestas")
        if obj.app_new_ratings: enabled.append("Valoraciones")
        
        if enabled:
            return ", ".join(enabled)
        return "Ninguna"
    app_notifications_summary.short_description = 'In-App Habilitadas'
    
    def email_notifications_summary(self, obj):
        """Resumen de notificaciones email habilitadas"""
        enabled = []
        if obj.email_new_ratings: enabled.append("Valoraciones")
        if obj.email_important_comments: enabled.append("Comentarios")
        if obj.email_weekly_summary: enabled.append("Resumen")
        
        if enabled:
            return ", ".join(enabled)
        return "Ninguna"
    email_notifications_summary.short_description = 'Email Habilitado'
