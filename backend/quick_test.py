import requests
import json

print("🔥 TEST RÁPIDO DE API")

# Test básico de autenticación
try:
    response = requests.post(
        'http://localhost:8000/api/auth/login/',
        json={'username': 'gamer1', 'password': 'gamer123'},
        timeout=10
    )
    print(f"Auth status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        token = data.get('access')
        print("✅ Autenticación exitosa")
        
        # Test de posts
        headers = {'Authorization': f'Bearer {token}'}
        posts_response = requests.get('http://localhost:8000/api/posts/', headers=headers, timeout=10)
        print(f"Posts status: {posts_response.status_code}")
        
        if posts_response.status_code == 200:
            posts_data = posts_response.json()
            print(f"✅ Posts API funcionando - {posts_data.get('count', 0)} posts")
        else:
            print(f"❌ Error en Posts API: {posts_response.text[:100]}")
    else:
        print(f"❌ Error de autenticación: {response.text[:100]}")
        
except Exception as e:
    print(f"❌ Error de conexión: {e}")

print("🎯 Test completado")
