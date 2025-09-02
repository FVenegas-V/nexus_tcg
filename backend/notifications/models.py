"""
Modelos para el sistema de notificaciones MVP con polling
Implementación para fase5-0001: Sistema de Notificaciones Backend
"""

from django.db import models
from django.contrib.auth import get_user_model
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey
from django.utils import timezone
from datetime import timedelta

User = get_user_model()


class Notification(models.Model):
    """
    Modelo principal de notificaciones para sistema MVP con polling
    
    Diseño optimizado para consultas frecuentes cada 30 segundos
    Soporta GenericForeignKey para relacionar con cualquier modelo
    """
    
    NOTIFICATION_TYPES = [
        ('NEW_POST', 'Nuevo post en comunidad'),
        ('NEW_COMMENT', 'Comentario en tu post'),
        ('COMMENT_REPLY', 'Respuesta a tu comentario'),
        ('NEW_RATING', 'Nueva valoración recibida'),
        ('COMMUNITY_JOIN', 'Nuevo miembro en comunidad administrada'),
        ('COMMUNITY_MENTION', 'Mención en comunidad'),
    ]
    
    PRIORITY_LEVELS = [
        ('LOW', 'Baja'),
        ('NORMAL', 'Normal'),
        ('HIGH', 'Alta'),
        ('URGENT', 'Urgente'),
    ]
    
    # Campos principales
    user = models.ForeignKey(
        User, 
        on_delete=models.CASCADE, 
        related_name='notifications',
        db_index=True,
        help_text="Usuario que recibe la notificación"
    )
    
    type = models.CharField(
        max_length=20, 
        choices=NOTIFICATION_TYPES,
        db_index=True,
        help_text="Tipo de notificación"
    )
    
    title = models.CharField(
        max_length=255,
        help_text="Título corto de la notificación"
    )
    
    message = models.TextField(
        help_text="Mensaje descriptivo de la notificación"
    )
    
    # Objeto relacionado (post, comment, rating, etc.) - OPCIONAL
    content_type = models.ForeignKey(
        ContentType, 
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        help_text="Tipo de contenido relacionado"
    )
    object_id = models.PositiveIntegerField(
        null=True,
        blank=True,
        help_text="ID del objeto relacionado"
    )
    related_object = GenericForeignKey('content_type', 'object_id')
    
    # Estados y metadatos
    is_read = models.BooleanField(
        default=False,
        db_index=True,
        help_text="¿Ha sido leída por el usuario?"
    )
    
    priority = models.CharField(
        max_length=10,
        choices=PRIORITY_LEVELS,
        default='NORMAL',
        help_text="Prioridad de la notificación"
    )
    
    # Campos para email fallback (Fase 5-0004)
    email_sent = models.BooleanField(
        default=False,
        db_index=True,
        help_text="¿Se envió notificación por email?"
    )
    
    email_sent_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Fecha de envío del email"
    )
    
    # Timestamps
    created_at = models.DateTimeField(
        auto_now_add=True,
        db_index=True,
        help_text="Fecha de creación"
    )
    
    read_at = models.DateTimeField(
        null=True, 
        blank=True,
        help_text="Fecha en que fue leída"
    )
    
    class Meta:
        ordering = ['-created_at']
        verbose_name = "Notificación"
        verbose_name_plural = "Notificaciones"
        
        # Índices optimizados para polling frecuente
        indexes = [
            models.Index(fields=['user', 'is_read', '-created_at']),  # Query principal de polling
            models.Index(fields=['user', 'type', '-created_at']),     # Filtros por tipo
            models.Index(fields=['created_at']),                      # Limpieza automática
            models.Index(fields=['email_sent', 'created_at']),        # Email fallback
        ]
        
        # Constraints para integridad
        constraints = [
            models.CheckConstraint(
                check=models.Q(priority__in=['LOW', 'NORMAL', 'HIGH', 'URGENT']),
                name='valid_priority'
            )
        ]
    
    def __str__(self):
        return f"{self.user.username} - {self.title} ({self.type})"
    
    def mark_as_read(self):
        """Marcar notificación como leída"""
        if not self.is_read:
            self.is_read = True
            self.read_at = timezone.now()
            self.save(update_fields=['is_read', 'read_at'])
    
    def is_recent(self, hours=24):
        """Verificar si la notificación es reciente"""
        return self.created_at >= timezone.now() - timedelta(hours=hours)
    
    def should_send_email(self, delay_hours=6):
        """
        Determinar si debe enviarse email fallback
        Solo si no ha sido leída después del delay especificado
        """
        if self.is_read or self.email_sent:
            return False
            
        delay_threshold = self.created_at + timedelta(hours=delay_hours)
        return timezone.now() >= delay_threshold
    
    @classmethod
    def create_notification(cls, user, notification_type, title, message, related_object=None, priority='NORMAL'):
        """
        Factory method para crear notificaciones de manera consistente
        
        Args:
            user: Usuario que recibe la notificación
            notification_type: Tipo de notificación (debe estar en NOTIFICATION_TYPES)
            title: Título de la notificación
            message: Mensaje descriptivo
            related_object: Objeto relacionado (Post, Comment, etc.)
            priority: Prioridad de la notificación
        """
        notification_data = {
            'user': user,
            'type': notification_type,
            'title': title,
            'message': message,
            'priority': priority,
        }
        
        if related_object:
            notification_data.update({
                'content_type': ContentType.objects.get_for_model(related_object),
                'object_id': related_object.pk,
            })
        
        return cls.objects.create(**notification_data)
    
    @classmethod
    def get_unread_for_user(cls, user, limit=5):
        """
        Método optimizado para polling - obtener notificaciones no leídas
        
        Args:
            user: Usuario
            limit: Número máximo de notificaciones a retornar
        """
        return cls.objects.filter(
            user=user,
            is_read=False
        ).select_related('content_type').order_by('-created_at')[:limit]
    
    @classmethod
    def cleanup_old_notifications(cls, days=30):
        """
        Limpieza automática de notificaciones antiguas leídas
        Para evitar crecimiento infinito de la tabla
        """
        cutoff_date = timezone.now() - timedelta(days=days)
        deleted_count = cls.objects.filter(
            is_read=True,
            created_at__lt=cutoff_date
        ).delete()
        return deleted_count


