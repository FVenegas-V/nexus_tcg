"""
Serializers para las APIs de comunidades TCG.
"""
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.utils import timezone
from .models import Community, CommunityCategory, CommunityMembership, GameType
from .serializers.game_type import GameTypeListSerializer

User = get_user_model()


class UserBasicSerializer(serializers.ModelSerializer):
    """Serializer básico para información de usuario."""
    
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name']


class CommunityCategorySerializer(serializers.ModelSerializer):
    """Serializer para categorías de comunidades."""
    
    class Meta:
        model = CommunityCategory
        fields = [
            'id', 'name', 'slug', 'description', 'icon', 'color',
            'is_active', 'community_count', 'is_popular'
        ]


class CommunityListSerializer(serializers.ModelSerializer):
    """Serializer para lista de comunidades (información básica)."""
    
    category = CommunityCategorySerializer(read_only=True)
    game_type = GameTypeListSerializer(read_only=True)
    created_by = UserBasicSerializer(read_only=True)
    
    # Campos calculados
    is_full = serializers.ReadOnlyField()
    is_popular = serializers.ReadOnlyField()
    member_capacity_percentage = serializers.ReadOnlyField()
    
    class Meta:
        model = Community
        fields = [
            'id', 'name', 'slug', 'description', 'image_url',
            'game_type', 'difficulty_level', 'category',
            'is_public', 'requires_approval', 'max_members',
            'member_count', 'post_count', 'tags',
            'created_at', 'updated_at', 'created_by',
            # Campos calculados
            'is_full', 'is_popular', 'member_capacity_percentage'
        ]


class CommunityDetailSerializer(CommunityListSerializer):
    """Serializer para detalle completo de comunidad."""
    
    # Agregar campos adicionales para el detalle
    rules = serializers.CharField(read_only=True)
    
    class Meta(CommunityListSerializer.Meta):
        fields = CommunityListSerializer.Meta.fields + ['rules']


class CommunityMembershipSerializer(serializers.ModelSerializer):
    """Serializer para membresías de comunidades."""
    
    user = UserBasicSerializer(read_only=True)
    community = serializers.StringRelatedField(read_only=True)
    
    # Campos calculados
    is_staff = serializers.ReadOnlyField()
    can_moderate = serializers.ReadOnlyField()
    can_admin = serializers.ReadOnlyField()
    is_active = serializers.ReadOnlyField()
    
    class Meta:
        model = CommunityMembership
        fields = [
            'id', 'user', 'community', 'role', 'status',
            'joined_at', 'updated_at', 'notes',
            # Campos calculados
            'is_staff', 'can_moderate', 'can_admin', 'is_active'
        ]


class CommunityMembershipListSerializer(serializers.ModelSerializer):
    """Serializer simplificado para lista de miembros."""
    
    user = UserBasicSerializer(read_only=True)
    
    class Meta:
        model = CommunityMembership
        fields = ['id', 'user', 'role', 'status', 'joined_at']


class CommunityStatsSerializer(serializers.ModelSerializer):
    """Serializer para estadísticas de comunidad."""
    
    # Estadísticas adicionales
    active_members_count = serializers.SerializerMethodField()
    moderators_count = serializers.SerializerMethodField()
    recent_members_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Community
        fields = [
            'id', 'name', 'member_count', 'post_count',
            'active_members_count', 'moderators_count', 'recent_members_count',
            'is_full', 'is_popular', 'member_capacity_percentage'
        ]
    
    def get_active_members_count(self, obj):
        """Contar miembros activos."""
        return obj.memberships.filter(status='active').count()
    
    def get_moderators_count(self, obj):
        """Contar moderadores y admins."""
        return obj.memberships.filter(
            role__in=['moderator', 'admin'],
            status='active'
        ).count()
    
    def get_recent_members_count(self, obj):
        """Contar miembros que se unieron en los últimos 30 días."""
        from django.utils import timezone
        from datetime import timedelta
        
        thirty_days_ago = timezone.now() - timedelta(days=30)
        return obj.memberships.filter(
            joined_at__gte=thirty_days_ago,
            status='active'
        ).count()


# ===== SERIALIZERS DE MEMBRESÍA =====

class JoinCommunitySerializer(serializers.Serializer):
    """
    Serializer para unirse a una comunidad.
    Maneja validaciones específicas para el proceso de join.
    """
    
    def validate(self, attrs):
        """Validaciones personalizadas para unirse a comunidad."""
        user = self.context['request'].user
        community = self.context['community']
        
        # Verificar que no sea miembro ya
        if CommunityMembership.objects.filter(community=community, user=user).exists():
            raise serializers.ValidationError("Ya eres miembro de esta comunidad.")
        
        # Verificar límite de miembros
        if community.member_limit and community.member_count >= community.member_limit:
            raise serializers.ValidationError("Esta comunidad ha alcanzado el límite de miembros.")
        
        # Verificar que la comunidad esté activa
        if not community.is_active:
            raise serializers.ValidationError("Esta comunidad no está activa.")
        
        return attrs
    
    def create(self, validated_data):
        """Crear nueva membresía."""
        user = self.context['request'].user
        community = self.context['community']
        
        # Crear membresía con rol de miembro por defecto
        membership = CommunityMembership.objects.create(
            community=community,
            user=user,
            role='member',
            joined_at=timezone.now()
        )
        
        return membership


