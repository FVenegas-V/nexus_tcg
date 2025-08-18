"""
Modelo de Posts para el sistema de publicaciones sociales.
"""
import json
from django.db import models
from django.conf import settings
from django.core.validators import MinLengthValidator, MaxLengthValidator
from django.utils import timezone


class Post(models.Model):
    """
    Modelo para publicaciones/posts en comunidades TCG.
    Los posts se crean DENTRO de comunidades específicas por usuarios miembros.
    """
    
    # --- Relaciones principales ---
    author = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='posts',
        help_text="Usuario autor del post"
    )
    community = models.ForeignKey(
        'Community',
        on_delete=models.CASCADE,
        related_name='posts',
        help_text="Comunidad donde se publica el post"
    )
    
    # --- Contenido ---
    title = models.CharField(
        max_length=200,
        blank=True,
        validators=[MaxLengthValidator(200)],
        help_text="Título opcional del post (máximo 200 caracteres)"
    )
    content = models.TextField(
        validators=[
            MinLengthValidator(1),
            MaxLengthValidator(10000)
        ],
        help_text="Contenido principal del post (1-10,000 caracteres)"
    )
    
    # --- Multimedia ---
    image_urls_json = models.TextField(
        blank=True,
        default='[]',
        help_text="URLs de imágenes en formato JSON (máximo 5)"
    )
    
    # --- Metadatos y contadores ---
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(
        default=True,
        help_text="Si False, el post está eliminado (soft delete)"
    )
    
    # Contadores denormalizados para performance
    comment_count = models.PositiveIntegerField(
        default=0,
        help_text="Número total de comentarios (actualizado automáticamente)"
    )
    reaction_count = models.PositiveIntegerField(
        default=0,
        help_text="Número total de reacciones (actualizado automáticamente)"
    )
    
    # --- Metadata ---
    class Meta:
        ordering = ['-created_at']
        indexes = [
            # Índice principal para listado por comunidad
            models.Index(fields=['community', '-created_at'], name='posts_community_date_idx'),
            # Índice para posts del autor
            models.Index(fields=['author', '-created_at'], name='posts_author_date_idx'),
            # Índice para posts activos
            models.Index(fields=['is_active', '-created_at'], name='posts_active_date_idx'),
            # Índice compuesto para feed algoritmo
            models.Index(fields=['community', 'is_active', '-created_at'], name='posts_feed_idx'),
        ]
        constraints = [
            # Validar que el contenido no esté vacío (simplificado para SQLite)
            models.CheckConstraint(
                check=models.Q(content__isnull=False),
                name='post_content_not_null'
            ),
        ]
        verbose_name = "Post"
        verbose_name_plural = "Posts"
    
    def __str__(self):
        """Representación string del post."""
        title_preview = self.title if self.title else self.content[:50]
        return f"{title_preview} - {self.author.username}"
    
    def save(self, *args, **kwargs):
        """Override save para validaciones adicionales."""
        # Limpiar title si está vacío
        if not self.title or self.title.strip() == '':
            self.title = ''
        
        # Limpiar content
        self.content = self.content.strip()
        
        # Validar que el usuario sea miembro de la comunidad
        if not hasattr(self, '_skip_membership_validation'):
            from .membership import CommunityMembership
            if not CommunityMembership.objects.filter(
                user=self.author,
                community=self.community,
                status='active'
            ).exists():
                raise ValueError("El usuario debe ser miembro activo de la comunidad para crear posts")
        
        super().save(*args, **kwargs)
    
    @property
    def image_urls(self):
        """Obtiene las URLs de imágenes como lista."""
        try:
            return json.loads(self.image_urls_json) if self.image_urls_json else []
        except (json.JSONDecodeError, TypeError):
            return []
    
    @image_urls.setter
    def image_urls(self, value):
        """Establece las URLs de imágenes desde una lista."""
        if isinstance(value, list):
            # Validar máximo 5 imágenes
            if len(value) > 5:
                raise ValueError("Máximo 5 imágenes permitidas")
            self.image_urls_json = json.dumps(value)
        else:
            raise ValueError("image_urls debe ser una lista")
    
    @property
    def excerpt(self):
        """Extracto del contenido para previews (150 caracteres)."""
        if len(self.content) <= 150:
            return self.content
        return self.content[:147] + "..."
    
    @property
    def has_images(self):
        """Indica si el post tiene imágenes."""
        return bool(self.image_urls)
    
    @property
    def image_count(self):
        """Número de imágenes en el post."""
        return len(self.image_urls) if self.image_urls else 0
    
    def can_edit(self, user):
        """Verifica si un usuario puede editar este post."""
        if not user.is_authenticated:
            return False
        
        # El autor puede editar dentro de 15 minutos
        if self.author == user:
            time_limit = timezone.now() - timezone.timedelta(minutes=15)
            return self.created_at > time_limit
        
        # TODO: Implementar permisos de moderadores y admins
        return False
    
    def can_delete(self, user):
        """Verifica si un usuario puede eliminar este post."""
        if not user.is_authenticated:
            return False
        
        # El autor puede eliminar siempre
        if self.author == user:
            return True
        
        # TODO: Implementar permisos de moderadores y admins
        return False
    
    def soft_delete(self):
        """Eliminación lógica del post."""
        self.is_active = False
        self.save(update_fields=['is_active', 'updated_at'])
    
    def restore(self):
        """Restaurar post eliminado lógicamente."""
        self.is_active = True
        self.save(update_fields=['is_active', 'updated_at'])
