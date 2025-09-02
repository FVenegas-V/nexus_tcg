# notifications/email_service.py
"""
Sistema de email fallback para notificaciones críticas
Fase 5-0004: Envío inteligente con deduplicación y rate limiting
"""

from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.conf import settings
from django.utils import timezone
from django.db import transaction
from datetime import timedelta
import logging

from .models import Notification

logger = logging.getLogger(__name__)


class NotificationEmailService:
    """
    Servicio para envío de emails de notificaciones con deduplicación inteligente
    """
    
    # Rate limiting: máximo de emails por usuario por hora
    MAX_EMAILS_PER_HOUR = 5
    
    # Tipos de notificación que requieren email inmediato
    CRITICAL_TYPES = [
        'security_alert',  # Alertas de seguridad
        'community_moderation',  # Moderación de comunidad
    ]
    
    # Tipos que se pueden agrupar en digest diario
    DIGEST_TYPES = [
        'new_post',
        'new_comment', 
        'post_like',
        'community_invite'
    ]
    
    @classmethod
    def should_send_email(cls, notification):
        """
        Determina si una notificación debe enviar email inmediato
        
        Args:
            notification: Instancia de Notification
            
        Returns:
            bool: True si debe enviar email
        """
        user = notification.user
        
        # Verificar preferencias del usuario
        prefs = getattr(user, 'notification_preferences', None)
        if not prefs or not prefs.email_enabled:
            return False
            
        # Verificar si el email está verificado
        if not user.email_verified:
            return False
            
        # Mapear type del modelo a tipos de email
        email_type = cls._map_notification_type(notification.type)
        
        # Notificaciones críticas siempre se envían
        if email_type in cls.CRITICAL_TYPES:
            if prefs.email_critical:
                return True
        
        # Para notificaciones normales, verificar preferencias
        if email_type in cls.DIGEST_TYPES:
            # Verificar preferencia específica del tipo
            if email_type == 'new_post' and prefs.email_posts:
                return cls._check_rate_limit(user)
            elif email_type == 'new_comment' and prefs.email_comments:
                return cls._check_rate_limit(user)
            elif email_type == 'post_like' and prefs.email_reactions:
                return cls._check_rate_limit(user)
            elif email_type == 'community_invite' and prefs.email_invites:
                return cls._check_rate_limit(user)
                
        return False
    
    @classmethod
    def _map_notification_type(cls, model_type):
        """
        Mapea el campo 'type' del modelo a tipos de email
        
        Args:
            model_type: Valor del campo 'type' del modelo Notification
            
        Returns:
            str: Tipo de email correspondiente
        """
        type_mapping = {
            'NEW_POST': 'new_post',
            'NEW_COMMENT': 'new_comment',
            'COMMENT_REPLY': 'new_comment',
            'NEW_RATING': 'post_like',
            'COMMUNITY_JOIN': 'community_invite',
            'COMMUNITY_MENTION': 'new_post',
            # Agregar tipos críticos cuando se definan
            'SECURITY_ALERT': 'security_alert',
            'MODERATION_ACTION': 'community_moderation',
        }
        
    @classmethod
    def get_model_types_for_digest(cls):
        """
        Retorna los valores del campo 'type' del modelo que corresponden a DIGEST_TYPES
        
        Returns:
            list: Lista de tipos del modelo para digest
        """
        model_types = []
        reverse_mapping = {
            'new_post': ['NEW_POST', 'COMMUNITY_MENTION'],
            'new_comment': ['NEW_COMMENT', 'COMMENT_REPLY'],
            'post_like': ['NEW_RATING'],
            'community_invite': ['COMMUNITY_JOIN'],
        }
        
        for email_type in cls.DIGEST_TYPES:
            model_types.extend(reverse_mapping.get(email_type, []))
            
        return model_types
    
    @classmethod
    def get_model_types_for_critical(cls):
        """
        Retorna los valores del campo 'type' del modelo que corresponden a CRITICAL_TYPES
        
        Returns:
            list: Lista de tipos del modelo críticos
        """
        model_types = []
        reverse_mapping = {
            'security_alert': ['SECURITY_ALERT'],
            'community_moderation': ['MODERATION_ACTION'],
        }
        
        for email_type in cls.CRITICAL_TYPES:
            model_types.extend(reverse_mapping.get(email_type, []))
            
        return model_types
    
    @classmethod
    def _check_rate_limit(cls, user):
        """
        Verifica el rate limit para emails del usuario
        
        Args:
            user: Usuario a verificar
            
        Returns:
            bool: True si puede enviar email
        """
        hour_ago = timezone.now() - timedelta(hours=1)
        
        # Contar emails enviados en la última hora
        recent_count = Notification.objects.filter(
            user=user,
            email_sent=True,
            created_at__gte=hour_ago
        ).count()
        
        return recent_count < cls.MAX_EMAILS_PER_HOUR
    
    @classmethod
    def send_notification_email(cls, notification):
        """
        Envía email para una notificación específica
        
        Args:
            notification: Instancia de Notification
            
        Returns:
            bool: True si el email se envió exitosamente
        """
        if not cls.should_send_email(notification):
            return False
            
        try:
            # Preparar contexto del email
            context = cls._prepare_email_context(notification)
            
            # Determinar template según el tipo
            email_type = cls._map_notification_type(notification.type)
            template_name = cls._get_template_name(email_type)
            
            # Renderizar contenido
            html_content = render_to_string(template_name, context)
            plain_content = cls._generate_plain_text(notification)
            
            # Enviar email
            success = send_mail(
                subject=cls._get_email_subject(notification),
                message=plain_content,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[notification.user.email],
                html_message=html_content,
                fail_silently=False,
            )
            
            if success:
                # Marcar como enviado
                with transaction.atomic():
                    notification.email_sent = True
                    notification.email_sent_at = timezone.now()
                    notification.save(update_fields=['email_sent', 'email_sent_at'])
                    
                logger.info(f"Email enviado para notificación {notification.id} a {notification.user.email}")
                return True
                
        except Exception as e:
            logger.error(f"Error enviando email para notificación {notification.id}: {str(e)}")
            
            # En desarrollo, mostrar en consola
            if settings.DEBUG:
                print(f"[EMAIL DEBUG] Para: {notification.user.email}")
                print(f"[EMAIL DEBUG] Asunto: {cls._get_email_subject(notification)}")
                print(f"[EMAIL DEBUG] Mensaje: {notification.message}")
                
        return False
    
    @classmethod
    def _prepare_email_context(cls, notification):
        """
        Prepara el contexto para renderizar el template de email
        
        Args:
            notification: Instancia de Notification
            
        Returns:
            dict: Contexto para el template
        """
        return {
            'notification': notification,
            'user': notification.user,
            'app_name': 'Nexus TCG',
            'frontend_url': getattr(settings, 'FRONTEND_URL', 'http://localhost:3000'),
            'unsubscribe_url': f"{getattr(settings, 'FRONTEND_URL', 'http://localhost:3000')}/notifications/preferences",
            'timestamp': notification.created_at,
        }
    
    @classmethod
    def _get_template_name(cls, notification_type):
        """
        Obtiene el nombre del template según el tipo de notificación
        
        Args:
            notification_type: Tipo de notificación
            
        Returns:
            str: Nombre del template
        """
        template_map = {
            'new_post': 'emails/notifications/new_post.html',
            'new_comment': 'emails/notifications/new_comment.html',
            'post_like': 'emails/notifications/post_reaction.html',
            'community_invite': 'emails/notifications/community_invite.html',
            'security_alert': 'emails/notifications/security_alert.html',
            'community_moderation': 'emails/notifications/moderation.html',
        }
        
        return template_map.get(notification_type, 'emails/notifications/generic.html')
    
    @classmethod
    def _get_email_subject(cls, notification):
        """
        Genera el asunto del email según el tipo de notificación
        
        Args:
            notification: Instancia de Notification
            
        Returns:
            str: Asunto del email
        """
        subject_map = {
            'new_post': 'Nuevo post en tu comunidad',
            'new_comment': 'Nuevo comentario en tu post', 
            'post_like': 'Tu post recibió una reacción',
            'community_invite': 'Invitación a comunidad',
            'security_alert': '🔒 Alerta de seguridad',
            'community_moderation': '⚠️ Acción de moderación',
        }
        
        email_type = cls._map_notification_type(notification.type)
        base_subject = subject_map.get(email_type, 'Nueva notificación')
        return f"Nexus TCG - {base_subject}"
    
    @classmethod
    def _generate_plain_text(cls, notification):
        """
        Genera versión en texto plano del email
        
        Args:
            notification: Instancia de Notification
            
        Returns:
            str: Contenido en texto plano
        """
        return f"""
Nexus TCG - Notificación

Hola {notification.user.username},

{notification.message}

---
Este email fue enviado porque tienes habilitadas las notificaciones por email.
Puedes cambiar tus preferencias en: {getattr(settings, 'FRONTEND_URL', 'http://localhost:3000')}/notifications/preferences

Saludos,
El equipo de Nexus TCG
        """.strip()
    
    @classmethod
    def send_daily_digest(cls, user):
        """
        Envía un digest diario con notificaciones agrupadas
        
        Args:
            user: Usuario para enviar digest
            
        Returns:
            bool: True si se envió exitosamente
        """
        # Obtener notificaciones no leídas del día
        yesterday = timezone.now() - timedelta(days=1)
        digest_types = cls.get_model_types_for_digest()
        notifications = Notification.objects.filter(
            user=user,
            is_read=False,
            created_at__gte=yesterday,
            type__in=digest_types,
            email_sent=False  # Solo las que no se enviaron individualmente
        ).order_by('-created_at')
        
        if not notifications.exists():
            return False
            
        try:
            # Agrupar por tipo (convertir a email type)
            grouped = {}
            for notif in notifications:
                email_type = cls._map_notification_type(notif.type)
                if email_type not in grouped:
                    grouped[email_type] = []
                grouped[email_type].append(notif)
            
            # Preparar contexto
            context = {
                'user': user,
                'grouped_notifications': grouped,
                'total_count': notifications.count(),
                'app_name': 'Nexus TCG',
                'frontend_url': getattr(settings, 'FRONTEND_URL', 'http://localhost:3000'),
                'unsubscribe_url': f"{getattr(settings, 'FRONTEND_URL', 'http://localhost:3000')}/notifications/preferences",
            }
            
            # Renderizar y enviar
            html_content = render_to_string('emails/notifications/daily_digest.html', context)
            plain_content = cls._generate_digest_plain_text(user, grouped, notifications.count())
            
            success = send_mail(
                subject=f"Nexus TCG - Resumen diario ({notifications.count()} notificaciones)",
                message=plain_content,
                from_email=settings.DEFAULT_FROM_EMAIL,
                recipient_list=[user.email],
                html_message=html_content,
                fail_silently=False,
            )
            
            if success:
                # Marcar todas como enviadas por email
                notifications.update(
                    email_sent=True,
                    email_sent_at=timezone.now()
                )
                logger.info(f"Digest diario enviado a {user.email} con {notifications.count()} notificaciones")
                return True
                
        except Exception as e:
            logger.error(f"Error enviando digest diario a {user.email}: {str(e)}")
            
        return False
    
    @classmethod 
    def _generate_digest_plain_text(cls, user, grouped_notifications, total_count):
        """
        Genera versión en texto plano del digest diario
        """
        content = f"""
Nexus TCG - Resumen Diario

Hola {user.username},

Tienes {total_count} notificaciones nuevas:

"""
        
        for notif_type, notifications in grouped_notifications.items():
            type_name = {
                'new_post': 'Nuevos posts',
                'new_comment': 'Nuevos comentarios',
                'post_like': 'Reacciones a tus posts',
                'community_invite': 'Invitaciones a comunidades'
            }.get(notif_type, notif_type)
            
            content += f"\n{type_name} ({len(notifications)}):\n"
            for notif in notifications[:3]:  # Máximo 3 por tipo
                content += f"- {notif.message}\n"
            
            if len(notifications) > 3:
                content += f"- ... y {len(notifications) - 3} más\n"
        
        content += f"""

Ve todas tus notificaciones en: {getattr(settings, 'FRONTEND_URL', 'http://localhost:3000')}/notifications

---
Puedes cambiar la frecuencia de estos emails en: {getattr(settings, 'FRONTEND_URL', 'http://localhost:3000')}/notifications/preferences

Saludos,
El equipo de Nexus TCG
        """.strip()
        
        return content
