"""
Serializers para el modelo CommunityTag y funcionalidades relacionadas.
"""
from rest_framework import serializers
from communities.models import CommunityTag


class CommunityTagSerializer(serializers.ModelSerializer):
    """Serializer básico para tags de comunidades."""
    
    class Meta:
        model = CommunityTag
        fields = [
            'id', 'name', 'display_name', 'description',
            'usage_count', 'is_suggested'
        ]
        read_only_fields = ['usage_count']


class TagAutocompleteSerializer(serializers.ModelSerializer):
    """Serializer para autocompletado de tags."""
    
    class Meta:
        model = CommunityTag
        fields = ['name', 'display_name', 'usage_count']


class PopularTagsSerializer(serializers.ModelSerializer):
    """Serializer para tags populares."""
    
    class Meta:
        model = CommunityTag
        fields = ['name', 'display_name', 'usage_count', 'description']


class TagStatsSerializer(serializers.Serializer):
    """Serializer para estadísticas de tags."""
    
    total_tags = serializers.IntegerField()
    popular_tags = PopularTagsSerializer(many=True)
    suggested_tags = TagAutocompleteSerializer(many=True)
