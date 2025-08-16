#!/usr/bin/env python
"""
Script para inicializar datos básicos necesarios para el funcionamiento de la app.
"""
import os
import sys
import django

# Setup Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from communities.models import GameType, CommunityCategory

def create_basic_data():
    """Crear datos básicos necesarios."""
    print("🎯 Creando datos básicos...")
    
    # Crear GameTypes básicos
    game_types = [
        {"name": "Magic: The Gathering", "description": "El juego de cartas coleccionables más popular del mundo"},
        {"name": "Pokémon TCG", "description": "Juego basado en la famosa franquicia Pokémon"},
        {"name": "Yu-Gi-Oh!", "description": "Juego de cartas de duelos estratégicos"},
        {"name": "Dragon Ball Super", "description": "Juego basado en la serie Dragon Ball"},
        {"name": "One Piece", "description": "Juego basado en el manga y anime One Piece"},
    ]
    
    for gt_data in game_types:
        game_type, created = GameType.objects.get_or_create(
            name=gt_data["name"],
            defaults={"description": gt_data["description"]}
        )
        if created:
            print(f"  ✅ Creado GameType: {game_type.name}")
        else:
            print(f"  📋 Ya existe GameType: {game_type.name}")
    
    # Crear CommunityCategories básicas
    categories = [
        {"name": "Competitivo", "description": "Comunidades enfocadas en torneos y competición"},
        {"name": "Casual", "description": "Comunidades para juego relajado y social"},
        {"name": "Coleccionistas", "description": "Comunidades enfocadas en colección e intercambio"},
        {"name": "Principiantes", "description": "Comunidades para nuevos jugadores"},
    ]
    
    for cat_data in categories:
        category, created = CommunityCategory.objects.get_or_create(
            name=cat_data["name"],
            defaults={"description": cat_data["description"]}
        )
        if created:
            print(f"  ✅ Creada Category: {category.name}")
        else:
            print(f"  📋 Ya existe Category: {category.name}")
    
    print("🎉 ¡Datos básicos creados exitosamente!")

if __name__ == "__main__":
    create_basic_data()
