"""
ViewSets para el sistema de notificaciones MVP con polling
Implementación para fase5-0001: APIs REST optimizadas
"""

from rest_framework import viewsets, status, filters
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django_filters.rest_framework import DjangoFilterBackend
from django.utils import timezone
from django.db.models import Q, Count
from django.core.paginator import Paginator
from datetime import timedelta

from .models import Notification, NotificationPreferences
from .serializers import (
    NotificationSerializer,
    NotificationListSerializer, 
    NotificationUnreadSerializer,
    NotificationCreateSerializer,
    NotificationPreferencesSerializer,
    NotificationStatsSerializer,
    NotificationBulkActionSerializer
)


class NotificationViewSet(viewsets.ModelViewSet):
    """
    ViewSet principal para notificaciones
    Soporte completo CRUD con endpoints optimizados para polling
    """
    
    permission_classes = [IsAuthenticated]
    filter_backends = [DjangoFilterBackend, filters.OrderingFilter]
    filterset_fields = ['type', 'is_read', 'priority']
    ordering_fields = ['created_at', 'priority']
    ordering = ['-created_at']
    
    def get_queryset(self):
        """Solo notificaciones del usuario autenticado"""
        return Notification.objects.filter(
            user=self.request.user
        ).select_related('content_type').order_by('-created_at')
    
    def get_serializer_class(self):
        """Usar diferentes serializers según la acción"""
        if self.action == 'list':
            return NotificationListSerializer
        elif self.action == 'unread':
            return NotificationUnreadSerializer
        elif self.action == 'create':
            return NotificationCreateSerializer
        return NotificationSerializer
    
    def list(self, request, *args, **kwargs):
        """
        Lista paginada de todas las notificaciones del usuario
        Soporte para filtros por tipo, estado de lectura y fecha
        """
        queryset = self.filter_queryset(self.get_queryset())
        
        # Paginación para evitar respuestas muy grandes
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)
    
    @action(detail=False, methods=['get'])
    def unread(self, request):
        """
        Endpoint optimizado para polling cada 30 segundos
        Solo retorna count + últimas 5 notificaciones no leídas
        """
        unread_notifications = Notification.objects.filter(
            user=request.user,
            is_read=False
        ).select_related('content_type').order_by('-created_at')[:5]
        
        unread_count = Notification.objects.filter(
            user=request.user,
            is_read=False
        ).count()
        
        serializer = NotificationUnreadSerializer(unread_notifications, many=True)
        
        return Response({
            'count': unread_count,
            'latest': serializer.data,
            'last_check': timezone.now(),
        })
    
    @action(detail=True, methods=['put', 'patch'])
    def mark_read(self, request, pk=None):
        """Marcar notificación individual como leída"""
        notification = self.get_object()
        
        if not notification.is_read:
            notification.mark_as_read()
            
        serializer = self.get_serializer(notification)
        return Response(serializer.data)
    
    @action(detail=False, methods=['put'])
    def mark_all_read(self, request):
        """Marcar todas las notificaciones como leídas"""
        updated_count = Notification.objects.filter(
            user=request.user,
            is_read=False
        ).update(
            is_read=True,
            read_at=timezone.now()
        )
        
        return Response({
            'message': f'{updated_count} notificaciones marcadas como leídas',
            'updated_count': updated_count
        })
    
    @action(detail=False, methods=['post'])
    def bulk_action(self, request):
        """Acciones en lote para múltiples notificaciones"""
        serializer = NotificationBulkActionSerializer(
            data=request.data,
            context={'request': request}
        )
        
        if serializer.is_valid():
            notification_ids = serializer.validated_data['notification_ids']
            action_type = serializer.validated_data['action']
            
            notifications = Notification.objects.filter(
                id__in=notification_ids,
                user=request.user
            )
            
            if action_type == 'mark_read':
                updated_count = notifications.filter(is_read=False).update(
                    is_read=True,
                    read_at=timezone.now()
                )
                message = f'{updated_count} notificaciones marcadas como leídas'
                
            elif action_type == 'mark_unread':
                updated_count = notifications.filter(is_read=True).update(
                    is_read=False,
                    read_at=None
                )
                message = f'{updated_count} notificaciones marcadas como no leídas'
                
            elif action_type == 'delete':
                deleted_count = notifications.delete()[0]
                message = f'{deleted_count} notificaciones eliminadas'
                updated_count = deleted_count
            
            return Response({
                'message': message,
                'updated_count': updated_count
            })
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['get'])
    def stats(self, request):
        """Estadísticas de notificaciones del usuario"""
        user_notifications = Notification.objects.filter(user=request.user)
        
        # Contadores básicos
        total_unread = user_notifications.filter(is_read=False).count()
        total_notifications = user_notifications.count()
        recent_count = user_notifications.filter(
            created_at__gte=timezone.now() - timedelta(days=7)
        ).count()
        
        # Breakdown por tipo de las no leídas
        unread_by_type = dict(
            user_notifications.filter(is_read=False)
            .values('type')
            .annotate(count=Count('type'))
            .values_list('type', 'count')
        )
        
        # Contadores específicos por tipo
        type_counts = {
            'new_posts_count': unread_by_type.get('NEW_POST', 0),
            'new_comments_count': unread_by_type.get('NEW_COMMENT', 0),
            'comment_replies_count': unread_by_type.get('COMMENT_REPLY', 0),
            'new_ratings_count': unread_by_type.get('NEW_RATING', 0),
        }
        
        stats_data = {
            'total_unread': total_unread,
            'unread_by_type': unread_by_type,
            'recent_count': recent_count,
            'total_notifications': total_notifications,
            'last_check': timezone.now(),
            **type_counts
        }
        
        serializer = NotificationStatsSerializer(stats_data)
        return Response(serializer.data)


