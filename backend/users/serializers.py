from django.contrib.auth import get_user_model, authenticate
from rest_framework import serializers
from django.core.exceptions import ValidationError
from django.utils import timezone
from .models import (
    PasswordResetToken, 
    EmailVerificationToken, 
    UserProfile, 
    UserRating,
    RatingFlag,
    UserSuspension,
    AbuseLog
)
import re

User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        min_length=8,
        style={'input_type': 'password'}
    )
    
    class Meta:
        model = User
        fields = ['username', 'email', 'password']
    
    def validate_username(self, value):
        """Valida que el username sea único"""
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError("Este nombre de usuario ya está en uso.")
        return value
    
    def validate_email(self, value):
        """Valida que el email sea único"""
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("Este email ya está registrado.")
        return value
    
    def create(self, validated_data):
        """Crea un nuevo usuario usando create_user para manejar el hash de la contraseña"""
        username = validated_data['username']
        email = validated_data['email']
        password = validated_data['password']
        
        user = User.objects.create_user(
            username=username,
            email=email,
            password=password
        )
        
        return user


class PasswordResetRequestSerializer(serializers.Serializer):
    """
    Serializer para solicitar recuperación de contraseña
    """
    email = serializers.EmailField()
    
    def validate_email(self, value):
        """Valida que el email exista en el sistema"""
        if not User.objects.filter(email=value).exists():
            raise serializers.ValidationError("No existe una cuenta con este email.")
        return value


class PasswordResetConfirmSerializer(serializers.Serializer):
    """
    Serializer para confirmar el cambio de contraseña
    """
    token = serializers.UUIDField()
    new_password = serializers.CharField(
        write_only=True,
        min_length=8,
        style={'input_type': 'password'}
    )
    confirm_password = serializers.CharField(
        write_only=True,
        min_length=8,
        style={'input_type': 'password'}
    )
    
    def validate(self, attrs):
        """Valida que las contraseñas coincidan"""
        if attrs['new_password'] != attrs['confirm_password']:
            raise serializers.ValidationError("Las contraseñas no coinciden.")
        return attrs
    
    def validate_token(self, value):
        """Valida que el token sea válido"""
        try:
            token = PasswordResetToken.objects.get(token=value)
            if not token.is_valid():
                raise serializers.ValidationError("El token ha expirado o ya fue usado.")
        except PasswordResetToken.DoesNotExist:
            raise serializers.ValidationError("Token inválido.")
        return value


class EmailVerificationResendSerializer(serializers.Serializer):
    """
    Serializer para reenviar email de verificación
    """
    email = serializers.EmailField()
    
    def validate_email(self, value):
        """Valida que el email exista y no esté ya verificado"""
        try:
            user = User.objects.get(email=value)
            if user.email_verified:
                raise serializers.ValidationError("Este email ya está verificado.")
        except User.DoesNotExist:
            raise serializers.ValidationError("No existe una cuenta con este email.")
        return value


class EmailVerifySerializer(serializers.Serializer):
    """
    Serializer para verificar email con token
    """
    token = serializers.UUIDField()
    
    def validate_token(self, value):
        """Valida que el token sea válido y no esté expirado"""
        try:
            token = EmailVerificationToken.objects.get(token=value)
            if not token.is_valid():
                raise serializers.ValidationError("El token ha expirado o ya fue usado.")
        except EmailVerificationToken.DoesNotExist:
            raise serializers.ValidationError("Token inválido.")
        return value


