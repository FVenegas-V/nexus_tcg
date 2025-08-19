#!/usr/bin/env python3
"""
Script para actualizar los image_urls de posts existentes que tienen PostImages.
"""
import os
import sys
import django

# Configurar Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from communities.models import Post, PostImage
from communities.signals_image import update_post_image_urls

def fix_existing_posts():
    """Actualizar todos los posts que tienen PostImages pero image_urls vacío."""
    
    print("🔍 Buscando posts con PostImages pero sin image_urls...")
    
    # Encontrar posts que tienen PostImages pero image_urls vacío
    posts_with_images = Post.objects.filter(
        images__isnull=False,
        is_active=True
    ).distinct()
    
    posts_fixed = 0
    posts_already_ok = 0
    
    for post in posts_with_images:
        print(f"\n📝 Procesando post {post.id}...")
        
        # Verificar PostImages asociadas
        post_images = PostImage.objects.filter(
            post=post,
            is_active=True,
            processed=True
        ).count()
        
        current_urls = post.image_urls
        print(f"   - PostImages procesadas: {post_images}")
        print(f"   - image_urls actuales: {len(current_urls)}")
        
        if post_images > 0 and len(current_urls) == 0:
            print(f"   ⚠️ Post necesita actualización")
            
            # Actualizar usando la función del signal
            update_post_image_urls(post)
            
            # Verificar resultado
            post.refresh_from_db()
            new_urls = post.image_urls
            print(f"   ✅ Actualizado: {len(new_urls)} URLs")
            posts_fixed += 1
            
        elif post_images == len(current_urls):
            print(f"   ✓ Post ya está actualizado")
            posts_already_ok += 1
        else:
            print(f"   ⚠️ Inconsistencia: {post_images} PostImages vs {len(current_urls)} URLs")
    
    print(f"\n📊 Resumen:")
    print(f"   - Posts corregidos: {posts_fixed}")
    print(f"   - Posts ya correctos: {posts_already_ok}")
    print(f"   - Total procesados: {posts_fixed + posts_already_ok}")

if __name__ == "__main__":
    fix_existing_posts()
