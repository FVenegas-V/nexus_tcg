#!/usr/bin/env python
"""
Script para verificar las calificaciones después del testing
"""
import os
import sys
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from users.models import User, UserRating
from datetime import datetime, timedelta

def main():
    print("🔍 === VERIFICACIÓN POST-TESTING DE CALIFICACIONES ===")
    print()
    
    # 1. Verificar calificaciones recientes (últimas 24 horas)
    print("1️⃣ Verificando calificaciones recientes...")
    recent_ratings = UserRating.objects.filter(
        created_at__gte=datetime.now() - timedelta(hours=24)
    ).order_by('-created_at')
    
    print(f"   📊 Calificaciones en últimas 24h: {recent_ratings.count()}")
    
    for rating in recent_ratings[:5]:  # Mostrar últimas 5
        print(f"   ⭐ {rating.rater.username} → {rating.rated_user.username}")
        print(f"      Puntuación: {rating.rating}/5 estrellas")
        print(f"      Tipo: {rating.interaction_type}")
        print(f"      Fecha: {rating.created_at}")
        if rating.comment:
            print(f"      Comentario: '{rating.comment[:50]}...'")
        print()
    
    # 2. Verificar usuarios específicos de testing
    print("2️⃣ Verificando usuarios de testing...")
    test_users = ['test_user_1', 'test_user_2']
    
    for username in test_users:
        try:
            user = User.objects.get(username=username)
            ratings_received = UserRating.objects.filter(rated_user=user).count()
            ratings_given = UserRating.objects.filter(rater=user).count()
            
            print(f"   👤 {username} (ID: {user.id})")
            print(f"      Calificaciones recibidas: {ratings_received}")
            print(f"      Calificaciones otorgadas: {ratings_given}")
            
            # Última calificación recibida
            last_received = UserRating.objects.filter(
                rated_user=user
            ).order_by('-created_at').first()
            
            if last_received:
                print(f"      Última recibida: {last_received.rating}⭐ de {last_received.rater.username}")
                print(f"      Fecha: {last_received.created_at}")
            
            print()
            
        except User.DoesNotExist:
            print(f"   ❌ Usuario {username} no encontrado")
    
    # 3. Estadísticas generales
    print("3️⃣ Estadísticas generales del sistema...")
    total_ratings = UserRating.objects.count()
    total_users = User.objects.count()
    avg_rating = UserRating.objects.aggregate(
        avg=django.db.models.Avg('rating')
    )['avg']
    
    print(f"   📈 Total calificaciones: {total_ratings}")
    print(f"   👥 Total usuarios: {total_users}")
    print(f"   📊 Promedio general: {avg_rating:.2f if avg_rating else 0}/5 estrellas")

if __name__ == "__main__":
    main()
