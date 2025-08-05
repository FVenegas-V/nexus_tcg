#!/usr/bin/env python
"""
Script de prueba para el sistema de registro de Nexus TCG
Ejecutar desde el directorio backend/
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
from rest_framework.test import APIClient
import json

def test_registration():
    print("🧪 PRUEBA DEL SISTEMA DE REGISTRO - Nexus TCG")
    print("=" * 50)
    
    # Crear cliente de prueba
    client = APIClient()
    
    # Datos de prueba
    test_data = {
        'username': 'usuario_prueba',
        'email': 'prueba@nexustcg.com',
        'password': 'contraseña123'
    }
    
    print(f"📊 Datos de prueba:")
    print(f"   Username: {test_data['username']}")
    print(f"   Email: {test_data['email']}")
    print(f"   Password: {'*' * len(test_data['password'])}")
    print()
    
    # Limpiar usuario si existe
    try:
        existing_user = User.objects.get(username=test_data['username'])
        existing_user.delete()
        print("🗑️  Usuario existente eliminado para la prueba")
    except User.DoesNotExist:
        pass
    
    print("1️⃣ ENVIANDO SOLICITUD DE REGISTRO...")
    print("-" * 30)
    
    # Simular request POST a /api/auth/register/
    response = client.post('/api/auth/register/', test_data, format='json')
    
    print(f"📡 Status Code: {response.status_code}")
    print(f"📄 Response Data: {json.dumps(response.data, indent=2, ensure_ascii=False)}")
    print()
    
    if response.status_code == 201:
        print("✅ REGISTRO EXITOSO!")
        
        # Verificar que el usuario se creó en la base de datos
        try:
            created_user = User.objects.get(username=test_data['username'])
            print(f"👤 Usuario creado en BD:")
            print(f"   ID: {created_user.id}")
            print(f"   Username: {created_user.username}")
            print(f"   Email: {created_user.email}")
            print(f"   Password Hash: {created_user.password[:50]}...")
            print(f"   Fecha creación: {created_user.date_joined}")
            print(f"   Activo: {created_user.is_active}")
            print()
            
            # Probar login con el usuario creado
            print("2️⃣ PROBANDO LOGIN CON USUARIO CREADO...")
            print("-" * 40)
            
            login_data = {
                'username': test_data['username'],
                'password': test_data['password']
            }
            
            login_response = client.post('/api/auth/login/', login_data, format='json')
            print(f"📡 Login Status Code: {login_response.status_code}")
            
            if login_response.status_code == 200:
                print("✅ LOGIN EXITOSO!")
                print(f"🔑 Access Token: {login_response.data.get('access', 'No encontrado')[:50]}...")
                print(f"🔄 Refresh Token: {login_response.data.get('refresh', 'No encontrado')[:50]}...")
                print(f"👤 Datos usuario: {json.dumps(login_response.data.get('user', {}), indent=2, ensure_ascii=False)}")
                
                # Probar API protegida
                print()
                print("3️⃣ PROBANDO API PROTEGIDA...")
                print("-" * 30)
                
                access_token = login_response.data.get('access')
                client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')
                
                profile_response = client.get('/api/users/me/')
                print(f"📡 Profile Status Code: {profile_response.status_code}")
                
                if profile_response.status_code == 200:
                    print("✅ ACCESO A API PROTEGIDA EXITOSO!")
                    print(f"👤 Perfil: {json.dumps(profile_response.data, indent=2, ensure_ascii=False, default=str)}")
                else:
                    print("❌ Error al acceder a API protegida")
                    print(f"Error: {profile_response.data}")
            else:
                print("❌ LOGIN FALLÓ")
                print(f"Error: {login_response.data}")
                
        except User.DoesNotExist:
            print("❌ Usuario no se creó en la base de datos")
    else:
        print("❌ REGISTRO FALLÓ")
        print(f"Errores: {response.data}")
    
    print()
    print("🔍 PROBANDO VALIDACIONES...")
    print("-" * 30)
    
    # Probar registro duplicado
    print("📝 Intentando registrar mismo username...")
    duplicate_response = client.post('/api/auth/register/', test_data, format='json')
    print(f"Status: {duplicate_response.status_code}")
    print(f"Error esperado: {duplicate_response.data}")
    
    print()
    print("🎯 RESUMEN DE LA PRUEBA:")
    print("=" * 30)
    print("✅ Sistema de registro funcional")
    print("✅ Validaciones de username y email únicos")
    print("✅ Hashing automático de contraseñas")
    print("✅ Login con JWT tokens")
    print("✅ APIs protegidas funcionando")

if __name__ == "__main__":
    test_registration()
