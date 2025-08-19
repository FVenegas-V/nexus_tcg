"""
Modelo de Comments para el sistema de comentarios con threading.
"""
from django.db import models
from django.conf import settings
from django.core.validators import MinLengthValidator, MaxLengthValidator
from django.utils import timezone


class Comment(models.Model):
    """
    Modelo para comentarios en posts con soporte para threading (respuestas anidadas).
    Soporta hasta 3 niveles de profundidad para mantener la legibilidad.
    """
    
    # --- Relaciones principales ---
    post = models.ForeignKey(
        'Post',
        on_delete=models.CASCADE,
        related_name='comments',
        help_text="Post al que pertenece este comentario"
    )
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='comments',
        help_text="Usuario autor del comentario"
    )
    
    # --- Threading system ---
    parent = models.ForeignKey(
        'self',
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name='replies',
        help_text="Comentario padre para threading (respuestas)"
    )
    thread_level = models.PositiveIntegerField(
        default=0,
        help_text="Nivel de profundidad en el thread (0=comentario principal)"
    )
    thread_path = models.CharField(
        max_length=500,
        blank=True,
        help_text="Ruta completa del thread para ordenamiento eficiente"
    )
    
    # --- Contenido ---
    content = models.TextField(
        validators=[
            MinLengthValidator(1),
            MaxLengthValidator(2000)
        ],
        help_text="Contenido del comentario (1-2,000 caracteres)"
    )
    
    # --- Metadatos ---
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(
        default=True,
        help_text="Si False, el comentario está eliminado (soft delete)"
    )
    
    # Contador denormalizado para performance
    reaction_count = models.PositiveIntegerField(
        default=0,
        help_text="Número total de reacciones (actualizado automáticamente)"
    )
    replies_count = models.PositiveIntegerField(
        default=0,
        help_text="Número de respuestas directas (actualizado automáticamente)"
    )
    
    # --- Metadata ---
    class Meta:
        ordering = ['thread_path', 'created_at']
        indexes = [
            # Índice principal para comentarios de un post
            models.Index(fields=['post', 'thread_path', 'created_at'], name='comments_post_thread_idx'),
            # Índice para comentarios del autor
            models.Index(fields=['author', '-created_at'], name='comments_author_date_idx'),
            # Índice para respuestas de un comentario
            models.Index(fields=['parent', 'created_at'], name='comments_parent_date_idx'),
            # Índice para comentarios activos
            models.Index(fields=['is_active', '-created_at'], name='comments_active_date_idx'),
        ]
        constraints = [
            # Validar que el contenido no esté vacío (simplificado para SQLite)
            models.CheckConstraint(
                check=models.Q(content__isnull=False),
                name='comment_content_not_null'
            ),
            # Validar máximo 3 niveles de threading
            models.CheckConstraint(
                check=models.Q(thread_level__lte=2),
                name='comment_max_thread_level'
            ),
        ]
        verbose_name = "Comentario"
        verbose_name_plural = "Comentarios"
    
    def __str__(self):
        """Representación string del comentario."""
        content_preview = self.content[:50]
        level_indicator = "  " * self.thread_level + "↳ " if self.thread_level > 0 else ""
        return f"{level_indicator}{content_preview} - {self.author.username}"
    
    def save(self, *args, **kwargs):
        """Override save para calcular thread_path y validaciones."""
        # Validar threading
        if self.parent:
            # Validar que no exceda 3 niveles
            if self.parent.thread_level >= 2:
                raise ValueError("No se pueden crear respuestas con más de 3 niveles de profundidad")
            
            # Validar que el parent esté en el mismo post
            if self.parent.post != self.post:
                raise ValueError("El comentario padre debe estar en el mismo post")
            
            # Calcular thread_level y thread_path
            self.thread_level = self.parent.thread_level + 1
            if self.parent.thread_path:
                self.thread_path = f"{self.parent.thread_path}/{self.parent.id}"
            else:
                self.thread_path = str(self.parent.id)
        else:
            # Comentario principal
            self.thread_level = 0
            self.thread_path = ""
        
        # Limpiar contenido
        self.content = self.content.strip()
        
        # Validar que el usuario tenga acceso al post
        if not hasattr(self, '_skip_access_validation'):
            # El usuario debe poder ver el post para comentar
            if not self.post.is_active:
                raise ValueError("No se puede comentar en un post eliminado")
        
        super().save(*args, **kwargs)
        
        # Actualizar thread_path con el ID propio si es comentario principal
        if not self.parent and not self.thread_path:
            self.thread_path = str(self.id)
            Comment.objects.filter(id=self.id).update(thread_path=self.thread_path)
    
    @property
    def excerpt(self):
        """Extracto del contenido para previews (100 caracteres)."""
        if len(self.content) <= 100:
            return self.content
        return self.content[:97] + "..."
    
    @property
    def is_reply(self):
        """Indica si este comentario es una respuesta."""
        return self.parent is not None
    
    @property
    def depth_indicator(self):
        """Indicador visual del nivel de profundidad."""
        return "  " * self.thread_level + ("↳ " if self.thread_level > 0 else "")
    
    def can_edit(self, user):
        """Verifica si un usuario puede editar este comentario."""
        if not user.is_authenticated:
            return False
        
        # El autor puede editar dentro de 15 minutos
        if self.author == user:
            time_limit = timezone.now() - timezone.timedelta(minutes=15)
            return self.created_at > time_limit
        
        # Por ahora, solo el autor puede editar
        # TODO: Implementar roles de moderador/admin en Community
        return False
    
    def can_delete(self, user):
        """Verifica si un usuario puede eliminar este comentario."""
        if not user.is_authenticated:
            return False
        
        # El autor puede eliminar siempre
        if self.author == user:
            return True
        
        # Por ahora, solo el autor puede eliminar
        # TODO: Implementar roles de moderador/admin en Community
        return False
    
    def can_reply(self, user):
        """Verifica si un usuario puede responder a este comentario."""
        if not user.is_authenticated:
            return False
        
        # No se puede responder si ya está en el nivel máximo
        if self.thread_level >= 2:
            return False
        
        # Debe tener acceso al post y a la comunidad
        if not self.post.is_active:
            return False
        
        # Verificar acceso a la comunidad
        return self.post.community.can_user_access(user)
    
    def soft_delete(self):
        """Eliminación lógica del comentario."""
        self.is_active = False
        self.content = "[Comentario eliminado]"
        self.save(update_fields=['is_active', 'content', 'updated_at'])
    
    def restore(self, original_content):
        """Restaurar comentario eliminado lógicamente."""
        self.is_active = True
        self.content = original_content
        self.save(update_fields=['is_active', 'content', 'updated_at'])
    
    def get_all_replies(self):
        """Obtiene todas las respuestas de este comentario recursivamente."""
        return Comment.objects.filter(
            thread_path__startswith=f"{self.thread_path}/{self.id}",
            is_active=True
        ).order_by('thread_path', 'created_at')
    
    def get_direct_replies(self):
        """Obtiene solo las respuestas directas (nivel inmediato)."""
        return self.replies.filter(is_active=True).order_by('created_at')