class NotificationPreferences(models.Model):
    """
    Preferencias de notificaciones por usuario
    Modelo para fase5-0005: Configuración de Preferencias
    """
    
    FREQUENCY_CHOICES = [
        ('immediate', 'Inmediato'),
        ('daily', 'Diario'),
        ('weekly', 'Semanal'),
        ('never', 'Nunca'),
    ]
    
    user = models.OneToOneField(
        User, 
        on_delete=models.CASCADE, 
        related_name='notification_preferences'
    )
    
    # Preferencias in-app (siempre habilitadas para MVP)
    app_new_posts = models.BooleanField(
        default=True, 
        help_text="Nuevos posts en comunidades suscritas"
    )
    app_new_comments = models.BooleanField(
        default=True, 
        help_text="Comentarios en tus posts"
    )
    app_comment_replies = models.BooleanField(
        default=True, 
        help_text="Respuestas a tus comentarios"
    )
    app_new_ratings = models.BooleanField(
        default=True, 
        help_text="Nuevas valoraciones de reputación"
    )
    
    # Preferencias de email
    email_new_ratings = models.BooleanField(
        default=True, 
        help_text="Valoraciones importantes por email"
    )
    email_important_comments = models.BooleanField(
        default=True, 
        help_text="Comentarios importantes por email"
    )
    # Preferencias de email (Fase 5-0004)
    email_enabled = models.BooleanField(
        default=True, 
        help_text="Habilitar notificaciones por email"
    )
    email_posts = models.BooleanField(
        default=True, 
        help_text="Emails por nuevos posts"
    )
    email_comments = models.BooleanField(
        default=True, 
        help_text="Emails por nuevos comentarios"
    )
    email_reactions = models.BooleanField(
        default=False, 
        help_text="Emails por reacciones a posts"
    )
    email_invites = models.BooleanField(
        default=True, 
        help_text="Emails por invitaciones a comunidades"
    )
    email_critical = models.BooleanField(
        default=True, 
        help_text="Emails por alertas críticas (seguridad, moderación)"
    )
    email_frequency = models.CharField(
        max_length=10,
        choices=FREQUENCY_CHOICES,
        default='immediate',
        help_text="Frecuencia de emails normales"
    )
    email_weekly_summary = models.BooleanField(
        default=True, 
        help_text="Resumen semanal de actividad"
    )
    
    # Configuración de frecuencia
    summary_frequency = models.CharField(
        max_length=10,
        choices=FREQUENCY_CHOICES,
        default='weekly',
        help_text="Frecuencia de emails de resumen"
    )
    
    # Configuración avanzada (opcional para MVP)
    quiet_hours_start = models.TimeField(
        null=True, 
        blank=True, 
        help_text="Inicio de horas silenciosas (opcional)"
    )
    quiet_hours_end = models.TimeField(
        null=True, 
        blank=True, 
        help_text="Fin de horas silenciosas (opcional)"
    )
    
    # Metadatos
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Preferencias de Notificación"
        verbose_name_plural = "Preferencias de Notificaciones"
    
    def __str__(self):
        return f"Preferencias de {self.user.username}"
    
    def allows_notification_type(self, notification_type):
        """
        Verificar si el usuario permite un tipo específico de notificación
        """
        type_mapping = {
            'NEW_POST': self.app_new_posts,
            'NEW_COMMENT': self.app_new_comments,
            'COMMENT_REPLY': self.app_comment_replies,
            'NEW_RATING': self.app_new_ratings,
        }
        return type_mapping.get(notification_type, True)
    
    def allows_email_for_type(self, notification_type):
        """
        Verificar si el usuario permite emails para un tipo específico
        """
        email_mapping = {
            'NEW_RATING': self.email_new_ratings,
            'NEW_COMMENT': self.email_important_comments,
            'COMMENT_REPLY': self.email_important_comments,
        }
        return email_mapping.get(notification_type, False)
