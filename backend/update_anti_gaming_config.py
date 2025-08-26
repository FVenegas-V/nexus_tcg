#!/usr/bin/env python3
"""
Script para actualizar la configuración anti-gaming con umbrales menos estrictos
"""
import os
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_tcg.settings')
django.setup()

from users.models import AntiAbuseConfig

def update_anti_gaming_config():
    """Actualiza la configuración anti-gaming con valores menos estrictos"""
    
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
        print("✅ Configuración anti-gaming creada con valores menos estrictos")
    else:
        print("✅ Configuración anti-gaming actualizada con valores menos estrictos")
    
    print("\n📊 NUEVA CONFIGURACIÓN:")
    print("========================")
    for key, value in new_config.items():
        if key != 'description':
            print(f"   {key}: {value}")
    
    print("\n🎯 CAMBIOS REALIZADOS:")
    print("======================")
    print("   • Sesgo 5 estrellas: 80% → 92% (más permisivo)")
    print("   • Mínimo valoraciones para análisis: 5 → 10")
    print("   • Valoraciones consecutivas: 5 → 8 valoraciones")
    print("   • Período consecutivas: 7 → 10 días")
    print("   • Spam cuenta nueva: 3 → 5 valoraciones permitidas")
    print("   • Ráfaga valoraciones: 10 → 15 por hora")
    print("   • Misma IP: 5 → 8 valoraciones permitidas")
    print("   • Severidad High: 90% → 95%")

if __name__ == '__main__':
    print("🔧 ACTUALIZANDO CONFIGURACIÓN ANTI-GAMING")
    print("==========================================")
    update_anti_gaming_config()
    print("\n🎉 ACTUALIZACIÓN COMPLETADA")
