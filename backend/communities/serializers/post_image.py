"""
Serializers para PostImage - Gestión de imágenes de posts con múltiples resoluciones.
"""
from rest_framework import serializers
from django.conf import settings
from django.db import models
from communities.models import PostImage, Post
from core.utils import image_validator


class PostImageSerializer(serializers.ModelSerializer):
    """
    Serializer para PostImage con URLs automáticas para todas las resoluciones.
    
    Características:
    - URLs completas para original, large, medium, thumbnail
    - Información de metadatos (dimensiones, tamaño, etc.)
    - Solo lectura para campos calculados
    """
    
    # URLs calculadas automáticamente
    urls = serializers.SerializerMethodField()
    
    # Información de archivo (solo lectura)
    file_size_mb = serializers.SerializerMethodField()
    aspect_ratio = serializers.SerializerMethodField()
    
    # Campos de solo lectura
    processed = serializers.BooleanField(read_only=True)
    created_at = serializers.DateTimeField(read_only=True)
    updated_at = serializers.DateTimeField(read_only=True)
    
    class Meta:
        model = PostImage
        fields = [
            'id',
            'post',
            'original_image',
            'urls',
            'original_filename',
            'file_size',
            'file_size_mb',
            'width',
            'height',
            'aspect_ratio',
            'content_type',
            'processed',
            'is_active',
            'order',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'original_filename',
            'file_size',
            'width',
            'height', 
            'content_type',
            'processed',
            'created_at',
            'updated_at',
        ]
    
    def get_urls(self, obj):
        """
        Generar URLs para todas las resoluciones disponibles.
        
        Returns:
            dict: URLs para cada resolución
        """
        if not obj.original_image:
            return {}
        
        # URLs base
        urls = {
            'original': self._get_full_url(obj.original_image.url) if obj.original_image else None,
        }
        
        # URLs de resoluciones procesadas
        if obj.processed:
            if obj.large_path:
                urls['large'] = self._get_media_url(obj.large_path)
            
            if obj.medium_path:
                urls['medium'] = self._get_media_url(obj.medium_path)
            
            if obj.thumbnail_path:
                urls['thumbnail'] = self._get_media_url(obj.thumbnail_path)
        
        return urls
    
    def get_file_size_mb(self, obj):
        """Convertir tamaño de archivo a MB con 2 decimales."""
        if obj.file_size:
            return round(obj.file_size / (1024 * 1024), 2)
        return 0
    
    def get_aspect_ratio(self, obj):
        """Calcular aspect ratio de la imagen."""
        if obj.width and obj.height:
            return round(obj.width / obj.height, 2)
        return 1
    
    def _get_full_url(self, relative_url):
        """Convertir URL relativa a URL completa."""
        if not relative_url:
            return None
        
        request = self.context.get('request')
        if request:
            return request.build_absolute_uri(relative_url)
        
        # Fallback sin request context
        return f"{settings.MEDIA_URL}{relative_url}"
    
    def _get_media_url(self, file_path):
        """Generar URL completa para un path de archivo."""
        if not file_path:
            return None
        
        media_url = f"{settings.MEDIA_URL}{file_path}"
        
        request = self.context.get('request')
        if request:
            return request.build_absolute_uri(media_url)
        
        return media_url
    
    def validate_original_image(self, value):
        """
        Validar imagen usando nuestro ImageValidator personalizado.
        
        Args:
            value: Archivo subido
            
        Returns:
            value: Archivo validado
        """
        if value:
            try:
                # El validador ya está configurado en el modelo, pero validamos aquí también
                image_info = image_validator.validate_file(value)
                
                # Podríamos guardar información adicional en el contexto
                self._image_info = image_info
                
            except Exception as e:
                raise serializers.ValidationError(f"Imagen inválida: {e}")
        
        return value
    
    def validate_order(self, value):
        """Validar que el order sea válido para el post."""
        if value < 0:
            raise serializers.ValidationError("El orden debe ser mayor o igual a 0")
        
        # Verificar límite máximo de imágenes por post
        max_images = getattr(settings, 'MAX_IMAGES_PER_POST', 5)
        if value >= max_images:
            raise serializers.ValidationError(f"Máximo {max_images} imágenes por post")
        
        return value
    
    def validate(self, attrs):
        """Validación a nivel de objeto."""
        post = attrs.get('post')
        order = attrs.get('order', 0)
        
        if post:
            # Verificar límite de imágenes por post
            max_images = getattr(settings, 'MAX_IMAGES_PER_POST', 5)
            current_images = PostImage.objects.filter(post=post, is_active=True).count()
            
            if current_images >= max_images:
                raise serializers.ValidationError(
                    f"El post ya tiene el máximo de {max_images} imágenes permitidas"
                )
            
            # Verificar que no haya conflicto de orden
            if PostImage.objects.filter(post=post, order=order, is_active=True).exists():
                raise serializers.ValidationError(
                    f"Ya existe una imagen con orden {order} en este post"
                )
        
        return attrs
    
    def create(self, validated_data):
        """Crear nueva imagen con procesamiento automático."""
        # Extraer información del archivo si la tenemos
        image_info = getattr(self, '_image_info', {})
        
        # Establecer metadatos desde la validación
        if image_info:
            validated_data.update({
                'original_filename': image_info.get('original_name', ''),
                'file_size': image_info.get('file_size', 0),
                'width': image_info.get('width', 0),
                'height': image_info.get('height', 0),
                'content_type': image_info.get('detected_mime', 'image/jpeg'),
            })
        
        # Crear instancia
        instance = super().create(validated_data)
        
        # El procesamiento automático se maneja en los signals
        return instance


