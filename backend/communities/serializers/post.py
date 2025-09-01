"""
Serializers para Post.
"""
import json
from rest_framework import serializers
from django.contrib.auth import get_user_model
from ..models import Post, Community, CommunityMembership

User = get_user_model()


class AuthorSerializer(serializers.ModelSerializer):
    """Serializer simplificado para información del autor."""
    
    avatar_url = serializers.SerializerMethodField()
    is_verified = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'avatar_url', 'is_verified']
    
    def get_avatar_url(self, obj):
        """Obtener URL del avatar del usuario."""
        # TODO: Implementar cuando tengamos UserProfile con avatar
        return None
    
    def get_is_verified(self, obj):
        """Verificar si el usuario tiene cuenta verificada."""
        # TODO: Implementar sistema de verificación
        return False


class CommunityInPostSerializer(serializers.ModelSerializer):
    """Serializer simplificado para información de comunidad en posts."""
    
    game_type_name = serializers.CharField(source='game_type.name', read_only=True)
    
    class Meta:
        model = Community
        fields = ['id', 'name', 'slug', 'game_type_name']


class PostListSerializer(serializers.ModelSerializer):
    """Serializer para listar posts (feed y listados)."""
    
    author = AuthorSerializer(read_only=True)
    community = CommunityInPostSerializer(read_only=True)
    excerpt = serializers.CharField(read_only=True)
    image_count = serializers.IntegerField(read_only=True)
    has_images = serializers.BooleanField(read_only=True)
    thumbnail_url = serializers.SerializerMethodField()
    user_reaction = serializers.SerializerMethodField()
    can_edit = serializers.SerializerMethodField()
    can_delete = serializers.SerializerMethodField()
    reaction_breakdown = serializers.SerializerMethodField()
    
    class Meta:
        model = Post
        fields = [
            'id', 'title', 'excerpt', 'author', 'community',
            'created_at', 'updated_at', 'comment_count', 'reaction_count',
            'image_count', 'has_images', 'thumbnail_url', 'user_reaction', 'can_edit', 'can_delete',
            'reaction_breakdown'
        ]
    
    def get_thumbnail_url(self, obj):
        """Obtener URL del primer thumbnail disponible."""
        from ..models import PostImage
        
        first_image = PostImage.objects.filter(
            post=obj, 
            is_active=True, 
            processed=True
        ).order_by('order').first()
        
        if first_image and first_image.thumbnail_path:
            from django.conf import settings
            media_url = f"{settings.MEDIA_URL}{first_image.thumbnail_path}"
            
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(media_url)
            
            return media_url
        
        return None
    
    def get_user_reaction(self, obj):
        """Obtener la reacción del usuario actual para este post."""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None
        
        from ..models import Reaction
        reaction = Reaction.get_user_reaction(request.user, obj)
        return reaction.reaction_type if reaction else None
    
    def get_can_edit(self, obj):
        """Verificar si el usuario puede editar este post."""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return obj.can_edit(request.user)
    
    def get_can_delete(self, obj):
        """Verificar si el usuario puede eliminar este post."""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return obj.can_delete(request.user)
    
    def get_reaction_breakdown(self, obj):
        """Obtener estadísticas de reacciones para este post."""
        from ..models import Reaction
        breakdown = Reaction.get_reaction_breakdown(obj)
        print(f"🔍 DEBUG PostListSerializer - Post {obj.id} breakdown: {breakdown}")
        return breakdown


class PostDetailSerializer(serializers.ModelSerializer):
    """Serializer para detalle completo de un post."""
    
    author = AuthorSerializer(read_only=True)
    community = CommunityInPostSerializer(read_only=True)
    images = serializers.SerializerMethodField()
    image_urls = serializers.ListField(read_only=True)  # Mantenemos por compatibilidad
    user_reaction = serializers.SerializerMethodField()
    can_edit = serializers.SerializerMethodField()
    can_delete = serializers.SerializerMethodField()
    reaction_breakdown = serializers.SerializerMethodField()
    
    class Meta:
        model = Post
        fields = [
            'id', 'title', 'content', 'images', 'image_urls', 'author', 'community',
            'created_at', 'updated_at', 'comment_count', 'reaction_count',
            'user_reaction', 'can_edit', 'can_delete', 'reaction_breakdown'
        ]
    
    def get_images(self, obj):
        """Obtener todas las imágenes del post con sus múltiples resoluciones."""
        from ..models import PostImage
        from .post_image import PostImageListSerializer
        
        images = PostImage.objects.filter(
            post=obj, 
            is_active=True
        ).order_by('order')
        
        return PostImageListSerializer(
            images, 
            many=True, 
            context=self.context
        ).data
    
    def get_user_reaction(self, obj):
        """Obtener la reacción del usuario actual para este post."""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None
        
        from ..models import Reaction
        reaction = Reaction.get_user_reaction(request.user, obj)
        return reaction.reaction_type if reaction else None
    
    def get_can_edit(self, obj):
        """Verificar si el usuario puede editar este post."""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return obj.can_edit(request.user)
    
    def get_can_delete(self, obj):
        """Verificar si el usuario puede eliminar este post."""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return obj.can_delete(request.user)
    
    def get_reaction_breakdown(self, obj):
        """Obtener estadísticas de reacciones para este post."""
        from ..models import Reaction
        return Reaction.get_reaction_breakdown(obj)


