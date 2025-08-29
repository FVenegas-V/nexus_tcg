#!/usr/bin/env python
"""
Script para listar todas las URLs del proyecto
"""
import os
import sys
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from django.urls import get_resolver
from django.conf import settings

def show_urls(urllist=None, depth=0):
    if urllist is None:
        urllist = get_resolver().url_patterns
    
    for entry in urllist:
        if hasattr(entry, 'url_patterns'):
            # Es un include()
            print("  " * depth + f"📁 {entry.pattern}")
            show_urls(entry.url_patterns, depth + 1)
        else:
            # Es una URL individual
            print("  " * depth + f"🔗 {entry.pattern} -> {entry.callback}")

def main():
    print("🌐 === URLs DISPONIBLES EN EL PROYECTO ===")
    print()
    
    try:
        show_urls()
    except Exception as e:
        print(f"Error: {e}")
        
    print()
    print("🎯 Buscando específicamente 'ratings'...")
    resolver = get_resolver()
    
    # Buscar patterns que contengan 'ratings'
    def find_ratings_urls(urllist, prefix=""):
        for entry in urllist:
            if hasattr(entry, 'url_patterns'):
                new_prefix = prefix + str(entry.pattern)
                find_ratings_urls(entry.url_patterns, new_prefix)
            else:
                full_pattern = prefix + str(entry.pattern)
                if 'rating' in full_pattern.lower():
                    print(f"   📍 {full_pattern}")
    
    find_ratings_urls(resolver.url_patterns)

if __name__ == "__main__":
    main()
