#!/usr/bin/env python3
"""
Script simple para probar notificaciones entre testuser1 y testuser2
"""
import requests
import json
import time

BASE_URL = "http://localhost:8000"

def login_user(username, password):
    """Login y obtener token"""
    response = requests.post(
        f"{BASE_URL}/api/auth/login/",
        json={"username": username, "password": password}
    )
    if response.status_code == 200:
        return response.json()["access"]
    else:
        print(f"❌ Error login {username}: {response.status_code}")
        print(response.text)
        return None

def get_notifications(token):
    """Obtener notificaciones del usuario"""
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(f"{BASE_URL}/api/notifications/", headers=headers)
    if response.status_code == 200:
        return response.json()
    else:
        print(f"❌ Error obteniendo notificaciones: {response.status_code}")
        return None

def create_test_post(token, community_id=3):
    """Crear un post de prueba"""
    headers = {"Authorization": f"Bearer {token}"}
    data = {
        "content": f"🧪 Post de prueba para notificaciones - {int(time.time())}",
        "community": community_id
    }
    response = requests.post(f"{BASE_URL}/api/posts/", json=data, headers=headers)
    if response.status_code == 201:
        return response.json()
    else:
        print(f"❌ Error creando post: {response.status_code}")
        print(response.text)
        return None

def add_comment(token, post_id, content):
    """Agregar comentario a un post"""
    headers = {"Authorization": f"Bearer {token}"}
    data = {"content": content}
    response = requests.post(f"{BASE_URL}/api/posts/{post_id}/comments/", json=data, headers=headers)
    if response.status_code == 201:
        return response.json()
    else:
        print(f"❌ Error agregando comentario: {response.status_code}")
        print(response.text)
        return None

def main():
    print("🔔 PRUEBA SIMPLE DE NOTIFICACIONES")
    print("=" * 40)
    
    # 1. Login usuarios
    print("1. 🔐 Login usuarios...")
    token1 = login_user("testuser1", "test123")
    token2 = login_user("testuser2", "test123")
    
    if not token1 or not token2:
        print("❌ Error en autenticación")
        return
    
    print("   ✅ Ambos usuarios autenticados")
    
    # 2. Verificar notificaciones iniciales
    print("\n2. 📊 Notificaciones iniciales...")
    notifs_inicial_user2 = get_notifications(token2)
    if notifs_inicial_user2:
        count_inicial = notifs_inicial_user2.get('count', 0)
        print(f"   📈 testuser2 tiene {count_inicial} notificaciones")
    
    # 3. testuser1 crea un post
    print("\n3. 📝 testuser1 creando post...")
    post = create_test_post(token1)
    if not post:
        print("❌ No se pudo crear el post")
        return
    
    print(f"   ✅ Post creado con ID: {post['id']}")
    
    # 4. testuser2 comenta el post
    print("\n4. 💬 testuser2 comentando post...")
    comment = add_comment(token2, post['id'], "¡Excelente post! 🎉")
    if comment:
        print(f"   ✅ Comentario agregado con ID: {comment['id']}")
    
    # 5. Esperar un momento para que se procesen las notificaciones
    print("\n5. ⏳ Esperando procesamiento...")
    time.sleep(2)
    
    # 6. Verificar notificaciones de testuser1
    print("\n6. 🔔 Verificando notificaciones de testuser1...")
    notifs_final = get_notifications(token1)
    if notifs_final:
        count_final = notifs_final.get('count', 0)
        print(f"   📈 testuser1 tiene {count_final} notificaciones")
        
        if count_final > 0:
            print("   🎉 ¡HAY NOTIFICACIONES!")
            for notif in notifs_final.get('results', [])[:3]:  # Mostrar solo las primeras 3
                print(f"     • {notif.get('type', 'unknown')}: {notif.get('message', 'Sin mensaje')}")
                print(f"       Leída: {notif.get('is_read', False)}, Tiempo: {notif.get('created_at', 'N/A')}")
            return True
        else:
            print("   ❌ No hay notificaciones nuevas")
    
    print("\n" + "=" * 40)
    print("❌ RESULTADO: No se generaron notificaciones")
    return False

if __name__ == "__main__":
    main()
