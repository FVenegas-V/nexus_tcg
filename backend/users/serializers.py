from django.contrib.auth.models import User
from rest_framework import serializers
from django.core.exceptions import ValidationError


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
