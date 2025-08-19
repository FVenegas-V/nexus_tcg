"""
Modelo de PostImage para gestión de imágenes con múltiples resoluciones.
"""
import os
import uuid
from django.db import models
from django.conf import settings
from django.core.validators import FileExtensionValidator
from django.utils import timezone
from core.utils.image_validator import validate_uploaded_image


def post_image_upload_path(instance, filename):
    """
    Generar path dinámico para subida de imágenes de posts.
    Estructura: posts/images/YYYY/MM/DD/user_ID/unique_id_original.ext
    """
    # Generar ID único para el archivo
    unique_id = uuid.uuid4().hex[:12]
    
    # Obtener extensión del archivo
    ext = filename.split('.')[-1].lower()
    
    # Generar estructura de directorios por fecha
    now = timezone.now()
    date_path = now.strftime('%Y/%m/%d')
    
    # Construir path final
    return f'posts/images/{date_path}/user_{instance.post.author.id}/{unique_id}_original.{ext}'


class PostImage(models.Model):
    """
    Modelo para gestión de imágenes de posts con múltiples resoluciones.
    
    Cada instancia representa una imagen con sus variantes generadas automáticamente:
    - original: archivo subido por el usuario
    - large: 1200x900px (para vista completa)
    - medium: 800x600px (para vista normal)
    - thumbnail: 150x150px (para listas/previews)
    """
    
    # --- Relación con Post ---
    post = models.ForeignKey(
        'Post',
        on_delete=models.CASCADE,
        related_name='images',
        help_text="Post al que pertenece esta imagen"
    )
    
    # --- Archivo original ---
    original_image = models.ImageField(
        upload_to=post_image_upload_path,
        validators=[
            FileExtensionValidator(allowed_extensions=['jpg', 'jpeg', 'png', 'webp']),
            validate_uploaded_image  # Validación personalizada estricta
        ],
        help_text="Imagen original subida por el usuario"
    )
    
    # --- Paths para diferentes resoluciones ---
    large_path = models.CharField(
        max_length=500,
        blank=True,
        help_text="Path de la imagen en resolución large (1200x900)"
    )
    
    medium_path = models.CharField(
        max_length=500,
        blank=True,
        help_text="Path de la imagen en resolución medium (800x600)"
    )
    
    thumbnail_path = models.CharField(
        max_length=500,
        blank=True,
        help_text="Path de la imagen en resolución thumbnail (150x150)"
    )
    
    # --- Metadatos ---
    original_filename = models.CharField(
        max_length=255,
        help_text="Nombre original del archivo subido"
    )
    
    file_size = models.PositiveIntegerField(
        help_text="Tamaño del archivo original en bytes"
    )
    
    width = models.PositiveIntegerField(
        help_text="Ancho de la imagen original en píxeles"
    )
    
    height = models.PositiveIntegerField(
        help_text="Alto de la imagen original en píxeles"
    )
    
    content_type = models.CharField(
        max_length=100,
        help_text="MIME type del archivo (ej: image/jpeg)"
    )
    
    # --- Control de estado ---
    processed = models.BooleanField(
        default=False,
        help_text="Indica si se generaron todas las resoluciones"
    )
    
    is_active = models.BooleanField(
        default=True,
        help_text="Permite soft delete de imágenes"
    )
    
    # --- Timestamps ---
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    # --- Orden en el post ---
    order = models.PositiveSmallIntegerField(
        default=0,
        help_text="Orden de la imagen en el post (0=primera)"
    )
    
    class Meta:
        ordering = ['order', 'created_at']
        indexes = [
            models.Index(fields=['post', 'is_active', 'order'], name='postimg_post_active_order_idx'),
            models.Index(fields=['processed'], name='postimg_processed_idx'),
        ]
        constraints = [
            models.UniqueConstraint(
                fields=['post', 'order'],
                condition=models.Q(is_active=True),
                name='unique_active_image_order_per_post'
            )
        ]
        verbose_name = "Imagen de Post"
        verbose_name_plural = "Imágenes de Posts"
    
    def __str__(self):
        return f"Imagen {self.order + 1} de Post #{self.post.id}"
    
    @property
    def original_path(self):
        """Path de la imagen original."""
        return self.original_image.name if self.original_image else ''
    
    @property
    def all_paths(self):
        """Diccionario con todos los paths de resoluciones."""
        return {
            'original': self.original_path,
            'large': self.large_path,
            'medium': self.medium_path,
            'thumbnail': self.thumbnail_path,
        }
    
    @property
    def all_urls(self):
        """Diccionario con todas las URLs de resoluciones."""
        from django.conf import settings
        base_url = settings.MEDIA_URL
        
        urls = {}
        for size, path in self.all_paths.items():
            if path:
                urls[size] = f"{base_url}{path}"
        
        return urls
    
    def get_absolute_url_for_size(self, size):
        """
        Obtener URL absoluta para un tamaño específico.
        
        Args:
            size (str): 'original', 'large', 'medium', 'thumbnail'
        
        Returns:
            str: URL completa o cadena vacía si no existe
        """
        urls = self.all_urls
        return urls.get(size, '')
    
    def delete_files(self):
        """
        Eliminar físicamente todos los archivos de imagen del disco.
        Solo usar cuando se quiera cleanup completo.
        """
        from django.core.files.storage import default_storage
        
        # Eliminar cada archivo si existe
        for size, path in self.all_paths.items():
            if path and default_storage.exists(path):
                try:
                    default_storage.delete(path)
                except Exception as e:
                    # Log del error pero continuar con otros archivos
                    print(f"Error eliminando {path}: {e}")
    
    def soft_delete(self):
        """Eliminación lógica de la imagen."""
        self.is_active = False
        self.save(update_fields=['is_active', 'updated_at'])
    
    def restore(self):
        """Restaurar imagen eliminada lógicamente."""
        self.is_active = True
        self.save(update_fields=['is_active', 'updated_at'])
    
    def save(self, *args, **kwargs):
        """Override save para extraer metadatos del archivo."""
        if self.original_image and not self.pk:  # Solo en creación
            # Extraer metadatos básicos
            self.file_size = self.original_image.size
            self.content_type = getattr(self.original_image.file, 'content_type', 'image/jpeg')
            
            # Si es posible, extraer dimensiones
            try:
                from PIL import Image
                with Image.open(self.original_image.file) as img:
                    self.width, self.height = img.size
            except Exception:
                # Fallback si no se puede abrir con PIL
                self.width = 0
                self.height = 0
        
        super().save(*args, **kwargs)
