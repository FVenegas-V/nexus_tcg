#!/usr/bin/env python
import os
import sys
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from communities.models import Community, CommunityMembership, Post
from users.models import User

def check_specific_user_posts():
    print("🔍 INVESTIGANDO POSTS DE USUARIOS ESPECÍFICOS")
    print("=" * 50)
    
    # Verificar posts de cada miembro individualmente
    usernames = ['test10', 'test_user_1', 'testuser1']
    
    for username in usernames:
        print(f"\n👤 USUARIO: {username}")
        print("-" * 30)
        
        try:
            user = User.objects.get(username=username)
            
            # Posts en todas las comunidades
            all_user_posts = Post.objects.filter(author=user)
            print(f"📝 Total posts del usuario: {all_user_posts.count()}")
            
            # Posts específicamente en Magic Players Chile
            magic_community = Community.objects.get(name='Magic Players Chile')
            magic_posts = Post.objects.filter(author=user, community=magic_community)
            print(f"🏘️ Posts en Magic Players Chile: {magic_posts.count()}")
            
            if magic_posts.exists():
                for post in magic_posts:
                    print(f"   📄 ID {post.id}: {post.content[:60]}... (Activo: {post.is_active})")
            else:
                print("   ❌ No tiene posts en Magic Players Chile")
                
            # Posts en otras comunidades
            other_posts = all_user_posts.exclude(community=magic_community)
            if other_posts.exists():
                print(f"🌐 Posts en otras comunidades: {other_posts.count()}")
                for post in other_posts:
                    print(f"   📄 {post.community.name}: {post.content[:50]}...")
            
            # Verificar si el usuario está realmente activo en la comunidad
            membership = CommunityMembership.objects.filter(user=user, community=magic_community).first()
            if membership:
                print(f"👥 Membresía: {membership.status} desde {membership.joined_at.strftime('%Y-%m-%d')}")
            else:
                print("❌ No tiene membresía en Magic Players Chile")
                
        except User.DoesNotExist:
            print(f"❌ Usuario {username} no encontrado")
        except Exception as e:
            print(f"❌ Error: {e}")

if __name__ == "__main__":
    check_specific_user_posts()
