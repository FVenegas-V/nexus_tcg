#!/usr/bin/env python
"""
Script de demostración del sistema de recuperación de contraseñas
Inicia el servidor y ejecuta pruebas en vivo
"""

import subprocess
import sys
import time
import threading
import os
import signal
import requests
import json

# Configuración
SERVER_URL = "http://localhost:8000"
MANAGE_PY_PATH = r"C:\Users\Pipe\Proyectos\nexus_tcg\backend\manage.py"
PYTHON_EXE = r"C:/Users/Pipe/Proyectos/nexus_tcg/venv/Scripts/python.exe"

def print_banner():
    """Imprime el banner de demostración"""
    print("="*80)
    print("🚀 DEMOSTRACIÓN DEL SISTEMA DE RECUPERACIÓN DE CONTRASEÑAS")
    print("   Nexus TCG - Fase 1-0003")
    print("="*80)

def start_server():
    """Inicia el servidor Django en un hilo separado"""
    print("\n🔧 Iniciando servidor Django...")
    
    # Cambiar al directorio del backend
    backend_dir = os.path.dirname(MANAGE_PY_PATH)
    
    try:
        # Ejecutar el servidor
        process = subprocess.Popen(
            [PYTHON_EXE, "manage.py", "runserver", "8000"],
            cwd=backend_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        print(f"✅ Servidor iniciado (PID: {process.pid})")
        print(f"🌐 Disponible en: {SERVER_URL}")
        
        return process
        
    except Exception as e:
        print(f"❌ Error iniciando servidor: {e}")
        return None

def wait_for_server(max_attempts=30):
    """Espera a que el servidor esté disponible"""
    print("\n⏳ Esperando a que el servidor esté listo...")
    
    for attempt in range(max_attempts):
        try:
            response = requests.get(f"{SERVER_URL}/admin/", timeout=2)
            if response.status_code in [200, 302]:
                print("✅ Servidor listo!")
                return True
        except:
            pass
        
        print(f"   Intento {attempt + 1}/{max_attempts}...")
        time.sleep(1)
    
    print("❌ Servidor no respondió a tiempo")
    return False

def demo_registration():
    """Demuestra el registro de usuario"""
    print("\n" + "="*50)
    print("📝 DEMOSTRACIÓN: REGISTRO DE USUARIO")
    print("="*50)
    
    user_data = {
        "username": "demo_user",
        "email": "demo@nexustcg.com",
        "password": "demopass123"
    }
    
    try:
        response = requests.post(f"{SERVER_URL}/api/auth/register/", json=user_data)
        
        print(f"📤 Enviando registro:")
        print(f"   Username: {user_data['username']}")
        print(f"   Email: {user_data['email']}")
        print(f"   Password: {user_data['password']}")
        
        print(f"\n📥 Respuesta del servidor:")
        print(f"   Status: {response.status_code}")
        
        if response.status_code == 201:
            data = response.json()
            print(f"   ✅ Usuario registrado exitosamente")
            print(f"   📧 Email: {data.get('email')}")
            print(f"   👤 Username: {data.get('username')}")
            return True
        elif response.status_code == 400 and "already" in response.text.lower():
            print(f"   ℹ️  Usuario ya existe, continuando...")
            return True
        else:
            print(f"   ❌ Error: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error en registro: {e}")
        return False

def demo_password_reset_request():
    """Demuestra la solicitud de recuperación de contraseña"""
    print("\n" + "="*50)
    print("🔄 DEMOSTRACIÓN: SOLICITUD DE RECUPERACIÓN")
    print("="*50)
    
    reset_data = {
        "email": "demo@nexustcg.com"
    }
    
    try:
        response = requests.post(f"{SERVER_URL}/api/auth/password-reset/", json=reset_data)
        
        print(f"📤 Enviando solicitud de recuperación:")
        print(f"   Email: {reset_data['email']}")
        
        print(f"\n📥 Respuesta del servidor:")
        print(f"   Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Solicitud exitosa")
            print(f"   💌 Mensaje: {data.get('message')}")
            print(f"\n📧 NOTA: En desarrollo, el enlace aparece en la consola del servidor")
            return True
        else:
            print(f"   ❌ Error: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error en solicitud: {e}")
        return False

def demo_login():
    """Demuestra el login del usuario"""
    print("\n" + "="*50)
    print("🔐 DEMOSTRACIÓN: LOGIN DE USUARIO")
    print("="*50)
    
    login_data = {
        "username": "demo_user",
        "password": "demopass123"
    }
    
    try:
        response = requests.post(f"{SERVER_URL}/api/auth/login/", json=login_data)
        
        print(f"📤 Enviando login:")
        print(f"   Username: {login_data['username']}")
        print(f"   Password: {login_data['password']}")
        
        print(f"\n📥 Respuesta del servidor:")
        print(f"   Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Login exitoso")
            print(f"   🎫 Access Token: {data.get('access', 'N/A')[:50]}...")
            print(f"   🔄 Refresh Token: {data.get('refresh', 'N/A')[:50]}...")
            return data.get('access')
        else:
            print(f"   ❌ Error: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error en login: {e}")
        return None

def demo_profile_access(access_token):
    """Demuestra el acceso al perfil protegido"""
    if not access_token:
        print("\n❌ No hay token disponible para acceso al perfil")
        return
    
    print("\n" + "="*50)
    print("👤 DEMOSTRACIÓN: ACCESO A PERFIL PROTEGIDO")
    print("="*50)
    
    headers = {
        "Authorization": f"Bearer {access_token}"
    }
    
    try:
        response = requests.get(f"{SERVER_URL}/api/users/me/", headers=headers)
        
        print(f"📤 Enviando solicitud de perfil:")
        print(f"   Token: {access_token[:30]}...")
        
        print(f"\n📥 Respuesta del servidor:")
        print(f"   Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Acceso exitoso al perfil")
            print(f"   📧 Email: {data.get('email')}")
            print(f"   👤 Username: {data.get('username')}")
            print(f"   🆔 ID: {data.get('id')}")
            print(f"   📅 Fecha de registro: {data.get('date_joined', 'N/A')[:10]}")
        else:
            print(f"   ❌ Error: {response.text}")
            
    except Exception as e:
        print(f"❌ Error accediendo al perfil: {e}")

def show_api_summary():
    """Muestra un resumen de las APIs disponibles"""
    print("\n" + "="*60)
    print("📋 RESUMEN DE APIs IMPLEMENTADAS")
    print("="*60)
    
    apis = [
        ("POST", "/api/auth/register/", "Registrar nuevo usuario"),
        ("POST", "/api/auth/login/", "Iniciar sesión y obtener JWT"),
        ("POST", "/api/auth/refresh/", "Renovar token JWT"),
        ("GET", "/api/users/me/", "Obtener perfil del usuario autenticado"),
        ("POST", "/api/auth/password-reset/", "🆕 Solicitar recuperación de contraseña"),
        ("POST", "/api/auth/password-reset/confirm/", "🆕 Confirmar cambio de contraseña"),
        ("GET", "/api/auth/password-reset/verify/<token>/", "🆕 Verificar token de recuperación"),
    ]
    
    for method, endpoint, description in apis:
        status = "🆕" if "password-reset" in endpoint else "✅"
        print(f"   {status} {method:4} {endpoint:40} - {description}")
    
    print(f"\n🎯 Total de endpoints: {len(apis)}")
    print(f"🆕 Nuevos en esta fase: 3")

def show_next_steps():
    """Muestra los próximos pasos sugeridos"""
    print("\n" + "="*60)
    print("🔮 PRÓXIMOS PASOS SUGERIDOS")
    print("="*60)
    
    steps = [
        "1. 🎨 Implementar UI de recuperación en Flutter",
        "2. 📧 Configurar SMTP real para producción",
        "3. 🔒 Implementar rate limiting",
        "4. 📊 Agregar logging y monitoreo",
        "5. ✅ Continuar con fase1-0004 (Verificación de email)",
        "6. 🚀 Preparar para despliegue en producción"
    ]
    
    for step in steps:
        print(f"   {step}")

def main():
    """Función principal de demostración"""
    print_banner()
    
    # Iniciar servidor
    server_process = start_server()
    if not server_process:
        return
    
    try:
        # Esperar a que el servidor esté listo
        if not wait_for_server():
            return
        
        # Ejecutar demostraciones
        print("\n🎬 Iniciando demostraciones...")
        
        # 1. Registro
        if not demo_registration():
            print("❌ Demo cancelado: Error en registro")
            return
        
        # 2. Solicitud de recuperación
        if not demo_password_reset_request():
            print("❌ Demo cancelado: Error en recuperación")
            return
        
        # 3. Login
        access_token = demo_login()
        
        # 4. Acceso a perfil protegido
        demo_profile_access(access_token)
        
        # 5. Mostrar resumen
        show_api_summary()
        show_next_steps()
        
        print("\n🎉 DEMOSTRACIÓN COMPLETADA EXITOSAMENTE")
        print("✅ Sistema de recuperación de contraseñas implementado y funcionando")
        
        # Mantener servidor corriendo
        print(f"\n🔧 Servidor manteniéndose activo en {SERVER_URL}")
        print("   Presiona Ctrl+C para detener...")
        
        # Esperar hasta que el usuario presione Ctrl+C
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            print("\n👋 Deteniendo servidor...")
        
    finally:
        # Terminar servidor
        if server_process:
            server_process.terminate()
            try:
                server_process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                server_process.kill()
            print("✅ Servidor detenido")

if __name__ == "__main__":
    main()
