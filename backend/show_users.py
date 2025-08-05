#!/usr/bin/env python
"""
Script para mostrar todos los usuarios registrados
"""

import os
import sys
import django
from pathlib import Path

# Configurar Django
sys.path.append(str(Path(__file__).parent))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from django.contrib.auth.models import User

def show_all_users():
    print("👥 TODOS LOS USUARIOS REGISTRADOS EN NEXUS TCG")
    print("=" * 50)
    
    users = User.objects.all().order_by('id')
    total = users.count()
    
    print(f"📊 Total de usuarios: {total}")
    print()
    
    if total == 0:
        print("🚫 No hay usuarios registrados")
    else:
        print("📋 Lista de usuarios:")
        print("-" * 80)
        print(f"{'ID':<3} | {'Username':<15} | {'Email':<25} | {'Activo':<6} | {'Fecha Registro'}")
        print("-" * 80)
        
        for user in users:
            fecha = user.date_joined.strftime('%Y-%m-%d %H:%M')
            activo = "✅ Sí" if user.is_active else "❌ No"
            print(f"{user.id:<3} | {user.username:<15} | {user.email:<25} | {activo:<6} | {fecha}")
        
        print("-" * 80)
        
        # Estadísticas adicionales
        active_users = users.filter(is_active=True).count()
        staff_users = users.filter(is_staff=True).count()
        superusers = users.filter(is_superuser=True).count()
        
        print()
        print("📈 ESTADÍSTICAS:")
        print(f"   Usuarios activos: {active_users}")
        print(f"   Staff: {staff_users}")
        print(f"   Superusuarios: {superusers}")
        
        # Mostrar último usuario registrado
        if users.exists():
            last_user = users.last()
            print()
            print(f"🆕 Último usuario registrado:")
            print(f"   {last_user.username} ({last_user.email})")
            print(f"   Registrado: {last_user.date_joined.strftime('%Y-%m-%d %H:%M:%S')}")

if __name__ == "__main__":
    show_all_users()
