"""
Procesador de imágenes para generar múltiples resoluciones automáticamente.
"""
import os
from PIL import Image, ImageOps
from django.conf import settings
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from io import BytesIO
from typing import Dict, Tuple, Optional


class ImageProcessor:
    """
    Procesador para crear múltiples resoluciones de imágenes automáticamente.
    
    Genera:
    - thumbnail: 150x150px (cuadrado, para listas)
    - medium: 800x600px (manteniendo proporción)
    - large: 1200x900px (manteniendo proporción)
    """
    
    def __init__(self):
        # Configuración desde settings
        self.sizes = getattr(settings, 'IMAGE_SIZES', {
            'thumbnail': (150, 150),
            'medium': (800, 600),
            'large': (1200, 900),
        })
        
        # Calidad de compresión (0-100)
        self.quality = getattr(settings, 'IMAGE_QUALITY', 85)
        
        # Formato de salida (WebP para mejor compresión)
        self.output_format = 'WEBP'
        self.output_extension = 'webp'
    
    def process_image(self, original_image_path: str, base_filename: str) -> Dict[str, str]:
        """
        Procesar imagen original y generar todas las resoluciones.
        
        Args:
            original_image_path: Path de la imagen original en storage
            base_filename: Nombre base para generar variantes (sin extensión)
            
        Returns:
            dict: Paths de todas las resoluciones generadas
            {
                'large': 'path/to/large.webp',
                'medium': 'path/to/medium.webp', 
                'thumbnail': 'path/to/thumbnail.webp'
            }
        """
        try:
            # Abrir imagen original desde storage
            with default_storage.open(original_image_path, 'rb') as original_file:
                with Image.open(original_file) as img:
                    # Convertir a RGB si es necesario (para WebP)
                    if img.mode in ('RGBA', 'LA', 'P'):
                        # Mantener transparencia convirtiendo a RGBA primero
                        img = img.convert('RGBA')
                        # Crear fondo blanco para WebP
                        background = Image.new('RGB', img.size, (255, 255, 255))
                        background.paste(img, mask=img.split()[-1] if img.mode == 'RGBA' else None)
                        img = background
                    elif img.mode != 'RGB':
                        img = img.convert('RGB')
                    
                    # Aplicar corrección de orientación EXIF
                    img = ImageOps.exif_transpose(img)
                    
                    # Generar cada resolución
                    generated_paths = {}
                    
                    for size_name, dimensions in self.sizes.items():
                        resized_path = self._generate_resized_image(
                            img, base_filename, size_name, dimensions
                        )
                        generated_paths[size_name] = resized_path
                    
                    return generated_paths
        
        except Exception as e:
            raise Exception(f"Error procesando imagen {original_image_path}: {e}")
    
    def _generate_resized_image(self, img: Image.Image, base_filename: str, 
                              size_name: str, target_size: Tuple[int, int]) -> str:
        """
        Generar una imagen redimensionada específica.
        
        Args:
            img: Imagen PIL original
            base_filename: Nombre base del archivo (con path, sin extensión)
            size_name: Nombre del tamaño (thumbnail, medium, large)
            target_size: Tupla (ancho, alto) objetivo
            
        Returns:
            str: Path de la imagen generada en storage
        """
        # Crear copia de la imagen para procesar
        img_copy = img.copy()
        
        # Aplicar redimensionamiento según el tipo
        if size_name == 'thumbnail':
            # Para thumbnails, crear cuadrado centrado
            resized_img = self._create_square_thumbnail(img_copy, target_size[0])
        else:
            # Para medium y large, mantener proporción
            resized_img = self._resize_keep_aspect(img_copy, target_size)
        
        # Generar nombre de archivo
        output_filename = f"{base_filename}_{size_name}.{self.output_extension}"
        
        # Guardar imagen procesada
        output_buffer = BytesIO()
        resized_img.save(
            output_buffer, 
            format=self.output_format, 
            quality=self.quality,
            optimize=True
        )
        
        # Guardar en storage
        output_buffer.seek(0)
        saved_path = default_storage.save(
            output_filename,
            ContentFile(output_buffer.getvalue())
        )
        
        return saved_path
    
    def _create_square_thumbnail(self, img: Image.Image, size: int) -> Image.Image:
        """
        Crear thumbnail cuadrado centrado.
        
        Args:
            img: Imagen original
            size: Tamaño del cuadrado (ej: 150 para 150x150)
            
        Returns:
            Image: Thumbnail cuadrado
        """
        # Calcular dimensiones para crop centrado
        width, height = img.size
        
        # Determinar el lado más pequeño para el crop
        crop_size = min(width, height)
        
        # Calcular coordenadas del crop centrado
        left = (width - crop_size) // 2
        top = (height - crop_size) // 2
        right = left + crop_size
        bottom = top + crop_size
        
        # Crop al cuadrado centrado
        img_cropped = img.crop((left, top, right, bottom))
        
        # Redimensionar al tamaño objetivo
        img_resized = img_cropped.resize((size, size), Image.Resampling.LANCZOS)
        
        return img_resized
    
    def _resize_keep_aspect(self, img: Image.Image, max_size: Tuple[int, int]) -> Image.Image:
        """
        Redimensionar imagen manteniendo proporción.
        
        Args:
            img: Imagen original
            max_size: Tamaño máximo (ancho, alto)
            
        Returns:
            Image: Imagen redimensionada
        """
        # Usar thumbnail de PIL que mantiene proporción automáticamente
        img.thumbnail(max_size, Image.Resampling.LANCZOS)
        return img
    
    def delete_processed_images(self, paths: Dict[str, str]):
        """
        Eliminar archivos procesados del storage.
        
        Args:
            paths: Diccionario de paths a eliminar
        """
        for size_name, path in paths.items():
            if path and default_storage.exists(path):
                try:
                    default_storage.delete(path)
                except Exception as e:
                    # Log del error pero continuar con otros archivos
                    print(f"Error eliminando {path}: {e}")
    
    def get_processed_paths(self, base_path: str, unique_id: str) -> Dict[str, str]:
        """
        Generar paths esperados para imágenes procesadas.
        
        Args:
            base_path: Path base (directorio)
            unique_id: ID único del archivo
            
        Returns:
            dict: Paths esperados para cada resolución
        """
        paths = {}
        for size_name in self.sizes.keys():
            filename = f"{unique_id}_{size_name}.{self.output_extension}"
            paths[size_name] = os.path.join(base_path, filename).replace('\\', '/')
        
        return paths
    
    def is_processing_needed(self, image_instance) -> bool:
        """
        Verificar si una imagen necesita procesamiento.
        
        Args:
            image_instance: Instancia del modelo PostImage
            
        Returns:
            bool: True si necesita procesamiento
        """
        # Verificar si ya está marcada como procesada
        if image_instance.processed:
            return False
        
        # Verificar si existen todos los archivos procesados
        paths = image_instance.all_paths
        for size_name in self.sizes.keys():
            if not paths.get(size_name) or not default_storage.exists(paths[size_name]):
                return True
        
        return False


# Instancia global para uso en la aplicación
image_processor = ImageProcessor()
