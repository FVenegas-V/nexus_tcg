"""
Manejador de archivos para imágenes con múltiples resoluciones.
"""
import os
import uuid
from datetime import datetime
from django.conf import settings
from django.core.files.storage import default_storage
from typing import Tuple, Dict


class FileHandler:
    """
    Manejador de archivos para imágenes de posts con múltiples resoluciones.
    
    Proporciona funcionalidades para:
    - Generar nombres únicos y organizados
    - Gestionar estructura de directorios
    - Cleanup de archivos
    """
    
    def __init__(self):
        self.base_path = 'posts/images'
        self.output_extension = 'webp'  # Extensión para archivos procesados
    
    def generate_base_filename(self, user_id: int, original_filename: str) -> Tuple[str, str]:
        """
        Generar nombre base único para archivo (sin extensión).
        
        Args:
            user_id: ID del usuario que sube la imagen
            original_filename: Nombre original del archivo
            
        Returns:
            Tuple[str, str]: (base_path_con_directorio, unique_id)
        """
        # Generar estructura de fecha
        now = datetime.now()
        date_path = now.strftime('%Y/%m/%d')
        
        # Generar identificador único
        unique_id = uuid.uuid4().hex[:12]  # 12 caracteres
        
        # Construir path base
        base_path = os.path.join(
            self.base_path,
            date_path,
            f"user_{user_id}"
        ).replace('\\', '/')
        
        return base_path, unique_id
    
    def generate_storage_paths(self, base_path: str, unique_id: str) -> Dict[str, str]:
        """
        Generar todos los paths de storage para las diferentes resoluciones.
        
        Args:
            base_path: Path base del directorio
            unique_id: ID único del archivo
            
        Returns:
            dict: Paths para cada resolución
        """
        return {
            'large': f"{base_path}/{unique_id}_large.{self.output_extension}",
            'medium': f"{base_path}/{unique_id}_medium.{self.output_extension}",
            'thumbnail': f"{base_path}/{unique_id}_thumbnail.{self.output_extension}",
        }
    
    def cleanup_files(self, file_paths: Dict[str, str]):
        """
        Eliminar múltiples archivos del storage.
        
        Args:
            file_paths: Diccionario de paths a eliminar
        """
        for path_name, path in file_paths.items():
            if path and default_storage.exists(path):
                try:
                    default_storage.delete(path)
                    print(f"Eliminado: {path}")
                except Exception as e:
                    print(f"Error eliminando {path}: {e}")
    
    def cleanup_single_file(self, file_path: str):
        """
        Eliminar un archivo específico del storage.
        
        Args:
            file_path: Path del archivo a eliminar
        """
        if file_path and default_storage.exists(file_path):
            try:
                default_storage.delete(file_path)
                print(f"Eliminado: {file_path}")
            except Exception as e:
                print(f"Error eliminando {file_path}: {e}")
    
    def get_file_size(self, file_path: str) -> int:
        """
        Obtener tamaño de archivo en bytes.
        
        Args:
            file_path: Path del archivo
            
        Returns:
            int: Tamaño en bytes, 0 si no existe
        """
        try:
            if default_storage.exists(file_path):
                return default_storage.size(file_path)
        except Exception:
            pass
        return 0
    
    def file_exists(self, file_path: str) -> bool:
        """
        Verificar si un archivo existe en storage.
        
        Args:
            file_path: Path del archivo
            
        Returns:
            bool: True si existe
        """
        try:
            return default_storage.exists(file_path)
        except Exception:
            return False
    
    def get_file_url(self, file_path: str) -> str:
        """
        Obtener URL pública de un archivo.
        
        Args:
            file_path: Path del archivo en storage
            
        Returns:
            str: URL completa del archivo
        """
        if not file_path:
            return ''
        
        try:
            return default_storage.url(file_path)
        except Exception:
            # Fallback manual si storage no soporta urls
            return f"{settings.MEDIA_URL}{file_path}"
    
    def get_directory_structure(self, user_id: int) -> str:
        """
        Obtener estructura de directorio para un usuario en la fecha actual.
        
        Args:
            user_id: ID del usuario
            
        Returns:
            str: Path del directorio
        """
        now = datetime.now()
        date_path = now.strftime('%Y/%m/%d')
        
        return os.path.join(
            self.base_path,
            date_path,
            f"user_{user_id}"
        ).replace('\\', '/')
    
    def generate_unique_filename(self, original_filename: str) -> str:
        """
        Generar nombre único basado en el original.
        
        Args:
            original_filename: Nombre original del archivo
            
        Returns:
            str: Nombre único con extensión preservada
        """
        # Extraer extensión
        name, ext = os.path.splitext(original_filename)
        
        # Generar ID único
        unique_id = uuid.uuid4().hex[:8]
        
        # Limpiar nombre original (solo caracteres seguros)
        clean_name = ''.join(c for c in name if c.isalnum() or c in '-_')[:20]
        
        return f"{clean_name}_{unique_id}{ext}"
    
    def validate_storage_space(self, required_space: int) -> bool:
        """
        Validar si hay suficiente espacio en storage.
        
        Args:
            required_space: Espacio requerido en bytes
            
        Returns:
            bool: True si hay espacio suficiente
        """
        # Para filesystem local, verificar espacio en disco
        # En producción con S3, esto podría ser diferente
        try:
            import shutil
            total, used, free = shutil.disk_usage(settings.MEDIA_ROOT)
            return free > required_space
        except Exception:
            # Si no se puede verificar, asumir que hay espacio
            return True
    
    def get_storage_stats(self) -> Dict[str, int]:
        """
        Obtener estadísticas del storage.
        
        Returns:
            dict: Estadísticas de espacio (en bytes)
        """
        try:
            import shutil
            total, used, free = shutil.disk_usage(settings.MEDIA_ROOT)
            return {
                'total': total,
                'used': used,
                'free': free,
                'used_percentage': (used / total) * 100 if total > 0 else 0
            }
        except Exception:
            return {
                'total': 0,
                'used': 0,
                'free': 0,
                'used_percentage': 0
            }


# Instancia global para uso en la aplicación
file_handler = FileHandler()
