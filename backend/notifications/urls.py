"""
URLs para el sistema de notificaciones MVP
Rutas optimizadas para polling y gestión de notificaciones
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

# Router para ViewSets
router = DefaultRouter()
router.register(r'notifications', views.NotificationViewSet, basename='notification')
router.register(r'preferences', views.NotificationPreferencesViewSet, basename='notification-preferences')

# URLs específicas
urlpatterns = [
    # ViewSet routes
    path('', include(router.urls)),
    
    # Endpoints funcionales específicos
    path('count/', views.notification_count, name='notification-count'),
    path('recent/', views.recent_notifications, name='recent-notifications'),
    path('<int:notification_id>/read/', views.mark_notification_read, name='mark-notification-read'),
    
    # FCM Testing endpoint (Fase 5-0006)
    path('test-fcm/', views.test_fcm_notification, name='test-fcm-notification'),
]

"""
Estructura de URLs resultante:

ViewSet URLs (automáticas):
- GET    /api/notifications/                    - Lista paginada de notificaciones
- POST   /api/notifications/                    - Crear notificación (uso interno)
- GET    /api/notifications/{id}/               - Detalle de notificación
- PUT    /api/notifications/{id}/               - Actualizar notificación
- DELETE /api/notifications/{id}/               - Eliminar notificación

Acciones especiales del ViewSet:
- GET    /api/notifications/unread/             - [POLLING] Notificaciones no leídas (optimizada)
- PUT    /api/notifications/{id}/mark_read/     - Marcar individual como leída
- PUT    /api/notifications/mark_all_read/      - Marcar todas como leídas
- POST   /api/notifications/bulk_action/        - Acciones en lote
- GET    /api/notifications/stats/              - Estadísticas del usuario

Preferencias:
- GET    /api/preferences/                      - Obtener preferencias (crear si no existen)
- PUT    /api/preferences/                      - Actualizar preferencias
- POST   /api/preferences/reset_to_defaults/    - Restaurar valores por defecto

Endpoints funcionales:
- GET    /api/count/                            - Solo contador de no leídas (ultra-ligero)
- GET    /api/recent/                           - Notificaciones recientes (24h)
- POST   /api/{id}/read/                        - Marcar como leída (alternativa REST)

Endpoints principales para polling:
1. /api/notifications/unread/    - Cada 30s para verificar nuevas notificaciones
2. /api/count/                   - Para widgets que solo necesitan el badge number
3. /api/notifications/           - Para pantalla completa de notificaciones
"""
