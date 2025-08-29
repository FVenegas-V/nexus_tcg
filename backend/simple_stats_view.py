"""
Vista de función simple para probar el endpoint de stats sin ViewSet
"""
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import get_user_model
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from users.models import UserRating
from users.serializers import UserRatingDetailSerializer, UserRatingStatsSerializer

User = get_user_model()

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def simple_user_stats(request, user_id):
    """
    Endpoint simplificado para obtener estadísticas de usuario
    """
    print(f"🔍 Stats endpoint llamado para usuario {user_id}")
    
    try:
        user = User.objects.get(id=user_id)
        print(f"✅ Usuario encontrado: {user.username}")
    except User.DoesNotExist:
        print(f"❌ Usuario {user_id} no encontrado")
        return Response({'error': 'Usuario no encontrado'}, status=404)
    
    # Obtener resumen
    print("📊 Obteniendo resumen...")
    summary = UserRating.get_user_rating_summary(user)
    print(f"✅ Resumen: {summary}")
    
    # Obtener valoraciones recientes
    print("📋 Obteniendo valoraciones recientes...")
    recent_ratings = UserRating.objects.filter(
        rated_user=user, 
        is_active=True
    ).select_related('rater', 'rater__profile').order_by('-created_at')[:5]
    print(f"✅ Valoraciones recientes: {recent_ratings.count()}")
    
    # Preparar respuesta
    print("📦 Preparando respuesta...")
    stats_data = {
        'total_ratings': summary['total_ratings'],
        'average_rating': summary['average_rating'],
        'rating_distribution': summary['rating_distribution'],
        'recent_ratings': recent_ratings
    }
    
    serializer = UserRatingStatsSerializer(stats_data)
    
    response_data = {
        'user': {
            'id': user.id,
            'username': user.username
        },
        'stats': serializer.data
    }
    
    print("✅ Respuesta preparada exitosamente")
    return Response(response_data)