class LeaveCommunitySerializer(serializers.Serializer):
    """
    Serializer para salir de una comunidad.
    Maneja validaciones para el proceso de leave.
    """
    
    def validate(self, attrs):
        """Validaciones para salir de comunidad."""
        user = self.context['request'].user
        community = self.context['community']
        
        try:
            membership = CommunityMembership.objects.get(community=community, user=user)
        except CommunityMembership.DoesNotExist:
            raise serializers.ValidationError("No eres miembro de esta comunidad.")
        
        # Verificar si es el último admin
        if membership.role == 'admin':
            admin_count = CommunityMembership.objects.filter(
                community=community,
                role='admin'
            ).count()
            
            if admin_count <= 1:
                raise serializers.ValidationError(
                    "No puedes salir de la comunidad siendo el único administrador. "
                    "Transfiere el rol de administrador a otro miembro primero."
                )
        
        return attrs


class MembershipDetailSerializer(serializers.ModelSerializer):
    """
    Serializer detallado para membresías individuales.
    Incluye información del usuario y estadísticas.
    """
    
    user = serializers.SerializerMethodField()
    community_name = serializers.CharField(source='community.name', read_only=True)
    days_as_member = serializers.SerializerMethodField()
    can_edit_role = serializers.SerializerMethodField()
    
    class Meta:
        model = CommunityMembership
        fields = [
            'id', 'user', 'community_name', 'role', 'joined_at', 
            'days_as_member', 'can_edit_role'
        ]
        read_only_fields = ['id', 'joined_at']
    
    def get_user(self, obj):
        """Información básica del usuario."""
        return {
            'id': obj.user.id,
            'username': obj.user.username,
            'email': obj.user.email,
            'first_name': obj.user.first_name or '',
            'last_name': obj.user.last_name or ''
        }
    
    def get_days_as_member(self, obj):
        """Calcular días como miembro."""
        if obj.joined_at:
            return (timezone.now() - obj.joined_at).days
        return 0
    
    def get_can_edit_role(self, obj):
        """Verificar si el usuario actual puede editar el rol de esta membresía."""
        request = self.context.get('request')
        if not request or not request.user.is_authenticated:
            return False
        
        # Staff siempre puede
        if request.user.is_staff:
            return True
        
        # Solo admins pueden cambiar roles
        try:
            requester_membership = CommunityMembership.objects.get(
                community=obj.community,
                user=request.user
            )
            return requester_membership.role == 'admin'
        except CommunityMembership.DoesNotExist:
            return False


class MembershipListSerializer(serializers.ModelSerializer):
    """
    Serializer optimizado para listado de miembros.
    Versión ligera para mejor performance.
    """
    
    username = serializers.CharField(source='user.username', read_only=True)
    user_id = serializers.IntegerField(source='user.id', read_only=True)
    joined_days_ago = serializers.SerializerMethodField()
    
    class Meta:
        model = CommunityMembership
        fields = ['id', 'user_id', 'username', 'role', 'joined_at', 'joined_days_ago']
    
    def get_joined_days_ago(self, obj):
        """Días desde que se unió."""
        if obj.joined_at:
            return (timezone.now() - obj.joined_at).days
        return 0


class ChangeRoleSerializer(serializers.Serializer):
    """
    Serializer para cambiar rol de un miembro.
    Solo para admins de la comunidad.
    """
    
    new_role = serializers.ChoiceField(
        choices=['member', 'moderator', 'admin'],
        help_text="Nuevo rol para el miembro"
    )
    
    def validate_new_role(self, value):
        """Validar el nuevo rol."""
        membership = self.context['membership']
        
        # No permitir cambiar rol a sí mismo si es el único admin
        if membership.role == 'admin' and value != 'admin':
            admin_count = CommunityMembership.objects.filter(
                community=membership.community,
                role='admin'
            ).count()
            
            if admin_count <= 1:
                raise serializers.ValidationError(
                    "No puedes cambiar tu rol siendo el único administrador."
                )
        
        return value
    
    def update(self, instance, validated_data):
        """Actualizar rol del miembro."""
        instance.role = validated_data['new_role']
        instance.save()
        return instance


class CommunityMemberStatsSerializer(serializers.Serializer):
    """
    Serializer para estadísticas de miembros de una comunidad.
    """
    
    total_members = serializers.IntegerField()
    admins_count = serializers.IntegerField()
    moderators_count = serializers.IntegerField()
    members_count = serializers.IntegerField()
    new_members_this_week = serializers.IntegerField()
    new_members_this_month = serializers.IntegerField()
    
    def to_representation(self, instance):
        """Calcular estadísticas dinámicamente."""
        community = instance
        one_week_ago = timezone.now() - timezone.timedelta(days=7)
        one_month_ago = timezone.now() - timezone.timedelta(days=30)
        
        # Obtener todas las membresías de una vez
        memberships = CommunityMembership.objects.filter(community=community)
        
        # Contar por roles
        role_counts = {}
        new_week = 0
        new_month = 0
        
        for membership in memberships:
            # Contar roles
            role_counts[membership.role] = role_counts.get(membership.role, 0) + 1
            
            # Contar nuevos miembros
            if membership.joined_at:
                if membership.joined_at >= one_week_ago:
                    new_week += 1
                if membership.joined_at >= one_month_ago:
                    new_month += 1
        
        return {
            'total_members': len(memberships),
            'admins_count': role_counts.get('admin', 0),
            'moderators_count': role_counts.get('moderator', 0),
            'members_count': role_counts.get('member', 0),
            'new_members_this_week': new_week,
            'new_members_this_month': new_month
        }