class ChangePasswordSerializer(serializers.Serializer):
    """Serializer para cambio de contraseña de usuario autenticado"""
    current_password = serializers.CharField(
        write_only=True,
        style={'input_type': 'password'}
    )
    new_password = serializers.CharField(
        write_only=True,
        min_length=8,
        style={'input_type': 'password'}
    )
    confirm_password = serializers.CharField(
        write_only=True,
        style={'input_type': 'password'}
    )
    
    def __init__(self, *args, **kwargs):
        self.user = kwargs.pop('user', None)
        super().__init__(*args, **kwargs)
    
    def validate_current_password(self, value):
        """Valida que la contraseña actual sea correcta"""
        if not self.user:
            raise serializers.ValidationError("Usuario no encontrado en contexto.")
        
        authenticated_user = authenticate(
            username=self.user.email, 
            password=value
        )
        
        if not authenticated_user:
            raise serializers.ValidationError("La contraseña actual es incorrecta.")
        return value
    
    def validate_new_password(self, value):
        """Valida políticas de seguridad de contraseña"""
        errors = self._validate_password_policy(value)
        if errors:
            raise serializers.ValidationError(errors)
        return value
    
    def validate(self, attrs):
        """Validaciones cruzadas entre campos"""
        current_password = attrs.get('current_password')
        new_password = attrs.get('new_password')
        confirm_password = attrs.get('confirm_password')
        
        if new_password != confirm_password:
            raise serializers.ValidationError({
                'confirm_password': 'Las contraseñas no coinciden.'
            })
        
        if current_password == new_password:
            raise serializers.ValidationError({
                'new_password': 'La nueva contraseña debe ser diferente a la actual.'
            })
        
        return attrs
    
    def _validate_password_policy(self, password):
        """Valida políticas de seguridad de contraseña"""
        errors = []
        
        if len(password) < 8:
            errors.append("La contraseña debe tener al menos 8 caracteres")
        
        if not re.search(r'[A-Z]', password):
            errors.append("La contraseña debe contener al menos una letra mayúscula")
        
        if not re.search(r'[a-z]', password):
            errors.append("La contraseña debe contener al menos una letra minúscula")
        
        if not re.search(r'\d', password):
            errors.append("La contraseña debe contener al menos un número")
        
        if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
            errors.append("La contraseña debe contener al menos un carácter especial (!@#$%^&*(),.?\":{}|<>)")
        
        return errors


# ===== SERIALIZERS PARA PERFILES DE USUARIO =====

class UserProfileSerializer(serializers.ModelSerializer):
    """
    Serializer completo para el perfil de usuario (uso interno y actualización)
    """
    age = serializers.SerializerMethodField()
    
    class Meta:
        model = UserProfile
        fields = [
            'bio', 'location', 'birth_date', 'age',
            'favorite_games', 'play_style', 'experience_level',
            'avatar_url', 'banner_url', 'theme_preference',
            'show_email', 'show_location', 'show_birth_date',
            'show_communities', 'show_activity_stats',
            'communities_count', 'posts_count', 'likes_received',
            'reputation_score', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'communities_count', 'posts_count', 'likes_received',
            'reputation_score', 'created_at', 'updated_at', 'age'
        ]
    
    def get_age(self, obj):
        """Calcula la edad del usuario"""
        return obj.get_age()

    def validate_favorite_games(self, value):
        """Valida que la lista de juegos favoritos no sea demasiado larga"""
        if len(value) > 10:
            raise serializers.ValidationError("No puedes tener más de 10 juegos favoritos.")
        return value

    def validate_bio(self, value):
        """Valida que la biografía no contenga contenido inapropiado"""
        # Lista básica de palabras prohibidas (se puede expandir)
        prohibited_words = ['spam', 'hack', 'cheat']
        for word in prohibited_words:
            if word.lower() in value.lower():
                raise serializers.ValidationError(f"La biografía contiene contenido no permitido.")
        return value


class PublicUserProfileSerializer(serializers.ModelSerializer):
    """
    Serializer para mostrar perfiles públicos respetando configuraciones de privacidad
    """
    username = serializers.CharField(source='user.username', read_only=True)
    first_name = serializers.CharField(source='user.first_name', read_only=True)
    last_name = serializers.CharField(source='user.last_name', read_only=True)
    email = serializers.SerializerMethodField()
    location = serializers.SerializerMethodField()
    birth_date = serializers.SerializerMethodField()
    age = serializers.SerializerMethodField()
    stats = serializers.SerializerMethodField()
    joined_at = serializers.DateTimeField(source='user.created_at', read_only=True)
    
    class Meta:
        model = UserProfile
        fields = [
            'username', 'first_name', 'last_name', 'email',
            'bio', 'location', 'birth_date', 'age', 'joined_at',
            'favorite_games', 'play_style', 'experience_level',
            'avatar_url', 'banner_url', 'stats'
        ]
    
    def get_email(self, obj):
        """Retorna email solo si el usuario permite mostrarlo"""
        return obj.user.email if obj.show_email else None
    
    def get_location(self, obj):
        """Retorna ubicación solo si el usuario permite mostrarla"""
        return obj.location if obj.show_location else None
    
    def get_birth_date(self, obj):
        """Retorna fecha de nacimiento solo si el usuario permite mostrarla"""
        return obj.birth_date if obj.show_birth_date else None
    
    def get_age(self, obj):
        """Retorna edad solo si el usuario permite mostrar fecha de nacimiento"""
        return obj.get_age() if obj.show_birth_date else None
    
    def get_stats(self, obj):
        """Retorna estadísticas solo si el usuario permite mostrarlas"""
        if obj.show_activity_stats:
            return {
                'communities_count': obj.communities_count,
                'posts_count': obj.posts_count,
                'likes_received': obj.likes_received,
                'reputation_score': obj.reputation_score,
            }
        return None


