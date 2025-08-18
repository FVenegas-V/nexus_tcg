import requests

print("🚀 TESTING FINAL DEL SISTEMA")
print("=" * 30)

# Test de autenticación
r = requests.post('http://localhost:8000/api/auth/login/', json={'username': 'gamer1', 'password': 'gamer123'})
if r.status_code == 200:
    print("✅ Autenticación: OK")
    token = r.json()['access']
    
    # Test de Posts API
    r2 = requests.get('http://localhost:8000/api/posts/', headers={'Authorization': f'Bearer {token}'})
    print(f"Posts API Status: {r2.status_code}")
    if r2.status_code == 200:
        count = r2.json().get('count', 0)
        print(f"✅ Posts API: {count} posts disponibles")
        
        # Test de creación de post
        r3 = requests.post('http://localhost:8000/api/posts/', 
                          json={'title': 'Test Final', 'content': 'Post de prueba final', 'community': 1},
                          headers={'Authorization': f'Bearer {token}'})
        print(f"Create Post Status: {r3.status_code}")
        if r3.status_code == 201:
            new_id = r3.json().get('id')
            print(f"✅ Crear Post: Post #{new_id} creado")
            
            # Test de feed
            r4 = requests.get('http://localhost:8000/api/posts/feed/', headers={'Authorization': f'Bearer {token}'})
            print(f"Feed Status: {r4.status_code}")
            if r4.status_code == 200:
                feed_count = r4.json().get('count', 0)
                print(f"✅ Feed: {feed_count} posts en feed")
            else:
                print(f"❌ Feed Error: {r4.text}")
        else:
            print(f"❌ Crear Post Error: {r3.text}")
    else:
        print(f"❌ Posts API Error: {r2.text}")
else:
    print("❌ Autenticación: Error")

print("\n🎉 TESTING COMPLETADO")
