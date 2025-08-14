from django.contrib.auth import get_user_model, authenticate
from rest_framework import serializers
from django.core.exceptions import ValidationError
from .models import PasswordResetToken, EmailVerificationToken, UserProfile
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