class UserPublicProfileDetailSerializer(serializers.ModelSerializer):
    """
    Serializer detallado para perfiles públicos con manejo completo de biografía.
    Todos los perfiles son públicos para fomentar transparencia en el MVP.
    """
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    username = serializers.CharField(source='user.username', read_only=True)
    first_name = serializers.CharField(source='user.first_name', read_only=True)
    last_name = serializers.CharField(source='user.last_name', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)
    stats = serializers.SerializerMethodField()
    joined_at = serializers.DateTimeField(source='user.date_joined', read_only=True)
    age = serializers.SerializerMethodField()
    
    # Manejo completo de biografía
    bio_preview = serializers.SerializerMethodField()
    bio_is_long = serializers.SerializerMethodField()
    
    # Actividad reciente
    recent_posts = serializers.SerializerMethodField()
    recent_communities = serializers.SerializerMethodField()
    
    class Meta:
        model = UserProfile
        fields = [
            'user_id', 'username', 'first_name', 'last_name', 'email',
            'bio', 'bio_preview', 'bio_is_long', 'location', 'birth_date', 
            'age', 'joined_at', 'favorite_games', 'play_style', 
            'experience_level', 'avatar_url', 'banner_url', 'stats',
            'recent_posts', 'recent_communities'
        ]
    
    def get_age(self, obj):
        """Retorna edad calculada desde birth_date"""
        return obj.get_age() if obj.birth_date else None
    
    def get_stats(self, obj):
        """Retorna todas las estadísticas - siempre públicas"""
        return {
            'communities_count': obj.communities_count,
            'posts_count': obj.posts_count,
            'likes_received': obj.likes_received,
            'reputation_score': obj.reputation_score,
        }
    
    def get_bio_preview(self, obj):
        """Genera preview de biografía si es muy larga (>200 chars)"""
        if not obj.bio:
            return None
        
        if len(obj.bio) > 200:
            return obj.bio[:200] + "..."
        
        return obj.bio
    
    def get_bio_is_long(self, obj):
        """Indica si la biografía necesita expandirse"""
        return obj.bio and len(obj.bio) > 200
    
    def get_recent_posts(self, obj):
        """Obtiene últimos 5 posts - siempre públicos"""
        if hasattr(obj.user, 'authored_posts'):
            posts = obj.user.authored_posts.all()[:5]
            return [{
                'id': post.id,
                'title': post.title or post.content[:50] + "..." if len(post.content) > 50 else post.content,
                'created_at': post.created_at,
                'community': {
                    'id': post.community.id,
                    'name': post.community.name
                } if post.community else None
            } for post in posts]
        
        return []
    
    def get_recent_communities(self, obj):
        """Obtiene últimas 5 comunidades - siempre públicas"""
        if hasattr(obj.user, 'memberships'):
            memberships = obj.user.memberships.all()[:5]
            return [{
                'id': membership.community.id,
                'name': membership.community.name,
                'role': membership.role,
                'joined_at': membership.joined_at
            } for membership in memberships]
        
        return []


class UserBasicSerializer(serializers.ModelSerializer):
    """
    Serializer básico para mostrar información mínima de usuario en listas
    """
    avatar_url = serializers.SerializerMethodField()
    location = serializers.SerializerMethodField()
    communities_count = serializers.SerializerMethodField()
    
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'avatar_url', 'location', 'communities_count']
    
    def get_avatar_url(self, obj):
        """Obtiene el avatar del perfil si existe"""
        if hasattr(obj, 'profile'):
            return obj.profile.avatar_url
        return None
    
    def get_location(self, obj):
        """Obtiene la ubicación del perfil si es pública"""
        if hasattr(obj, 'profile') and obj.profile.show_location:
            return obj.profile.location
        return None
    
    def get_communities_count(self, obj):
        """Obtiene el número de comunidades si es público"""
        if hasattr(obj, 'profile') and obj.profile.show_activity_stats:
            return obj.profile.communities_count
        return None


