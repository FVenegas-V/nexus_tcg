"""
Management command para gestionar las reputaciones en Nexus TCG.
Permite recalcular, validar y mantener el sistema de reputación.
"""

from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.db import transaction
from django.db import models
from decimal import Decimal
import logging

from users.reputation import (
    calculate_user_reputation,
    get_reputation_breakdown,
    update_user_reputation_sync,
    validate_reputation_consistency
)
from users.tasks import (
    update_user_reputation_task,
    bulk_update_reputations_task,
    recalculate_all_reputations_task,
    validate_reputation_consistency_task
)

logger = logging.getLogger(__name__)
User = get_user_model()


class Command(BaseCommand):
    help = 'Gestiona el sistema de reputación de usuarios'

    def add_arguments(self, parser):
        parser.add_argument(
            'action',
            choices=[
                'recalculate',
                'validate',
                'update',
                'breakdown',
                'stats',
                'async-recalculate',
                'async-validate'
            ],
            help='Acción a realizar'
        )
        
        parser.add_argument(
            '--user',
            type=str,
            help='Username del usuario específico (para update/breakdown)'
        )
        
        parser.add_argument(
            '--user-id',
            type=int,
            help='ID del usuario específico (para update/breakdown)'
        )
        
        parser.add_argument(
            '--batch-size',
            type=int,
            default=100,
            help='Tamaño del lote para procesamiento masivo (default: 100)'
        )
        
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Solo mostrar lo que se haría sin ejecutar cambios'
        )
        
        parser.add_argument(
            '--force',
            action='store_true',
            help='Forzar operación sin confirmación'
        )
        
        parser.add_argument(
            '--verbose',
            action='store_true',
            help='Salida detallada'
        )

    def handle(self, *args, **options):
        """Maneja la ejecución del comando según la acción especificada."""
        
        action = options['action']
        self.verbose = options['verbose']
        
        try:
            if action == 'recalculate':
                self.handle_recalculate(options)
            elif action == 'validate':
                self.handle_validate(options)
            elif action == 'update':
                self.handle_update(options)
            elif action == 'breakdown':
                self.handle_breakdown(options)
            elif action == 'stats':
                self.handle_stats(options)
            elif action == 'async-recalculate':
                self.handle_async_recalculate(options)
            elif action == 'async-validate':
                self.handle_async_validate(options)
            else:
                raise CommandError(f"Acción no reconocida: {action}")
                
        except Exception as e:
            raise CommandError(f"Error ejecutando {action}: {e}")

    def handle_recalculate(self, options):
        """Recalcula reputaciones de usuarios."""
        
        # Obtener usuarios target
        if options['user'] or options['user_id']:
            user = self.get_target_user(options)
            users = [user]
            self.stdout.write(f"Recalculando reputación para usuario: {user.username}")
        else:
            # Todos los usuarios con valoraciones
            users = User.objects.filter(
                ratings_received__is_active=True
            ).distinct()
            
            total_count = users.count()
            
            if not options['force']:
                confirm = input(
                    f"¿Recalcular reputación para {total_count} usuarios? [y/N]: "
                )
                if confirm.lower() != 'y':
                    self.stdout.write("Operación cancelada.")
                    return
            
            self.stdout.write(f"Recalculando reputaciones para {total_count} usuarios...")
        
        # Procesar
        processed = 0
        errors = 0
        
        for user in users:
            try:
                if options['dry_run']:
                    # Solo calcular sin guardar
                    score, count = calculate_user_reputation(user)
                    self.stdout.write(
                        f"[DRY RUN] {user.username}: {score} ({count} valoraciones)"
                    )
                else:
                    # Actualizar reputación
                    old_score = user.reputation_score or Decimal('0.0')
                    new_score, count = update_user_reputation_sync(user)
                    
                    if self.verbose:
                        self.stdout.write(
                            f"{user.username}: {old_score} → {new_score} ({count} valoraciones)"
                        )
                
                processed += 1
                
                # Progress cada 50 usuarios
                if processed % 50 == 0:
                    self.stdout.write(f"Procesados: {processed}")
                    
            except Exception as e:
                errors += 1
                self.stderr.write(f"Error con usuario {user.username}: {e}")
        
        # Resultado final
        if options['dry_run']:
            self.stdout.write(
                self.style.SUCCESS(
                    f"[DRY RUN] Se procesarían {processed} usuarios"
                )
            )
        else:
            self.stdout.write(
                self.style.SUCCESS(
                    f"Recálculo completado: {processed} usuarios procesados, {errors} errores"
                )
            )

    def handle_validate(self, options):
        """Valida consistencia de reputaciones."""
        
        self.stdout.write("Validando consistencia de reputaciones...")
        
        try:
            report = validate_reputation_consistency(options['batch_size'])
            
            # Mostrar resultados
            self.stdout.write(f"Usuarios verificados: {report['total_users_checked']}")
            self.stdout.write(f"Usuarios procesados: {report['users_processed']}")
            self.stdout.write(f"Inconsistencias encontradas: {report['inconsistencies_found']}")
            
            if report['is_consistent']:
                self.stdout.write(
                    self.style.SUCCESS("✓ Todas las reputaciones son consistentes")
                )
            else:
                self.stdout.write(
                    self.style.WARNING(
                        f"⚠ Se encontraron {report['inconsistencies_found']} inconsistencias"
                    )
                )
                
                if self.verbose and report['inconsistencies']:
                    self.stdout.write("\nPrimeras inconsistencias:")
                    for inc in report['inconsistencies'][:10]:
                        if 'error' in inc:
                            self.stdout.write(f"  {inc['username']}: ERROR - {inc['error']}")
                        else:
                            self.stdout.write(
                                f"  {inc['username']}: "
                                f"esperado={inc['expected_score']}, "
                                f"almacenado={inc['stored_score']}"
                            )
                            
        except Exception as e:
            raise CommandError(f"Error en validación: {e}")

    def handle_update(self, options):
        """Actualiza reputación de un usuario específico."""
        
        user = self.get_target_user(options)
        
        self.stdout.write(f"Actualizando reputación para usuario: {user.username}")
        
        try:
            old_score = user.reputation_score or Decimal('0.0')
            old_count = user.reputation_count or 0
            
            if options['dry_run']:
                new_score, new_count = calculate_user_reputation(user)
                self.stdout.write(
                    f"[DRY RUN] {user.username}: "
                    f"{old_score} → {new_score} "
                    f"({old_count} → {new_count} valoraciones)"
                )
            else:
                new_score, new_count = update_user_reputation_sync(user)
                self.stdout.write(
                    self.style.SUCCESS(
                        f"Reputación actualizada: "
                        f"{old_score} → {new_score} "
                        f"({old_count} → {new_count} valoraciones)"
                    )
                )
                
        except Exception as e:
            raise CommandError(f"Error actualizando usuario {user.username}: {e}")

    def handle_breakdown(self, options):
        """Muestra desglose detallado de reputación de un usuario."""
        
        user = self.get_target_user(options)
        
        try:
            breakdown = get_reputation_breakdown(user)
            
            self.stdout.write(f"\n=== Desglose de Reputación: {user.username} ===")
            self.stdout.write(f"Puntuación Final: {breakdown['final_score']}")
            self.stdout.write(f"Total Valoraciones: {breakdown['total_ratings']}")
            
            if breakdown['ratings_data']:
                self.stdout.write("\nDesglose por Valoración:")
                self.stdout.write(
                    f"{'Evaluador':<15} {'Puntos':<8} {'Peso Temp':<10} "
                    f"{'Cred. Eval':<10} {'Contribución':<12}"
                )
                self.stdout.write("-" * 65)
                
                for rating_data in breakdown['ratings_data'][:10]:  # Primeras 10
                    self.stdout.write(
                        f"{rating_data['evaluator_username']:<15} "
                        f"{rating_data['rating_value']:<8} "
                        f"{rating_data['temporal_weight']:<10.3f} "
                        f"{rating_data['evaluator_credibility']:<10.3f} "
                        f"{rating_data['weighted_contribution']:<12.3f}"
                    )
                
                if len(breakdown['ratings_data']) > 10:
                    remaining = len(breakdown['ratings_data']) - 10
                    self.stdout.write(f"... y {remaining} valoraciones más")
            
            self.stdout.write(f"\nFactores del Algoritmo:")
            for factor, value in breakdown['algorithm_factors'].items():
                self.stdout.write(f"  {factor}: {value:.3f}")
                
        except Exception as e:
            raise CommandError(f"Error obteniendo desglose para {user.username}: {e}")

    def handle_stats(self, options):
        """Muestra estadísticas generales del sistema de reputación."""
        
        try:
            # Estadísticas básicas
            total_users = User.objects.count()
            users_with_reputation = User.objects.filter(
                reputation_score__isnull=False
            ).count()
            users_with_ratings = User.objects.filter(
                ratings_received__is_active=True
            ).distinct().count()
            
            # Estadísticas de reputación
            avg_reputation = User.objects.filter(
                reputation_score__isnull=False
            ).aggregate(
                avg_score=models.Avg('reputation_score'),
                max_score=models.Max('reputation_score'),
                min_score=models.Min('reputation_score')
            )
            
            # Distribución por rangos
            from django.db import models
            
            ranges = [
                (0, 1, "Muy Baja"),
                (1, 2, "Baja"),
                (2, 3, "Media"),
                (3, 4, "Alta"),
                (4, 5, "Muy Alta")
            ]
            
            self.stdout.write("=== Estadísticas del Sistema de Reputación ===")
            self.stdout.write(f"Total de usuarios: {total_users}")
            self.stdout.write(f"Usuarios con reputación: {users_with_reputation}")
            self.stdout.write(f"Usuarios con valoraciones: {users_with_ratings}")
            
            if avg_reputation['avg_score']:
                self.stdout.write(f"\nPuntuaciones:")
                self.stdout.write(f"  Promedio: {avg_reputation['avg_score']:.3f}")
                self.stdout.write(f"  Máxima: {avg_reputation['max_score']:.3f}")
                self.stdout.write(f"  Mínima: {avg_reputation['min_score']:.3f}")
                
                self.stdout.write(f"\nDistribución por rangos:")
                for min_val, max_val, label in ranges:
                    count = User.objects.filter(
                        reputation_score__gte=min_val,
                        reputation_score__lt=max_val
                    ).count()
                    percentage = (count / users_with_reputation * 100) if users_with_reputation > 0 else 0
                    self.stdout.write(f"  {label} ({min_val}-{max_val}): {count} ({percentage:.1f}%)")
            
        except Exception as e:
            raise CommandError(f"Error obteniendo estadísticas: {e}")

    def handle_async_recalculate(self, options):
        """Lanza recálculo asíncrono con Celery."""
        
        if not options['force']:
            confirm = input("¿Lanzar recálculo asíncrono de todas las reputaciones? [y/N]: ")
            if confirm.lower() != 'y':
                self.stdout.write("Operación cancelada.")
                return
        
        try:
            result = recalculate_all_reputations_task.delay()
            self.stdout.write(
                self.style.SUCCESS(
                    f"Tarea de recálculo lanzada: {result.id}"
                )
            )
            self.stdout.write("Usa 'celery inspect active' para monitorear el progreso")
            
        except Exception as e:
            raise CommandError(f"Error lanzando tarea asíncrona: {e}")

    def handle_async_validate(self, options):
        """Lanza validación asíncrona con Celery."""
        
        try:
            result = validate_reputation_consistency_task.delay()
            self.stdout.write(
                self.style.SUCCESS(
                    f"Tarea de validación lanzada: {result.id}"
                )
            )
            self.stdout.write("Usa 'celery inspect active' para monitorear el progreso")
            
        except Exception as e:
            raise CommandError(f"Error lanzando tarea asíncrona: {e}")

    def get_target_user(self, options):
        """Obtiene el usuario target desde las opciones."""
        
        if options['user_id']:
            try:
                return User.objects.get(id=options['user_id'])
            except User.DoesNotExist:
                raise CommandError(f"Usuario con ID {options['user_id']} no encontrado")
                
        elif options['user']:
            try:
                return User.objects.get(username=options['user'])
            except User.DoesNotExist:
                raise CommandError(f"Usuario '{options['user']}' no encontrado")
        else:
            raise CommandError("Especifica --user o --user-id para operaciones específicas")
