#!/usr/bin/env python3
"""
Test para verificar el endpoint unread específicamente para la notificación 65
"""

import requests
import json

# Token del testuser1
token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzU2ODM0MTA0LCJpYXQiOjE3NTY4MzA1MDQsImp0aSI6ImRiMTAwOTUxMjlmZjQyMjc5MGExYWVjNTU1MDc2M2FkIiwidXNlcl9pZCI6MTF9.0yF0SIMSuJdqlAHF2I8w8Wj3e9HtcdIKlkg9IzuFa6Q"

headers = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json"
}

print("🔔 Probando endpoint unread en localhost...")
try:
    response = requests.get("http://localhost:8000/api/notifications/unread/", headers=headers, timeout=5)
    print(f"Status: {response.status_code}")
except requests.exceptions.Timeout:
    print("❌ TIMEOUT - El servidor no respondió en 5 segundos")
    print("🔄 Intentando con 10.0.2.2...")
    try:
        response = requests.get("http://10.0.2.2:8000/api/notifications/unread/", headers=headers, timeout=5)
        print(f"Status con 10.0.2.2: {response.status_code}")
    except Exception as e2:
        print(f"❌ También falló con 10.0.2.2: {e2}")
        exit(1)
except requests.exceptions.ConnectionError:
    print("❌ CONNECTION ERROR con localhost - Probando 10.0.2.2...")
    try:
        response = requests.get("http://10.0.2.2:8000/api/notifications/unread/", headers=headers, timeout=5)
        print(f"Status con 10.0.2.2: {response.status_code}")
    except Exception as e2:
        print(f"❌ También falló con 10.0.2.2: {e2}")
        exit(1)

if response.status_code == 200:
    data = response.json()
    print(f"Número de notificaciones: {len(data.get('latest', []))}")
    
    # Buscar específicamente la notificación 65
    latest = data.get('latest', [])
    for notification in latest:
        if notification.get('id') == 65:
            print(f"\n🎯 Notificación 65 encontrada:")
            print(json.dumps(notification, indent=2, ensure_ascii=False))
            break
    else:
        print("\n❌ Notificación 65 no encontrada")
        
    # Mostrar las primeras 3 notificaciones para comparar
    print(f"\n📋 Primeras 3 notificaciones:")
    for i, notification in enumerate(latest[:3]):
        print(f"\nNotificación {i+1}:")
        print(f"  ID: {notification.get('id')}")
        print(f"  Título: {notification.get('title')}")
        print(f"  Tiene related_object_url: {'related_object_url' in notification}")
        if 'related_object_url' in notification:
            print(f"  URL: {notification.get('related_object_url')}")
else:
    print(f"Error: {response.text}")