class NotificationPreferencesViewSet(viewsets.ModelViewSet):
    """
    ViewSet para preferencias de notificaciones (fase5-0005)
    """
    
    permission_classes = [IsAuthenticated]
    serializer_class = NotificationPreferencesSerializer
    
    def get_queryset(self):
        """Solo preferencias del usuario autenticado"""
        return NotificationPreferences.objects.filter(user=self.request.user)
    
    def get_object(self):
        """Obtener o crear preferencias del usuario"""
        preferences, created = NotificationPreferences.objects.get_or_create(
            user=self.request.user
        )
        return preferences
    
    def list(self, request, *args, **kwargs):
        """Obtener preferencias del usuario (crear si no existen)"""
        preferences = self.get_object()
        serializer = self.get_serializer(preferences)
        return Response(serializer.data)
    
    def update(self, request, *args, **kwargs):
        """Actualizar preferencias del usuario"""
        preferences = self.get_object()
        serializer = self.get_serializer(
            preferences,
            data=request.data,
            partial=kwargs.pop('partial', True)
        )
        
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    @action(detail=False, methods=['post'])
    def reset_to_defaults(self, request):
        """Restaurar preferencias a valores por defecto"""
        preferences = self.get_object()
        
        # Restaurar a valores por defecto del modelo
        preferences.app_new_posts = True
        preferences.app_new_comments = True
        preferences.app_comment_replies = True
        preferences.app_new_ratings = True
        preferences.email_new_ratings = True
        preferences.email_important_comments = True
        preferences.email_weekly_summary = True
        preferences.summary_frequency = 'weekly'
        preferences.quiet_hours_start = None
        preferences.quiet_hours_end = None
        
        preferences.save()
        
        serializer = self.get_serializer(preferences)
        return Response({
            'message': 'Preferencias restauradas a valores por defecto',
            'preferences': serializer.data
        })


# API Views funcionales para casos específicos

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def notification_count(request):
    """
    Endpoint ultra-ligero solo para obtener contador de no leídas
    Para widgets que solo necesitan el badge number
    """
    count = Notification.objects.filter(
        user=request.user,
        is_read=False
    ).count()
    
    return Response({'unread_count': count})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def mark_notification_read(request, notification_id):
    """
    Endpoint específico para marcar una notificación como leída
    Alternativa REST a la acción del ViewSet
    """
    try:
        notification = Notification.objects.get(
            id=notification_id,
            user=request.user
        )
        notification.mark_as_read()
        
        return Response({
            'message': 'Notificación marcada como leída',
            'notification_id': notification_id,
            'read_at': notification.read_at
        })
        
    except Notification.DoesNotExist:
        return Response(
            {'error': 'Notificación no encontrada'},
            status=status.HTTP_404_NOT_FOUND
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def recent_notifications(request):
    """
    Endpoint para obtener notificaciones recientes (últimas 24 horas)
    Útil para pantallas de inicio o dashboards
    """
    since = timezone.now() - timedelta(hours=24)
    
    recent = Notification.objects.filter(
        user=request.user,
        created_at__gte=since
    ).select_related('content_type').order_by('-created_at')[:10]
    
    serializer = NotificationListSerializer(recent, many=True)
    
    return Response({
        'count': recent.count(),
        'notifications': serializer.data,
        'since': since
    })
