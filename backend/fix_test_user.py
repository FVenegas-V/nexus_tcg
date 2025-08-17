#!/usr/bin/env python
import os
import sys
import django

# Configurar Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from django.contrib.auth.models import User

def create_test_user():
    username = 'test1'
    email = 'test1@example.com'
    password = 'password123'
    
    # Eliminar usuario existente si hay problemas
    try:
        existing_user = User.objects.get(username=username)
        existing_user.delete()
        print(f"Usuario existente {username} eliminado")
    except User.DoesNotExist:
        pass
    
    # Crear nuevo usuario
    user = User.objects.create_user(
        username=username,
        email=email,
        password=password,
        first_name='Test',
        last_name='User'
    )
    
    print(f"✅ Usuario creado: {user.username}")
    print(f"📧 Email: {user.email}")
    print(f"🔑 Password: {password}")
    
    return user

if __name__ == '__main__':
    create_test_user()
