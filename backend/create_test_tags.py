#!/usr/bin/env python
"""
Script para crear tags de prueba para la Fase 2
"""
import os
import sys
import django

# Configurar Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_tcg.settings')
django.setup()

from games.models import GameType
from communities.models import CommunityTag, Community

def create_test_tags():
    """Crear tags de prueba para las APIs de Fase 2"""
    
    print("🏷️ Creando tags de prueba para Fase 2...")
    
    # Tags básicos por tipo de juego
    tags_data = [
        # Tags generales
        {'name': 'competitivo', 'description': 'Para jugadores competitivos'},
        {'name': 'casual', 'description': 'Para jugadores casuales'},
        {'name': 'principiante', 'description': 'Para jugadores nuevos'},
        {'name': 'avanzado', 'description': 'Para jugadores experimentados'},
        {'name': 'torneo', 'description': 'Comunidades de torneos'},
        
        # Tags específicos por juego
        {'name': 'meta', 'description': 'Discusión del meta actual'},
        {'name': 'budget', 'description': 'Mazos económicos'},
        {'name': 'deck-building', 'description': 'Construcción de mazos'},
        {'name': 'trading', 'description': 'Intercambio de cartas'},
        {'name': 'collection', 'description': 'Colección de cartas'},
        
        # Tags de formato
        {'name': 'standard', 'description': 'Formato Standard'},
        {'name': 'legacy', 'description': 'Formato Legacy'},
        {'name': 'modern', 'description': 'Formato Modern'},
        {'name': 'limited', 'description': 'Formato Limited'},
        
        # Tags sociales
        {'name': 'local', 'description': 'Comunidad local'},
        {'name': 'online', 'description': 'Juego en línea'},
        {'name': 'espanol', 'description': 'Comunidad en español'},
        {'name': 'internacional', 'description': 'Comunidad internacional'},
    ]
    
    created_tags = []
    
    for tag_data in tags_data:
        tag, created = CommunityTag.objects.get_or_create(
            name=tag_data['name'],
            defaults={
                'description': tag_data['description'],
                'color': '#' + format(hash(tag_data['name']) % 0xFFFFFF, '06x'),  # Color generado
                'usage_count': 0
            }
        )
        
        if created:
            created_tags.append(tag)
            print(f"✅ Tag creado: {tag.name}")
        else:
            print(f"📌 Tag ya existe: {tag.name}")
    
    print(f"\n🎉 {len(created_tags)} tags nuevos creados")
    print(f"📊 Total de tags en sistema: {CommunityTag.objects.count()}")
    
    # Actualizar usage_count con valores aleatorios para testing
    import random
    for tag in CommunityTag.objects.all():
        tag.usage_count = random.randint(0, 50)
        tag.save()
    
    print("📈 Usage counts actualizados para testing")
    
    return created_tags

if __name__ == '__main__':
    try:
        created_tags = create_test_tags()
        print("\n✅ Script de creación de tags completado exitosamente")
        
        # Mostrar algunos tags populares
        popular_tags = CommunityTag.objects.order_by('-usage_count')[:5]
        print("\n🌟 Top 5 tags populares:")
        for tag in popular_tags:
            print(f"  - {tag.name} ({tag.usage_count} usos)")
            
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
