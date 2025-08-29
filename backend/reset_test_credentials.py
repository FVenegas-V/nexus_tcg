#!/usr/bin/env python
"""
Script para verificar y resetear credenciales de usuarios de testing
"""
import os
import sys
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from users.models import User

def main():
    print("🔧 === VERIFICACIÓN Y RESET DE CREDENCIALES ===")
    print()
    
    # Usuarios a verificar
    test_users = ['test_user_1', 'test_user_2']
    
    for username in test_users:
        try:
            user = User.objects.get(username=username)
            print(f"👤 Usuario: {username} (ID: {user.id})")
            
            # Resetear contraseña a algo conocido
            user.set_password('test123')
            user.save()
            
            print(f"   ✅ Contraseña reseteada a: test123")
            print(f"   📧 Email: {user.email or 'No configurado'}")
            print(f"   🆔 ID: {user.id}")
            print()
            
        except User.DoesNotExist:
            print(f"❌ Usuario {username} no encontrado")
            
            # Crear el usuario si no existe
            print(f"   🔨 Creando usuario {username}...")
            user = User.objects.create_user(
                username=username,
                email=f"{username}@test.com",
                password='test123'
            )
            print(f"   ✅ Usuario {username} creado con ID: {user.id}")
            print()
    
    print("🎯 Credenciales para testing:")
    print("   Username: test_user_1 | Password: test123")
    print("   Username: test_user_2 | Password: test123")

if __name__ == "__main__":
    main()
