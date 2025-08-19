"""
Validador de imágenes con verificación estricta de seguridad y formato.
"""
import magic
from PIL import Image
from django.conf import settings
from django.core.exceptions import ValidationError
from django.core.files.uploadedfile import UploadedFile


class ImageValidator:
    """
    Validador comprehensivo para imágenes subidas por usuarios.
    
    Realiza validaciones de:
    - Tamaño de archivo
    - Dimensiones de imagen  
    - Formato/MIME type
    - Integridad del archivo
    - Seguridad básica
    """
    
    def __init__(self):
        # Configuración desde settings con fallbacks seguros
        self.max_file_size = getattr(settings, 'FILE_UPLOAD_MAX_MEMORY_SIZE', 5 * 1024 * 1024)  # 5MB
        self.allowed_formats = getattr(settings, 'ALLOWED_IMAGE_FORMATS', ['JPEG', 'PNG', 'WEBP'])
        self.max_dimension = 4000  # Máximo 4000px en cualquier dimensión
        self.min_dimension = 10    # Mínimo 10px para evitar imágenes inválidas
        
        # MIME types correspondientes a formatos permitidos
        self.allowed_mime_types = {
            'JPEG': ['image/jpeg', 'image/jpg'],
            'PNG': ['image/png'],
            'WEBP': ['image/webp']
        }
    
    def validate_file(self, uploaded_file: UploadedFile) -> dict:
        """
        Validar archivo de imagen completo.
        
        Args:
            uploaded_file: Archivo subido por Django
            
        Returns:
            dict: Información extraída del archivo válido
            
        Raises:
            ValidationError: Si la imagen no cumple con los requisitos
        """
        # 1. Validar tamaño de archivo
        self._validate_file_size(uploaded_file)
        
        # 2. Validar MIME type con python-magic
        detected_mime = self._validate_mime_type(uploaded_file)
        
        # 3. Validar contenido real con PIL
        image_info = self._validate_image_content(uploaded_file)
        
        # 4. Validar dimensiones
        self._validate_dimensions(image_info['width'], image_info['height'])
        
        # 5. Compilar información final
        return {
            'width': image_info['width'],
            'height': image_info['height'],
            'format': image_info['format'],
            'mode': image_info['mode'],
            'detected_mime': detected_mime,
            'file_size': uploaded_file.size,
            'original_name': uploaded_file.name,
        }
    
    def _validate_file_size(self, uploaded_file: UploadedFile):
        """Validar que el archivo no exceda el tamaño máximo."""
        if uploaded_file.size > self.max_file_size:
            size_mb = self.max_file_size / (1024 * 1024)
            raise ValidationError(
                f"El archivo es demasiado grande. Máximo permitido: {size_mb:.1f}MB"
            )
        
        if uploaded_file.size == 0:
            raise ValidationError("El archivo está vacío")
    
    def _validate_mime_type(self, uploaded_file: UploadedFile) -> str:
        """
        Validar MIME type usando python-magic para mayor seguridad.
        
        Returns:
            str: MIME type detectado
        """
        # Leer una muestra del archivo para detectar tipo real
        uploaded_file.seek(0)
        file_sample = uploaded_file.read(1024)  # Leer primer KB
        uploaded_file.seek(0)  # Resetear posición
        
        try:
            detected_mime = magic.from_buffer(file_sample, mime=True)
        except Exception as e:
            raise ValidationError(f"No se pudo detectar el tipo de archivo: {e}")
        
        # Verificar que el MIME detectado esté en la lista permitida
        allowed_mimes = []
        for format_name in self.allowed_formats:
            allowed_mimes.extend(self.allowed_mime_types.get(format_name, []))
        
        if detected_mime not in allowed_mimes:
            formats_str = ', '.join(self.allowed_formats)
            raise ValidationError(
                f"Formato de imagen no permitido. "
                f"Formatos soportados: {formats_str}. "
                f"Detectado: {detected_mime}"
            )
        
        return detected_mime
    
    def _validate_image_content(self, uploaded_file: UploadedFile) -> dict:
        """
        Validar el contenido real de la imagen con PIL.
        
        Returns:
            dict: Información extraída de la imagen
        """
        uploaded_file.seek(0)
        
        try:
            with Image.open(uploaded_file) as img:
                # Verificar que PIL puede procesar la imagen
                img.verify()
                
                # Reabrir para extraer información (verify() corrompe el objeto)
                uploaded_file.seek(0)
                with Image.open(uploaded_file) as img_info:
                    return {
                        'width': img_info.width,
                        'height': img_info.height,
                        'format': img_info.format,
                        'mode': img_info.mode,
                    }
        
        except Exception as e:
            raise ValidationError(f"Archivo de imagen corrupto o inválido: {e}")
        
        finally:
            uploaded_file.seek(0)  # Resetear para uso posterior
    
    def _validate_dimensions(self, width: int, height: int):
        """Validar que las dimensiones estén dentro de los límites."""
        if width < self.min_dimension or height < self.min_dimension:
            raise ValidationError(
                f"La imagen es demasiado pequeña. "
                f"Mínimo: {self.min_dimension}x{self.min_dimension}px. "
                f"Actual: {width}x{height}px"
            )
        
        if width > self.max_dimension or height > self.max_dimension:
            raise ValidationError(
                f"La imagen es demasiado grande. "
                f"Máximo: {self.max_dimension}x{self.max_dimension}px. "
                f"Actual: {width}x{height}px"
            )
    
    def is_valid_format(self, format_name: str) -> bool:
        """Verificar si un formato está permitido."""
        return format_name.upper() in self.allowed_formats
    
    def get_max_file_size_mb(self) -> float:
        """Obtener tamaño máximo de archivo en MB."""
        return self.max_file_size / (1024 * 1024)


# Instancia global para uso en validators de Django
image_validator = ImageValidator()


def validate_uploaded_image(uploaded_file):
    """
    Function validator para usar en campos Django.
    
    Args:
        uploaded_file: Archivo subido
        
    Raises:
        ValidationError: Si la imagen no es válida
    """
    image_validator.validate_file(uploaded_file)
