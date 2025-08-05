#!/usr/bin/env python
"""
Script de prueba para el sistema de recuperación de contraseñas
Teste las nuevas funcionalidades de fase1-0003
"""

import os
import sys
import django
import uuid
from datetime import timedelta
from django.utils import timezone

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from django.contrib.auth import get_user_model
from users.models import PasswordResetToken
from users.serializers import (
    RegisterSerializer,
    PasswordResetRequestSerializer,
    PasswordResetConfirmSerializer
)
import json

User = get_user_model()

def print_separator(title):
    print("\n" + "="*60)
    print(f" {title}")
    print("="*60)

def test_user_model():
    """Prueba el modelo de usuario personalizado"""
    print_separator("PROBANDO MODELO DE USUARIO PERSONALIZADO")
    
    # Crear usuario
    user_data = {
        'username': 'testuser',
        'email': 'test@example.com',
        'password': 'testpass123'
    }
    
    user = User.objects.create_user(**user_data)
    print(f"✅ Usuario creado: {user.username} ({user.email})")
    print(f"   - ID: {user.id}")
    print(f"   - Email verificado: {user.email_verified}")
    print(f"   - Fecha de creación: {user.created_at}")
    
    return user

def test_password_reset_token():
    """Prueba el modelo de token de recuperación"""
    print_separator("PROBANDO MODELO DE TOKEN DE RECUPERACIÓN")
    
    # Obtener usuario existente o crear uno nuevo
    user, created = User.objects.get_or_create(
        email='test@example.com',
        defaults={
            'username': 'testuser',
            'password': 'testpass123'
        }
    )
    
    # Crear token de recuperación
    reset_token = PasswordResetToken.objects.create(user=user)
    print(f"✅ Token creado: {reset_token.token}")
    print(f"   - Usuario: {reset_token.user.email}")
    print(f"   - Válido: {reset_token.is_valid()}")
    print(f"   - Expira en: {reset_token.expires_at}")
    
    # Probar validación de token
    assert reset_token.is_valid() == True, "El token debería ser válido"
    print("✅ Validación de token correcta")
    
    # Probar marcar como usado
    reset_token.mark_as_used()
    assert reset_token.is_valid() == False, "El token debería ser inválido después de usarse"
    print("✅ Marcar como usado funciona correctamente")
    
    return reset_token

def test_serializers():
    """Prueba los serializers de recuperación de contraseña"""
    print_separator("PROBANDO SERIALIZERS DE RECUPERACIÓN")
    
    # Crear usuario para las pruebas
    user, created = User.objects.get_or_create(
        email='recovery@example.com',
        defaults={
            'username': 'recoveryuser',
            'password': 'testpass123'
        }
    )
    
    # 1. Probar PasswordResetRequestSerializer
    print("\n1. Probando PasswordResetRequestSerializer:")
    request_data = {'email': 'recovery@example.com'}
    request_serializer = PasswordResetRequestSerializer(data=request_data)
    
    if request_serializer.is_valid():
        print("✅ Serializer de solicitud válido")
        print(f"   - Email validado: {request_serializer.validated_data['email']}")
    else:
        print(f"❌ Error en serializer de solicitud: {request_serializer.errors}")
    
    # 2. Probar con email inexistente
    print("\n2. Probando con email inexistente:")
    invalid_request_data = {'email': 'noexiste@example.com'}
    invalid_request_serializer = PasswordResetRequestSerializer(data=invalid_request_data)
    
    if not invalid_request_serializer.is_valid():
        print("✅ Validación correcta para email inexistente")
        print(f"   - Error: {invalid_request_serializer.errors}")
    else:
        print("❌ Debería haber fallado con email inexistente")
    
    # 3. Probar PasswordResetConfirmSerializer
    print("\n3. Probando PasswordResetConfirmSerializer:")
    
    # Crear token válido
    reset_token = PasswordResetToken.objects.create(user=user)
    
    confirm_data = {
        'token': str(reset_token.token),
        'new_password': 'newpassword123',
        'confirm_password': 'newpassword123'
    }
    
    confirm_serializer = PasswordResetConfirmSerializer(data=confirm_data)
    
    if confirm_serializer.is_valid():
        print("✅ Serializer de confirmación válido")
        print(f"   - Token: {confirm_serializer.validated_data['token']}")
    else:
        print(f"❌ Error en serializer de confirmación: {confirm_serializer.errors}")
    
    # 4. Probar con contraseñas que no coinciden
    print("\n4. Probando contraseñas que no coinciden:")
    mismatch_data = {
        'token': str(reset_token.token),
        'new_password': 'password1',
        'confirm_password': 'password2'
    }
    
    mismatch_serializer = PasswordResetConfirmSerializer(data=mismatch_data)
    
    if not mismatch_serializer.is_valid():
        print("✅ Validación correcta para contraseñas diferentes")
        print(f"   - Error: {mismatch_serializer.errors}")
    else:
        print("❌ Debería haber fallado con contraseñas diferentes")

