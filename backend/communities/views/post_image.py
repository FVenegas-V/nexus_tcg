"""
ViewSet para gestión de imágenes de posts.
"""
from rest_framework import viewsets, status, permissions, serializers
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import get_object_or_404
from django.db import transaction, models
from communities.models import PostImage, Post
from communities.serializers import (
    PostImageSerializer,
    PostImageListSerializer,
    PostImageUploadSerializer
)
from communities.permissions import PostPermission


class PostImageViewSet(viewsets.ModelViewSet):
    """
    ViewSet para gestión completa de imágenes de posts.
    
    Endpoints:
    - GET /api/post-images/ - Listar todas las imágenes (admin only)
    - POST /api/post-images/ - Crear imagen individual
    - GET /api/post-images/{id}/ - Obtener imagen específica
    - PUT/PATCH /api/post-images/{id}/ - Actualizar imagen
    - DELETE /api/post-images/{id}/ - Eliminar imagen
    
    Acciones especiales:
    - POST /api/post-images/upload/ - Upload múltiple
    - POST /api/post-images/{id}/reorder/ - Reordenar imagen
    - GET /api/post-images/by-post/{post_id}/ - Imágenes de un post
    """
    
    queryset = PostImage.objects.filter(is_active=True)
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]
    
    def get_serializer_class(self):
        """Seleccionar serializer según la acción."""
        if self.action == 'list':
            return PostImageListSerializer
        elif self.action == 'upload':
            return PostImageUploadSerializer
        else:
            return PostImageSerializer
    
    def get_queryset(self):
        """Filtrar imágenes según el usuario."""
        if self.request.user.is_staff:
            # Staff puede ver todas las imágenes
            return PostImage.objects.filter(is_active=True)
        else:
            # Usuarios normales solo ven sus propias imágenes
            return PostImage.objects.filter(
                is_active=True,
                post__author=self.request.user
            )
    
    def perform_create(self, serializer):
        """Personalizar creación de imagen."""
        # Verificar que el usuario puede subir imágenes al post
        post = serializer.validated_data['post']
        
        if post.author != self.request.user:
            raise serializers.ValidationError(
                "No tienes permisos para agregar imágenes a este post"
            )
        
        # Asignar orden automáticamente si no se especifica
        if 'order' not in serializer.validated_data:
            last_order = PostImage.objects.filter(
                post=post, 
                is_active=True
            ).aggregate(
                max_order=models.Max('order')
            )['max_order'] or -1
            
            serializer.validated_data['order'] = last_order + 1
        
        serializer.save()
    
    def perform_destroy(self, instance):
        """Soft delete de imagen."""
        # Verificar permisos
        if instance.post.author != self.request.user and not self.request.user.is_staff:
            raise serializers.ValidationError(
                "No tienes permisos para eliminar esta imagen"
            )
        
        # Soft delete
        instance.soft_delete()
    
    @action(detail=False, methods=['post'], url_path='upload')
    def upload(self, request):
        """
        Endpoint para upload múltiple de imágenes.
        
        POST /api/post-images/upload/
        
        Body:
        {
            "post_id": 123,
            "images": [file1, file2, file3]
        }
        """
        serializer = self.get_serializer(data=request.data)
        
        if serializer.is_valid():
            try:
                with transaction.atomic():
                    created_images = serializer.save()
                
                # Serializar imágenes creadas para respuesta
                response_serializer = PostImageListSerializer(
                    created_images, 
                    many=True, 
                    context={'request': request}
                )
                
                return Response({
                    'message': f'{len(created_images)} imágenes subidas exitosamente',
                    'images': response_serializer.data
                }, status=status.HTTP_201_CREATED)
                
            except Exception as e:
                return Response({
                    'error': f'Error procesando imágenes: {str(e)}'
                }, status=status.HTTP_400_BAD_REQUEST)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'])
    def reorder(self, request, pk=None):
        """
        Cambiar orden de una imagen específica.
        
        POST /api/post-images/{id}/reorder/
        
        Body:
        {
            "new_order": 2
        }
        """
        image = self.get_object()
        new_order = request.data.get('new_order')
        
        if new_order is None:
            return Response({
                'error': 'new_order es requerido'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            new_order = int(new_order)
            if new_order < 0:
                raise ValueError("Order debe ser >= 0")
        except (ValueError, TypeError):
            return Response({
                'error': 'new_order debe ser un número entero válido >= 0'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Verificar permisos
        if image.post.author != request.user and not request.user.is_staff:
            return Response({
                'error': 'No tienes permisos para reordenar esta imagen'
            }, status=status.HTTP_403_FORBIDDEN)
        
        try:
            with transaction.atomic():
                # Obtener todas las imágenes del post
                post_images = list(
                    PostImage.objects.filter(
                        post=image.post, 
                        is_active=True
                    ).order_by('order')
                )
                
                # Remover la imagen actual de la lista
                post_images.remove(image)
                
                # Insertar en la nueva posición
                post_images.insert(new_order, image)
                
                # Actualizar todos los órdenes
                for i, img in enumerate(post_images):
                    img.order = i
                    img.save(update_fields=['order'])
            
            return Response({
                'message': f'Imagen reordenada a posición {new_order}',
                'new_order': new_order
            })
            
        except Exception as e:
            return Response({
                'error': f'Error reordenando imagen: {str(e)}'
            }, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'], url_path='by-post/(?P<post_id>[^/.]+)')
    def by_post(self, request, post_id=None):
        """
        Obtener todas las imágenes de un post específico.
        
        GET /api/post-images/by-post/{post_id}/
        """
        try:
            post = get_object_or_404(Post, id=post_id, is_active=True)
            
            # Verificar permisos de lectura del post
            if not request.user.is_authenticated:
                return Response({
                    'error': 'Autenticación requerida'
                }, status=status.HTTP_401_UNAUTHORIZED)
            
            # Obtener imágenes del post
            images = PostImage.objects.filter(
                post=post, 
                is_active=True
            ).order_by('order')
            
            serializer = PostImageListSerializer(
                images, 
                many=True, 
                context={'request': request}
            )
            
            return Response({
                'post_id': post_id,
                'count': images.count(),
                'images': serializer.data
            })
            
        except Exception as e:
            return Response({
                'error': f'Error obteniendo imágenes: {str(e)}'
            }, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=True, methods=['post'])
    def reprocess(self, request, pk=None):
        """
        Reprocesar imagen para regenerar resoluciones.
        
        POST /api/post-images/{id}/reprocess/
        """
        image = self.get_object()
        
        # Verificar permisos (solo el autor o staff)
        if image.post.author != request.user and not request.user.is_staff:
            return Response({
                'error': 'No tienes permisos para reprocesar esta imagen'
            }, status=status.HTTP_403_FORBIDDEN)
        
        try:
            from communities.signals_image import reprocess_image
            
            # Ejecutar reprocesamiento
            reprocess_image(image.id)
            
            # Recargar imagen desde BD
            image.refresh_from_db()
            
            serializer = self.get_serializer(image)
            
            return Response({
                'message': 'Imagen reprocesada exitosamente',
                'image': serializer.data
            })
            
        except Exception as e:
            return Response({
                'error': f'Error reprocesando imagen: {str(e)}'
            }, status=status.HTTP_400_BAD_REQUEST)
