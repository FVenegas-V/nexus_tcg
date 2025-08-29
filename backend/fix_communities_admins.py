#!/usr/bin/env python3
"""
Script para solucionar el problema de memberships - agregar admins a comunidades sin admins
"""
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from users.models import User
from communities.models import Community, CommunityMembership

def fix_communities_without_admins():
    print("🔧 SOLUCIONANDO COMUNIDADES SIN ADMINS")
    print("=" * 50)
    
    # Buscar todas las comunidades
    communities = Community.objects.all()
    
    for community in communities:
        print(f"\n🏠 Revisando: {community.name}")
        
        # Contar admins actuales
        admin_count = CommunityMembership.objects.filter(
            community=community,
            role='admin'
        ).count()
        
        print(f"   👑 Admins actuales: {admin_count}")
        
        if admin_count == 0:
            print("   ⚠️  Sin admins - necesita un admin!")
            
            # Buscar un usuario apropiado para ser admin
            # Prioridad: admin del sistema, luego cualquier usuario staff
            potential_admin = User.objects.filter(is_staff=True).first()
            
            if not potential_admin:
                # Si no hay staff, usar el primer usuario activo
                potential_admin = User.objects.filter(is_active=True).first()
            
            if potential_admin:
                # Crear o actualizar membership para que sea admin
                membership, created = CommunityMembership.objects.get_or_create(
                    community=community,
                    user=potential_admin,
                    defaults={'role': 'admin'}
                )
                
                if created:
                    print(f"   ✅ Creado admin: {potential_admin.username}")
                else:
                    # Si ya existe, promover a admin
                    membership.role = 'admin'
                    membership.save()
                    print(f"   🔄 Promovido a admin: {potential_admin.username}")
            else:
                print("   ❌ No se encontró usuario para ser admin")
        else:
            print(f"   ✅ Ya tiene {admin_count} admin(s)")
    
    print(f"\n🎯 VERIFICANDO POISON DESPUÉS DEL FIX:")
    poison = User.objects.filter(username="Poison").first()
    if poison:
        memberships = CommunityMembership.objects.filter(user=poison)
        for membership in memberships:
            admin_count = CommunityMembership.objects.filter(
                community=membership.community,
                role='admin'
            ).count()
            print(f"   🏠 {membership.community.name}: Poison es {membership.role}, hay {admin_count} admin(s)")
    
    print(f"\n✅ Fix completado. Poison debería poder salir de las comunidades ahora.")

if __name__ == '__main__':
    fix_communities_without_admins()
