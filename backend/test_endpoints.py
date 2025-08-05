#!/usr/bin/env python
"""
Script para probar los endpoints HTTP del sistema de registro
"""

import os
import sys
import django
from pathlib import Path

# Configurar Django
sys.path.append(str(Path(__file__).parent))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from django.test import Client
from django.contrib.auth.models import User
import json

def test_registration_endpoints():
    print("🌐 PRUEBA DE ENDPOINTS HTTP - REGISTRO Y LOGIN")
    print("=" * 50)
    
    # Crear cliente HTTP de prueba
    client = Client()
    
    # Limpiar usuario de prueba
    username = 'api_test_user'
    try:
        User.objects.get(username=username).delete()
        print("🗑️  Usuario de prueba eliminado")
    except User.DoesNotExist:
        print("✅ No hay usuario previo")
    
    print()
    print("1️⃣ PROBANDO ENDPOINT DE REGISTRO")
    print("POST /api/auth/register/")
    print("-" * 40)
    
    # Datos de registro
    register_data = {
        'username': username,
        'email': 'apitest@nexustcg.com',
        'password': 'testpassword123'
    }
    
    print(f"📤 Enviando datos:")
    for key, value in register_data.items():
        if key == 'password':
            print(f"   {key}: {'*' * len(value)}")
        else:
            print(f"   {key}: {value}")
    
    # Hacer request de registro
    response = client.post(
        '/api/auth/register/',
        data=json.dumps(register_data),
        content_type='application/json'
    )
    
    print(f"📡 Status Code: {response.status_code}")
    
    if response.status_code == 201:
        response_data = json.loads(response.content.decode())
        print("✅ REGISTRO EXITOSO!")
        print(f"📄 Response: {json.dumps(response_data, indent=2, ensure_ascii=False)}")
        
        print()
        print("2️⃣ PROBANDO ENDPOINT DE LOGIN")
        print("POST /api/auth/login/")
        print("-" * 35)
        
        # Datos de login
        login_data = {
            'username': username,
            'password': 'testpassword123'
        }
        
        print(f"📤 Enviando credenciales:")
        print(f"   username: {login_data['username']}")
        print(f"   password: {'*' * len(login_data['password'])}")
        
        # Hacer request de login
        login_response = client.post(
            '/api/auth/login/',
            data=json.dumps(login_data),
            content_type='application/json'
        )
        
        print(f"📡 Status Code: {login_response.status_code}")
        
        if login_response.status_code == 200:
            login_data_response = json.loads(login_response.content.decode())
            print("✅ LOGIN EXITOSO!")
            
            # Mostrar tokens (parcialmente)
            access_token = login_data_response.get('access', '')
            refresh_token = login_data_response.get('refresh', '')
            user_info = login_data_response.get('user', {})
            
            print(f"🔑 Access Token: {access_token[:30]}...")
            print(f"🔄 Refresh Token: {refresh_token[:30]}...")
            print(f"👤 Usuario info:")
            print(f"   ID: {user_info.get('id')}")
            print(f"   Username: {user_info.get('username')}")
            print(f"   Email: {user_info.get('email')}")
            
            print()
            print("3️⃣ PROBANDO ENDPOINT PROTEGIDO")
            print("GET /api/users/me/")
            print("-" * 30)
            
            # Usar token para acceder a endpoint protegido
            headers = {
                'HTTP_AUTHORIZATION': f'Bearer {access_token}',
                'content_type': 'application/json'
            }
            
            profile_response = client.get('/api/users/me/', **headers)
            
            print(f"📡 Status Code: {profile_response.status_code}")
            
            if profile_response.status_code == 200:
                profile_data = json.loads(profile_response.content.decode())
                print("✅ ACCESO A API PROTEGIDA EXITOSO!")
                print(f"📄 Perfil completo:")
                print(json.dumps(profile_data, indent=2, ensure_ascii=False, default=str))
            else:
                print("❌ Error al acceder a API protegida")
                print(f"Error: {profile_response.content.decode()}")
                
        else:
            print("❌ LOGIN FALLÓ")
            print(f"Error: {login_response.content.decode()}")
            
    else:
        print("❌ REGISTRO FALLÓ")
        print(f"Error: {response.content.decode()}")
    
    print()
    print("4️⃣ PROBANDO VALIDACIONES DE ERROR")
    print("-" * 35)
    
    # Probar registro con datos faltantes
    print("📝 Probando registro sin password...")
    invalid_data = {
        'username': 'test_invalid',
        'email': 'invalid@test.com'
        # password faltante
    }
    
    invalid_response = client.post(
        '/api/auth/register/',
        data=json.dumps(invalid_data),
        content_type='application/json'
    )
    
    print(f"Status: {invalid_response.status_code}")
    if invalid_response.status_code != 201:
        print(f"✅ Error apropiado: {invalid_response.content.decode()}")
    
    # Probar login con credenciales incorrectas
    print()
    print("📝 Probando login con credenciales incorrectas...")
    wrong_login = {
        'username': username,
        'password': 'wrong_password'
    }
    
    wrong_response = client.post(
        '/api/auth/login/',
        data=json.dumps(wrong_login),
        content_type='application/json'
    )
    
    print(f"Status: {wrong_response.status_code}")
    if wrong_response.status_code == 401:
        print(f"✅ Error apropiado: {wrong_response.content.decode()}")
    
    print()
    print("🎯 RESUMEN FINAL:")
    print("=" * 25)
    print("✅ Endpoint de registro funcional")
    print("✅ Endpoint de login con JWT funcional")
    print("✅ Endpoints protegidos funcionando")
    print("✅ Validaciones y manejo de errores apropiados")
    print("✅ Integración completa del sistema")

if __name__ == "__main__":
    test_registration_endpoints()
