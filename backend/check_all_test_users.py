#!/usr/bin/env python
import os
import sys
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from communities.models import Community, CommunityMembership, Post
from users.models import User

def check_all_test_users():
    print("🔍 INVESTIGANDO TODOS LOS USUARIOS CON 'TEST' EN EL NOMBRE")
    print("=" * 60)
    
    # Buscar todos los usuarios que contengan "test"
    test_users = User.objects.filter(username__icontains='test').order_by('username')
    
    print(f"👥 Total usuarios encontrados: {test_users.count()}")
    print("\n=== LISTADO DE USUARIOS TEST ===")
    
    for user in test_users:
        print(f"\n👤 USUARIO: {user.username}")
        print(f"   📧 Email: {user.email}")
        print(f"   📅 Creado: {user.date_joined.strftime('%Y-%m-%d %H:%M')}")
        
        # Verificar posts
        user_posts = Post.objects.filter(author=user)
        print(f"   📝 Total posts: {user_posts.count()}")
        
        # Verificar membresías
        memberships = CommunityMembership.objects.filter(user=user, status='active')
        print(f"   👥 Comunidades activas: {memberships.count()}")
        
        for membership in memberships:
            posts_in_community = Post.objects.filter(author=user, community=membership.community, is_active=True).count()
            print(f"      🏘️ {membership.community.name}: {posts_in_community} posts")
    
    # Verificar específicamente Magic Players Chile
    print(f"\n" + "="*60)
    print("🏘️ ANÁLISIS ESPECÍFICO: MAGIC PLAYERS CHILE")
    print("="*60)
    
    try:
        magic_community = Community.objects.get(name='Magic Players Chile')
        magic_members = CommunityMembership.objects.filter(community=magic_community, status='active')
        
        print(f"👥 Miembros activos: {magic_members.count()}")
        
        for membership in magic_members:
            user = membership.user
            posts_count = Post.objects.filter(author=user, community=magic_community, is_active=True).count()
            print(f"   👤 {user.username}: {posts_count} posts activos")
            
            # Mostrar los posts si los tiene
            posts = Post.objects.filter(author=user, community=magic_community, is_active=True)
            for post in posts:
                print(f"      📄 ID {post.id}: {post.content[:50]}...")
                
    except Community.DoesNotExist:
        print("❌ Comunidad no encontrada")

if __name__ == "__main__":
    check_all_test_users()
