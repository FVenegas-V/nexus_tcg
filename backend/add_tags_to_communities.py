"""
Script para agregar tags a las comunidades existentes.
"""
import os
import sys
import django

# Configurar Django
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from communities.models import Community

def add_tags_to_communities():
    """Agregar tags apropiados a cada comunidad."""
    
    print("Agregando tags a las comunidades...")
    
    # Magic Players Chile
    try:
        magic_community = Community.objects.get(name__icontains='Magic Players Chile')
        magic_community.tags = ['competitivo', 'torneos', 'drafts', 'casual', 'magic']
        magic_community.save()
        print(f"✅ Tags agregados a {magic_community.name}: {magic_community.tags}")
    except Community.DoesNotExist:
        print("❌ No se encontró Magic Players Chile")
    
    # Pokémon TCG Principiantes
    try:
        pokemon_community = Community.objects.get(name__icontains='Pokémon TCG')
        pokemon_community.tags = ['principiante', 'aprender', 'pokemon', 'casual', 'nuevo']
        pokemon_community.save()
        print(f"✅ Tags agregados a {pokemon_community.name}: {pokemon_community.tags}")
    except Community.DoesNotExist:
        print("❌ No se encontró Pokémon TCG Principiantes")
    
    # Yu-Gi-Oh! Meta Decks
    try:
        yugioh_community = Community.objects.get(name__icontains='Yu-Gi-Oh')
        yugioh_community.tags = ['meta', 'competitivo', 'estrategia', 'yugioh', 'avanzado']
        yugioh_community.save()
        print(f"✅ Tags agregados a {yugioh_community.name}: {yugioh_community.tags}")
    except Community.DoesNotExist:
        print("❌ No se encontró Yu-Gi-Oh! Meta Decks")
    
    # Dragon Ball Super
    try:
        dbs_community = Community.objects.get(name__icontains='Dragon Ball')
        dbs_community.tags = ['dragon-ball', 'anime', 'competitivo', 'casual', 'comunidad']
        dbs_community.save()
        print(f"✅ Tags agregados a {dbs_community.name}: {dbs_community.tags}")
    except Community.DoesNotExist:
        print("❌ No se encontró Dragon Ball Super")
    
    print("\n🎉 Proceso completado!")
    
    # Verificar que los tags se guardaron correctamente
    print("\nVerificando tags guardados:")
    all_communities = Community.objects.all()
    for community in all_communities:
        print(f"  {community.name}: {community.tags}")

if __name__ == '__main__':
    add_tags_to_communities()