class PostCreateUpdateSerializer(serializers.ModelSerializer):
    """Serializer para crear y actualizar posts."""
    
    images = serializers.ListField(
        child=serializers.ImageField(),
        required=False,
        allow_empty=True,
        max_length=5,
        help_text="Máximo 5 imágenes permitidas"
    )
    
    class Meta:
        model = Post
        fields = ['title', 'content', 'community', 'images']
        extra_kwargs = {
            'title': {
                'required': False,
                'allow_blank': True,
                'max_length': 200,
                'help_text': 'Título opcional del post'
            },
            'content': {
                'required': True,
                'allow_blank': False,
                'max_length': 10000,
                'help_text': 'Contenido del post (requerido)'
            }
        }
    
    def validate_content(self, value):
        """Validar que el contenido no esté vacío."""
        if not value or len(value.strip()) < 1:
            raise serializers.ValidationError("El contenido del post no puede estar vacío.")
        return value.strip()
    
    def validate_images(self, images):
        """Validar imágenes subidas."""
        if len(images) > 5:
            raise serializers.ValidationError("Máximo 5 imágenes permitidas por post.")
        
        for image in images:
            # Validar tamaño (5MB máximo)
            if image.size > 5 * 1024 * 1024:
                raise serializers.ValidationError(f"La imagen {image.name} excede el tamaño máximo de 5MB.")
            
            # Validar formato
            allowed_formats = ['jpg', 'jpeg', 'png', 'webp', 'gif']
            file_extension = image.name.split('.')[-1].lower()
            if file_extension not in allowed_formats:
                raise serializers.ValidationError(
                    f"Formato de imagen no permitido: {file_extension}. "
                    f"Formatos permitidos: {', '.join(allowed_formats)}"
                )
        
        return images
    
    def validate(self, attrs):
        """Validación global del post."""
        # Verificar que el usuario sea miembro de la comunidad
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            raise serializers.ValidationError("Debe estar autenticado para crear posts.")
        
        # Obtener la comunidad de los datos del formulario o del contexto
        community = attrs.get('community')
        community_id = self.context.get('community_id')
        
        if community:
            # Si viene de los datos del formulario (caso normal)
            if not CommunityMembership.objects.filter(
                user=request.user,
                community=community,
                status='active'
            ).exists():
                raise serializers.ValidationError(
                    "Debe ser miembro activo de la comunidad para crear posts."
                )
        elif community_id:
            # Si viene del contexto de la URL (caso legacy)
            try:
                community = Community.objects.get(id=community_id)
                attrs['community'] = community
                # Verificar membresía activa
                if not CommunityMembership.objects.filter(
                    user=request.user,
                    community=community,
                    status='active'
                ).exists():
                    raise serializers.ValidationError(
                        "Debe ser miembro activo de la comunidad para crear posts."
                    )
            except Community.DoesNotExist:
                raise serializers.ValidationError("La comunidad especificada no existe.")
        else:
            raise serializers.ValidationError("Debe especificar una comunidad para el post.")
        
        return attrs
    
    def create(self, validated_data):
        """Crear un nuevo post."""
        # Extraer imágenes de los datos validados
        images = validated_data.pop('images', [])
        
        # Extraer la comunidad de los datos validados (ya validada en validate())
        community = validated_data.pop('community')
        
        # El autor ya viene en validated_data desde perform_create()
        # Crear el post
        post = Post.objects.create(
            community=community,
            **validated_data
        )
        
        # Procesar imágenes si las hay
        if images:
            image_urls = self._process_images(images, post)
            post.image_urls = image_urls
            post.save(update_fields=['image_urls_json'])
        
        return post
    
    def update(self, instance, validated_data):
        """Actualizar un post existente."""
        # Extraer imágenes de los datos validados
        images = validated_data.pop('images', None)
        
        # Actualizar campos básicos
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        
        # Procesar nuevas imágenes si se proporcionan
        if images is not None:
            if images:  # Si hay imágenes nuevas
                image_urls = self._process_images(images, instance)
                instance.image_urls = image_urls
            else:  # Si se envía lista vacía, eliminar imágenes
                instance.image_urls = []
        
        instance.save()
        return instance
    
    def _process_images(self, images, post):
        """
        Procesar y guardar imágenes.
        Por ahora retorna URLs mock, en fase futura se implementará upload real.
        """
        # TODO: Implementar upload real a S3/storage en fase3-0005
        image_urls = []
        for i, image in enumerate(images):
            # Por ahora generar URLs mock para testing
            mock_url = f"https://cdn.nexustcg.com/posts/{post.id}/image_{i+1}_{image.name}"
            image_urls.append(mock_url)
        
        return image_urls
    
    def to_representation(self, instance):
        """Usar PostDetailSerializer para la respuesta."""
        return PostDetailSerializer(instance, context=self.context).data
