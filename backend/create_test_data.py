"""
Script para crear datos de prueba y verificar los problemas identificados.
"""
import os
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from communities.models import GameType, Community, CommunityTag
from django.contrib.auth.models import User

def create_test_data():
    """Crear datos de prueba para las APIs."""
    
    print("🔧 Creando datos de prueba...")
    
    # 1. Verificar y crear GameTypes
    if GameType.objects.count() == 0:
        print("📚 Cargando GameTypes...")
        from django.core.management import call_command
        call_command('load_game_types')
    
    game_types_count = GameType.objects.count()
    print(f"✅ GameTypes disponibles: {game_types_count}")
    
    # 2. Crear usuario de prueba
    user, created = User.objects.get_or_create(
        username='testuser',
        defaults={
            'email': 'test@example.com',
            'first_name': 'Test',
            'last_name': 'User'
        }
    )
    if created:
        user.set_password('testpass123')
        user.save()
    print(f"✅ Usuario de prueba: {user.username}")
    
    # 3. Crear comunidades de prueba
    magic_game = GameType.objects.filter(name__icontains='magic').first()
    pokemon_game = GameType.objects.filter(name__icontains='pokemon').first()
    
    if magic_game:
        community1, created = Community.objects.get_or_create(
            name='Magic Players Madrid',
            defaults={
                'description': 'Comunidad de jugadores de Magic en Madrid',
                'game_type': magic_game,
                'creator': user,
                'is_public': True,
                'member_count': 15,
                'difficulty_level': 'intermedio',
                'tags': ['competitive', 'tournament']
            }
        )
        print(f"✅ Comunidad Magic: {community1.name}")
    
    if pokemon_game:
        community2, created = Community.objects.get_or_create(
            name='Pokemon TCG Barcelona',
            defaults={
                'description': 'Comunidad de Pokemon TCG en Barcelona',
                'game_type': pokemon_game,
                'creator': user,
                'is_public': True,
                'member_count': 8,
                'difficulty_level': 'principiante',
                'tags': ['casual', 'trading']
            }
        )
        print(f"✅ Comunidad Pokemon: {community2.name}")
    
    # 4. Verificar datos finales
    total_communities = Community.objects.count()
    total_tags = CommunityTag.objects.count()
    
    print(f"\n📊 RESUMEN:")
    print(f"   GameTypes: {game_types_count}")
    print(f"   Communities: {total_communities}")
    print(f"   Tags: {total_tags}")
    print(f"   Users: {User.objects.count()}")
    
    # 5. Probar acceso a datos específicos
    game_1 = GameType.objects.filter(id=1).first()
    if game_1:
        communities_count = Community.objects.filter(game_type=game_1, is_public=True).count()
        print(f"   GameType ID=1: {game_1.name} ({communities_count} comunidades)")
    else:
        print(f"   ❌ GameType ID=1 no encontrado")
    
    print("\n🎯 Datos de prueba listos!")

if __name__ == "__main__":
    create_test_data()
