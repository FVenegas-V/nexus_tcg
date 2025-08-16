#!/usr/bin/env python
"""
Script para crear superusuario admin.
"""
import os
import sys
import django

# Setup Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

def create_admin():
    """Crear usuario admin si no existe."""
    username = 'admin'
    email = 'admin@nexustcg.com'
    password = 'admin123'
    
    if User.objects.filter(username=username).exists():
        print(f"✅ Usuario '{username}' ya existe")
        user = User.objects.get(username=username)
    else:
        user = User.objects.create_superuser(
            username=username,
            email=email,
            password=password
        )
        print(f"✅ Superusuario '{username}' creado exitosamente")
    
    print(f"📋 Credenciales para http://127.0.0.1:8000/admin/:")
    print(f"   Usuario: {username}")
    print(f"   Contraseña: admin123")
    print(f"   Email: {email}")

if __name__ == "__main__":
    create_admin()
