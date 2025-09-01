#!/usr/bin/env python
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from communities.models import CommunityCategory

# Crear categorías básicas
categories = [
    {'name': 'Meta Decks', 'description': 'Discusión sobre mazos competitivos y meta actual'},
    {'name': 'Casual Play', 'description': 'Juego casual y diversión'},
    {'name': 'Trading', 'description': 'Intercambio de cartas'},
    {'name': 'Rules & Strategy', 'description': 'Reglas del juego y estrategias'},
    {'name': 'General Discussion', 'description': 'Discusión general sobre TCG'},
    {'name': 'Collection', 'description': 'Colecciones y cartas raras'},
]

print("Creando categorías...")
for cat_data in categories:
    category, created = CommunityCategory.objects.get_or_create(
        name=cat_data['name'],
        defaults={
            'description': cat_data['description'],
            'is_active': True
        }
    )
    if created:
        print(f"✅ Creada: {category.name}")
    else:
        print(f"⚠️  Ya existe: {category.name}")

print(f"\nTotal categorías: {CommunityCategory.objects.count()}")
