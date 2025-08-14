"""
Modelos de categorías para comunidades TCG.
"""
from django.db import models
from django.utils.text import slugify


class CommunityCategory(models.Model):
    """
    Categorías para clasificar comunidades de TCG.
    Ejemplos: Competitive, Casual, Trading, Collecting, Beginner-Friendly
    """
    name = models.CharField(
        max_length=50, 
        unique=True,
        help_text="Nombre de la categoría (ej: Competitive, Casual)"
    )
    slug = models.SlugField(
        unique=True,
        blank=True,
        help_text="URL-friendly version del nombre (se genera automáticamente)"
    )
    description = models.TextField(
        blank=True,
        help_text="Descripción de qué tipo de comunidades incluye esta categoría"
    )
    icon = models.CharField(
        max_length=50, 
        blank=True,
        help_text="Nombre del ícono Material Design (ej: emoji_events, group)"
    )
    color = models.CharField(
        max_length=7, 
        default='#2196F3',
        help_text="Color en formato hex (ej: #FF5722)"
    )
    
    # Estadísticas (calculadas automáticamente)
    community_count = models.IntegerField(
        default=0,
        help_text="Número de comunidades en esta categoría"
    )
    is_active = models.BooleanField(
        default=True,
        help_text="Si la categoría está disponible para nuevas comunidades"
    )
    
    # Metadatos
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Categoría de Comunidad"
        verbose_name_plural = "Categorías de Comunidades"
        ordering = ['-community_count', 'name']
    
    def __str__(self):
        return "{} ({} comunidades)".format(self.name, self.community_count)
    
    def save(self, *args, **kwargs):
        """Generar slug automáticamente si no existe."""
        if not self.slug:
            self.slug = slugify(self.name)
        super().save(*args, **kwargs)
    
    @property
    def is_popular(self):
        """Determina si es una categoría popular (más de 10 comunidades)."""
        return self.community_count >= 10
