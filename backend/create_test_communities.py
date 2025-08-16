#!/usr/bin/env python
"""
Script para crear datos de prueba de Communities
Ejecutar desde el directorio backend con: python create_test_communities.py
"""
import os
import sys
import django
from datetime import datetime

# Configurar Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from communities.models import Community, CommunityCategory, GameType, CommunityTag
from django.contrib.auth.models import User

def create_test_communities():
    print("🚀 Creando datos de prueba para Communities...")
    
    # Obtener o crear usuario administrador
    admin_user, created = User.objects.get_or_create(
        username='admin',
        defaults={
            'email': 'admin@nexustcg.com',
            'first_name': 'Admin',
            'last_name': 'User',
            'is_staff': True,
            'is_superuser': True,
        }
    )
    if created:
        admin_user.set_password('admin123')
        admin_user.save()
        print(f"✅ Usuario admin creado")
    
    # Obtener GameTypes existentes
    try:
        magic_game = GameType.objects.get(slug='magic-the-gathering')
        pokemon_game = GameType.objects.get(slug='pokemon-tcg')
        yugioh_game = GameType.objects.get(slug='yu-gi-oh')
        dragon_ball_game = GameType.objects.get(slug='dragon-ball-super')
        one_piece_game = GameType.objects.get(slug='one-piece')
    except GameType.DoesNotExist:
        print("❌ Error: GameTypes no encontrados. Ejecuta primero create_test_data.py")
        return
    
    # Obtener Categories existentes
    try:
        casual_category = CommunityCategory.objects.get(slug='casual')
        competitive_category = CommunityCategory.objects.get(slug='competitivo')
        collectors_category = CommunityCategory.objects.get(slug='coleccionistas')
    except CommunityCategory.DoesNotExist:
        print("❌ Error: Categories no encontradas")
        return
    
    # Obtener o crear Tags
    competitive_tag, _ = CommunityTag.objects.get_or_create(
        name='competitivo',
        defaults={'display_name': 'Competitivo', 'description': 'Juego competitivo pensado para torneos'}
    )
    casual_tag, _ = CommunityTag.objects.get_or_create(
        name='casual',
        defaults={'display_name': 'Casual', 'description': 'Gente que quiere pasarla bien'}
    )
    tournament_tag, _ = CommunityTag.objects.get_or_create(
        name='torneo',
        defaults={'display_name': 'Torneo', 'description': 'Comunidades de torneos'}
    )
    
    # Datos de comunidades de prueba
    communities_data = [
        {
            'name': 'Magic Players Chile',
            'slug': 'magic-players-chile',
            'description': 'Comunidad oficial de jugadores de Magic: The Gathering en Chile. Organizamos torneos, drafts y eventos casuales.',
            'game_type': magic_game,
            'category': competitive_category,
            'difficulty_level': 'intermedio',
            'tags': [competitive_tag, tournament_tag],
            'is_public': True,
            'is_featured': True,
            'member_count': 156,
            'post_count': 89,
            'max_members': 500,
            'requires_approval': False,
        },
        {
            'name': 'Pokémon TCG Principiantes',
            'slug': 'pokemon-tcg-principiantes',
            'description': 'Espacio para nuevos jugadores de Pokémon TCG. Ayudamos con reglas, deck building y primeros pasos.',
            'game_type': pokemon_game,
            'category': casual_category,
            'difficulty_level': 'principiante',
            'tags': [casual_tag],
            'is_public': True,
            'is_featured': False,
            'member_count': 78,
            'post_count': 45,
            'max_members': 200,
            'requires_approval': False,
        },
        {
            'name': 'Yu-Gi-Oh! Meta Deck Discussion',
            'slug': 'yugioh-meta-deck-discussion',
            'description': 'Análisis del meta actual, estrategias avanzadas y discusión de mazos competitivos.',
            'game_type': yugioh_game,
            'category': competitive_category,
            'difficulty_level': 'avanzado',
            'tags': [competitive_tag, tournament_tag],
            'is_public': True,
            'is_featured': True,
            'member_count': 234,
            'post_count': 167,
            'max_members': 300,
            'requires_approval': True,
        },
        {
            'name': 'Dragon Ball Super Casual',
            'slug': 'dragon-ball-super-casual',
            'description': 'Comunidad relajada para fanáticos de Dragon Ball Super Card Game. ¡Diversión garantizada!',
            'game_type': dragon_ball_game,
            'category': casual_category,
            'difficulty_level': 'principiante',
            'tags': [casual_tag],
            'is_public': True,
            'is_featured': False,
            'member_count': 45,
            'post_count': 23,
            'max_members': 150,
            'requires_approval': False,
        },
        {
            'name': 'One Piece Collectors',
            'slug': 'one-piece-collectors',
            'description': 'Comunidad dedicada al coleccionismo de cartas de One Piece. Intercambios, valoraciones y más.',
            'game_type': one_piece_game,
            'category': collectors_category,
            'difficulty_level': 'intermedio',
            'tags': [casual_tag],
            'is_public': True,
            'is_featured': False,
            'member_count': 67,
            'post_count': 34,
            'max_members': 100,
            'requires_approval': False,
        },
        {
            'name': 'Magic Legacy Masters',
            'slug': 'magic-legacy-masters',
            'description': 'Grupo élite para jugadores experimentados de Legacy y Vintage. Nivel competitivo alto.',
            'game_type': magic_game,
            'category': competitive_category,
            'difficulty_level': 'avanzado',
            'tags': [competitive_tag, tournament_tag],
            'is_public': False,
            'is_featured': True,
            'member_count': 89,
            'post_count': 156,
            'max_members': 50,
            'requires_approval': True,
        },
        {
            'name': 'Pokémon Collectors Santiago',
            'slug': 'pokemon-collectors-santiago',
            'description': 'Coleccionistas de cartas Pokémon en Santiago. Intercambios presenciales y online.',
            'game_type': pokemon_game,
            'category': collectors_category,
            'difficulty_level': 'intermedio',
            'tags': [casual_tag],
            'is_public': True,
            'is_featured': False,
            'member_count': 123,
            'post_count': 78,
            'max_members': 250,
            'requires_approval': False,
        },
        {
            'name': 'Yu-Gi-Oh! Duel Academy',
            'slug': 'yugioh-duel-academy',
            'description': 'Academia virtual para aprender Yu-Gi-Oh! desde cero. Tutoriales, práctica y torneos amistosos.',
            'game_type': yugioh_game,
            'category': casual_category,
            'difficulty_level': 'principiante',
            'tags': [casual_tag],
            'is_public': True,
            'is_featured': False,
            'member_count': 178,
            'post_count': 234,
            'max_members': 500,
            'requires_approval': False,
        },
    ]
    
    # Crear comunidades
    created_count = 0
    for community_data in communities_data:
        # Extraer tags para procesamiento separado
        tags = community_data.pop('tags')
        
        # Crear o actualizar comunidad
        community, created = Community.objects.get_or_create(
            slug=community_data['slug'],
            defaults={
                **community_data,
                'created_by': admin_user,
            }
        )
        
        if created:
            # Agregar tags
            community.tags.set(tags)
            created_count += 1
            print(f"✅ Comunidad creada: {community.name}")
        else:
            print(f"⚠️  Comunidad ya existe: {community.name}")
    
    print(f"\n🎉 Proceso completado!")
    print(f"📊 Comunidades creadas: {created_count}")
    print(f"📊 Total de comunidades: {Community.objects.count()}")
    
    # Mostrar estadísticas por categoría
    print(f"\n📈 Estadísticas por categoría:")
    for category in CommunityCategory.objects.all():
        count = Community.objects.filter(category=category).count()
        print(f"   - {category.name}: {count} comunidades")
    
    # Mostrar estadísticas por GameType
    print(f"\n🎮 Estadísticas por GameType:")
    for game_type in GameType.objects.all():
        count = Community.objects.filter(game_type=game_type).count()
        print(f"   - {game_type.name}: {count} comunidades")

if __name__ == '__main__':
    create_test_communities()
