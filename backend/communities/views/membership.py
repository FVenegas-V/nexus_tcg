"""
ViewSets especializados para gestión de membresías en comunidades.
"""
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404
from django.db import transaction
from django.utils import timezone

from ..models import Community, CommunityMembership
from ..serializers.membership import (
    JoinCommunitySerializer,
    LeaveCommunitySerializer,
    MembershipDetailSerializer,
    MembershipListSerializer,
    ChangeRoleSerializer,
    CommunityMemberStatsSerializer
)
from ..permissions import (
    IsCommunityMemberOrReadOnly,
    IsCommunityModeratorOrAdmin,
    IsCommunityAdmin,
    CanJoinCommunity,
    CanLeaveCommunity
)


class CommunityMembershipViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet para gestión de membresías de comunidades.
    
    Endpoints disponibles:
    - GET /api/communities/{id}/memberships/ - Listar miembros
    - GET /api/communities/{id}/memberships/{membership_id}/ - Detalle de membresía
    - POST /api/communities/{id}/join/ - Unirse a comunidad
    - DELETE /api/communities/{id}/leave/ - Salir de comunidad
    - PATCH /api/memberships/{membership_id}/change-role/ - Cambiar rol
    - GET /api/communities/{id}/stats/ - Estadísticas de membresía
    """
    
    permission_classes = [IsAuthenticated, IsCommunityMemberOrReadOnly]
    
    def get_queryset(self):
        """Obtener membresías de la comunidad específica."""
        community_id = self.kwargs.get('community_pk')
        if community_id:
            return CommunityMembership.objects.filter(
                community_id=community_id
            ).select_related('user', 'community').order_by('-joined_at')
        return CommunityMembership.objects.none()
    
    def get_serializer_class(self):
        """Seleccionar serializer según la acción."""
        if self.action == 'list':
            return MembershipListSerializer
        elif self.action in ['join', 'leave', 'change_role', 'stats']:
            # Estos se manejan directamente en las acciones
            return None
        return MembershipDetailSerializer
    
    @action(
        detail=False, 
        methods=['post'], 
        permission_classes=[IsAuthenticated, CanJoinCommunity],
        url_path='join'
    )
    def join(self, request, community_pk=None):
        """
        Unirse a una comunidad.
        
        POST /api/communities/{id}/join/
        """
        community = get_object_or_404(Community, pk=community_pk)
        
        serializer = JoinCommunitySerializer(
            data=request.data,
            context={'request': request, 'community': community}
        )
        
        if serializer.is_valid():
            with transaction.atomic():
                membership = serializer.save()
                
                # Actualizar contador de miembros en la comunidad
                community.refresh_from_db()
                
                response_serializer = MembershipDetailSerializer(
                    membership,
                    context={'request': request}
                )
                
                return Response({
                    'message': f'Te has unido exitosamente a {community.name}',
                    'membership': response_serializer.data
                }, status=status.HTTP_201_CREATED)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(
        detail=False,
        methods=['delete'],
        permission_classes=[IsAuthenticated, CanLeaveCommunity],
        url_path='leave'
    )
    def leave(self, request, community_pk=None):
        """
        Salir de una comunidad.
        
        DELETE /api/communities/{id}/leave/
        """
        community = get_object_or_404(Community, pk=community_pk)
        
        try:
            membership = CommunityMembership.objects.get(
                community=community,
                user=request.user
            )
        except CommunityMembership.DoesNotExist:
            return Response(
                {'error': 'No eres miembro de esta comunidad.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        serializer = LeaveCommunitySerializer(
            data={},
            context={'request': request, 'community': community}
        )
        
        if serializer.is_valid():
            with transaction.atomic():
                membership_role = membership.role
                membership.delete()
                
                # Refrescar estadísticas de la comunidad
                community.refresh_from_db()
                
                return Response({
                    'message': f'Has salido exitosamente de {community.name}',
                    'former_role': membership_role
                }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(
        detail=True,
        methods=['patch'],
        permission_classes=[IsAuthenticated, IsCommunityAdmin],
        url_path='change-role'
    )
    def change_role(self, request, pk=None, community_pk=None):
        """
        Cambiar rol de un miembro.
        Solo admins pueden cambiar roles.
        
        PATCH /api/memberships/{membership_id}/change-role/
        """
        membership = get_object_or_404(
            CommunityMembership,
            pk=pk,
            community_id=community_pk
        )
        
        # Verificar que el solicitante no se esté cambiando rol a sí mismo
        # si es el único admin
        if membership.user == request.user and membership.role == 'admin':
            admin_count = CommunityMembership.objects.filter(
                community=membership.community,
                role='admin'
            ).count()
            
            if admin_count <= 1:
                return Response(
                    {'error': 'No puedes cambiar tu propio rol siendo el único administrador.'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        serializer = ChangeRoleSerializer(
            membership,
            data=request.data,
            partial=True,
            context={'membership': membership}
        )
        
        if serializer.is_valid():
            with transaction.atomic():
                updated_membership = serializer.save()
                
                response_serializer = MembershipDetailSerializer(
                    updated_membership,
                    context={'request': request}
                )
                
                return Response({
                    'message': f'Rol actualizado exitosamente a {updated_membership.role}',
                    'membership': response_serializer.data
                }, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(
        detail=False,
        methods=['get'],
        permission_classes=[IsAuthenticated, IsCommunityMemberOrReadOnly],
        url_path='stats'
    )
    def stats(self, request, community_pk=None):
        """
        Obtener estadísticas de membresía de la comunidad.
        
        GET /api/communities/{id}/memberships/stats/
        """
        community = get_object_or_404(Community, pk=community_pk)
        
        serializer = CommunityMemberStatsSerializer(community)
        
        return Response({
            'community': {
                'id': community.id,
                'name': community.name
            },
            'stats': serializer.data
        }, status=status.HTTP_200_OK)
    
    @action(
        detail=False,
        methods=['get'],
        permission_classes=[IsAuthenticated, IsCommunityModeratorOrAdmin],
        url_path='moderator-view'
    )
    def moderator_view(self, request, community_pk=None):
        """
        Vista especial para moderadores con información adicional.
        
        GET /api/communities/{id}/memberships/moderator-view/
        """
        community = get_object_or_404(Community, pk=community_pk)
        
        # Obtener todas las membresías con información detallada
        memberships = CommunityMembership.objects.filter(
            community=community
        ).select_related('user').order_by('-joined_at')
        
        # Agregar información adicional para moderadores
        data = []
        for membership in memberships:
            member_data = MembershipDetailSerializer(
                membership,
                context={'request': request}
            ).data
            
            # Agregar información adicional para moderadores
            member_data.update({
                'user_email': membership.user.email,
                'user_date_joined': membership.user.date_joined,
                'user_last_login': membership.user.last_login,
                'is_email_verified': membership.user.email_verified
            })
            
            data.append(member_data)
        
        return Response({
            'community': community.name,
            'total_members': len(data),
            'members': data
        }, status=status.HTTP_200_OK)


class UserMembershipViewSet(viewsets.ReadOnlyModelViewSet):
    """
    ViewSet para que los usuarios vean sus propias membresías.
    
    Endpoints:
    - GET /api/my-memberships/ - Mis membresías
    - GET /api/my-memberships/{id}/ - Detalle de una membresía
    """
    
    serializer_class = MembershipDetailSerializer
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        """Obtener solo las membresías del usuario actual."""
        return CommunityMembership.objects.filter(
            user=self.request.user
        ).select_related('community').order_by('-joined_at')
    
    @action(detail=False, methods=['get'])
    def summary(self, request):
        """
        Resumen de membresías del usuario.
        
        GET /api/my-memberships/summary/
        """
        memberships = self.get_queryset()
        
        # Contar por roles
        role_counts = {}
        communities_by_game = {}
        
        for membership in memberships:
            # Contar roles
            role_counts[membership.role] = role_counts.get(membership.role, 0) + 1
            
            # Agrupar por tipo de juego
            game_type = membership.community.game_type
            if game_type not in communities_by_game:
                communities_by_game[game_type] = []
            communities_by_game[game_type].append({
                'id': membership.community.id,
                'name': membership.community.name,
                'role': membership.role
            })
        
        return Response({
            'total_memberships': len(memberships),
            'roles': role_counts,
            'communities_by_game': communities_by_game
        }, status=status.HTTP_200_OK)
