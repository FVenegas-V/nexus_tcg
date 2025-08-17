#!/usr/bin/env python
"""
Script para crear usuario de prueba test1
"""
import os
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from users.models import User

def create_test_user():
    """Crear usuario de prueba test1"""
    try:
        # Verificar si ya existe
        if User.objects.filter(username='test1').exists():
            print("❌ Usuario test1 ya existe")
            user = User.objects.get(username='test1')
            print(f"✅ Usuario encontrado: {user.username} - {user.email}")
            return
        
        # Crear usuario
        user = User.objects.create_user(
            username='test1',
            email='test1@example.com',
            password='password123',
            first_name='Test',
            last_name='User'
        )
        
        print(f"✅ Usuario creado exitosamente:")
        print(f"   👤 Username: {user.username}")
        print(f"   📧 Email: {user.email}")
        print(f"   🔑 Password: password123")
        print(f"   📅 Created: {user.date_joined}")
        
    except Exception as e:
        print(f"❌ Error creando usuario: {e}")

if __name__ == '__main__':
    create_test_user()
