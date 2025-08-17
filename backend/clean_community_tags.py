"""
Script para limpiar los objetos CommunityTag que interfieren con el campo JSONField.
"""
import os
import sys
import django

# Configurar Django
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from communities.models import Community, CommunityTag

def clean_community_tags():
    """Limpiar objetos CommunityTag que interfieren."""
    
    print("Limpiando objetos CommunityTag...")
    
    # Mostrar objetos actuales
    tags = CommunityTag.objects.all()
    print(f"Objetos CommunityTag encontrados: {tags.count()}")
    for tag in tags:
        print(f"  - {tag.name}: {tag.display_name}")
    
    # Eliminar todos los objetos CommunityTag
    count = tags.count()
    tags.delete()
    
    print(f"✅ {count} objetos CommunityTag eliminados.")
    
    # Verificar que las comunidades conserven sus tags como strings
    print("\nVerificando Community.tags después de la limpieza:")
    communities = Community.objects.all()
    for c in communities:
        print(f"  {c.name}: {c.tags}")

if __name__ == '__main__':
    clean_community_tags()
