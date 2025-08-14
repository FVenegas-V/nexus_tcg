"""
Migración para finalizar transición game_type y agregar tags (SQLite compatible).
"""
from django.db import migrations, models


def copy_game_type_ids(apps, schema_editor):
    """Copia los IDs de game_type_new al campo game_type."""
    Community = apps.get_model('communities', 'Community')
    
    for community in Community.objects.all():
        if community.game_type_new:
            # Convertir el CharField a ID temporal
            community.game_type = str(community.game_type_new.id)
            community.save(update_fields=['game_type'])
    

def restore_game_type_names(apps, schema_editor):
    """Restaura los nombres en el campo game_type."""
    Community = apps.get_model('communities', 'Community')
    GameType = apps.get_model('communities', 'GameType')
    
    for community in Community.objects.all():
        if community.game_type and community.game_type.isdigit():
            try:
                game_type_obj = GameType.objects.get(id=int(community.game_type))
                community.game_type = game_type_obj.name
                community.save(update_fields=['game_type'])
            except GameType.DoesNotExist:
                pass


class Migration(migrations.Migration):

    dependencies = [
        ('communities', '0003_migrate_game_type_data'),
    ]

    operations = [
        # Agregar campo tags como JSONField (compatible con SQLite)
        migrations.AddField(
            model_name='community',
            name='tags',
            field=models.JSONField(
                default=list, 
                help_text='Lista de tags para clasificación adicional (máximo 10)', 
                blank=True
            ),
        ),
        
        # Copiar IDs de game_type_new a game_type
        migrations.RunPython(
            copy_game_type_ids,
            restore_game_type_names,
        ),
        
        # Eliminar campo temporal game_type_new
        migrations.RemoveField(
            model_name='community',
            name='game_type_new',
        ),
        
        # Alterar game_type a ForeignKey
        migrations.AlterField(
            model_name='community',
            name='game_type',
            field=models.ForeignKey(
                help_text='Tipo de juego TCG asociado a esta comunidad', 
                on_delete=models.deletion.CASCADE, 
                related_name='communities', 
                to='communities.gametype'
            ),
        ),
    ]
