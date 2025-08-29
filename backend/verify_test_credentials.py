#!/usr/bin/env python
"""
Script para verificar y configurar credenciales de usuarios de prueba
"""
import os
import sys
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from users.models import User
from django.contrib.auth import authenticate

def main():
    print("🔐 === VERIFICACIÓN DE CREDENCIALES DE USUARIOS DE PRUEBA ===")
    print()
    
    # Información de usuarios de prueba
    test_users = [
        {
            'username': 'testuser1',
            'password': 'test123',
            'email': 'test1@example.com',
            'first_name': 'Usuario',
            'last_name': 'Uno'
        },
        {
            'username': 'testuser2', 
            'password': 'test123',
            'email': 'test2@example.com',
            'first_name': 'Usuario',
            'last_name': 'Dos'
        }
    ]
    
    print("1️⃣ Verificando/configurando usuarios de prueba...")
    
    for user_data in test_users:
        username = user_data['username']
        password = user_data['password']
        
        # Obtener o crear usuario
        user, created = User.objects.get_or_create(
            username=username,
            defaults={
                'email': user_data['email'],
                'first_name': user_data['first_name'],
                'last_name': user_data['last_name']
            }
        )
        
        # Configurar contraseña
        user.set_password(password)
        user.save()
        
        status = "✅ CREADO" if created else "🔄 ACTUALIZADO"
        print(f"   {status}: {username}")
        print(f"     - ID: {user.id}")
        print(f"     - Email: {user.email}")
        print(f"     - Contraseña: {password}")
        
        # Verificar autenticación
        auth_user = authenticate(username=username, password=password)
        if auth_user:
            print(f"     - ✅ Autenticación EXITOSA")
        else:
            print(f"     - ❌ Autenticación FALLIDA")
        print()
    
    print("2️⃣ Resumen de credenciales para la app:")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("👤 USUARIO 1 (Evaluador):")
    print("   Username: testuser1")
    print("   Password: test123")
    print("   ID: 11")
    print()
    print("👤 USUARIO 2 (Evaluado):")
    print("   Username: testuser2")
    print("   Password: test123")
    print("   ID: 12")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print()
    
    print("3️⃣ Pasos para testing:")
    print("   1. En la app Flutter, hacer login con:")
    print("      👉 Username: testuser1")
    print("      👉 Password: test123")
    print()
    print("   2. Navegar al perfil público del usuario ID: 12")
    print("      (o buscar por username: testuser2)")
    print()
    print("   3. Presionar el botón 'Valorar'")
    print()
    print("   4. Completar la calificación y verificar que se guarde")
    print()
    
    # Verificar si ya existe una calificación entre estos usuarios
    from users.models import UserRating
    existing_rating = UserRating.objects.filter(
        rater__username='testuser1',
        rated_user__username='testuser2'
    ).first()
    
    if existing_rating:
        print("⚠️  NOTA: Ya existe una calificación entre estos usuarios:")
        print(f"   testuser1 calificó a testuser2 con {existing_rating.rating}⭐")
        print("   Puedes probar actualizando la calificación existente")
    else:
        print("✅ No hay calificaciones existentes entre estos usuarios")
        print("   Perfecto para testing de nueva calificación")

if __name__ == "__main__":
    main()
