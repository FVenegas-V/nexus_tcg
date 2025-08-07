from django.contrib.auth import get_user_model, authenticate
from rest_framework import serializers
from django.core.exceptions import ValidationError
from .models import PasswordResetToken, EmailVerificationToken
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
