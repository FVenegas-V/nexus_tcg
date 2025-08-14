"""
Modelo para tipos de juegos TCG soportados en la plataforma.
"""
from django.db import models
from django.utils.text import slugify
from django.core.validators import MinValueValidator, MaxValueValidator


class GameType(models.Model):
    """
    Tipos de juegos de Trading Card Games soportados.
    Cada comunidad debe estar asociada a un tipo de juego específico.
    """
    
    # --- Información Básica ---
    name = models.CharField(
        max_length=100, 
        unique=True,
        help_text="Nombre oficial del juego TCG"
    )
    slug = models.SlugField(
        unique=True,
        blank=True,
        help_text="URL amigable generada automáticamente"
    )
    description = models.TextField(
        blank=True,
        help_text="Descripción del juego y sus características principales"
    )
    logo_url = models.URLField(
        blank=True, 
        null=True,
        help_text="URL del logo oficial del juego"
    )
    
    # --- Metadatos del Juego ---
    publisher = models.CharField(
        max_length=100, 
        blank=True,
        help_text="Editorial o compañía que publica el juego"
    )
    release_year = models.IntegerField(
        null=True, 
        blank=True,
        validators=[
            MinValueValidator(1990),
            MaxValueValidator(2030)
        ],
        help_text="Año de lanzamiento del juego"
    )
    min_players = models.IntegerField(
        default=2,
        validators=[MinValueValidator(1)],
        help_text="Número mínimo de jugadores"
    )
    max_players = models.IntegerField(
        null=True, 
        blank=True,
        validators=[MinValueValidator(2)],
        help_text="Número máximo de jugadores (null = sin límite)"
    )
    
    # --- Sistema de Priorización ---
    is_active = models.BooleanField(
        default=True,
        help_text="Si el juego está activo para nuevas comunidades"
    )
    is_featured = models.BooleanField(
        default=False,
        help_text="Si el juego aparece en la sección destacada"
    )
    community_count = models.IntegerField(
        default=0,
        help_text="Número de comunidades asociadas (actualizado automáticamente)"
    )
    
    # --- Metadatos del Sistema ---
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Fecha de creación del registro"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="Fecha de última actualización"
    )
    
    class Meta:
        ordering = ['-is_featured', '-community_count', 'name']
        verbose_name = "Game Type"
        verbose_name_plural = "Game Types"
        indexes = [
            models.Index(fields=['is_featured', '-community_count']),
            models.Index(fields=['is_active']),
            models.Index(fields=['slug']),
        ]
    
    def save(self, *args, **kwargs):
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)
    
    def __str__(self):
        return self.name
    
    def get_display_info(self):
        """Retorna información formateada para APIs."""
        return {
            'id': self.id,
            'name': self.name,
            'slug': self.slug,
            'logo_url': self.logo_url,
            'publisher': self.publisher,
            'community_count': self.community_count,
            'is_featured': self.is_featured
        }
