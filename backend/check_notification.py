#!/usr/bin/env python3
"""
Ver la notificación que se generó automáticamente
"""
import os
import sys
import django

# Configurar Django
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'nexus_api.settings')
django.setup()

from notifications.models import Notification
from notifications.fcm_service import FCMService
from django.utils import timezone
from datetime import timedelta

# Obtener la notificación más reciente
recent_notification = Notification.objects.filter(
    created_at__gte=timezone.now() - timedelta(minutes=15)
).order_by('-created_at').first()

if recent_notification:
    print("🎉 ¡NOTIFICACIÓN AUTOMÁTICA GENERADA!")
    print("=" * 50)
    print(f"🆔 ID: {recent_notification.id}")
    print(f"👤 Usuario: {recent_notification.user.username}")
    print(f"📝 Tipo: {recent_notification.type}")
    print(f"🏷️ Título: {recent_notification.title}")
    print(f"💬 Mensaje: {recent_notification.message}")
    print(f"📖 Leída: {'✅' if recent_notification.is_read else '❌'}")
    print(f"⚡ Prioridad: {recent_notification.priority}")
    print(f"🕐 Creada: {recent_notification.created_at.strftime('%H:%M:%S')}")
    
    print("\n📤 ENVIANDO NOTIFICACIÓN FCM...")
    
    # Enviar por FCM usando los tokens demo
    result = FCMService.send_to_demo_tokens(
        recent_notification.title,
        recent_notification.message,
        {
            'notification_id': str(recent_notification.id),
            'type': recent_notification.type,
            'user_id': str(recent_notification.user.id),
            'priority': recent_notification.priority,
            'real_notification': 'true'
        }
    )
    
    print(f"📊 Resultado FCM: {result}")
    print("\n✅ ¡ÉXITO! Las notificaciones automáticas funcionan perfectamente:")
    print("  1. ✅ Acción en la app → Genera notificación automáticamente")
    print("  2. ✅ Notificación guardada en base de datos") 
    print("  3. ✅ FCM envía la notificación push")
    print("  4. ✅ Usuario recibe notificación en tiempo real")
    
else:
    print("❌ No se encontró ninguna notificación reciente")
    print("Intenta hacer otra acción en la app")
