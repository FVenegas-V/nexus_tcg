#!/usr/bin/env python
import os
import sys
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from communities.models import Community, CommunityMembership, Post
from users.models import User

def investigate_posts_issue():
    print("🔍 INVESTIGANDO PROBLEMA DE POSTS EN MAGIC PLAYERS CHILE")
    print("=" * 60)
    
    try:
        magic_community = Community.objects.get(name='Magic Players Chile')
        print(f"🏘️ Comunidad: {magic_community.name}")
        print(f"📊 Member count: {magic_community.member_count}")
        
        # Obtener todos los miembros
        print("\n=== MIEMBROS DE LA COMUNIDAD ===")
        memberships = CommunityMembership.objects.filter(community=magic_community)
        for membership in memberships:
            print(f"👤 {membership.user.username} (Status: {membership.status}, Fecha: {membership.joined_at.strftime('%Y-%m-%d')})")
        
        # Obtener TODOS los posts (incluyendo inactivos)
        print(f"\n=== TODOS LOS POSTS (INCLUYENDO INACTIVOS) ===")
        all_posts = Post.objects.filter(community=magic_community)
        print(f"📝 Total de posts encontrados: {all_posts.count()}")
        
        for post in all_posts:
            print(f"\n📄 POST ID: {post.id}")
            print(f"   👤 Autor: {post.author.username}")
            print(f"   📅 Fecha: {post.created_at.strftime('%Y-%m-%d %H:%M')}")
            print(f"   🔄 Estado is_active: {post.is_active}")
            print(f"   📝 Contenido: {post.content[:80]}...")
            
            # Verificar si el autor es miembro de la comunidad
            is_member = CommunityMembership.objects.filter(
                community=magic_community, 
                user=post.author, 
                status='active'
            ).exists()
            print(f"   👥 ¿Autor es miembro activo?: {is_member}")
        
        # Verificar posts activos vs inactivos
        print(f"\n=== ANÁLISIS DE ESTADOS ===")
        active_posts = all_posts.filter(is_active=True)
        inactive_posts = all_posts.filter(is_active=False)
        
        print(f"✅ Posts activos: {active_posts.count()}")
        print(f"❌ Posts inactivos: {inactive_posts.count()}")
        
        if inactive_posts.exists():
            print(f"\n🚨 POSTS INACTIVOS ENCONTRADOS:")
            for post in inactive_posts:
                print(f"   - ID {post.id}: {post.author.username} - {post.content[:50]}...")
        
        # Verificar si hay algún problema con el filtrado en el API
        print(f"\n=== VERIFICACIÓN DE API QUERY ===")
        print("Query que debería usar el frontend:")
        print("Post.objects.filter(community=magic_community, is_active=True)")
        
        api_posts = Post.objects.filter(community=magic_community, is_active=True)
        print(f"📱 Posts que ve la app: {api_posts.count()}")
        
        for post in api_posts:
            print(f"   ✓ {post.author.username}: {post.content[:50]}...")
            
    except Community.DoesNotExist:
        print("❌ Comunidad Magic Players Chile no encontrada")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    investigate_posts_issue()
