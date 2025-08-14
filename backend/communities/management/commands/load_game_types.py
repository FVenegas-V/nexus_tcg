"""
Comando para cargar datos iniciales de tipos de juegos TCG.
"""
from django.core.management.base import BaseCommand
from communities.models import GameType


class Command(BaseCommand):
    help = 'Carga datos iniciales de tipos de juegos TCG populares'

    def handle(self, *args, **options):
        game_types_data = [
            {
                'name': 'Magic: The Gathering',
                'slug': 'magic-the-gathering',
                'description': 'El juego de cartas coleccionables más popular del mundo, creado por Richard Garfield.',
                'publisher': 'Wizards of the Coast',
                'release_year': 1993,
                'min_players': 2,
                'max_players': 8,
                'is_featured': True,
            },
            {
                'name': 'Pokemon TCG',
                'slug': 'pokemon-tcg',
                'description': 'Juego de cartas basado en la popular franquicia Pokemon.',
                'publisher': 'The Pokemon Company',
                'release_year': 1996,
                'min_players': 2,
                'max_players': 2,
                'is_featured': True,
            },
            {
                'name': 'Yu-Gi-Oh!',
                'slug': 'yu-gi-oh',
                'description': 'Juego de cartas de duelos basado en el manga y anime Yu-Gi-Oh!',
                'publisher': 'Konami',
                'release_year': 1999,
                'min_players': 2,
                'max_players': 2,
                'is_featured': True,
            },
            {
                'name': 'Dragon Ball Super Card Game',
                'slug': 'dragon-ball-super',
                'description': 'Juego de cartas basado en la serie Dragon Ball Super.',
                'publisher': 'Bandai',
                'release_year': 2017,
                'min_players': 2,
                'max_players': 2,
                'is_featured': False,
            },
            {
                'name': 'One Piece Card Game',
                'slug': 'one-piece',
                'description': 'Juego de cartas basado en el manga y anime One Piece.',
                'publisher': 'Bandai',
                'release_year': 2022,
                'min_players': 2,
                'max_players': 2,
                'is_featured': False,
            },
            {
                'name': 'Digimon Card Game',
                'slug': 'digimon',
                'description': 'Juego de cartas basado en la franquicia Digimon.',
                'publisher': 'Bandai',
                'release_year': 2020,
                'min_players': 2,
                'max_players': 2,
                'is_featured': False,
            },
            {
                'name': 'Force of Will',
                'slug': 'force-of-will',
                'description': 'Juego de cartas con mecánicas únicas y arte anime.',
                'publisher': 'Force of Will Co.',
                'release_year': 2012,
                'min_players': 2,
                'max_players': 4,
                'is_featured': False,
            },
        ]

        created_count = 0
        updated_count = 0

        for game_data in game_types_data:
            game_type, created = GameType.objects.get_or_create(
                slug=game_data['slug'],
                defaults=game_data
            )
            
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'✓ Creado: {game_type.name}')
                )
            else:
                # Actualizar datos existentes
                for key, value in game_data.items():
                    setattr(game_type, key, value)
                game_type.save()
                updated_count += 1
                self.stdout.write(
                    self.style.WARNING(f'↻ Actualizado: {game_type.name}')
                )

        self.stdout.write(
            self.style.SUCCESS(
                f'\n🎯 Proceso completado:'
                f'\n  • Creados: {created_count} tipos de juego'
                f'\n  • Actualizados: {updated_count} tipos de juego'
                f'\n  • Total: {GameType.objects.count()} tipos de juego en la base de datos'
            )
        )
