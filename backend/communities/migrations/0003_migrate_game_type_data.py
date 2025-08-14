"""
Migración de datos para convertir game_type de CharField a ForeignKey.
"""
from django.db import migrations


def migrate_game_types_forward(apps, schema_editor):
    """Migra los game_types de CharField a ForeignKey."""
    Community = apps.get_model('communities', 'Community')
    GameType = apps.get_model('communities', 'GameType')
    
    # Mapeo de strings a GameType
    game_type_mapping = {
        'Magic: The Gathering': 'magic-the-gathering',
        'Pokemon TCG': 'pokemon-tcg', 
        'Yu-Gi-Oh!': 'yu-gi-oh',
        'Dragon Ball Super Card Game': 'dragon-ball-super',
        'One Piece Card Game': 'one-piece',
        'Digimon Card Game': 'digimon',
        'Force of Will': 'force-of-will',
    }
    
    migrated_count = 0
    error_count = 0
    
    for community in Community.objects.all():
        game_type_name = community.game_type
        
        if game_type_name in game_type_mapping:
            slug = game_type_mapping[game_type_name]
            try:
                game_type_obj = GameType.objects.get(slug=slug)
                community.game_type_new = game_type_obj
                community.save(update_fields=['game_type_new'])
                migrated_count += 1
                print(f"✓ Migrado: Comunidad {community.id} -> {game_type_name}")
            except GameType.DoesNotExist:
                print(f"✗ Error: GameType '{slug}' no encontrado para comunidad {community.id}")
                error_count += 1
        else:
            print(f"✗ Error: game_type '{game_type_name}' no reconocido en comunidad {community.id}")
            error_count += 1
    
    print(f"\n🎯 Migración completada:")
    print(f"  • Migrados: {migrated_count} comunidades")
    print(f"  • Errores: {error_count} comunidades")


def migrate_game_types_reverse(apps, schema_editor):
    """Revierte la migración copiando de game_type_new a game_type."""
    Community = apps.get_model('communities', 'Community')
    
    for community in Community.objects.all():
        if community.game_type_new:
            community.game_type = community.game_type_new.name
            community.save(update_fields=['game_type'])


class Migration(migrations.Migration):

    dependencies = [
        ('communities', '0002_add_gametype_and_tag_models'),
    ]

    operations = [
        migrations.RunPython(
            migrate_game_types_forward,
            migrate_game_types_reverse,
            elidable=True,
        ),
    ]
