#!/usr/bin/env python3
"""
Test rápido de reacción
"""
import requests

BASE_URL = "http://localhost:8000"

# Login Poison
login_response = requests.post(f"{BASE_URL}/api/auth/login/", json={"username": "Poison", "password": "poison123"})
if login_response.status_code != 200:
    print(f"Error login: {login_response.status_code} - {login_response.text}")
    exit(1)

token = login_response.json()["access"]
headers = {"Authorization": f"Bearer {token}"}

# Obtener posts
posts_response = requests.get(f"{BASE_URL}/api/posts/feed/", headers=headers)
if posts_response.status_code != 200:
    print(f"Error posts: {posts_response.status_code}")
    exit(1)

posts = posts_response.json()["results"]
if not posts:
    print("No hay posts")
    exit(1)

post_id = posts[0]["id"]
print(f"Intentando reaccionar al post {post_id}")

# Intentar reacción
reaction_response = requests.post(
    f"{BASE_URL}/api/posts/{post_id}/toggle_reaction/",
    json={"reaction_type": "like"},
    headers=headers
)

print(f"Status: {reaction_response.status_code}")
print(f"Response: {reaction_response.text}")
