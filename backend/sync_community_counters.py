#!/usr/bin/env python
"""
Script para sincronizar contadores de posts en todas las comunidades.
Corrige discrepancias entre Community.post_count y el número real de posts activos.
"""
import os
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from communities.models import Community, Post


def sync_all_community_post_counts():
    """
    Sincronizar contadores de posts para todas las comunidades.
    """
    print("🔧 SINCRONIZANDO CONTADORES DE POSTS DE TODAS LAS COMUNIDADES")
    print("=" * 60)
    
    communities = Community.objects.all()
    total_fixed = 0
    total_checked = 0
    
    for community in communities:
        total_checked += 1
        
        # Contar posts reales activos
        real_count = Post.objects.filter(
            community=community, 
            is_active=True
        ).count()
        
        current_count = community.post_count
        
        print(f"\n📊 {community.name} (ID: {community.id})")
        print(f"   Contador actual: {current_count}")
        print(f"   Posts reales: {real_count}")
        
        # Solo actualizar si hay diferencia
        if current_count != real_count:
            community.post_count = real_count
            community.save()
            total_fixed += 1
            print(f"   ✅ CORREGIDO: {current_count} → {real_count}")
        else:
            print(f"   ✓ OK: Contador correcto")
    
    print("\n" + "=" * 60)
    print(f"🎯 RESUMEN:")
    print(f"   Comunidades revisadas: {total_checked}")
    print(f"   Comunidades corregidas: {total_fixed}")
    print(f"   Comunidades OK: {total_checked - total_fixed}")
    
    if total_fixed > 0:
        print(f"\n✅ Se corrigieron {total_fixed} contadores desactualizados")
    else:
        print(f"\n✅ Todos los contadores están sincronizados")


if __name__ == "__main__":
    sync_all_community_post_counts()
