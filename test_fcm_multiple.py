#!/usr/bin/env python3
"""
Script para probar FCM con múltiples emuladores
"""

import requests
import json

# Configuración
BASE_URL = "http://localhost:8000"
AUTH_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzU3MDQ5NTU0LCJpYXQiOjE3NTcwNDU5NTQsImp0aSI6IjAwNDIwMjFmZDJjNjQ0YjJhNGZlYWQ0NTQwNWE4ODFhIiwidXNlcl9pZCI6MTEwfQ.vlPeXniAWNlye_ViJdIbfMI82lYTCEKTrxwGuiBxMgs"

# Headers
headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {AUTH_TOKEN}"
}

def test_fcm_single():
    """Probar FCM con token único (emulador principal)"""
    print("🧪 Probando FCM - Token único...")
    
    data = {
        "title": "Test FCM - Emulador 1",
        "body": "Esta notificación va al emulador principal",
        "send_to_all": False
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/notifications/test-fcm/",
            headers=headers,
            json=data
        )
        
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.status_code == 200
        
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_fcm_multiple():
    """Probar FCM con múltiples tokens"""
    print("\n🧪 Probando FCM - Múltiples emuladores...")
    
    data = {
        "title": "Test FCM - Ambos Emuladores",
        "body": "Esta notificación debería llegar a AMBOS emuladores!",
        "send_to_all": True
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/notifications/test-fcm/",
            headers=headers,
            json=data
        )
        
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.status_code == 200
        
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_fcm_specific_token():
    """Probar FCM con token específico (emulador 2)"""
    print("\n🧪 Probando FCM - Token específico (Emulador 2)...")
    
    # Token del emulador 2
    emulator2_token = "eQOqyKy2TQuTmfk8kTpUOC:APA91bFPXB13tBcbkG63mgzKYjcQPc3SOV1xinttTtKM4cTn0KoT-g9fNUsuCJFpM7dVXfQMYzYf8eejcZfrgf6eajnzobeU_e1h5d2xysoscFw0kZCZhgE"
    
    data = {
        "title": "Test FCM - Solo Emulador 2",
        "body": "Esta notificación va SOLO al emulador 2",
        "token": emulator2_token
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/notifications/test-fcm/",
            headers=headers,
            json=data
        )
        
        print(f"Status: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.status_code == 200
        
    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    print("🚀 Iniciando pruebas FCM...\n")
    
    # Ejecutar todas las pruebas
    test1 = test_fcm_single()
    test2 = test_fcm_multiple()  
    test3 = test_fcm_specific_token()
    
    print(f"\n📊 Resultados:")
    print(f"✅ Test 1 (Emulador principal): {'PASÓ' if test1 else 'FALLÓ'}")
    print(f"✅ Test 2 (Ambos emuladores): {'PASÓ' if test2 else 'FALLÓ'}")
    print(f"✅ Test 3 (Emulador específico): {'PASÓ' if test3 else 'FALLÓ'}")
    
    if all([test1, test2, test3]):
        print("\n🎉 ¡Todas las pruebas FCM pasaron exitosamente!")
    else:
        print("\n❌ Algunas pruebas fallaron. Revisa los logs del backend.")
