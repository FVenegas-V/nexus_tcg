"""
Serializers para Comment con sistema de threading avanzado.
Implementa threading de hasta 3 niveles de profundidad con optimizaciones de performance.
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.db.models import Prefetch
from ..models import Comment, Post, Community

User = get_user_model()


class CommentAuthorSerializer(serializers.ModelSerializer):
    """Serializer simplificado para información del autor del comentario."""
    
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


class PostInCommentSerializer(serializers.ModelSerializer):
    """Serializer simplificado para información del post en comentarios."""
    
    author_username = serializers.CharField(source='author.username', read_only=True)
    community_name = serializers.CharField(source='community.name', read_only=True)
    
    class Meta:
        model = Post
        fields = ['id', 'title', 'author_username', 'community_name']


class CommentListSerializer(serializers.ModelSerializer):
    """
    Serializer para listar comentarios con representación visual del threading.
    Optimizado para mostrar comentarios en feed y listados con jerarquía visual.
    """
    
    author = CommentAuthorSerializer(read_only=True)
    post = PostInCommentSerializer(read_only=True)
    excerpt = serializers.CharField(read_only=True)
    depth_indicator = serializers.CharField(read_only=True)
    time_since_created = serializers.SerializerMethodField()
    can_reply = serializers.SerializerMethodField()
    can_edit = serializers.SerializerMethodField()
    can_delete = serializers.SerializerMethodField()
    has_replies = serializers.SerializerMethodField()
    
    class Meta:
        model = Comment
        fields = [
            'id', 'content', 'excerpt', 'author', 'post',
            'thread_level', 'depth_indicator', 'replies_count',
            'reaction_count', 'created_at', 'updated_at',
            'time_since_created', 'can_reply', 'can_edit', 
            'can_delete', 'has_replies', 'is_active'
        ]
    
    def get_time_since_created(self, obj):
        """Calcular tiempo transcurrido desde la creación."""
        now = timezone.now()
        diff = now - obj.created_at
        
        if diff.days > 0:
            return f"{diff.days}d"
        elif diff.seconds > 3600:
            hours = diff.seconds // 3600
            return f"{hours}h"
        elif diff.seconds > 60:
            minutes = diff.seconds // 60
            return f"{minutes}m"
        else:
            return "ahora"
    
    def get_can_reply(self, obj):
        """Verificar si el usuario actual puede responder."""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return obj.can_reply(request.user)
    
    def get_can_edit(self, obj):
        """Verificar si el usuario actual puede editar."""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return obj.can_edit(request.user)
    
    def get_can_delete(self, obj):
        """Verificar si el usuario actual puede eliminar."""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return obj.can_delete(request.user)
    
    def get_has_replies(self, obj):
        """Verificar si el comentario tiene respuestas."""
        return obj.replies_count > 0


class CommentDetailSerializer(CommentListSerializer):
    """
    Serializer para detalles completos de un comentario individual.
    Incluye metadatos extendidos y información completa del threading.
    """
    
    parent = serializers.SerializerMethodField()
    direct_replies = serializers.SerializerMethodField()
    thread_path_display = serializers.SerializerMethodField()
    edit_time_left = serializers.SerializerMethodField()
    
    class Meta(CommentListSerializer.Meta):
        fields = CommentListSerializer.Meta.fields + [
            'parent', 'direct_replies', 'thread_path', 
            'thread_path_display', 'edit_time_left'
        ]
    
    def get_parent(self, obj):
        """Obtener información del comentario padre."""
        if not obj.parent:
            return None
        
        return {
            'id': obj.parent.id,
            'author_username': obj.parent.author.username,
            'excerpt': obj.parent.excerpt,
            'thread_level': obj.parent.thread_level
        }
    
    def get_direct_replies(self, obj):
        """Obtener respuestas directas del comentario."""
        # Solo incluir si se solicita explícitamente
        if not self.context.get('include_replies', False):
            return None
        
        replies = obj.get_direct_replies()[:5]  # Limitar a 5 respuestas
        return CommentListSerializer(replies, many=True, context=self.context).data
    
    def get_thread_path_display(self, obj):
        """Mostrar el path del thread en formato legible."""
        if not obj.thread_path:
            return "Comentario principal"
        
        path_parts = obj.thread_path.split('/')
        return f"Respuesta nivel {obj.thread_level} (Path: {' → '.join(path_parts)})"
    
    def get_edit_time_left(self, obj):
        """Calcular tiempo restante para editar (15 minutos)."""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return None
        
        if obj.author != request.user:
            return None
        
        time_limit = obj.created_at + timezone.timedelta(minutes=15)
        now = timezone.now()
        
        if now >= time_limit:
            return "Tiempo agotado"
        
        time_left = time_limit - now
        minutes_left = int(time_left.total_seconds() // 60)
        return f"{minutes_left} minutos restantes"


class CommentCreateSerializer(serializers.ModelSerializer):
    """
    Serializer para crear nuevos comentarios con validaciones de threading.
    Maneja validaciones de permisos, profundidad máxima y acceso a comunidades.
    """
    
    class Meta:
        model = Comment
        fields = ['content', 'post', 'parent']
    
    def validate_content(self, value):
        """Validar contenido del comentario."""
        content = value.strip()
        
        if len(content) < 1:
            raise serializers.ValidationError(
                "El comentario no puede estar vacío."
            )
        
        if len(content) > 2000:
            raise serializers.ValidationError(
                "El comentario no puede exceder 2,000 caracteres."
            )
        
        return content
    
    def validate_post(self, value):
        """Validar que el post existe y está activo."""
        if not value.is_active:
            raise serializers.ValidationError(
                "No se puede comentar en un post eliminado."
            )
        
        return value
    
    def validate_parent(self, value):
        """Validar comentario padre para threading."""
        if not value:
            return value
        
        # Verificar que el comentario padre esté activo
        if not value.is_active:
            raise serializers.ValidationError(
                "No se puede responder a un comentario eliminado."
            )
        
        # Verificar máximo 3 niveles de profundidad
        if value.thread_level >= 2:
            raise serializers.ValidationError(
                "No se pueden crear respuestas con más de 3 niveles de profundidad."
            )
        
        return value
    
    def validate(self, attrs):
        """Validaciones cruzadas."""
        post = attrs.get('post')
        parent = attrs.get('parent')
        
        # Si hay parent, verificar que esté en el mismo post
        if parent and parent.post != post:
            raise serializers.ValidationError({
                'parent': 'El comentario padre debe estar en el mismo post.'
            })
        
        # Verificar permisos de acceso a la comunidad
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            user = request.user
            community = post.community
            
            # Verificar que el usuario tenga acceso a la comunidad
            if not community.can_user_access(user):
                raise serializers.ValidationError(
                    "No tienes permisos para comentar en esta comunidad."
                )
        
        return attrs
    
    def create(self, validated_data):
        """Crear comentario con autor del request."""
        request = self.context.get('request')
        validated_data['author'] = request.user
        return super().create(validated_data)


class CommentUpdateSerializer(serializers.ModelSerializer):
    """
    Serializer para actualizar comentarios con restricciones temporales.
    Solo permite editar contenido dentro del tiempo límite (15 minutos).
    """
    
    class Meta:
        model = Comment
        fields = ['content']
    
    def validate_content(self, value):
        """Validar contenido del comentario."""
        content = value.strip()
        
        if len(content) < 1:
            raise serializers.ValidationError(
                "El comentario no puede estar vacío."
            )
        
        if len(content) > 2000:
            raise serializers.ValidationError(
                "El comentario no puede exceder 2,000 caracteres."
            )
        
        return content
    
    def validate(self, attrs):
        """Validar permisos de edición."""
        request = self.context.get('request')
        comment = self.instance
        
        if not request or not request.user.is_authenticated:
            raise serializers.ValidationError(
                "Debes estar autenticado para editar comentarios."
            )
        
        if not comment.can_edit(request.user):
            if comment.author == request.user:
                raise serializers.ValidationError(
                    "Solo puedes editar comentarios dentro de los primeros 15 minutos."
                )
            else:
                raise serializers.ValidationError(
                    "No tienes permisos para editar este comentario."
                )
        
        return attrs


class CommentThreadSerializer(serializers.ModelSerializer):
    """
    Serializer especializado para mostrar threads completos de comentarios.
    Optimizado para mostrar jerarquía completa con respuestas anidadas.
    """
    
    author = CommentAuthorSerializer(read_only=True)
    replies = serializers.SerializerMethodField()
    depth_indicator = serializers.CharField(read_only=True)
    can_reply = serializers.SerializerMethodField()
    
    class Meta:
        model = Comment
        fields = [
            'id', 'content', 'author', 'thread_level', 
            'depth_indicator', 'replies_count', 'reaction_count',
            'created_at', 'replies', 'can_reply', 'is_active'
        ]
    
    def get_replies(self, obj):
        """Obtener respuestas directas del comentario para threading visual."""
        # Limitar profundidad para evitar recursión infinita
        max_depth = self.context.get('max_depth', 3)
        
        if obj.thread_level >= max_depth:
            return []
        
        # Obtener respuestas directas activas
        direct_replies = obj.get_direct_replies()
        
        # Recursivamente serializar respuestas
        context = self.context.copy()
        context['max_depth'] = max_depth
        
        return CommentThreadSerializer(
            direct_replies, 
            many=True, 
            context=context
        ).data
    
    def get_can_reply(self, obj):
        """Verificar si el usuario actual puede responder."""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        return obj.can_reply(request.user)