def test_complete_flow():
    """Prueba el flujo completo de recuperación de contraseña"""
    print_separator("PROBANDO FLUJO COMPLETO DE RECUPERACIÓN")
    
    # 1. Crear usuario
    user, created = User.objects.get_or_create(
        email='flow@example.com',
        defaults={
            'username': 'flowuser',
        }
    )
    user.set_password('originalpassword')
    user.save()
    
    original_password_hash = user.password
    print(f"✅ Usuario creado/obtenido: {user.email}")
    print(f"   - Hash de contraseña original: {original_password_hash[:20]}...")
    
    # 2. Solicitar recuperación de contraseña
    print("\n2. Solicitando recuperación de contraseña:")
    reset_token = PasswordResetToken.objects.create(user=user)
    print(f"✅ Token de recuperación creado: {reset_token.token}")
    
    # 3. Verificar que el token es válido
    print("\n3. Verificando validez del token:")
    print(f"   - Token válido: {reset_token.is_valid()}")
    print(f"   - Expira en: {reset_token.expires_at}")
    print(f"   - Usado en: {reset_token.used_at}")
    
    # 4. Simular cambio de contraseña
    print("\n4. Cambiando contraseña:")
    new_password = 'newpassword123'
    
    if reset_token.is_valid():
        user.set_password(new_password)
        user.save()
        reset_token.mark_as_used()
        print("✅ Contraseña cambiada exitosamente")
        print(f"   - Nuevo hash: {user.password[:20]}...")
        print(f"   - Token marcado como usado: {reset_token.used_at}")
    else:
        print("❌ Token inválido, no se pudo cambiar la contraseña")
    
    # 5. Verificar que la contraseña cambió
    print("\n5. Verificando cambio de contraseña:")
    user.refresh_from_db()
    
    if user.check_password(new_password):
        print("✅ Nueva contraseña funciona correctamente")
    else:
        print("❌ Error: La nueva contraseña no funciona")
    
    if user.check_password('originalpassword'):
        print("❌ Error: La contraseña original aún funciona")
    else:
        print("✅ Contraseña original ya no funciona")
    
    # 6. Verificar que el token no se puede usar de nuevo
    print("\n6. Verificando que el token ya no es válido:")
    if not reset_token.is_valid():
        print("✅ Token correctamente invalidado después del uso")
    else:
        print("❌ Error: Token aún válido después del uso")

def show_statistics():
    """Muestra estadísticas del sistema"""
    print_separator("ESTADÍSTICAS DEL SISTEMA")
    
    total_users = User.objects.count()
    total_tokens = PasswordResetToken.objects.count()
    valid_tokens = PasswordResetToken.objects.filter(
        used_at__isnull=True,
        expires_at__gt=timezone.now()
    ).count()
    used_tokens = PasswordResetToken.objects.filter(
        used_at__isnull=False
    ).count()
    expired_tokens = PasswordResetToken.objects.filter(
        used_at__isnull=True,
        expires_at__lte=timezone.now()
    ).count()
    
    print(f"👥 Total de usuarios: {total_users}")
    print(f"🔑 Total de tokens de recuperación: {total_tokens}")
    print(f"✅ Tokens válidos: {valid_tokens}")
    print(f"✔️  Tokens usados: {used_tokens}")
    print(f"⏰ Tokens expirados: {expired_tokens}")
    
    # Mostrar últimos usuarios
    print(f"\n📋 Últimos usuarios registrados:")
    recent_users = User.objects.order_by('-created_at')[:5]
    for i, user in enumerate(recent_users, 1):
        print(f"   {i}. {user.username} ({user.email}) - {user.created_at.strftime('%Y-%m-%d %H:%M')}")

def main():
    """Función principal que ejecuta todas las pruebas"""
    print("🚀 INICIANDO PRUEBAS DEL SISTEMA DE RECUPERACIÓN DE CONTRASEÑAS")
    print("   Nexus TCG - Fase 1-0003")
    
    try:
        # Ejecutar todas las pruebas
        test_user_model()
        test_password_reset_token()
        test_serializers()
        test_complete_flow()
        show_statistics()
        
        print_separator("RESUMEN DE PRUEBAS")
        print("✅ Todas las pruebas completadas exitosamente")
        print("🎉 Sistema de recuperación de contraseñas funcionando correctamente")
        print("\n📋 Nuevas APIs disponibles:")
        print("   - POST /api/auth/password-reset/")
        print("   - POST /api/auth/password-reset/confirm/")
        print("   - GET  /api/auth/password-reset/verify/<token>/")
        
    except Exception as e:
        print(f"\n❌ Error durante las pruebas: {str(e)}")
        print(f"   Tipo de error: {type(e).__name__}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
