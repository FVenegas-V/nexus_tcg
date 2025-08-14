"""
Serializers para el modelo GameType y funcionalidades relacionadas.
"""
from rest_framework import serializers
from communities.models import GameType


class GameTypeListSerializer(serializers.ModelSerializer):
    """Serializer básico para listado de tipos de juego."""
    
    class Meta:
        model = GameType
        fields = [
            'id', 'name', 'slug', 'logo_url', 
            'community_count', 'is_featured'
        ]
        read_only_fields = ['community_count']


class GameTypeDetailSerializer(serializers.ModelSerializer):
    """Serializer detallado para un tipo de juego específico."""
    
    class Meta:
        model = GameType
        fields = [
            'id', 'name', 'slug', 'description', 'logo_url',
            'publisher', 'release_year', 'min_players', 'max_players',
            'is_featured', 'community_count', 'created_at'
        ]
        read_only_fields = ['slug', 'community_count', 'created_at']


class GameTypeStatsSerializer(serializers.ModelSerializer):
    """Serializer para estadísticas de tipos de juego."""
    
    class Meta:
        model = GameType
        fields = ['id', 'name', 'slug', 'community_count', 'is_featured']


class FeaturedGameTypesSerializer(serializers.Serializer):
    """Serializer para respuesta de tipos de juego destacados y todos."""
    
    featured = GameTypeListSerializer(many=True, read_only=True)
    all = GameTypeListSerializer(many=True, read_only=True)
    stats = serializers.SerializerMethodField()
    
    def get_stats(self, obj):
        """Retorna estadísticas generales."""
        return {
            'total_games': obj.get('total_games', 0),
            'featured_count': obj.get('featured_count', 0),
            'total_communities': obj.get('total_communities', 0)
        }
