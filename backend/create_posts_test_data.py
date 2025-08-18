"""
Script para crear datos de prueba para el sistema de Posts.
"""
import os
import sys
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from django.contrib.auth import get_user_model
from communities.models import (
    Community, CommunityCategory, CommunityMembership, 
    GameType, Post, Reaction
)
from django.contrib.contenttypes.models import ContentType

User = get_user_model()

def create_test_data():
    """Crear datos de prueba para Posts."""
    
    print("🎯 Creando datos de prueba para Posts...")
    
    # 1. Crear usuarios de prueba
    print("👤 Creando usuarios...")
    admin_user = User.objects.get_or_create(
        username='admin_test',
        defaults={
            'email': 'admin@test.com',
            'first_name': 'Admin',
            'last_name': 'Test'
        }
    )[0]
    admin_user.set_password('admin123')
    admin_user.save()
    
    user1 = User.objects.get_or_create(
        username='gamer1',
        defaults={
            'email': 'gamer1@test.com',
            'first_name': 'Gamer',
            'last_name': 'One'
        }
    )[0]
    user1.set_password('gamer123')
    user1.save()
    
    user2 = User.objects.get_or_create(
        username='tcg_pro',
        defaults={
            'email': 'tcgpro@test.com',
            'first_name': 'TCG',
            'last_name': 'Pro'
        }
    )[0]
    user2.set_password('tcg123')
    user2.save()
    
    user3 = User.objects.get_or_create(
        username='card_collector',
        defaults={
            'email': 'collector@test.com',
            'first_name': 'Card',
            'last_name': 'Collector'
        }
    )[0]
    user3.set_password('card123')
    user3.save()
    
    # 2. Crear categorías y game types
    print("🎮 Creando categorías y tipos de juego...")
    category = CommunityCategory.objects.get_or_create(
        name='Estrategia',
        defaults={'description': 'Juegos de estrategia'}
    )[0]
    
    game_type = GameType.objects.get_or_create(
        name='Magic: The Gathering',
        defaults={'slug': 'magic'}
    )[0]
    
    # 3. Crear comunidades
    print("🏘️ Creando comunidades...")
    community1 = Community.objects.get_or_create(
        name='Magic Players España',
        defaults={
            'description': 'Comunidad de jugadores de Magic en España',
            'category': category,
            'created_by': admin_user,
            'game_type': game_type,
            'difficulty_level': 'intermediate'
        }
    )[0]
    
    community2 = Community.objects.get_or_create(
        name='Principiantes MTG',
        defaults={
            'description': 'Comunidad para principiantes de Magic',
            'category': category,
            'created_by': user1,
            'game_type': game_type,
            'difficulty_level': 'beginner'
        }
    )[0]
    
    # 4. Crear membresías
    print("👥 Creando membresías...")
    memberships = [
        (admin_user, community1, 'admin'),
        (user1, community1, 'member'),
        (user2, community1, 'moderator'),
        (user3, community1, 'member'),
        (user1, community2, 'admin'),
        (user2, community2, 'member'),
        (user3, community2, 'member'),
    ]
    
    for user, community, role in memberships:
        CommunityMembership.objects.get_or_create(
            user=user,
            community=community,
            defaults={'role': role}
        )
    
    # 5. Crear posts
    print("📝 Creando posts...")
    posts_data = [
        {
            'title': '¿Mejor formato para principiantes?',
            'content': 'Hola a todos! Soy nuevo en Magic y me gustaría saber qué formato recomiendan para empezar. He oído hablar de Standard, Draft, Commander... ¿cuál es más amigable para principiantes?',
            'author': user3,
            'community': community1
        },
        {
            'title': 'Deck Budget Mono Rojo Agresivo',
            'content': 'Comparto mi deck mono rojo que me está funcionando muy bien en Standard y cuesta menos de 50€. Lista completa: 4x Monastery Swiftspear, 4x Lightning Bolt, 4x Rift Bolt...',
            'author': user1,
            'community': community1
        },
        {
            'title': 'Resultados del torneo local',
            'content': 'Ayer participé en mi primer torneo local de Draft. Conseguí quedar 3º de 16 personas! Fue una experiencia increíble. El ambiente era muy bueno y aprendí muchísimo.',
            'author': user2,
            'community': community1
        },
        {
            'title': 'Dudas sobre las reglas de Stack',
            'content': 'Tengo algunas dudas sobre cómo funciona el stack en Magic. Específicamente cuando hay múltiples hechizos instantáneos y habilidades activadas. ¿Alguien puede explicármelo?',
            'author': user3,
            'community': community2
        },
        {
            'title': 'Review: Commander Legends 2',
            'content': 'Acabo de abrir una caja de Commander Legends 2 y quería compartir mi experiencia. La calidad de las cartas ha mejorado mucho y hay algunas reimpresas muy interesantes...',
            'author': user1,
            'community': community1
        },
        {
            'title': 'Tip: Cómo organizar tu colección',
            'content': 'Después de años coleccionando, he encontrado el mejor sistema para organizar cartas. Uso carpetas por colores, ordenadas alfabéticamente, y una base de datos digital para tracking.',
            'author': user2,
            'community': community2
        }
    ]
    
    created_posts = []
    for post_data in posts_data:
        post = Post.objects.create(**post_data)
        created_posts.append(post)
        print(f"   ✅ Post creado: {post.title}")
    
    # 6. Crear reacciones
    print("❤️ Creando reacciones...")
    post_content_type = ContentType.objects.get_for_model(Post)
    
    reactions_data = [
        (created_posts[0], user1, 'like'),
        (created_posts[0], user2, 'love'),
        (created_posts[1], user2, 'like'),
        (created_posts[1], user3, 'like'),
        (created_posts[1], admin_user, 'love'),
        (created_posts[2], user1, 'love'),
        (created_posts[2], user3, 'like'),
        (created_posts[3], user1, 'like'),
        (created_posts[3], user2, 'wow'),
        (created_posts[4], user2, 'love'),
        (created_posts[4], user3, 'like'),
        (created_posts[4], admin_user, 'like'),
        (created_posts[5], user1, 'like'),
        (created_posts[5], user3, 'love'),
    ]
    
    for post, user, reaction_type in reactions_data:
        Reaction.objects.get_or_create(
            content_type=post_content_type,
            object_id=post.id,
            user=user,
            defaults={'reaction_type': reaction_type}
        )
    
    print(f"   ✅ {len(reactions_data)} reacciones creadas")
    
    print("\n🎉 Datos de prueba creados exitosamente!")
    print("\n📊 Resumen:")
    print(f"   👤 Usuarios: {User.objects.count()}")
    print(f"   🏘️ Comunidades: {Community.objects.count()}")
    print(f"   📝 Posts: {Post.objects.count()}")
    print(f"   ❤️ Reacciones: {Reaction.objects.count()}")
    
    print("\n🔐 Credenciales de prueba:")
    print("   admin_test / admin123 (Admin)")
    print("   gamer1 / gamer123 (Usuario)")
    print("   tcg_pro / tcg123 (Moderador)")
    print("   card_collector / card123 (Usuario)")

if __name__ == "__main__":
    create_test_data()
