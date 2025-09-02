"""
Serializers para el sistema de notificaciones MVP
Implementación para fase5-0001: APIs REST optimizadas para polling
"""

from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.contenttypes.models import ContentType
from .models import Notification, NotificationPreferences

User = get_user_model()


class NotificationSerializer(serializers.ModelSerializer):
    """
    Serializer principal para notificaciones
    Optimizado para respuestas de polling frecuente
    """
    
    # Información del objeto relacionado
    related_object_type = serializers.SerializerMethodField()
    related_object_url = serializers.SerializerMethodField()
    
    # Timestamps formateados
    created_at_formatted = serializers.SerializerMethodField()
    time_ago = serializers.SerializerMethodField()
    
    class Meta:
        model = Notification
        fields = [
            'id',
            'type',
            'title', 
            'message',
            'priority',
            'is_read',
            'created_at',
            'created_at_formatted',
            'time_ago',
            'read_at',
            'related_object_type',
            'related_object_url',
        ]
        read_only_fields = ['id', 'created_at', 'read_at']
    
    def get_related_object_type(self, obj):
        """Retorna el tipo de objeto relacionado"""
        if obj.content_type:
            return obj.content_type.model
        return None
    
    def get_related_object_url(self, obj):
        """
        Genera URL para navegación desde notificación al contenido
        Mapea tipos de contenido a rutas del frontend
        """
        if not obj.related_object:
            return None
            
        content_type = obj.content_type.model
        object_id = obj.object_id
        
        # Mapeo de tipos a rutas del frontend Flutter
        if content_type == 'post':
            return f'/post/{object_id}'
        elif content_type == 'comment':
            # Para comentarios, navegar al post donde está el comentario
            comment = obj.related_object
            if hasattr(comment, 'post') and comment.post:
                return f'/post/{comment.post.id}'
            elif hasattr(comment, 'post_id'):
                return f'/post/{comment.post_id}'
        elif content_type == 'userrating':
            # Para ratings, navegar al perfil del usuario calificado
            rating = obj.related_object
            if hasattr(rating, 'rated_user_id'):
                return f'/profile/{rating.rated_user_id}/reputation'
        elif content_type == 'community':
            return f'/communities/{object_id}'
        
        return None
    
    def get_created_at_formatted(self, obj):
        """Formato legible de fecha de creación"""
        return obj.created_at.strftime('%d/%m/%Y %H:%M')
    
    def get_time_ago(self, obj):
        """Tiempo transcurrido desde la creación (para UI)"""
        from django.utils import timezone
        from datetime import timedelta
        
        now = timezone.now()
        diff = now - obj.created_at
        
        if diff < timedelta(minutes=1):
            return "Hace un momento"
        elif diff < timedelta(hours=1):
            minutes = int(diff.total_seconds() / 60)
            return f"Hace {minutes} minuto{'s' if minutes != 1 else ''}"
        elif diff < timedelta(days=1):
            hours = int(diff.total_seconds() / 3600)
            return f"Hace {hours} hora{'s' if hours != 1 else ''}"
        elif diff < timedelta(weeks=1):
            days = diff.days
            return f"Hace {days} día{'s' if days != 1 else ''}"
        else:
            weeks = diff.days // 7
            return f"Hace {weeks} semana{'s' if weeks != 1 else ''}"


class NotificationListSerializer(NotificationSerializer):
    """
    Serializer ligero para listas de notificaciones
    Excluye campos pesados para mejor performance en polling
    """
    
    class Meta(NotificationSerializer.Meta):
        fields = [
            'id',
            'type',
            'title',
            'priority',
            'is_read',
            'created_at',
            'time_ago',
            'related_object_type',
            'related_object_url',
        ]


class NotificationUnreadSerializer(serializers.ModelSerializer):
    """
    Serializer ultra-optimizado para endpoint de polling (/unread/)
    Solo campos esenciales para máxima performance + URL para navegación
    """
    
    time_ago = serializers.SerializerMethodField()
    related_object_url = serializers.SerializerMethodField()
    
    class Meta:
        model = Notification
        fields = [
            'id',
            'type', 
            'title',
            'priority',
            'time_ago',
            'related_object_url',
        ]
    
    def get_related_object_url(self, obj):
        """
        Genera URL para navegación desde notificación al contenido
        Mapea tipos de contenido a rutas del frontend
        """
        if not obj.related_object:
            return None
            
        content_type = obj.content_type.model
        object_id = obj.object_id
        
        # Mapeo de tipos a rutas del frontend Flutter
        if content_type == 'post':
            return f'/post/{object_id}'
        elif content_type == 'comment':
            # Para comentarios, navegar al post donde está el comentario
            comment = obj.related_object
            if hasattr(comment, 'post') and comment.post:
                return f'/post/{comment.post.id}'
            elif hasattr(comment, 'post_id'):
                return f'/post/{comment.post_id}'
        elif content_type == 'userrating':
            # Para ratings, navegar al perfil del usuario calificado
            rating = obj.related_object
            if hasattr(rating, 'rated_user_id'):
                return f'/profile/{rating.rated_user_id}/reputation'
        elif content_type == 'community':
            return f'/communities/{object_id}'
        
        return None
    
    def get_time_ago(self, obj):
        """Versión simplificada de time_ago"""
        from django.utils import timezone
        from datetime import timedelta
        
        diff = timezone.now() - obj.created_at
        
        if diff < timedelta(hours=1):
            return "Reciente"
        elif diff < timedelta(days=1):
            return "Hoy"
        else:
            return f"{diff.days}d"