class UserSearchSerializer(serializers.ModelSerializer):
    """
    Serializer optimizado para búsquedas de usuarios
    """
    avatar_url = serializers.CharField(source='profile.avatar_url', read_only=True)
    location = serializers.SerializerMethodField()
    communities_count = serializers.SerializerMethodField()
    play_style = serializers.CharField(source='profile.play_style', read_only=True)
    experience_level = serializers.CharField(source='profile.experience_level', read_only=True)
    
    class Meta:
        model = User
        fields = [
            'id', 'username', 'first_name', 'last_name',
            'avatar_url', 'location', 'communities_count',
            'play_style', 'experience_level'
        ]
    
    def get_location(self, obj):
        """Obtiene la ubicación si es pública"""
        if hasattr(obj, 'profile') and obj.profile.show_location:
            return obj.profile.location
        return None
    
    def get_communities_count(self, obj):
        """Obtiene el número de comunidades si es público"""
        if hasattr(obj, 'profile') and obj.profile.show_activity_stats:
            return obj.profile.communities_count
        return None


# ============================================================================
# SERIALIZERS PARA SISTEMA DE VALORACIONES (FASE 4.2)
# ============================================================================

class UserRatingSerializer(serializers.ModelSerializer):
    """
    Serializer completo para el modelo UserRating
    Usado para crear y actualizar valoraciones
    """
    rater_username = serializers.CharField(source='rater.username', read_only=True)
    rated_user_username = serializers.CharField(source='rated_user.username', read_only=True)
    
    class Meta:
        model = UserRating
        fields = [
            'id', 'rater', 'rated_user', 'rating', 'comment',
            'interaction_type', 'interaction_reference',
            'rater_username', 'rated_user_username',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'rater', 'created_at', 'updated_at']
    
    def validate_rating(self, value):
        """Valida que la valoración esté entre 1 y 5"""
        if not (1 <= value <= 5):
            raise serializers.ValidationError("La valoración debe estar entre 1 y 5 estrellas")
        return value
    
    def validate_comment(self, value):
        """Valida la longitud del comentario"""
        if len(value) > 300:
            raise serializers.ValidationError("El comentario no puede exceder 300 caracteres")
        return value
    
    def validate(self, data):
        """Validaciones a nivel de instancia"""
        request = self.context.get('request')
        if request and request.user:
            # Verificar que el usuario no se valore a sí mismo
            if data.get('rated_user') == request.user:
                raise serializers.ValidationError("No puedes valorarte a ti mismo")
            
            # Para actualizaciones, verificar que solo el creador puede modificar
            if self.instance and self.instance.rater != request.user:
                raise serializers.ValidationError("Solo puedes modificar tus propias valoraciones")
        
        return data


class UserRatingCreateSerializer(serializers.ModelSerializer):
    """
    Serializer específico para crear valoraciones
    Simplifica los campos requeridos para el endpoint de creación
    """
    
    class Meta:
        model = UserRating
        fields = [
            'rated_user', 'rating', 'comment', 
            'interaction_type', 'interaction_reference'
        ]
    
    def validate_rating(self, value):
        """Valida que la valoración esté entre 1 y 5"""
        if not (1 <= value <= 5):
            raise serializers.ValidationError("La valoración debe estar entre 1 y 5 estrellas")
        return value
    
    def validate_comment(self, value):
        """Valida la longitud del comentario"""
        if value and len(value) > 300:
            raise serializers.ValidationError("El comentario no puede exceder 300 caracteres")
        return value
    
    def validate(self, data):
        """Validaciones a nivel de instancia"""
        request = self.context.get('request')
        if request and request.user:
            # Verificar que el usuario no se valore a sí mismo
            if data.get('rated_user') == request.user:
                raise serializers.ValidationError("No puedes valorarte a ti mismo")
            
            # Verificar si ya existe una valoración del mismo usuario
            if UserRating.objects.filter(
                rater=request.user, 
                rated_user=data.get('rated_user')
            ).exists():
                raise serializers.ValidationError("Ya has valorado a este usuario")
        
        return data
    
    def create(self, validated_data):
        """Crea una nueva valoración asignando automáticamente el rater"""
        validated_data['rater'] = self.context['request'].user
        return super().create(validated_data)


