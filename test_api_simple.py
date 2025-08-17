import requests
import json

# Probar la API directamente
try:
    response = requests.get('http://localhost:8000/api/communities/?ordering=-member_count')
    print(f'Status: {response.status_code}')
    
    if response.status_code == 200:
        data = response.json()
        print(f'Total communities: {len(data)}')
        
        for i, community in enumerate(data, 1):
            print(f'\n{i}. {community["name"]}')
            print(f'   Tags: {community.get("tags", "NO TAGS FIELD")}')
    else:
        print(f'Error: {response.text}')
        
except Exception as e:
    print(f'Exception: {e}')
