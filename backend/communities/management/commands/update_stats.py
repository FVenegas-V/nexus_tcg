"""
Comando para actualizar estadísticas de GameTypes y Tags.
"""
from django.core.management.base import BaseCommand
from django.db.models import Count, Q
from communities.models import Community, GameType, CommunityTag


class Command(BaseCommand):
    help = 'Actualiza estadísticas de GameTypes y Tags basándose en las comunidades'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Ejecutar sin hacer cambios (solo mostrar lo que se haría)',
        )

    def handle(self, *args, **options):
        dry_run = options['dry_run']
        
        if dry_run:
            self.stdout.write(
                self.style.WARNING('🔍 MODO DRY-RUN: No se harán cambios reales')
            )
        
        self.stdout.write('📊 Actualizando estadísticas...\n')
        
        # Actualizar estadísticas de GameType
        self.update_game_type_stats(dry_run)
        
        # Actualizar estadísticas de Tags
        self.update_tag_stats(dry_run)
        
        self.stdout.write(
            self.style.SUCCESS('\n✅ Actualización de estadísticas completada')
        )

    def update_game_type_stats(self, dry_run):
        """Actualiza community_count para cada GameType."""
        self.stdout.write('🎮 Actualizando estadísticas de GameTypes...')
        
        game_types = GameType.objects.all()
        updated_count = 0
        
        for game_type in game_types:
            # Contar comunidades públicas asociadas
            actual_count = Community.objects.filter(
                game_type=game_type,
                is_public=True
            ).count()
            
            old_count = game_type.community_count
            
            if actual_count != old_count:
                if not dry_run:
                    game_type.community_count = actual_count
                    game_type.save(update_fields=['community_count'])
                
                self.stdout.write(
                    f'  📈 {game_type.name}: {old_count} → {actual_count} comunidades'
                )
                updated_count += 1
            else:
                self.stdout.write(
                    f'  ✓ {game_type.name}: {actual_count} comunidades (sin cambios)'
                )
        
        if updated_count > 0:
            self.stdout.write(
                self.style.SUCCESS(f'  ✅ {updated_count} GameTypes actualizados')
            )
        else:
            self.stdout.write('  ℹ️ Todas las estadísticas de GameTypes están actualizadas')

    def update_tag_stats(self, dry_run):
        """Actualiza usage_count para cada Tag."""
        self.stdout.write('\n🏷️ Actualizando estadísticas de Tags...')
        
        # Obtener todos los tags únicos usados en comunidades
        all_communities = Community.objects.filter(is_public=True).exclude(tags=[])
        tag_usage = {}
        
        for community in all_communities:
            for tag_name in community.tags:
                tag_usage[tag_name.lower()] = tag_usage.get(tag_name.lower(), 0) + 1
        
        # Actualizar tags existentes
        existing_tags = CommunityTag.objects.all()
        updated_count = 0
        created_count = 0
        
        for tag in existing_tags:
            actual_count = tag_usage.get(tag.name.lower(), 0)
            old_count = tag.usage_count
            
            if actual_count != old_count:
                if not dry_run:
                    tag.usage_count = actual_count
                    tag.save(update_fields=['usage_count'])
                
                self.stdout.write(
                    f'  📊 {tag.name}: {old_count} → {actual_count} usos'
                )
                updated_count += 1
            else:
                self.stdout.write(
                    f'  ✓ {tag.name}: {actual_count} usos (sin cambios)'
                )
        
        # Crear tags que no existen pero están siendo usados
        existing_tag_names = set(tag.name.lower() for tag in existing_tags)
        
        for tag_name, usage_count in tag_usage.items():
            if tag_name not in existing_tag_names:
                if not dry_run:
                    CommunityTag.objects.create(
                        name=tag_name,
                        usage_count=usage_count,
                        description=f'Tag creado automáticamente'
                    )
                
                self.stdout.write(
                    f'  🆕 {tag_name}: creado con {usage_count} usos'
                )
                created_count += 1
        
        if updated_count > 0 or created_count > 0:
            self.stdout.write(
                self.style.SUCCESS(
                    f'  ✅ {updated_count} tags actualizados, {created_count} tags creados'
                )
            )
        else:
            self.stdout.write('  ℹ️ Todas las estadísticas de tags están actualizadas')
