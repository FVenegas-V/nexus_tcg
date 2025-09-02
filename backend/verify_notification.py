import requests
import json
import time

def test_single_notification():
    print("🔔 VERIFICANDO QUE UNA NOTIFICACIÓN LLEGUE CORRECTAMENTE")
    print("=" * 60)
    
    # 1. Login testuser1
    print("1. Login testuser1...")
    response = requests.post("http://127.0.0.1:8000/api/auth/login/", json={
        "username": "testuser1",
        "password": "test123"
    })
    
    if response.status_code != 200:
        print(f"❌ Error en login testuser1: {response.status_code}")
        return False
    
    token1 = response.json()['access']
    print("✅ testuser1 autenticado")
    
    # 2. Login testuser2
    print("2. Login testuser2...")
    response = requests.post("http://127.0.0.1:8000/api/auth/login/", json={
        "username": "testuser2", 
        "password": "test123"
    })
    
    if response.status_code != 200:
        print(f"❌ Error en login testuser2: {response.status_code}")
        return False
    
    token2 = response.json()['access']
    print("✅ testuser2 autenticado")
    
    # 3. Obtener notificaciones ANTES (testuser1)
    print("3. Verificando notificaciones iniciales de testuser1...")
    headers1 = {'Authorization': f'Bearer {token1}'}
    response = requests.get("http://127.0.0.1:8000/api/notifications/", headers=headers1)
    
    if response.status_code != 200:
        print(f"❌ Error obteniendo notificaciones: {response.status_code}")
        return False
    
    initial_count = len(response.json().get('results', []))
    print(f"✅ Notificaciones iniciales: {initial_count}")
    
    # 4. Obtener una comunidad
    print("4. Obteniendo comunidades...")
    response = requests.get("http://127.0.0.1:8000/api/communities/", headers=headers1)
    
    if response.status_code != 200:
        print(f"❌ Error obteniendo comunidades: {response.status_code}")
        return False
    
    communities = response.json().get('results', [])
    if not communities:
        print("❌ No hay comunidades disponibles")
        return False
    
    community_id = communities[0]['id']
    print(f"✅ Usando comunidad ID: {community_id}")
    
    # 5. testuser2 se une a la comunidad
    print("5. testuser2 uniéndose a la comunidad...")
    headers2 = {'Authorization': f'Bearer {token2}'}
    response = requests.post(f"http://127.0.0.1:8000/api/communities/{community_id}/join/", 
                           headers=headers2)
    
    if response.status_code in [200, 201]:
        print("✅ testuser2 se unió a la comunidad")
    elif response.status_code == 400 and 'already a member' in response.text:
        print("✅ testuser2 ya era miembro de la comunidad")
    else:
        print(f"❌ Error uniéndose a comunidad: {response.status_code}")
        return False
    
    # 6. testuser1 crea un post
    print("6. testuser1 creando post...")
    post_data = {
        'content': f'Post de prueba para notificaciones - {int(time.time())}',
        'community': community_id
    }
    response = requests.post("http://127.0.0.1:8000/api/posts/", 
                           json=post_data, headers=headers1)
    
    if response.status_code != 201:
        print(f"❌ Error creando post: {response.status_code}")
        print(f"Response: {response.text}")
        return False
    
    post_id = response.json()['id']
    print(f"✅ Post creado con ID: {post_id}")
    
    # 7. testuser2 comenta el post (esto debe generar notificación para testuser1)
    print("7. testuser2 comentando post...")
    headers2 = {'Authorization': f'Bearer {token2}'}
    comment_data = {
        'content': f'Comentario de prueba - {int(time.time())}',
        'post': post_id
    }
    response = requests.post("http://127.0.0.1:8000/api/comments/", 
                           json=comment_data, headers=headers2)
    
    if response.status_code != 201:
        print(f"❌ Error añadiendo comentario: {response.status_code}")
        print(f"Response: {response.text}")
        return False
    
    print("✅ Comentario añadido")
    
    # 8. Esperar un momento y verificar nueva notificación
    print("8. Esperando 2 segundos y verificando nueva notificación...")
    time.sleep(2)
    
    response = requests.get("http://127.0.0.1:8000/api/notifications/", headers=headers1)
    
    if response.status_code != 200:
        print(f"❌ Error obteniendo notificaciones finales: {response.status_code}")
        return False
    
    final_notifications = response.json().get('results', [])
    final_count = len(final_notifications)
    
    print(f"✅ Notificaciones finales: {final_count}")
    
    # 9. Verificar que llegó la notificación
    if final_count > initial_count:
        print("🎉 ¡NOTIFICACIÓN RECIBIDA CORRECTAMENTE!")
        new_notifications = final_notifications[:final_count - initial_count]
        for notif in new_notifications:
            print(f"   📔 Tipo: {notif['notification_type']}")
            print(f"   📝 Mensaje: {notif['message']}")
            print(f"   📅 Fecha: {notif['created_at']}")
            print(f"   📖 Leída: {'Sí' if notif['read'] else 'No'}")
        return True
    else:
        print("❌ NO SE RECIBIÓ NINGUNA NOTIFICACIÓN NUEVA")
        return False

if __name__ == "__main__":
    success = test_single_notification()
    if success:
        print("\n✅ PRUEBA EXITOSA: El sistema de notificaciones funciona correctamente")
    else:
        print("\n❌ PRUEBA FALLIDA: Hay problemas con el sistema de notificaciones")
