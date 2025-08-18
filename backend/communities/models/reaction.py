"""
Modelo de Reactions para el sistema de reacciones emoji en posts y comentarios.
"""
from django.db import models
from django.conf import settings
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey


class Reaction(models.Model):
    """
    Modelo para reacciones emoji en posts y comentarios.
    Utiliza GenericForeignKey para soportar múltiples tipos de contenido.
    Un usuario solo puede tener una reacción por contenido (constraint único).
    """
    
    # Tipos de reacciones disponibles con sus emojis
    REACTION_TYPES = [
        ('like', '👍 Me gusta'),
        ('love', '❤️ Me encanta'),
        ('laugh', '😂 Me divierte'),
        ('wow', '😮 Me sorprende'),
        ('sad', '😢 Me entristece'),
        ('angry', '😠 Me molesta'),
    ]
    
    # Mapping de tipos a emojis para fácil acceso
    EMOJI_MAP = {
        'like': '👍',
        'love': '❤️',
        'laugh': '😂',
        'wow': '😮',
        'sad': '😢',
        'angry': '😠',
    }
    
    # --- Relaciones principales ---
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='reactions',
        help_text="Usuario que hizo la reacción"
    )
    
    # --- Generic relationship para soportar Posts y Comments ---
    content_type = models.ForeignKey(
        ContentType,
        on_delete=models.CASCADE,
        limit_choices_to={'model__in': ('post', 'comment')},
        help_text="Tipo de contenido (post o comment)"
    )
    object_id = models.PositiveIntegerField(
        help_text="ID del objeto (post o comment)"
    )
    content_object = GenericForeignKey('content_type', 'object_id')
    
    # --- Tipo de reacción ---
    reaction_type = models.CharField(
        max_length=10,
        choices=REACTION_TYPES,
        help_text="Tipo de reacción emoji"
    )
    
    # --- Metadatos ---
    created_at = models.DateTimeField(auto_now_add=True)
    
    # --- Metadata ---
    class Meta:
        # Constraint único: un usuario solo puede reaccionar una vez por contenido
        unique_together = ['user', 'content_type', 'object_id']
        
        indexes = [
            # Índice principal para reacciones por contenido
            models.Index(fields=['content_type', 'object_id', 'reaction_type'], name='reactions_content_type_idx'),
            # Índice para reacciones por usuario
            models.Index(fields=['user', '-created_at'], name='reactions_user_date_idx'),
            # Índice para breakdown por tipo
            models.Index(fields=['content_type', 'object_id', '-created_at'], name='reactions_content_date_idx'),
        ]
        
        constraints = [
            # Validar que reaction_type esté en las opciones válidas
            models.CheckConstraint(
                check=models.Q(reaction_type__in=['like', 'love', 'laugh', 'wow', 'sad', 'angry']),
                name='reaction_valid_type'
            ),
        ]
        
        verbose_name = "Reacción"
        verbose_name_plural = "Reacciones"
        ordering = ['-created_at']
    
    def __str__(self):
        """Representación string de la reacción."""
        emoji = self.get_emoji()
        content_str = str(self.content_object)[:30] if self.content_object else "Contenido eliminado"
        return f"{emoji} {self.user.username} → {content_str}"
    
    def save(self, *args, **kwargs):
        """Override save para validaciones adicionales."""
        # Validar que el contenido exista y esté activo
        if self.content_object and hasattr(self.content_object, 'is_active'):
            if not self.content_object.is_active:
                raise ValueError("No se puede reaccionar a contenido eliminado")
        
        super().save(*args, **kwargs)
    
    def get_emoji(self):
        """Obtiene el emoji correspondiente al tipo de reacción."""
        return self.EMOJI_MAP.get(self.reaction_type, '❓')
    
    def get_display_name(self):
        """Obtiene el nombre completo de la reacción."""
        return dict(self.REACTION_TYPES).get(self.reaction_type, 'Desconocido')
    
    @classmethod
    def get_reaction_breakdown(cls, content_object):
        """
        Obtiene un breakdown completo de reacciones para un contenido específico.
        
        Returns:
            dict: {
                'total_count': int,
                'breakdown': {
                    'like': {'count': int, 'emoji': str, 'users': [...]},
                    'love': {'count': int, 'emoji': str, 'users': [...]},
                    ...
                }
            }
        """
        content_type = ContentType.objects.get_for_model(content_object)
        reactions = cls.objects.filter(
            content_type=content_type,
            object_id=content_object.id
        ).select_related('user')
        
        breakdown = {}
        total_count = 0
        
        # Inicializar todos los tipos con count 0
        for reaction_type, _ in cls.REACTION_TYPES:
            breakdown[reaction_type] = {
                'count': 0,
                'emoji': cls.EMOJI_MAP[reaction_type],
                'users': []
            }
        
        # Contar reacciones actuales
        for reaction in reactions:
            reaction_type = reaction.reaction_type
            breakdown[reaction_type]['count'] += 1
            breakdown[reaction_type]['users'].append({
                'id': reaction.user.id,
                'username': reaction.user.username,
                'avatar_url': getattr(reaction.user, 'avatar_url', None)
            })
            total_count += 1
        
        return {
            'total_count': total_count,
            'breakdown': breakdown
        }
    
    @classmethod
    def get_user_reaction(cls, user, content_object):
        """
        Obtiene la reacción específica de un usuario para un contenido.
        
        Returns:
            Reaction or None: La reacción del usuario o None si no ha reaccionado
        """
        if not user.is_authenticated:
            return None
        
        try:
            content_type = ContentType.objects.get_for_model(content_object)
            return cls.objects.get(
                user=user,
                content_type=content_type,
                object_id=content_object.id
            )
        except cls.DoesNotExist:
            return None
    
    @classmethod
    def toggle_reaction(cls, user, content_object, reaction_type):
        """
        Agrega, cambia o elimina una reacción de un usuario.
        
        Args:
            user: Usuario que reacciona
            content_object: Post o Comment al que reacciona
            reaction_type: Tipo de reacción ('like', 'love', etc.)
            
        Returns:
            tuple: (reaction_instance or None, action_taken)
            action_taken puede ser: 'created', 'updated', 'deleted'
        """
        content_type = ContentType.objects.get_for_model(content_object)
        
        try:
            existing_reaction = cls.objects.get(
                user=user,
                content_type=content_type,
                object_id=content_object.id
            )
            
            if existing_reaction.reaction_type == reaction_type:
                # Misma reacción: eliminar (toggle off)
                existing_reaction.delete()
                return None, 'deleted'
            else:
                # Reacción diferente: cambiar
                existing_reaction.reaction_type = reaction_type
                existing_reaction.save()
                return existing_reaction, 'updated'
                
        except cls.DoesNotExist:
            # No hay reacción previa: crear nueva
            new_reaction = cls.objects.create(
                user=user,
                content_type=content_type,
                object_id=content_object.id,
                reaction_type=reaction_type
            )
            return new_reaction, 'created'
    
    @classmethod
    def get_trending_reactions(cls, hours=24):
        """
        Obtiene las reacciones más populares en las últimas X horas.
        
        Args:
            hours: Número de horas hacia atrás para considerar
            
        Returns:
            dict: Conteo de reacciones por tipo en el período
        """
        from django.utils import timezone
        from datetime import timedelta
        
        since = timezone.now() - timedelta(hours=hours)
        
        reactions = cls.objects.filter(created_at__gte=since)
        trending = {}
        
        for reaction_type, _ in cls.REACTION_TYPES:
            count = reactions.filter(reaction_type=reaction_type).count()
            trending[reaction_type] = {
                'count': count,
                'emoji': cls.EMOJI_MAP[reaction_type]
            }
        
        return trending
