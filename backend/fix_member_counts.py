#!/usr/bin/env python
"""
Script para corregir los member_count de todas las comunidades.
Recalcula basándose en las membresías activas reales.
"""

import os
import sys
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from communities.models import Community, CommunityMembership

def fix_member_counts():
    """Recalcular y corregir todos los member_count de comunidades."""
    print("🔧 Iniciando corrección de member_count...")
    
    communities = Community.objects.all()
    
    for community in communities:
        # Contar membresías activas reales
        real_member_count = CommunityMembership.objects.filter(
            community=community,
            status='active'
        ).count()
        
        # Comparar con el valor actual
        if community.member_count != real_member_count:
            print(f"📊 {community.name}:")
            print(f"   - Actual: {community.member_count} miembros")
            print(f"   - Real: {real_member_count} miembros")
            print(f"   - Diferencia: {real_member_count - community.member_count}")
            
            # Actualizar
            community.member_count = real_member_count
            community.save()
            print(f"   ✅ Corregido a {real_member_count} miembros")
        else:
            print(f"✅ {community.name}: {community.member_count} miembros (correcto)")
    
    print("\n🎉 Corrección completada!")

if __name__ == "__main__":
    fix_member_counts()
