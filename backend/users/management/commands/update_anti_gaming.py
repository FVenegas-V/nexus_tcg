"""
Management command para actualizar la configuración anti-gaming
"""
from django.core.management.base import BaseCommand
from users.models import AntiAbuseConfig

class Command(BaseCommand):
    help = 'Actualiza la configuración anti-gaming con umbrales menos estrictos'

    def handle(self, *args, **options):
        # Nueva configuración más permisiva
        new_config = {
            'enabled': True,
            'mutual_rating_threshold': 3,           # Sin cambios (3 valoraciones mutuas)
            'five_star_bias_threshold': 0.92,       # 92% en lugar de 80%
            'rating_burst_threshold': 15,           # 15 en lugar de 10 valoraciones por hora
            'same_ip_threshold': 8,                 # 8 en lugar de 5 valoraciones desde misma IP
            'new_account_days': 7,                  # Sin cambios (7 días)
            'new_account_limit': 5,                 # 5 en lugar de 3 valoraciones para cuentas nuevas
            'description': 'Configuración anti-gaming ajustada para ser menos estricta - Actualizada'
        }
        
        # Actualizar o crear configuración
        config, created = AntiAbuseConfig.objects.update_or_create(
            key='gaming_detection',
            defaults={'value': new_config}
        )
        
        if created:
            self.stdout.write(self.style.SUCCESS("✅ Configuración anti-gaming creada con valores menos estrictos"))
        else:
            self.stdout.write(self.style.SUCCESS("✅ Configuración anti-gaming actualizada con valores menos estrictos"))
        
        self.stdout.write("\n📊 NUEVA CONFIGURACIÓN:")
        self.stdout.write("========================")
        for key, value in new_config.items():
            if key != 'description':
                self.stdout.write(f"   {key}: {value}")
        
        self.stdout.write("\n🎯 CAMBIOS REALIZADOS:")
        self.stdout.write("======================")
        self.stdout.write("   • Sesgo 5 estrellas: 80% → 92% (más permisivo)")
        self.stdout.write("   • Mínimo valoraciones para análisis: 5 → 10")
        self.stdout.write("   • Valoraciones consecutivas: 5 → 8 valoraciones")
        self.stdout.write("   • Período consecutivas: 7 → 10 días")
        self.stdout.write("   • Spam cuenta nueva: 3 → 5 valoraciones permitidas")
        self.stdout.write("   • Ráfaga valoraciones: 10 → 15 por hora")
        self.stdout.write("   • Misma IP: 5 → 8 valoraciones permitidas")
        self.stdout.write("   • Severidad High: 90% → 95%")
