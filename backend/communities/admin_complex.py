"""
Configuración del panel de administración para comunidades TCG.
"""
from django.contrib import admin
from django.utils.html import format_html
from django.db.models import Count
from .models import CommunityCategory, Community, CommunityMembership


@admin.register(CommunityCategory)
class CommunityCategoryAdmin(admin.ModelAdmin):
    """
    Admin para categorías de comunidades.
    """
    list_display = ['name', 'community_count', 'is_active', 'color_display', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'description']
    readonly_fields = ['slug', 'community_count', 'created_at', 'updated_at']
    prepopulated_fields = {'slug': ('name',)}
    
    fieldsets = (
        ('Información Básica', {
            'fields': ('name', 'slug', 'description')
        }),
        ('Personalización', {
            'fields': ('icon', 'color', 'is_active')
        }),
        ('Estadísticas', {
            'fields': ('community_count',),
            'classes': ('collapse',)
        }),
        ('Metadatos', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def color_display(self, obj):
        """Mostrar el color como un cuadro visual."""
        return format_html(
            '<div style="background-color: {0}; width: 20px; height: 20px; border-radius: 3px; display: inline-block;"></div> {1}',
            obj.color,
            obj.color
        )
    color_display.short_description = 'Color'


class CommunityMembershipInline(admin.TabularInline):
    """
    Inline para mostrar membresías en el admin de Community.
    """
    model = CommunityMembership
    extra = 0
    readonly_fields = ['joined_at']
    fields = ['user', 'role', 'status', 'joined_at']
    
    def get_queryset(self, request):
        """Optimizar queries con select_related."""
        return super().get_queryset(request).select_related('user')


@admin.register(Community)
class CommunityAdmin(admin.ModelAdmin):
    """
    Admin principal para comunidades.
    """
    list_display = [
        'name', 'game_type', 'difficulty_level', 'member_count', 
        'is_public', 'is_full_status', 'created_at'
    ]
    list_filter = [
        'game_type', 'difficulty_level', 'category', 'is_public', 
        'requires_approval', 'created_at'
    ]
    search_fields = ['name', 'description', 'tags', 'created_by__username']
    readonly_fields = [
        'slug', 'member_count', 'created_at', 
        'updated_at', 'member_capacity_display'
    ]
    prepopulated_fields = {'slug': ('name',)}
    filter_horizontal = []
    inlines = [CommunityMembershipInline]
    
    fieldsets = (
        ('Información Básica', {
            'fields': ('name', 'slug', 'description', 'image_url')
        }),
        ('Categorización', {
            'fields': ('game_type', 'difficulty_level', 'category', 'tags')
        }),
        ('Configuración', {
            'fields': ('is_public', 'requires_approval', 'max_members', 'created_by')
        }),
        ('Estadísticas', {
            'fields': ('member_count', 'member_capacity_display'),
            'classes': ('collapse',)
        }),
        ('Metadatos', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        """Optimizar queries con select_related y prefetch_related."""
        return super().get_queryset(request).select_related(
            'category', 'created_by'
        ).prefetch_related('memberships')
    
    def is_full_status(self, obj):
        """Mostrar si la comunidad está llena."""
        if not obj.max_members:
            return "Sin límite"
        
        if obj.is_full:
            return format_html('<span style="color: red;">● Llena</span>')
        else:
            percentage = obj.member_capacity_percentage
            if percentage is None:
                return "Sin límite"
            color = 'orange' if percentage > 80 else 'green'
            return format_html(
                '<span style="color: {0};">● {1:.1f}% ocupada</span>',
                color, percentage
            )
    is_full_status.short_description = 'Estado de Capacidad'
    
    def member_capacity_display(self, obj):
        """Mostrar capacidad de miembros de forma visual."""
        if not obj.max_members:
            return format_html(
                '{0} miembros (sin límite)',
                obj.member_count
            )
        
        percentage = obj.member_capacity_percentage
        if percentage is None:
            return format_html(
                '{0} miembros (sin límite)',
                obj.member_count
            )
            
        color = '#f44336' if percentage >= 100 else '#ff9800' if percentage > 80 else '#4caf50'
        
        return format_html(
            '{0} / {1} miembros ({2:.1f}%)<br>'
            '<div style="width: 200px; background-color: #e0e0e0; border-radius: 3px; overflow: hidden;">'
            '<div style="width: {3}%; background-color: {4}; height: 20px;"></div>'
            '</div>',
            obj.member_count,
            obj.max_members, 
            percentage,
            percentage,
            color
        )
    member_capacity_display.short_description = 'Capacidad de Miembros'
    
    # Acciones personalizadas
    actions = ['make_public', 'make_private', 'reset_member_count']
    
    def make_public(self, request, queryset):
        """Hacer comunidades públicas."""
        updated = queryset.update(is_public=True)
        self.message_user(request, '{} comunidades marcadas como públicas.'.format(updated))
    make_public.short_description = "Marcar como públicas"
    
    def make_private(self, request, queryset):
        """Hacer comunidades privadas."""
        updated = queryset.update(is_public=False)
        self.message_user(request, '{} comunidades marcadas como privadas.'.format(updated))
    make_private.short_description = "Marcar como privadas"
    
    def reset_member_count(self, request, queryset):
        """Recalcular contador de miembros."""
        for community in queryset:
            community.member_count = community.memberships.filter(status='active').count()
            community.save()
        self.message_user(request, 'Contadores de miembros recalculados para {} comunidades.'.format(queryset.count()))
    reset_member_count.short_description = "Recalcular contador de miembros"


@admin.register(CommunityMembership)
class CommunityMembershipAdmin(admin.ModelAdmin):
    """
    Admin para gestionar membresías individualmente.
    """
    list_display = [
        'user', 'community', 'role', 'status', 'joined_at'
    ]
    list_filter = [
        'role', 'status', 'joined_at', 'community__game_type'
    ]
    search_fields = [
        'user__username', 'user__first_name', 'user__last_name',
        'community__name'
    ]
    readonly_fields = ['joined_at', 'updated_at']
    
    fieldsets = (
        ('Membresía', {
            'fields': ('user', 'community', 'role', 'status')
        }),
        ('Información Adicional', {
            'fields': ('notes',),
            'classes': ('collapse',)
        }),
        ('Metadatos', {
            'fields': ('joined_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def get_queryset(self, request):
        """Optimizar queries."""
        return super().get_queryset(request).select_related(
            'user', 'community'
        )
    
    # Acciones personalizadas
    actions = ['approve_pending', 'suspend_members', 'activate_members']
    
    def approve_pending(self, request, queryset):
        """Aprobar membresías pendientes."""
        updated = queryset.filter(status='pending').update(status='active')
        self.message_user(request, '{} membresías aprobadas.'.format(updated))
    approve_pending.short_description = "Aprobar membresías pendientes"
    
    def suspend_members(self, request, queryset):
        """Suspender miembros."""
        updated = queryset.update(status='suspended', role='member')
        self.message_user(request, '{} membresías suspendidas.'.format(updated))
    suspend_members.short_description = "Suspender miembros"
    
    def activate_members(self, request, queryset):
        """Activar miembros."""
        updated = queryset.update(status='active')
        self.message_user(request, '{} membresías activadas.'.format(updated))
    activate_members.short_description = "Activar miembros"


# Personalización del admin site
admin.site.site_header = "Nexus TCG - Administración"
admin.site.site_title = "Nexus TCG Admin"
admin.site.index_title = "Panel de Control"
