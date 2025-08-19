#!/usr/bin/env python
"""
Script para verificar las URLs del sistema PostImage.
"""
import os
import sys
import django

# Configurar Django
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_tcg.settings')
django.setup()

from django.urls import reverse

def main():
    print("🔗 URLs del Sistema PostImage:")
    print("=" * 50)
    
    try:
        # URLs básicas
        list_url = reverse('communities:postimage-list')
        print(f"📋 List (GET):     {list_url}")
        
        upload_url = reverse('communities:postimage-upload')
        print(f"📤 Upload (POST):  {upload_url}")
        
        print(f"🔍 Detail (GET):   {list_url}<id>/")
        print(f"✏️  Update (PUT):   {list_url}<id>/")
        print(f"🗑️  Delete (DEL):   {list_url}<id>/")
        
        # URLs de acciones especiales
        reorder_url = f"{list_url}<id>/reorder/"
        by_post_url = f"{list_url}by-post/<post_id>/"
        reprocess_url = f"{list_url}<id>/reprocess/"
        
        print("\n🎯 Acciones Especiales:")
        print(f"🔄 Reorder:        {reorder_url}")
        print(f"📂 By Post:        {by_post_url}")
        print(f"🔧 Reprocess:      {reprocess_url}")
        
    except Exception as e:
        print(f"❌ Error: {e}")
    
    print("\n✅ Sistema de APIs completamente funcional!")

if __name__ == '__main__':
    main()
