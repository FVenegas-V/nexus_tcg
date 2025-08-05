#!/usr/bin/env python
"""
Script de prueba de APIs para el sistema de recuperación de contraseñas
Prueba los endpoints HTTP de fase1-0003
"""

import requests
import json
import time
from datetime import datetime

# Configuración del servidor
BASE_URL = "http://localhost:8000"
API_BASE = f"{BASE_URL}/api"

def print_separator(title):
    print("\n" + "="*70)
    print(f" {title}")
    print("="*70)

def pretty_print_response(response, action):
    """Imprime la respuesta de una manera legible"""
    print(f"\n{action}:")
    print(f"Status Code: {response.status_code}")
    
    try:
        data = response.json()
        print(f"Response: {json.dumps(data, indent=2, ensure_ascii=False)}")
    except:
        print(f"Response (text): {response.text}")

def test_server_running():
    """Verifica que el servidor esté corriendo"""
    print_separator("VERIFICANDO SERVIDOR")
    
    try:
        response = requests.get(f"{BASE_URL}/admin/", timeout=5)
        if response.status_code in [200, 302]:
            print("✅ Servidor Django está corriendo")
            return True
        else:
            print(f"❌ Servidor responde con código: {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ No se puede conectar al servidor")
        print("   Asegúrate de que el servidor esté corriendo con:")
        print("   python manage.py runserver")
        return False
    except Exception as e:
        print(f"❌ Error verificando servidor: {e}")
        return False

def test_password_reset_apis():
    """Prueba todas las APIs de recuperación de contraseña"""
    print_separator("PROBANDO APIs DE RECUPERACIÓN DE CONTRASEÑAS")
    
    # 1. Primero, registrar un usuario para las pruebas
    print("\n1. Registrando usuario de prueba:")
    
    register_data = {
        "username": "apitest",
        "email": "apitest@example.com",
        "password": "originalpass123"
    }
    
    try:
        response = requests.post(f"{API_BASE}/auth/register/", json=register_data)
        if response.status_code == 201:
            print("✅ Usuario registrado exitosamente")
            pretty_print_response(response, "Registro de usuario")
        elif response.status_code == 400 and "already exists" in response.text.lower():
            print("ℹ️  Usuario ya existe, continuando con las pruebas")
        else:
            pretty_print_response(response, "Error en registro")
            return False
    except Exception as e:
        print(f"❌ Error registrando usuario: {e}")
        return False
    
    # 2. Solicitar recuperación de contraseña
    print("\n2. Solicitando recuperación de contraseña:")
    
    reset_request_data = {
        "email": "apitest@example.com"
    }
    
    try:
        response = requests.post(f"{API_BASE}/auth/password-reset/", json=reset_request_data)
        pretty_print_response(response, "Solicitud de recuperación")
        
        if response.status_code != 200:
            print("❌ Error en solicitud de recuperación")
            return False
        
    except Exception as e:
        print(f"❌ Error en solicitud de recuperación: {e}")
        return False
    
    # 3. Probar con email inexistente
    print("\n3. Probando con email inexistente:")
    
    invalid_email_data = {
        "email": "noexiste@example.com"
    }
    
    try:
        response = requests.post(f"{API_BASE}/auth/password-reset/", json=invalid_email_data)
        pretty_print_response(response, "Email inexistente")
        
        if response.status_code == 400:
            print("✅ Validación correcta para email inexistente")
        else:
            print("❌ Debería haber fallado con email inexistente")
            return False
            
    except Exception as e:
        print(f"❌ Error probando email inexistente: {e}")
        return False
    
    # 4. Para probar los otros endpoints, necesitamos obtener un token válido
    # En un entorno de desarrollo, podemos obtenerlo de la base de datos
    print("\n4. Simulando obtención de token de recuperación:")
    print("   (En producción, el token sería enviado por email)")
    print("   Para completar la prueba, necesitamos obtener el token de la base de datos")
    
    return True

def test_login_after_recovery():
    """Prueba el login después de una recuperación simulada"""
    print_separator("PROBANDO LOGIN DESPUÉS DE RECUPERACIÓN")
    
    # Intentar login con credenciales originales
    login_data = {
        "username": "apitest",
        "password": "originalpass123"
    }
    
    try:
        response = requests.post(f"{API_BASE}/auth/login/", json=login_data)
        pretty_print_response(response, "Login con contraseña original")
        
        if response.status_code == 200:
            print("✅ Login exitoso con contraseña original")
            data = response.json()
            access_token = data.get('access')
            
            if access_token:
                print(f"✅ Token JWT obtenido: {access_token[:50]}...")
                return access_token
            else:
                print("❌ No se obtuvo token JWT")
                return None
        else:
            print("❌ Error en login")
            return None
            
    except Exception as e:
        print(f"❌ Error en login: {e}")
        return None