class UserRatingDetailSerializer(serializers.ModelSerializer):
    """
    Serializer detallado para mostrar valoraciones con información del usuario
    Usado para listados y detalles de valoraciones
    """
    rater_info = serializers.SerializerMethodField()
    rated_user_info = serializers.SerializerMethodField()
    rating_display = serializers.SerializerMethodField()
    time_ago = serializers.SerializerMethodField()
    
    class Meta:
        model = UserRating
        fields = [
            'id', 'rating', 'comment', 'interaction_type', 
            'interaction_reference', 'rater_info', 'rated_user_info',
            'rating_display', 'time_ago', 'created_at', 'updated_at'
        ]
    
    def get_rater_info(self, obj):
        """Información básica del usuario que valoró"""
        return {
            'id': obj.rater.id,
            'username': obj.rater.username,
            'avatar_url': getattr(obj.rater.profile, 'avatar_url', None) if hasattr(obj.rater, 'profile') else None
        }
    
    def get_rated_user_info(self, obj):
        """Información básica del usuario valorado"""
        return {
            'id': obj.rated_user.id,
            'username': obj.rated_user.username,
            'avatar_url': getattr(obj.rated_user.profile, 'avatar_url', None) if hasattr(obj.rated_user, 'profile') else None
        }
    
    def get_rating_display(self, obj):
        """Representación visual de la valoración"""
        stars = '⭐' * obj.rating
        return f"{stars} ({obj.rating}/5)"
    
    def get_time_ago(self, obj):
        """Tiempo transcurrido desde la valoración"""
        from django.utils import timezone
        from datetime import timedelta
        
        now = timezone.now()
        diff = now - obj.created_at
        
        if diff.days > 30:
            return f"hace {diff.days // 30} mes{'es' if diff.days // 30 > 1 else ''}"
        elif diff.days > 0:
            return f"hace {diff.days} día{'s' if diff.days > 1 else ''}"
        elif diff.seconds > 3600:
            hours = diff.seconds // 3600
            return f"hace {hours} hora{'s' if hours > 1 else ''}"
        elif diff.seconds > 60:
            minutes = diff.seconds // 60
            return f"hace {minutes} minuto{'s' if minutes > 1 else ''}"
        else:
            return "hace un momento"


class UserRatingStatsSerializer(serializers.Serializer):
    """
    Serializer para estadísticas de valoraciones de un usuario
    Usado para el endpoint de estadísticas
    """
    total_ratings = serializers.IntegerField()
    average_rating = serializers.FloatField()
    rating_distribution = serializers.DictField()
    recent_ratings = UserRatingDetailSerializer(many=True, read_only=True)
    
    def to_representation(self, instance):
        """Personaliza la representación de las estadísticas"""
        data = super().to_representation(instance)
        
        # Formatear el promedio
        if data['average_rating']:
            data['average_rating_display'] = f"{data['average_rating']:.1f}/5.0 ⭐"
            data['rating_percentage'] = round((data['average_rating'] / 5) * 100, 1)
        else:
            data['average_rating_display'] = "Sin valoraciones"
            data['rating_percentage'] = 0
        
        return data


# ======================================
# FASE 4-0006: ANTI-GAMING SERIALIZERS
# ======================================

