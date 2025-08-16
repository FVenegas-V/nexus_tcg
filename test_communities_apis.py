import requests
import json

# URL base del servidor
BASE_URL = "http://localhost:8000"

# APIs a probar
apis = {
    'GameTypes': '/api/games/',
    'Tags': '/api/tags/',
    'Memberships': '/api/memberships/',
    'Communities': '/api/communities/',
    'Categories': '/api/categories/'
}

print("🧪 Probando todas las APIs de Communities...\n")

for name, endpoint in apis.items():
    try:
        url = BASE_URL + endpoint
        response = requests.get(url, timeout=5)
        
        print(f"📡 {name} - {endpoint}")
        print(f"   Status: {response.status_code}")
        
        if response.status_code == 200:
            try:
                data = response.json()
                if isinstance(data, list):
                    print(f"   Resultado: Lista con {len(data)} elementos")
                    if len(data) > 0:
                        print(f"   Primer elemento: {list(data[0].keys()) if data[0] else 'Vacío'}")
                elif isinstance(data, dict):
                    print(f"   Resultado: Objeto con {len(data)} campos")
                    print(f"   Campos: {list(data.keys())}")
                else:
                    print(f"   Resultado: {type(data)}")
            except json.JSONDecodeError:
                print(f"   Contenido: {response.text[:100]}...")
        else:
            print(f"   Error: {response.text[:200]}...")
        
        print()
        
    except Exception as e:
        print(f"❌ Error al probar {name}: {str(e)}\n")

print("✅ Pruebas completadas")