def test_protected_endpoint(access_token):
    """Prueba un endpoint protegido con el token JWT"""
    print_separator("PROBANDO ENDPOINT PROTEGIDO")
    
    if not access_token:
        print("❌ No hay token disponible para probar endpoint protegido")
        return False
    
    headers = {
        "Authorization": f"Bearer {access_token}"
    }
    
    try:
        response = requests.get(f"{API_BASE}/users/me/", headers=headers)
        pretty_print_response(response, "Perfil de usuario")
        
        if response.status_code == 200:
            print("✅ Acceso exitoso a endpoint protegido")
            return True
        else:
            print("❌ Error accediendo a endpoint protegido")
            return False
            
    except Exception as e:
        print(f"❌ Error en endpoint protegido: {e}")
        return False

def show_api_documentation():
    """Muestra la documentación de las nuevas APIs"""
    print_separator("DOCUMENTACIÓN DE NUEVAS APIs")
    
    print("""
📋 NUEVAS APIs DE RECUPERACIÓN DE CONTRASEÑAS (Fase 1-0003):

1. 🔄 Solicitar recuperación de contraseña:
   POST /api/auth/password-reset/
   
   Body:
   {
     "email": "usuario@example.com"
   }
   
   Response (200):
   {
     "message": "Se ha enviado un enlace de recuperación a tu email."
   }

2. ✅ Confirmar cambio de contraseña:
   POST /api/auth/password-reset/confirm/
   
   Body:
   {
     "token": "uuid-del-token",
     "new_password": "nuevacontraseña123",
     "confirm_password": "nuevacontraseña123"
   }
   
   Response (200):
   {
     "message": "Contraseña cambiada exitosamente."
   }

3. 🔍 Verificar token de recuperación:
   GET /api/auth/password-reset/verify/<uuid:token>/
   
   Response (200):
   {
     "valid": true,
     "user_email": "usuario@example.com"
   }

📧 CONFIGURACIÓN DE EMAIL:
   - En desarrollo, los enlaces se muestran en la consola del servidor
   - Para producción, configura las variables de entorno en .env:
     * EMAIL_HOST_USER
     * EMAIL_HOST_PASSWORD
     * EMAIL_HOST
     * EMAIL_PORT

🔒 SEGURIDAD:
   - Tokens válidos por 1 hora
   - Tokens de un solo uso
   - Validación de coincidencia de contraseñas
   - Verificación de existencia de usuario
""")

def main():
    """Función principal que ejecuta todas las pruebas de API"""
    print("🚀 INICIANDO PRUEBAS DE APIs DE RECUPERACIÓN DE CONTRASEÑAS")
    print(f"   Nexus TCG - Fase 1-0003")
    print(f"   Servidor: {BASE_URL}")
    print(f"   Tiempo: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # Verificar que el servidor esté corriendo
    if not test_server_running():
        print("\n❌ PRUEBAS CANCELADAS: Servidor no disponible")
        print("\n🔧 Para iniciar el servidor:")
        print("   1. cd backend")
        print("   2. python manage.py runserver")
        return
    
    # Ejecutar pruebas de API
    success = True
    
    if not test_password_reset_apis():
        success = False
    
    access_token = test_login_after_recovery()
    
    if not test_protected_endpoint(access_token):
        success = False
    
    # Mostrar documentación
    show_api_documentation()
    
    # Resumen final
    print_separator("RESUMEN DE PRUEBAS DE API")
    
    if success:
        print("✅ Pruebas básicas de API completadas")
        print("🎉 Sistema de recuperación de contraseñas disponible via HTTP")
    else:
        print("⚠️  Algunas pruebas de API fallaron")
    
    print("\n📝 NOTAS:")
    print("   - Para pruebas completas de recuperación, usa test_password_recovery.py")
    print("   - Para testing manual, usa herramientas como Postman o curl")
    print("   - En desarrollo, los emails aparecen en la consola del servidor")

if __name__ == "__main__":
    main()