class PostImageListSerializer(serializers.ModelSerializer):
    """
    Serializer simplificado para listados de imágenes.
    Solo incluye información esencial para performance.
    """
    
    thumbnail_url = serializers.SerializerMethodField()
    file_size_mb = serializers.SerializerMethodField()
    
    class Meta:
        model = PostImage
        fields = [
            'id',
            'thumbnail_url',
            'original_filename',
            'file_size_mb',
            'width',
            'height',
            'order',
            'processed',
            'created_at',
        ]
    
    def get_thumbnail_url(self, obj):
        """URL del thumbnail si está disponible."""
        if obj.processed and obj.thumbnail_path:
            media_url = f"{settings.MEDIA_URL}{obj.thumbnail_path}"
            
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(media_url)
            
            return media_url
        
        return None
    
    def get_file_size_mb(self, obj):
        """Tamaño de archivo en MB."""
        if obj.file_size:
            return round(obj.file_size / (1024 * 1024), 2)
        return 0


class PostImageUploadSerializer(serializers.Serializer):
    """
    Serializer especializado para upload de múltiples imágenes.
    Permite subir varias imágenes en una sola request.
    """
    
    post_id = serializers.IntegerField()
    images = serializers.ListField(
        child=serializers.ImageField(),
        min_length=1,
        max_length=5,  # Máximo 5 imágenes por request
    )
    
    def validate_post_id(self, value):
        """Validar que el post existe y el usuario tiene permisos."""
        try:
            post = Post.objects.get(id=value, is_active=True)
        except Post.DoesNotExist:
            raise serializers.ValidationError("Post no encontrado")
        
        # Verificar permisos (el usuario debe ser el autor)
        request = self.context.get('request')
        if request and request.user != post.author:
            raise serializers.ValidationError("No tienes permisos para subir imágenes a este post")
        
        return value
    
    def validate_images(self, value):
        """Validar cada imagen individualmente."""
        if not value:
            raise serializers.ValidationError("Debe incluir al menos una imagen")
        
        max_images = getattr(settings, 'MAX_IMAGES_PER_POST', 5)
        if len(value) > max_images:
            raise serializers.ValidationError(f"Máximo {max_images} imágenes por request")
        
        # Validar cada imagen
        for i, image_file in enumerate(value):
            try:
                image_validator.validate_file(image_file)
            except Exception as e:
                raise serializers.ValidationError(f"Imagen {i+1} inválida: {e}")
        
        return value
    
    def validate(self, attrs):
        """Validación global del upload."""
        post_id = attrs['post_id']
        images = attrs['images']
        
        # Verificar límite total de imágenes en el post
        post = Post.objects.get(id=post_id)
        current_count = PostImage.objects.filter(post=post, is_active=True).count()
        max_images = getattr(settings, 'MAX_IMAGES_PER_POST', 5)
        
        if current_count + len(images) > max_images:
            remaining = max_images - current_count
            raise serializers.ValidationError(
                f"El post ya tiene {current_count} imágenes. "
                f"Solo puedes agregar {remaining} más (máximo {max_images} total)"
            )
        
        return attrs
    
    def create(self, validated_data):
        """Crear múltiples PostImage desde el upload."""
        post_id = validated_data['post_id']
        images = validated_data['images']
        
        post = Post.objects.get(id=post_id)
        
        # Obtener el siguiente orden disponible
        last_order = PostImage.objects.filter(post=post, is_active=True).aggregate(
            max_order=models.Max('order')
        )['max_order'] or -1
        
        created_images = []
        
        for i, image_file in enumerate(images):
            # Crear PostImage para cada archivo
            post_image = PostImage.objects.create(
                post=post,
                original_image=image_file,
                order=last_order + i + 1,
                original_filename=image_file.name,
            )
            created_images.append(post_image)
        
        return created_images
