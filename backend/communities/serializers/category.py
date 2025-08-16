"""
Serializers para CommunityCategory.
"""
from rest_framework import serializers
from ..models import CommunityCategory


class CommunityCategorySerializer(serializers.ModelSerializer):
    """Serializer para categorías de comunidades."""
    
    community_count = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = CommunityCategory
        fields = [
            'id', 'name', 'slug', 'description', 'icon', 
            'color', 'community_count', 'is_active', 'created_at'
        ]
