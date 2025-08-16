"""
Serializers para Community.
"""
from rest_framework import serializers
from ..models import Community


class CommunityListSerializer(serializers.ModelSerializer):
    """Serializer para listar comunidades (vista simple)."""
    
    category_name = serializers.CharField(source='category.name', read_only=True)
    member_count = serializers.IntegerField(read_only=True)
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)
    
    class Meta:
        model = Community
        fields = [
            'id', 'name', 'slug', 'description', 'category_name', 
            'game_type', 'difficulty_level', 'member_count', 
            'is_public', 'created_by_username', 'created_at'
        ]


class CommunityDetailSerializer(serializers.ModelSerializer):
    """Serializer para detalles completos de comunidad."""
    
    category = serializers.StringRelatedField(read_only=True)
    created_by = serializers.StringRelatedField(read_only=True)
    member_count = serializers.IntegerField(read_only=True)
    post_count = serializers.IntegerField(read_only=True)
    
    class Meta:
        model = Community
        fields = [
            'id', 'name', 'slug', 'description', 'category', 
            'game_type', 'difficulty_level', 'tags', 'rules',
            'is_public', 'member_count', 'post_count',
            'max_members', 'requires_approval', 'image_url', 'banner_url',
            'created_by', 'created_at', 'updated_at'
        ]


class CommunityStatsSerializer(serializers.ModelSerializer):
    """Serializer para estadísticas de comunidad."""
    
    member_count = serializers.IntegerField(read_only=True)
    post_count = serializers.IntegerField(read_only=True)
    active_members_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Community
        fields = [
            'id', 'name', 'member_count', 'post_count', 
            'active_members_count', 'created_at'
        ]
    
    def get_active_members_count(self, obj):
        """Contar miembros activos en los últimos 30 días."""
        from django.utils import timezone
        from datetime import timedelta
        
        thirty_days_ago = timezone.now() - timedelta(days=30)
        return obj.memberships.filter(
            status='active',
            last_activity__gte=thirty_days_ago
        ).count()


class CommunityMembershipSerializer(serializers.ModelSerializer):
    """Serializer para membresías (usado en CommunityDetailSerializer)."""
    
    user_username = serializers.CharField(source='user.username', read_only=True)
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    
    class Meta:
        model = Community
        fields = ['user_id', 'user_username', 'role', 'joined_at', 'status']


class CommunityMembershipListSerializer(serializers.ModelSerializer):
    """Serializer para listar membresías de una comunidad."""
    
    user = serializers.StringRelatedField(read_only=True)
    
    class Meta:
        model = Community
        fields = ['user', 'role', 'joined_at', 'status']
