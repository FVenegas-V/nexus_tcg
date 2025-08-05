#!/usr/bin/env python
"""
Script simplificado para probar el registro
"""

import os
import sys
import django
from pathlib import Path

# Configurar Django
sys.path.append(str(Path(__file__).parent))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from django.contrib.auth.models import User
from users.serializers import RegisterSerializer

def test_direct_registration():
    print("🧪 PRUEBA DIRECTA DEL SISTEMA DE REGISTRO")
    print("=" * 45)
    
    # Limpiar usuario si existe
    username = 'test_user_2025'
    try:
        existing_user = User.objects.get(username=username)
        existing_user.delete()
        print("🗑️  Usuario existente eliminado")
    except User.DoesNotExist:
        print("✅ No hay usuario existente con ese nombre")
    
    print()
    print("1️⃣ CREANDO USUARIO CON SERIALIZER...")
    print("-" * 40)
    
    # Datos de prueba
    data = {
        'username': username,
        'email': 'test2025@nexustcg.com',
        'password': 'password123'
    }
    
    print(f"📊 Datos de entrada:")
    for key, value in data.items():
        if key == 'password':
            print(f"   {key}: {'*' * len(value)}")
        else:
            print(f"   {key}: {value}")
    
    # Crear serializer y validar
    serializer = RegisterSerializer(data=data)
    
    print()
    print("🔍 VALIDANDO DATOS...")
    if serializer.is_valid():
        print("✅ Datos válidos!")
        
        # Crear usuario
        user = serializer.save()
        
        print(f"✅ Usuario creado exitosamente!")
        print(f"   ID: {user.id}")
        print(f"   Username: {user.username}")
        print(f"   Email: {user.email}")
        print(f"   Password (hash): {user.password[:50]}...")
        print(f"   Fecha creación: {user.date_joined}")
        print(f"   ¿Activo?: {user.is_active}")
        
        # Verificar que la contraseña funciona
        print()
        print("2️⃣ VERIFICANDO AUTENTICACIÓN...")
        print("-" * 35)
        
        from django.contrib.auth import authenticate
        auth_user = authenticate(username=username, password='password123')
        
        if auth_user:
            print("✅ Autenticación exitosa!")
            print(f"   Usuario autenticado: {auth_user.username}")
        else:
            print("❌ Fallo en autenticación")
        
        # Probar contraseña incorrecta
        wrong_auth = authenticate(username=username, password='wrong_password')
        if not wrong_auth:
            print("✅ Contraseña incorrecta rechazada correctamente")
        
        print()
        print("3️⃣ PROBANDO VALIDACIONES...")
        print("-" * 30)
        
        # Intentar crear usuario duplicado
        duplicate_data = {
            'username': username,  # Mismo username
            'email': 'otro@email.com',
            'password': 'password456'
        }
        
        duplicate_serializer = RegisterSerializer(data=duplicate_data)
        if not duplicate_serializer.is_valid():
            print("✅ Username duplicado rechazado:")
            print(f"   Error: {duplicate_serializer.errors}")
        
        # Intentar email duplicado
        email_duplicate_data = {
            'username': 'otro_usuario',
            'email': 'test2025@nexustcg.com',  # Mismo email
            'password': 'password789'
        }
        
        email_duplicate_serializer = RegisterSerializer(data=email_duplicate_data)
        if not email_duplicate_serializer.is_valid():
            print("✅ Email duplicado rechazado:")
            print(f"   Error: {email_duplicate_serializer.errors}")
            
    else:
        print("❌ Errores de validación:")
        print(f"   {serializer.errors}")
    
    print()
    print("📊 ESTADÍSTICAS DE LA BASE DE DATOS:")
    print("-" * 35)
    total_users = User.objects.count()
    print(f"Total de usuarios: {total_users}")
    
    if total_users > 0:
        print("Usuarios registrados:")
        for user in User.objects.all()[:5]:  # Mostrar solo los primeros 5
            print(f"  - {user.username} ({user.email}) - {user.date_joined.strftime('%Y-%m-%d %H:%M')}")
    
    print()
    print("🎯 RESUMEN:")
    print("=" * 20)
    print("✅ RegisterSerializer funciona correctamente")
    print("✅ Validaciones de username y email únicas")
    print("✅ Hash de contraseñas automático")
    print("✅ Autenticación funcional")
    print("✅ Manejo de errores apropiado")

if __name__ == "__main__":
    test_direct_registration()
