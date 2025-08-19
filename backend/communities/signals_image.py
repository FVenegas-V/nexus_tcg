"""
Signals para procesamiento automático de imágenes de posts.
"""
import os
from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from django.db import transaction
from .models import PostImage
from core.utils import image_processor, file_handler


@receiver(post_save, sender=PostImage)
def process_post_image(sender, instance, created, **kwargs):
    """
    Procesar imagen automáticamente después de guardar.
    
    Args:
        sender: Modelo PostImage
        instance: Instancia de PostImage creada/actualizada
        created: True si es una nueva instancia
        kwargs: Argumentos adicionales
    """
    if not created:
        # Solo procesar en creación, no en actualizaciones
        return
    
    if instance.processed:
        # Ya fue procesada
        return
    
    if not instance.original_image:
        # No hay imagen original
        return
    
    try:
        # Extraer información del path original
        original_path = instance.original_image.name
        
        # Generar nombre base para las variantes
        base_path = os.path.dirname(original_path)
        filename = os.path.basename(original_path)
        name_without_ext = os.path.splitext(filename)[0]
        base_filename = os.path.join(base_path, name_without_ext)
        
        # Procesar imagen y generar resoluciones
        generated_paths = image_processor.process_image(original_path, base_filename)
        
        # Actualizar paths en la instancia
        instance.large_path = generated_paths.get('large', '')
        instance.medium_path = generated_paths.get('medium', '')
        instance.thumbnail_path = generated_paths.get('thumbnail', '')
        instance.processed = True
        
        # Guardar cambios (sin triggear signal de nuevo)
        PostImage.objects.filter(pk=instance.pk).update(
            large_path=instance.large_path,
            medium_path=instance.medium_path,
            thumbnail_path=instance.thumbnail_path,
            processed=True
        )
        
        print(f"✅ Imagen procesada exitosamente: {instance.id}")
        
        # Actualizar image_urls del post después del procesamiento exitoso
        try:
            update_post_image_urls(instance.post)
        except Exception as e:
            print(f"❌ Error actualizando image_urls del post {instance.post.id}: {e}")
        
    except Exception as e:
        print(f"❌ Error procesando imagen {instance.id}: {e}")
        
        # Marcar como no procesada para reintento posterior
        PostImage.objects.filter(pk=instance.pk).update(processed=False)


@receiver(post_delete, sender=PostImage)
def cleanup_post_image_files(sender, instance, **kwargs):
    """
    Limpiar archivos físicos cuando se elimina un PostImage.
    
    Args:
        sender: Modelo PostImage
        instance: Instancia eliminada
        kwargs: Argumentos adicionales
    """
    # Actualizar image_urls del post cuando se elimina una imagen
    try:
        update_post_image_urls(instance.post)
    except Exception as e:
        print(f"❌ Error actualizando image_urls del post {instance.post.id}: {e}")
    
    try:
        # Recopilar todos los paths a eliminar
        paths_to_delete = {}
        
        # Archivo original
        if instance.original_image:
            paths_to_delete['original'] = instance.original_image.name
        
        # Archivos procesados
        if instance.large_path:
            paths_to_delete['large'] = instance.large_path
        
        if instance.medium_path:
            paths_to_delete['medium'] = instance.medium_path
            
        if instance.thumbnail_path:
            paths_to_delete['thumbnail'] = instance.thumbnail_path
        
        # Eliminar archivos
        file_handler.cleanup_files(paths_to_delete)
        
        print(f"🗑️ Archivos eliminados para PostImage {instance.id}")
        
    except Exception as e:
        print(f"❌ Error eliminando archivos de PostImage {instance.id}: {e}")


def reprocess_image(post_image_id):
    """
    Función para reprocesar una imagen específica.
    
    Args:
        post_image_id: ID del PostImage a reprocesar
    """
    try:
        instance = PostImage.objects.get(id=post_image_id)
        
        if not instance.original_image:
            print(f"❌ No hay imagen original para PostImage {post_image_id}")
            return
        
        # Limpiar archivos procesados existentes
        if instance.processed:
            paths_to_clean = {
                'large': instance.large_path,
                'medium': instance.medium_path,
                'thumbnail': instance.thumbnail_path,
            }
            file_handler.cleanup_files(paths_to_clean)
        
        # Marcar como no procesada
        instance.processed = False
        instance.large_path = ''
        instance.medium_path = ''
        instance.thumbnail_path = ''
        instance.save()
        
        # Triggear procesamiento nuevamente
        process_post_image(PostImage, instance, created=True)
        
        print(f"🔄 Imagen reprocesada: {post_image_id}")
        
    except PostImage.DoesNotExist:
        print(f"❌ PostImage {post_image_id} no encontrado")
    except Exception as e:
        print(f"❌ Error reprocesando imagen {post_image_id}: {e}")


def bulk_reprocess_unprocessed():
    """
    Reprocesar todas las imágenes que no han sido procesadas.
    """
    unprocessed_images = PostImage.objects.filter(processed=False, is_active=True)
    
    print(f"🔄 Reprocesando {unprocessed_images.count()} imágenes...")
    
    for image in unprocessed_images:
        try:
            reprocess_image(image.id)
        except Exception as e:
            print(f"❌ Error reprocesando imagen {image.id}: {e}")
    
    print("✅ Reprocesamiento masivo completado")


def update_post_image_urls(post):
    """
    Actualiza el campo image_urls del post basado en las PostImage asociadas.
    
    Args:
        post: Instancia del modelo Post
    """
    try:
        # Obtener todas las imágenes activas del post
        post_images = PostImage.objects.filter(
            post=post,
            is_active=True,
            processed=True
        ).order_by('order')
        
        # Generar URLs para cada imagen (usar thumbnail como URL principal)
        image_urls = []
        for img in post_images:
            if img.thumbnail_path:
                # Construir URL del thumbnail
                from django.conf import settings
                media_url = f"{settings.MEDIA_URL}{img.thumbnail_path}"
                image_urls.append(media_url)
        
        # Actualizar el post
        post.image_urls = image_urls
        post.save(update_fields=['image_urls_json'])
        
        print(f"✅ Actualizado image_urls para post {post.id}: {len(image_urls)} imágenes")
        
    except Exception as e:
        print(f"❌ Error actualizando image_urls para post {post.id}: {e}")
