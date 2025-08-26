"""
Comando de Django para inicializar configuración del sistema anti-abuso
FASE 4-0006: Validaciones y Prevención de Abuso del Sistema de Reputación
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
from users.models import AntiAbuseConfig


class Command(BaseCommand):
    help = 'Inicializa la configuración del sistema anti-abuso'
    
    def add_arguments(self, parser):
        parser.add_argument(
            '--reset',
            action='store_true',
            help='Resetea configuración existente'
        )
        
        parser.add_argument(
            '--daily-limit',
            type=int,
            default=15,
            help='Límite diario de valoraciones (default: 15)'
        )
        
        parser.add_argument(
            '--weekly-limit',
            type=int,
            default=50,
            help='Límite semanal de valoraciones (default: 50)'
        )
        
        parser.add_argument(
            '--cooldown-days',
            type=int,
            default=5,
            help='Días de cooldown entre valoraciones del mismo usuario (default: 5)'
        )
    
    def handle(self, *args, **options):
        """Ejecuta la inicialización de configuración"""
        
        self.stdout.write(
            self.style.SUCCESS('🔧 Inicializando sistema anti-abuso...')
        )
        
        # Configuración de rate limiting
        rate_limiting_config = {
            'enabled': True,
            'daily_limit': options['daily_limit'],
            'weekly_limit': options['weekly_limit'],
            'cooldown_days': options['cooldown_days'],
            'description': 'Configuración para límites de valoraciones'
        }
        
        # Configuración de detección de gaming
        gaming_detection_config = {
            'enabled': True,
            'mutual_rating_threshold': 3,  # 3+ valoraciones mutuas = sospechoso
            'five_star_bias_threshold': 0.8,  # 80%+ de 5 estrellas = sospechoso
            'rating_burst_threshold': 10,  # 10+ valoraciones en 1 hora = sospechoso
            'same_ip_threshold': 5,  # 5+ valoraciones desde misma IP = sospechoso
            'new_account_days': 7,  # Cuentas < 7 días son nuevas
            'new_account_limit': 3,  # Nuevas cuentas solo 3 valoraciones/día
            'description': 'Configuración para detección de gaming del sistema'
        }
        
        # Configuración de moderación automática
        auto_moderation_config = {
            'enabled': True,
            'auto_flag_enabled': True,
            'auto_suspend_enabled': False,  # Por ahora manual
            'critical_flags_for_suspension': 3,
            'high_flags_for_warning': 2,
            'description': 'Configuración para moderación automática'
        }
        
        # Configuración de notificaciones
        notifications_config = {
            'enabled': True,
            'email_admins_on_flags': True,
            'email_users_on_suspension': True,
            'admin_emails': ['admin@nexustcg.com'],
            'description': 'Configuración de notificaciones del sistema'
        }
        
        configs = [
            ('rate_limiting', rate_limiting_config),
            ('gaming_detection', gaming_detection_config),
            ('auto_moderation', auto_moderation_config),
            ('notifications', notifications_config)
        ]
        
        created_count = 0
        updated_count = 0
        
        for key, config_value in configs:
            config_obj, created = AntiAbuseConfig.objects.get_or_create(
                key=key,
                defaults={
                    'value': config_value,
                    'description': config_value.get('description', ''),
                    'is_active': True
                }
            )
            
            if created:
                created_count += 1
                self.stdout.write(
                    self.style.SUCCESS(f'✅ Creada configuración: {key}')
                )
            elif options['reset']:
                config_obj.value = config_value
                config_obj.description = config_value.get('description', '')
                config_obj.updated_at = timezone.now()
                config_obj.save()
                updated_count += 1
                self.stdout.write(
                    self.style.WARNING(f'🔄 Actualizada configuración: {key}')
                )
            else:
                self.stdout.write(
                    self.style.HTTP_INFO(f'ℹ️  Ya existe configuración: {key}')
                )
        
        # Mostrar resumen
        self.stdout.write(
            self.style.SUCCESS(f'\n📊 Resumen de inicialización:')
        )
        self.stdout.write(f'   • Configuraciones creadas: {created_count}')
        self.stdout.write(f'   • Configuraciones actualizadas: {updated_count}')
        self.stdout.write(f'   • Total configuraciones: {len(configs)}')
        
        # Mostrar configuración actual
        self.stdout.write(
            self.style.SUCCESS(f'\n⚙️  Configuración actual:')
        )
        self.stdout.write(f'   • Límite diario: {rate_limiting_config["daily_limit"]} valoraciones')
        self.stdout.write(f'   • Límite semanal: {rate_limiting_config["weekly_limit"]} valoraciones')
        self.stdout.write(f'   • Cooldown entre usuarios: {rate_limiting_config["cooldown_days"]} días')
        self.stdout.write(f'   • Detección de gaming: {"✅ Habilitada" if gaming_detection_config["enabled"] else "❌ Deshabilitada"}')
        self.stdout.write(f'   • Moderación automática: {"✅ Habilitada" if auto_moderation_config["enabled"] else "❌ Deshabilitada"}')
        
        # Comandos útiles
        self.stdout.write(
            self.style.SUCCESS(f'\n💡 Comandos útiles:')
        )
        self.stdout.write('   • Ver configuración: python manage.py show_antiabuse_config')
        self.stdout.write('   • Resetear configuración: python manage.py init_antiabuse_config --reset')
        self.stdout.write('   • Cambiar límites: python manage.py init_antiabuse_config --daily-limit 20 --weekly-limit 60')
        
        self.stdout.write(
            self.style.SUCCESS('\n🎉 Sistema anti-abuso inicializado correctamente!')
        )
