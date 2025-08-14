"""
Modelo para sistema de etiquetas dinámicas de comunidades.
"""
from django.db import models
from django.core.validators import MinLengthValidator, RegexValidator


class CommunityTag(models.Model):
    """
    Sistema de etiquetas para clasificación flexible de comunidades.
    Permite a los usuarios crear y usar tags personalizados.
    """
    
    name = models.CharField(
        max_length=30,
        unique=True,
        validators=[
            MinLengthValidator(2),
            RegexValidator(
                regex=r'^[a-zA-Z0-9-_]+$',
                message='Tag solo puede contener letras, números, guiones y guiones bajos'
            )
        ],
        help_text="Nombre del tag (2-30 caracteres, solo alfanuméricos)"
    )
    display_name = models.CharField(
        max_length=30,
        blank=True,
        help_text="Nombre para mostrar (con espacios y mayúsculas)"
    )
    description = models.CharField(
        max_length=100,
        blank=True,
        help_text="Descripción breve del significado del tag"
    )
    
    # --- Estadísticas y Metadatos ---
    usage_count = models.IntegerField(
        default=0,
        help_text="Número de comunidades que usan este tag"
    )
    is_suggested = models.BooleanField(
        default=False,
        help_text="Si aparece en sugerencias automáticas"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Fecha de creación del tag"
    )
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_tags',
        help_text="Usuario que creó el tag"
    )
    
    class Meta:
        ordering = ['-usage_count', 'name']
        verbose_name = "Community Tag"
        verbose_name_plural = "Community Tags"
        indexes = [
            models.Index(fields=['-usage_count']),
            models.Index(fields=['is_suggested']),
            models.Index(fields=['name']),
        ]
    
    def save(self, *args, **kwargs):
        if not self.display_name:
            self.display_name = self.name.replace('-', ' ').replace('_', ' ').title()
        
        # Normalizar nombre a lowercase
        self.name = self.name.lower()
        super().save(*args, **kwargs)
    
    def __str__(self):
        return self.display_name or self.name
    
    @classmethod
    def get_popular_tags(cls, limit=20):
        """Retorna los tags más populares."""
        return cls.objects.filter(usage_count__gt=0).order_by('-usage_count')[:limit]
    
    @classmethod
    def search_tags(cls, query, limit=10):
        """Busca tags para autocompletado."""
        return cls.objects.filter(
            name__icontains=query.lower()
        ).order_by('-usage_count', 'name')[:limit]
    
    def increment_usage(self):
        """Incrementa el contador de uso."""
        self.usage_count = models.F('usage_count') + 1
        self.save(update_fields=['usage_count'])
    
    def decrement_usage(self):
        """Decrementa el contador de uso."""
        if self.usage_count > 0:
            self.usage_count = models.F('usage_count') - 1
            self.save(update_fields=['usage_count'])