class NotificationCreateSerializer(serializers.ModelSerializer):
    """
    Serializer para crear notificaciones (uso interno principalmente)
    """
    
    class Meta:
        model = Notification
        fields = [
            'user',
            'type',
            'title',
            'message',
            'priority',
            'content_type',
            'object_id',
        ]
    
    def validate_type(self, value):
        """Validar que el tipo de notificación sea válido"""
        valid_types = [choice[0] for choice in Notification.NOTIFICATION_TYPES]
        if value not in valid_types:
            raise serializers.ValidationError(
                f"Tipo de notificación inválido. Opciones: {valid_types}"
            )
        return value


class NotificationPreferencesSerializer(serializers.ModelSerializer):
    """
    Serializer para preferencias de notificaciones (fase5-0005)
    """
    
    class Meta:
        model = NotificationPreferences
        fields = [
            'app_new_posts',
            'app_new_comments', 
            'app_comment_replies',
            'app_new_ratings',
            'email_new_ratings',
            'email_important_comments',
            'email_weekly_summary',
            'summary_frequency',
            'quiet_hours_start',
            'quiet_hours_end',
            'updated_at',
        ]
        read_only_fields = ['updated_at']
    
    def validate_summary_frequency(self, value):
        """Validar frecuencia de resúmenes"""
        valid_frequencies = [choice[0] for choice in NotificationPreferences.FREQUENCY_CHOICES]
        if value not in valid_frequencies:
            raise serializers.ValidationError(
                f"Frecuencia inválida. Opciones: {valid_frequencies}"
            )
        return value
    
    def validate(self, data):
        """Validaciones cruzadas"""
        quiet_start = data.get('quiet_hours_start')
        quiet_end = data.get('quiet_hours_end')
        
        # Si se especifica una hora silenciosa, ambas deben estar presentes
        if (quiet_start and not quiet_end) or (quiet_end and not quiet_start):
            raise serializers.ValidationError(
                "Si especificas horas silenciosas, debes incluir tanto inicio como fin"
            )
        
        return data


class NotificationStatsSerializer(serializers.Serializer):
    """
    Serializer para estadísticas de notificaciones (para dashboard)
    """
    
    total_unread = serializers.IntegerField()
    unread_by_type = serializers.DictField()
    recent_count = serializers.IntegerField() 
    total_notifications = serializers.IntegerField()
    last_check = serializers.DateTimeField(allow_null=True)
    
    # Breakdown por tipo
    new_posts_count = serializers.IntegerField()
    new_comments_count = serializers.IntegerField()
    comment_replies_count = serializers.IntegerField()
    new_ratings_count = serializers.IntegerField()


class NotificationBulkActionSerializer(serializers.Serializer):
    """
    Serializer para acciones en lote (marcar múltiples como leídas)
    """
    
    ACTION_CHOICES = [
        ('mark_read', 'Marcar como leídas'),
        ('mark_unread', 'Marcar como no leídas'),
        ('delete', 'Eliminar'),
    ]
    
    notification_ids = serializers.ListField(
        child=serializers.IntegerField(),
        min_length=1,
        max_length=100,  # Límite razonable para acciones en lote
        help_text="Lista de IDs de notificaciones"
    )
    
    action = serializers.ChoiceField(
        choices=ACTION_CHOICES,
        help_text="Acción a realizar en las notificaciones"
    )
    
    def validate_notification_ids(self, value):
        """Validar que los IDs existan y pertenezcan al usuario"""
        request = self.context.get('request')
        if not request or not request.user:
            raise serializers.ValidationError("Usuario no autenticado")
        
        # Verificar que todas las notificaciones existan y pertenezcan al usuario
        existing_notifications = Notification.objects.filter(
            id__in=value,
            user=request.user
        ).values_list('id', flat=True)
        
        invalid_ids = set(value) - set(existing_notifications)
        if invalid_ids:
            raise serializers.ValidationError(
                f"IDs de notificación inválidos o no pertenecen al usuario: {list(invalid_ids)}"
            )
        
        return value