class RatingFlagSerializer(serializers.ModelSerializer):
    """
    Serializer para flags de valoraciones sospechosas
    """
    rating_info = serializers.SerializerMethodField()
    rater_info = serializers.SerializerMethodField()
    rated_user_info = serializers.SerializerMethodField()
    reviewed_by_info = serializers.SerializerMethodField()
    severity_display = serializers.CharField(source='get_severity_display', read_only=True)
    flag_type_display = serializers.CharField(source='get_flag_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    
    class Meta:
        model = RatingFlag
        fields = [
            'id', 'flag_type', 'flag_type_display', 'severity', 'severity_display',
            'status', 'status_display', 'details', 'created_at', 'reviewed_at',
            'moderator_notes', 'rating_info', 'rater_info', 'rated_user_info',
            'reviewed_by_info'
        ]
        read_only_fields = ['id', 'created_at']
    
    def get_rating_info(self, obj):
        """Información básica de la valoración flaggeada"""
        return {
            'id': obj.rating.id,
            'rating': obj.rating.rating,
            'comment': obj.rating.comment[:100] + '...' if len(obj.rating.comment) > 100 else obj.rating.comment,
            'interaction_type': obj.rating.interaction_type,
            'created_at': obj.rating.created_at
        }
    
    def get_rater_info(self, obj):
        """Información del usuario que dio la valoración"""
        return {
            'id': obj.rating.rater.id,
            'username': obj.rating.rater.username,
            'email': obj.rating.rater.email
        }
    
    def get_rated_user_info(self, obj):
        """Información del usuario que recibió la valoración"""
        return {
            'id': obj.rating.rated_user.id,
            'username': obj.rating.rated_user.username,
            'email': obj.rating.rated_user.email
        }
    
    def get_reviewed_by_info(self, obj):
        """Información del moderador que revisó el flag"""
        if obj.reviewed_by:
            return {
                'id': obj.reviewed_by.id,
                'username': obj.reviewed_by.username,
                'email': obj.reviewed_by.email
            }
        return None


class UserSuspensionSerializer(serializers.ModelSerializer):
    """
    Serializer para suspensiones de usuarios
    """
    user_info = serializers.SerializerMethodField()
    suspended_by_info = serializers.SerializerMethodField()
    lifted_by_info = serializers.SerializerMethodField()
    suspension_type_display = serializers.CharField(source='get_suspension_type_display', read_only=True)
    reason_display = serializers.CharField(source='get_reason_display', read_only=True)
    days_remaining = serializers.SerializerMethodField()
    is_expired = serializers.SerializerMethodField()
    
    class Meta:
        model = UserSuspension
        fields = [
            'id', 'suspension_type', 'suspension_type_display', 'reason', 'reason_display',
            'reason_details', 'suspended_at', 'expires_at', 'is_active', 'lifted_at',
            'lift_reason', 'user_info', 'suspended_by_info', 'lifted_by_info',
            'days_remaining', 'is_expired'
        ]
        read_only_fields = ['id', 'suspended_at']
    
    def get_user_info(self, obj):
        """Información del usuario suspendido"""
        return {
            'id': obj.user.id,
            'username': obj.user.username,
            'email': obj.user.email
        }
    
    def get_suspended_by_info(self, obj):
        """Información del moderador que suspendió"""
        return {
            'id': obj.suspended_by.id,
            'username': obj.suspended_by.username
        }
    
    def get_lifted_by_info(self, obj):
        """Información del moderador que levantó la suspensión"""
        if obj.lifted_by:
            return {
                'id': obj.lifted_by.id,
                'username': obj.lifted_by.username
            }
        return None
    
    def get_days_remaining(self, obj):
        """Días restantes de suspensión"""
        if not obj.is_active or not obj.expires_at:
            return None
        
        remaining = (obj.expires_at - timezone.now()).days
        return max(0, remaining)
    
    def get_is_expired(self, obj):
        """Si la suspensión ha expirado"""
        if not obj.expires_at:
            return False
        return timezone.now() > obj.expires_at


class AbuseLogSerializer(serializers.ModelSerializer):
    """
    Serializer para logs de auditoría del sistema anti-abuso
    """
    target_user_info = serializers.SerializerMethodField()
    moderator_info = serializers.SerializerMethodField()
    action_type_display = serializers.CharField(source='get_action_type_display', read_only=True)
    
    class Meta:
        model = AbuseLog
        fields = [
            'id', 'action_type', 'action_type_display', 'timestamp', 'details',
            'notes', 'target_user_info', 'moderator_info'
        ]
        read_only_fields = ['id', 'timestamp']
    
    def get_target_user_info(self, obj):
        """Información del usuario afectado"""
        if obj.target_user:
            return {
                'id': obj.target_user.id,
                'username': obj.target_user.username
            }
        return None
    
    def get_moderator_info(self, obj):
        """Información del moderador que ejecutó la acción"""
        if obj.moderator:
            return {
                'id': obj.moderator.id,
                'username': obj.moderator.username
            }
        return {'system': True}  # Acción automática
