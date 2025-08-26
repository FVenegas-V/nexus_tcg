"""
Admin básico y seguro solo para eliminar comunidades.
"""
from django.contrib import admin
from .models import Community

# Desregistrar si ya está registrado
try:
    admin.site.unregister(Community)
except admin.sites.NotRegistered:
    pass

@admin.register(Community)
class CommunityAdminBasic(admin.ModelAdmin):
    """Admin básico solo para operaciones seguras."""
    
    # Solo mostrar campos básicos y seguros
    list_display = ['id', 'name', 'member_count', 'is_public', 'created_at']
    list_filter = ['is_public', 'created_at']
    search_fields = ['name']
    readonly_fields = ['member_count', 'created_at', 'updated_at']
    
    # Campos a mostrar en el formulario de edición
    fields = [
        'name', 'description', 'is_public', 
        'member_count', 'created_at', 'updated_at'
    ]
    
    # Permitir eliminación masiva
    actions = ['delete_selected']
    
    def has_add_permission(self, request):
        """Deshabilitar creación desde admin por seguridad."""
        return False
    
    def has_change_permission(self, request, obj=None):
        """Solo permitir ver, no editar."""
        return True
    
    def has_delete_permission(self, request, obj=None):
        """Permitir eliminar."""
        return True
