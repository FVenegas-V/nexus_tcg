#!/usr/bin/env python3
"""
Crear datos específicos para testing del sistema de comentarios
"""

import os
import sys
import django
from django.contrib.auth import get_user_model

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from communities.models import Community, CommunityMembership, Post, Comment, Reaction

User = get_user_model()

def create_test_data_for_comments():
    """Crear datos específicos para probar comentarios"""
    print("🎯 Creando datos de prueba para comentarios...")
    
    # 1. Crear usuarios de prueba
    users = []
    for i in range(1, 6):  # 5 usuarios
        username = f'testuser{i}'
        try:
            user = User.objects.get(username=username)
            print(f"   Usuario {username} ya existe")
        except User.DoesNotExist:
            user = User.objects.create_user(
                username=username,
                email=f'test{i}@comments.com',
                password='TestPass123!'
            )
            print(f"   ✅ Usuario {username} creado")
        users.append(user)
    
    # 2. Crear o obtener comunidad de prueba
    try:
        community = Community.objects.get(name='Comentarios Testing')
        print("   Comunidad 'Comentarios Testing' ya existe")
    except Community.DoesNotExist:
        # Necesitamos una categoría y game_type
        from communities.models import CommunityCategory, GameType
        
        try:
            category = CommunityCategory.objects.first()
            if not category:
                category = CommunityCategory.objects.create(
                    name='Testing',
                    description='Categoría para testing'
                )
        except:
            category = None
            
        try:
            game_type = GameType.objects.first()
            if not game_type:
                game_type = GameType.objects.create(
                    name='Magic: The Gathering',
                    slug='magic-the-gathering'
                )
        except:
            game_type = None
            
        community = Community.objects.create(
            name='Comentarios Testing',
            description='Comunidad para probar el sistema de comentarios',
            game_type=game_type,
            difficulty_level='intermedio',
            category=category,
            is_public=True,
            created_by=users[0]  # El primer usuario crea la comunidad
        )
        print("   ✅ Comunidad 'Comentarios Testing' creada")
    
    # 3. Hacer que todos los usuarios sean miembros
    for user in users:
        membership, created = CommunityMembership.objects.get_or_create(
            user=user,
            community=community,
            defaults={'role': 'member'}
        )
        if created:
            print(f"   ✅ {user.username} agregado a la comunidad")
    
    # 4. Crear posts de prueba
    posts = []
    for i in range(1, 4):  # 3 posts
        post_title = f'Post {i} - Testing Comentarios'
        try:
            post = Post.objects.get(title=post_title)
            print(f"   Post '{post_title}' ya existe")
        except Post.DoesNotExist:
            post = Post.objects.create(
                title=post_title,
                content=f'Este es el contenido del post {i} para probar comentarios. '
                       f'Aquí puedes probar el sistema de threading de comentarios con 3 niveles.',
                author=users[0],
                community=community
            )
            print(f"   ✅ Post '{post_title}' creado")
        posts.append(post)
    
    # 5. Crear comentarios con threading
    print("\n💬 Creando estructura de comentarios con threading...")
    
    for post_idx, post in enumerate(posts):
        print(f"\n   📝 Post: {post.title}")
        
        # Comentarios principales (nivel 0)
        main_comments = []
        for i in range(1, 4):  # 3 comentarios principales
            content = f'Comentario principal {i} del post {post_idx + 1}. ' \
                     f'Este es un comentario de nivel 0 que puede tener respuestas.'
            
            comment = Comment.objects.create(
                content=content,
                author=users[i % len(users)],
                post=post,
                parent=None,
                thread_level=0,
                thread_path=str(len(main_comments) + 1)
            )
            main_comments.append(comment)
            print(f"      ↳ Nivel 0: {comment.content[:50]}...")
            
            # Respuestas nivel 1
            for j in range(1, 3):  # 2 respuestas por comentario principal
                reply_content = f'Respuesta {j} al comentario principal {i}. ' \
                               f'Este es un comentario de nivel 1.'
                
                reply = Comment.objects.create(
                    content=reply_content,
                    author=users[(i + j) % len(users)],
                    post=post,
                    parent=comment,
                    thread_level=1,
                    thread_path=f'{comment.thread_path}.{j}'
                )
                print(f"         ↳ Nivel 1: {reply.content[:50]}...")
                
                # Algunas respuestas de nivel 2
                if j == 1:  # Solo para la primera respuesta
                    for k in range(1, 2):  # 1 respuesta nivel 2
                        reply2_content = f'Respuesta nivel 2 número {k}. ' \
                                       f'Este es el nivel máximo de threading.'
                        
                        reply2 = Comment.objects.create(
                            content=reply2_content,
                            author=users[(i + j + k) % len(users)],
                            post=post,
                            parent=reply,
                            thread_level=2,
                            thread_path=f'{reply.thread_path}.{k}'
                        )
                        print(f"            ↳ Nivel 2: {reply2.content[:50]}...")
    
    # 6. Agregar algunas reacciones
    print("\n😊 Agregando reacciones a comentarios...")
    all_comments = Comment.objects.filter(post__in=posts)
    
    reaction_types = ['like', 'love', 'laugh', 'wow', 'sad', 'angry']
    
    for comment in all_comments[:10]:  # Solo primeros 10 comentarios
        # 1-3 reacciones aleatorias por comentario
        num_reactions = (comment.id % 3) + 1
        for i in range(num_reactions):
            user = users[i % len(users)]
            reaction_type = reaction_types[i % len(reaction_types)]
            
            reaction, created = Reaction.objects.get_or_create(
                user=user,
                content_type=Comment._meta.get_field('id').related_model._meta.get_field('comment')._get_content_type(),
                object_id=comment.id,
                defaults={'reaction_type': reaction_type}
            )
            
            if created:
                print(f"   ✅ {user.username} reaccionó {reaction_type} al comentario {comment.id}")
    
    print("\n🎉 Datos de prueba creados exitosamente!")
    print(f"📊 Resumen:")
    print(f"   - Usuarios: {len(users)}")
    print(f"   - Comunidad: {community.name}")
    print(f"   - Posts: {len(posts)}")
    print(f"   - Comentarios totales: {Comment.objects.filter(post__in=posts).count()}")
    print(f"   - Comentarios nivel 0: {Comment.objects.filter(post__in=posts, thread_level=0).count()}")
    print(f"   - Comentarios nivel 1: {Comment.objects.filter(post__in=posts, thread_level=1).count()}")
    print(f"   - Comentarios nivel 2: {Comment.objects.filter(post__in=posts, thread_level=2).count()}")
    print(f"   - Reacciones: {Reaction.objects.filter(object_id__in=[c.id for c in all_comments]).count()}")
    
    return {
        'users': users,
        'community': community,
        'posts': posts,
        'test_user': users[0]  # Usuario principal para testing
    }

if __name__ == '__main__':
    try:
        data = create_test_data_for_comments()
        print(f"\n🚀 ¡Listo para testing!")
        print(f"   👤 Usuario de prueba: {data['test_user'].username}")
        print(f"   🔑 Contraseña: TestPass123!")
        print(f"   🏘️ Comunidad: {data['community'].name}")
        print(f"   📝 Posts disponibles: {len(data['posts'])}")
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
