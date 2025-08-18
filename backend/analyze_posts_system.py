"""
Script para verificar estadísticas y estado general del sistema de Posts.
"""
import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8000"
API_URL = f"{BASE_URL}/api"

def get_auth_token():
    """Obtener token de autenticación."""
    login_data = {'username': 'gamer1', 'password': 'gamer123'}
    response = requests.post(f"{API_URL}/auth/login/", json=login_data)
    
    if response.status_code == 200:
        return response.json().get('access')
    return None

def get_system_stats():
    """Obtener estadísticas del sistema."""
    print("📊 ESTADÍSTICAS DEL SISTEMA DE POSTS")
    print("=" * 50)
    
    token = get_auth_token()
    if not token:
        print("❌ No se pudo autenticar")
        return
    
    headers = {'Authorization': f'Bearer {token}'}
    
    # 1. Estadísticas generales de posts
    print("\n📝 POSTS:")
    response = requests.get(f"{API_URL}/posts/", headers=headers)
    if response.status_code == 200:
        data = response.json()
        total_posts = data.get('count', 0)
        print(f"   📊 Total de posts: {total_posts}")
        
        # Analizar posts por autor
        posts = data.get('results', [])
        authors = {}
        communities = {}
        
        for post in posts:
            author = post.get('author', {}).get('username', 'Desconocido')
            community_name = post.get('community', {}).get('name', 'Sin comunidad')
            
            authors[author] = authors.get(author, 0) + 1
            communities[community_name] = communities.get(community_name, 0) + 1
        
        print(f"   👥 Autores únicos: {len(authors)}")
        print(f"   🏘️ Comunidades con posts: {len(communities)}")
        
        # Top autores
        if authors:
            top_author = max(authors.items(), key=lambda x: x[1])
            print(f"   🏆 Autor más activo: {top_author[0]} ({top_author[1]} posts)")
    
    # 2. Estadísticas de mi feed
    print("\n🏠 MI FEED:")
    response = requests.get(f"{API_URL}/posts/feed/", headers=headers)
    if response.status_code == 200:
        data = response.json()
        feed_count = data.get('count', 0)
        print(f"   📊 Posts en mi feed: {feed_count}")
    
    # 3. Mis posts
    print("\n👤 MIS POSTS:")
    response = requests.get(f"{API_URL}/posts/my_posts/", headers=headers)
    if response.status_code == 200:
        data = response.json()
        my_posts_count = data.get('count', 0)
        print(f"   📊 Mis posts: {my_posts_count}")
    
    # 4. Test de búsquedas populares
    print("\n🔍 BÚSQUEDAS POPULARES:")
    search_terms = ['Magic', 'deck', 'carta', 'Commander', 'torneo']
    
    for term in search_terms:
        response = requests.get(f"{API_URL}/posts/?search={term}", headers=headers)
        if response.status_code == 200:
            data = response.json()
            count = data.get('count', 0)
            print(f"   🔍 '{term}': {count} resultados")
    
    # 5. Test de filtros por comunidad
    print("\n🏘️ POSTS POR COMUNIDAD:")
    for community_id in [1, 2]:
        response = requests.get(f"{API_URL}/posts/?community={community_id}", headers=headers)
        if response.status_code == 200:
            data = response.json()
            count = data.get('count', 0)
            community_name = 'Desconocida'
            results = data.get('results', [])
            if results:
                community_name = results[0].get('community', {}).get('name', 'Desconocida')
            print(f"   🏘️ Comunidad {community_id} ({community_name}): {count} posts")
    
    # 6. Test de performance de endpoints
    print("\n⚡ PERFORMANCE DE ENDPOINTS:")
    endpoints = [
        ('/posts/', 'Lista general'),
        ('/posts/feed/', 'Feed personalizado'),
        ('/posts/my_posts/', 'Mis posts'),
        ('/posts/by_community/?community_id=1', 'Por comunidad')
    ]
    
    import time
    for endpoint, name in endpoints:
        start = time.time()
        response = requests.get(f"{API_URL}{endpoint}", headers=headers)
        end = time.time()
        
        response_time = (end - start) * 1000
        status = "✅" if response.status_code == 200 else "❌"
        print(f"   {status} {name}: {response_time:.2f}ms")
    
    print("\n" + "=" * 50)
    print(f"📅 Reporte generado: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("🎉 Análisis completado")

if __name__ == "__main__":
    get_system_stats()
