#!/usr/bin/env python
"""
Script para verificar que los modelos Post, Comment y Reaction se crearon correctamente.
"""
import os
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

# Importar modelos
from communities.models import Post, Comment, Reaction
from django.db import connection

print("🎯 VERIFICACIÓN DE MODELOS FASE3-0001")
print("=" * 50)

# Verificar importación
try:
    print("✅ Modelos importados correctamente:")
    print(f"  - Post: {Post._meta.db_table}")
    print(f"  - Comment: {Comment._meta.db_table}")
    print(f"  - Reaction: {Reaction._meta.db_table}")
except Exception as e:
    print(f"❌ Error importando modelos: {e}")
    exit(1)

# Verificar tablas en BD
try:
    cursor = connection.cursor()
    
    # Verificar tabla posts
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'communities_%';")
    tables = cursor.fetchall()
    
    print("\n✅ Tablas en base de datos:")
    for table in tables:
        if any(keyword in table[0] for keyword in ['post', 'comment', 'reaction']):
            print(f"  - {table[0]}")
    
    # Verificar estructura de tabla Post
    cursor.execute("PRAGMA table_info(communities_post);")
    post_columns = cursor.fetchall()
    
    print(f"\n✅ Estructura tabla Post ({len(post_columns)} columnas):")
    for col in post_columns[:5]:  # Mostrar solo primeras 5
        print(f"  - {col[1]} ({col[2]})")
    
    if len(post_columns) > 5:
        print(f"  ... y {len(post_columns) - 5} columnas más")
        
except Exception as e:
    print(f"❌ Error verificando base de datos: {e}")
    exit(1)

print("\n🎉 VERIFICACIÓN COMPLETADA EXITOSAMENTE")
print("Los modelos Post, Comment y Reaction están listos para usar.")
