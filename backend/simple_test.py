#!/usr/bin/env python
"""
Test simple de tags en la base de datos.
"""
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')
django.setup()

from communities.models import CommunityTag

print("=== VERIFICANDO TAGS EN BASE DE DATOS ===")
tags = CommunityTag.objects.all()
print(f"Total tags en BD: {tags.count()}")

for tag in tags:
    print(f"  - ID: {tag.id}, Name: {tag.name}")
    print(f"    Usage Count: {tag.usage_count}")
    print(f"    Is Suggested: {tag.is_suggested}")
    print(f"    Display Name: {tag.display_name}")
    print(f"    Description: {tag.description}")
    print()

print("=== TESTING QUERYSET CON FILTROS ===")
# Simular el get_queryset del ViewSet
queryset = CommunityTag.objects.all().order_by('-usage_count', 'name')
print(f"Queryset count después del filtro: {queryset.count()}")

print("=== TESTING BÚSQUEDA ===")
# Simular búsqueda por 'c'
search_queryset = CommunityTag.objects.filter(
    name__icontains='c'
).order_by('-usage_count', 'name')
print(f"Búsqueda por 'c' encontró: {search_queryset.count()} tags")

for tag in search_queryset:
    print(f"  - {tag.name}")
