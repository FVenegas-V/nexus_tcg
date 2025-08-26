#!/usr/bin/env python
import os
import sys
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from communities.models import Community, Post
from users.models import User

def create_test_post():
    print("📝 CREANDO POST DE TESTUSER1 EN MAGIC PLAYERS CHILE")
    print("=" * 50)
    
    try:
        user = User.objects.get(username='testuser1')
        community = Community.objects.get(name='Magic Players Chile')
        
        # Crear post de testuser1
        new_post = Post.objects.create(
            author=user,
            community=community,
            content="¡Hola comunidad de Magic! Soy testuser1 y me encanta este juego. ¿Alguien quiere intercambiar cartas de la última expansión? Tengo varias cartas raras disponibles. 🃏✨",
            is_active=True
        )
        
        print(f"✅ Post creado exitosamente!")
        print(f"   📄 ID: {new_post.id}")
        print(f"   👤 Autor: {new_post.author.username}")
        print(f"   🏘️ Comunidad: {new_post.community.name}")
        print(f"   📅 Fecha: {new_post.created_at.strftime('%Y-%m-%d %H:%M')}")
        print(f"   📝 Contenido: {new_post.content}")
        
        # Verificar el nuevo conteo
        community.refresh_from_db()
        total_posts = Post.objects.filter(community=community, is_active=True).count()
        print(f"\n📊 Total posts en Magic Players Chile: {total_posts}")
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    create_test_post()
