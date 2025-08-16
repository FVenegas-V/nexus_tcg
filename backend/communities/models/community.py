"""
Modelo principal de comunidades TCG.
"""
from django.db import models
from django.conf import settings
from django.utils.text import slugify
from django.core.validators import MinLengthValidator, URLValidator
from .category import CommunityCategory


class Community(models.Model):
    """
    Modelo principal para comunidades de Trading Card Games.
    Cada comunidad representa un grupo de usuarios con intereses comunes.
    """
    
    # --- Información Básica ---
    name = models.CharField(
        max_length=100, 
        unique=True,
        validators=[MinLengthValidator(3)],
        help_text="Nombre único de la comunidad (3-100 caracteres)"
    )
    description = models.TextField(
        help_text="Descripción detallada de la comunidad y sus objetivos"
    )
    slug = models.SlugField(
        unique=True,
        blank=True,
        help_text="URL amigable generada automáticamente"
    )
    image_url = models.URLField(
        blank=True, 
        null=True,
        validators=[URLValidator()],
        help_text="URL de la imagen de portada de la comunidad"
    )
    
    # --- Categorización ---
    game_type = models.ForeignKey(
        'GameType',
        on_delete=models.CASCADE,
        related_name='communities',
        help_text="Tipo de juego TCG asociado a esta comunidad"
    )
    difficulty_level = models.CharField(
        max_length=20,
        choices=[
            ('principiante', 'Principiante'),
            ('intermedio', 'Intermedio'),
            ('avanzado', 'Avanzado'),
        ],
        default='intermedio',
        help_text="Nivel de experiencia requerido"
    )
    category = models.ForeignKey(
        CommunityCategory,
        on_delete=models.CASCADE,
        related_name='communities',
        help_text="Categoría temática de la comunidad"
    )
    tags = models.JSONField(
        default=list,
        blank=True,
        help_text="Lista de tags para clasificación adicional (máximo 10)"
    )
    
    # --- Configuración ---
    is_public = models.BooleanField(
        default=True,
        help_text="Si la comunidad es visible públicamente"
    )
    requires_approval = models.BooleanField(
        default=False,
        help_text="Si las solicitudes de membresía requieren aprobación manual"
    )
    max_members = models.IntegerField(
        null=True, 
        blank=True,
        help_text="Límite máximo de miembros (null = sin límite)"
    )
    
    # --- Metadatos ---
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Fecha de creación de la comunidad"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="Última actualización"
    )
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='created_communities',
        help_text="Usuario que creó la comunidad"
    )
    
    # --- Estadísticas (desnormalizadas para performance) ---
    member_count = models.IntegerField(
        default=0,
        help_text="Número actual de miembros activos"
    )
    post_count = models.IntegerField(
        default=0,
        help_text="Número total de posts en la comunidad"
    )
    
    class Meta:
        verbose_name = "Comunidad"
        verbose_name_plural = "Comunidades"
        ordering = ['-member_count', '-created_at']
        indexes = [
            models.Index(fields=['game_type']),
            models.Index(fields=['difficulty_level']),
            models.Index(fields=['is_public']),
            models.Index(fields=['-member_count']),
            models.Index(fields=['-created_at']),
        ]
    
    def __str__(self):
        return "{} ({} miembros)".format(self.name, self.member_count)
    
    def save(self, *args, **kwargs):
        """Generar slug automáticamente y validaciones."""
        if not self.slug:
            self.slug = slugify(self.name)
        
        # Validar límite de miembros
        if self.max_members and self.member_count > self.max_members:
            self.member_count = self.max_members
            
        super().save(*args, **kwargs)
    
    @property
    def is_full(self):
        """Determina si la comunidad ha alcanzado su límite de miembros."""
        if not self.max_members:
            return False
        return self.member_count >= self.max_members
    
    @property
    def is_popular(self):
        """Determina si es una comunidad popular (más de 100 miembros)."""
        return self.member_count >= 100
    
    @property
    def member_capacity_percentage(self):
        """Retorna el porcentaje de capacidad usado (si hay límite)."""
        if not self.max_members:
            return None
        return (self.member_count / self.max_members) * 100
    
    def get_absolute_url(self):
        """URL canónica de la comunidad."""
        return "/communities/{}/".format(self.slug)
    
    def add_tag(self, tag_name):
        """Agrega un tag a la comunidad si no existe."""
        tag_name = tag_name.lower().strip()
        if tag_name and tag_name not in self.tags and len(self.tags) < 10:
            self.tags.append(tag_name)
            return True
        return False
    
    def remove_tag(self, tag_name):
        """Remueve un tag de la comunidad."""
        tag_name = tag_name.lower().strip()
        if tag_name in self.tags:
            self.tags.remove(tag_name)
            return True
        return False
    
    def has_tag(self, tag_name):
        """Verifica si la comunidad tiene un tag específico."""
        return tag_name.lower().strip() in self.tags
    
    @property
    def tag_count(self):
        """Retorna el número de tags."""
        return len(self.tags)
