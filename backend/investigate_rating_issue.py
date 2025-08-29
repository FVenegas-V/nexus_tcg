#!/usr/bin/env python3
"""
Script para investigar el problema de valoraciones no actualizadas
"""
import os
import sys
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from users.models import User, UserRating

def investigate_rating_issue():
    print("🔍 INVESTIGANDO PROBLEMA DE VALORACIONES")
    print("=" * 60)
    
    # Buscar usuarios
    poison = User.objects.filter(username="Poison").first()
    test10 = User.objects.filter(username="test10").first()
    
    if not poison:
        print("❌ Usuario Poison no encontrado")
        return
    if not test10:
        print("❌ Usuario test10 no encontrado")
        return
    
    print(f"👤 Evaluador: {poison.username} (ID: {poison.id})")
    print(f"👤 Evaluado: {test10.username} (ID: {test10.id})")
    
    # Buscar la valoración que acabas de crear
    rating = UserRating.objects.filter(
        rater=poison,
        rated_user=test10
    ).first()
    
    if rating:
        print(f"\n✅ VALORACIÓN ENCONTRADA:")
        print(f"   🔍 ID: {rating.id}")
        print(f"   ⭐ Rating: {rating.rating}/5")
        print(f"   💬 Comentario: {rating.comment}")
        print(f"   🗓️ Creada: {rating.created_at}")
        print(f"   🔄 Actualizada: {rating.updated_at}")
        print(f"   ✅ Activa: {rating.is_active}")
    else:
        print(f"\n❌ NO SE ENCONTRÓ VALORACIÓN de {poison.username} a {test10.username}")
        
        # Verificar si hay valoraciones del evaluador
        poison_ratings = UserRating.objects.filter(rater=poison)
        print(f"\n📊 Valoraciones hechas por {poison.username}: {poison_ratings.count()}")
        for r in poison_ratings:
            print(f"   - A {r.rated_user.username}: {r.rating}⭐ ({r.created_at})")
        
        # Verificar si hay valoraciones al evaluado
        test10_ratings = UserRating.objects.filter(rated_user=test10)
        print(f"\n📊 Valoraciones recibidas por {test10.username}: {test10_ratings.count()}")
        for r in test10_ratings:
            print(f"   - De {r.rater.username}: {r.rating}⭐ ({r.created_at})")
    
    # Verificar estadísticas de reputación de test10
    print(f"\n📈 ESTADÍSTICAS DE REPUTACIÓN DE {test10.username}:")
    
    # Calcular manualmente
    ratings_received = UserRating.objects.filter(rated_user=test10, is_active=True)
    if ratings_received.exists():
        avg_rating = sum(r.rating for r in ratings_received) / ratings_received.count()
        total_ratings = ratings_received.count()
        print(f"   📊 Promedio calculado: {avg_rating:.2f}")
        print(f"   📊 Total valoraciones: {total_ratings}")
        
        # Breakdown por rating
        breakdown = {}
        for r in ratings_received:
            breakdown[r.rating] = breakdown.get(r.rating, 0) + 1
        print(f"   📊 Breakdown: {breakdown}")
    else:
        print(f"   📊 No tiene valoraciones activas")
    
    # Verificar si hay signals o problemas en la actualización
    print(f"\n🔧 POSIBLES PROBLEMAS:")
    print(f"   1. La valoración se creó pero no está activa (is_active=False)")
    print(f"   2. Error en los signals que actualizan estadísticas")
    print(f"   3. Cache no actualizado en el frontend")
    print(f"   4. Problema en el endpoint de API")

if __name__ == '__main__':
    investigate_rating_issue()
