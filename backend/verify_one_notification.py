#!/usr/bin/env python3
"""
Script para verificar que una notificación llegue correctamente
"""

import requests
import time

def test_one_notification():
    print("🔔 VERIFICANDO UNA NOTIFICACIÓN")
    print("="*40)
    
    # URLs corregidas
    AUTH_URL = "http://127.0.0.1:8000/api/auth"
    API_URL = "http://127.0.0.1:8000/api"
    
    # 1. Login testuser1
    print("1. 🔐 Login testuser1...")
    try:
        response = requests.post(f"{AUTH_URL}/login/", json={
            'username': 'testuser1', 
            'password': 'test123'
        })
        if response.status_code == 200:
            token1 = response.json()['access']
            print("   ✅ testuser1 autenticado")
        else:
            print(f"   ❌ Error: {response.status_code}")
            return
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return
    
    # 2. Login testuser2  
    print("2. 🔐 Login testuser2...")
    try:
        response = requests.post(f"{AUTH_URL}/login/", json={
            'username': 'testuser2',
            'password': 'test123'
        })
        if response.status_code == 200:
            token2 = response.json()['access']
            print("   ✅ testuser2 autenticado")
        else:
            print(f"   ❌ Error: {response.status_code}")
            return
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return
    
    # 3. testuser1 se une a una comunidad
    print("3. 👥 testuser1 uniéndose a comunidad...")
    headers1 = {'Authorization': f'Bearer {token1}'}
    try:
        # Obtener primera comunidad
        response = requests.get(f"{API_URL}/communities/", headers=headers1)
        if response.status_code == 200:
            communities = response.json().get('results', [])
            if communities:
                community_id = communities[0]['id']
                print(f"   📍 Comunidad: {communities[0]['name']}")
                
                # Unirse a la comunidad
                response = requests.post(f"{API_URL}/communities/{community_id}/join/", headers=headers1)
                if response.status_code in [200, 201]:
                    print("   ✅ testuser1 unido a comunidad")
                elif 'already' in str(response.json()).lower():
                    print("   ✅ testuser1 ya era miembro")
                else:
                    print(f"   ❌ Error uniéndose: {response.status_code}")
                    return
            else:
                print("   ❌ No hay comunidades")
                return
        else:
            print(f"   ❌ Error obteniendo comunidades: {response.status_code}")
            return
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return
    
    # 4. testuser2 se une a la misma comunidad
    print("4. 👥 testuser2 uniéndose a comunidad...")
    headers2 = {'Authorization': f'Bearer {token2}'}
    try:
        response = requests.post(f"{API_URL}/communities/{community_id}/join/", headers=headers2)
        if response.status_code in [200, 201]:
            print("   ✅ testuser2 unido a comunidad")
        elif 'already' in str(response.json()).lower():
            print("   ✅ testuser2 ya era miembro")
        else:
            print(f"   ❌ Error: {response.status_code}")
            return
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return
    
    # 5. testuser1 crea un post
    print("5. 📝 testuser1 creando post...")
    try:
        post_data = {
            'content': f'Post de prueba notificaciones - {time.strftime("%H:%M:%S")}',
            'community': community_id
        }
        response = requests.post(f"{API_URL}/posts/", json=post_data, headers=headers1)
        if response.status_code == 201:
            post_id = response.json()['id']
            print(f"   ✅ Post creado: {post_id}")
        else:
            print(f"   ❌ Error creando post: {response.status_code}")
            return
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return
    
    # 6. testuser2 comenta (esto debe generar notificación para testuser1)
    print("6. 💬 testuser2 comentando...")
    try:
        comment_data = {
            'content': f'Comentario de prueba - {time.strftime("%H:%M:%S")}',
            'post': post_id
        }
        response = requests.post(f"{API_URL}/comments/", json=comment_data, headers=headers2)
        if response.status_code == 201:
            print("   ✅ Comentario creado")
        else:
            print(f"   ❌ Error comentando: {response.status_code}")
            print(f"   📄 Respuesta: {response.text}")
            return
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return
    
    # 7. Verificar notificaciones para testuser1
    print("7. 🔔 Verificando notificaciones...")
    time.sleep(2)  # Esperar procesamiento
    
    try:
        response = requests.get(f"{API_URL}/notifications/", headers=headers1)
        if response.status_code == 200:
            notifications = response.json().get('results', [])
            print(f"   📱 testuser1 tiene {len(notifications)} notificaciones")
            
            if notifications:
                latest = notifications[0]
                print(f"   📋 Última: {latest['notification_type']}")
                print(f"   📝 Mensaje: {latest['message']}")
                print(f"   📅 Tiempo: {latest['created_at']}")
                print("   ✅ ¡NOTIFICACIÓN FUNCIONANDO!")
                return True
            else:
                print("   📭 No hay notificaciones")
                return False
        else:
            print(f"   ❌ Error: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False

if __name__ == "__main__":
    success = test_one_notification()
    print("\n" + "="*40)
    if success:
        print("✅ ÉXITO: Las notificaciones están funcionando")
        print("📱 Ahora el icono en la app debería mostrar el badge")
    else:
        print("❌ PROBLEMA: Las notificaciones no llegaron")
        print("🔧 Revisar configuración del sistema")
