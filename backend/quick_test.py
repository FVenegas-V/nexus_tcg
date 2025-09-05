import requests
import json

print("🔔 PRUEBA RÁPIDA DE NOTIFICACIONES")
print("=" * 40)

# Login testuser1
response = requests.post("http://127.0.0.1:8000/api/auth/login/", 
                        json={"username": "testuser1", "password": "test123"})
if response.status_code == 200:
    token1 = response.json()['access']
    print("✅ testuser1 autenticado")
    
    # Verificar notificaciones
    headers = {'Authorization': f'Bearer {token1}'}
    response = requests.get("http://127.0.0.1:8000/api/notifications/", headers=headers)
    if response.status_code == 200:
        notifications = response.json().get('results', [])
        print(f"✅ {len(notifications)} notificaciones encontradas para testuser1")
        for i, notif in enumerate(notifications[:3], 1):
            print(f"   {i}. {notif['notification_type']}: {notif['message'][:40]}...")
    else:
        print(f"❌ Error obteniendo notificaciones: {response.status_code}")
else:
    print("❌ Error en login testuser1")

print("\n📱 LISTOS PARA EMULADORES:")
print("1. Login testuser1 en emulador 1")
print("2. Login testuser2 en emulador 2") 
print("3. Interactúa en emulador 2")
print("4. Verifica notificaciones en emulador 1")
