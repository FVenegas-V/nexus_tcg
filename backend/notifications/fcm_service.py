"""
Firebase Cloud Messaging Service para Nexus TCG
Fase 5-0006: Demo de notificaciones push

Servicio simplificado para demostración que complementa el sistema polling existente.
Actualizado para usar Firebase Admin SDK en lugar de pyfcm.
"""

import firebase_admin
from firebase_admin import credentials, messaging
from django.conf import settings
import logging
import os
from typing import Optional, Dict, Any, List

logger = logging.getLogger(__name__)


class FCMService:
    """
    Servicio para envío de notificaciones push via Firebase Cloud Messaging
    
    Diseñado para complementar (no reemplazar) el sistema de polling existente.
    Enfocado en notificaciones cuando la app está cerrada/en background.
    Actualizado para usar Firebase Admin SDK.
    """
    
    _initialized = False
    _app = None
    
    @classmethod
    def initialize(cls):
        """Inicializar Firebase Admin SDK (solo una vez)"""
        if cls._initialized:
            return True
        
        try:
            # Verificar si FCM está habilitado
            if not getattr(settings, 'ENABLE_FCM_DEMO', False):
                logger.info("[FCMService] FCM deshabilitado (ENABLE_FCM_DEMO=False)")
                return False
            
            # Ruta al archivo de credenciales
            cred_path = os.path.join(settings.BASE_DIR, 'firebase-service-account.json')
            
            if not os.path.exists(cred_path):
                logger.warning(f"[FCMService] Archivo de credenciales no encontrado: {cred_path}")
                return False
            
            # Inicializar Firebase Admin
            cred = credentials.Certificate(cred_path)
            cls._app = firebase_admin.initialize_app(cred)
            
            cls._initialized = True
            logger.info("[FCMService] Firebase Admin SDK inicializado correctamente")
            return True
            
        except Exception as e:
            logger.error(f"[FCMService] Error inicializando Firebase: {e}")
            return False
    
    @classmethod
    def is_available(cls) -> bool:
        """Verificar si FCM está disponible y configurado"""
        return cls._initialized or cls.initialize()
    
    @classmethod
    def send_notification(
        cls, 
        token: str, 
        title: str, 
        body: str, 
        data: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        Enviar notificación FCM a un dispositivo específico
        
        Args:
            token: FCM registration token del dispositivo
            title: Título de la notificación
            body: Cuerpo de la notificación
            data: Datos adicionales (opcional)
            
        Returns:
            bool: True si se envió exitosamente, False en caso contrario
        """
        if not cls.is_available():
            logger.debug("[FCMService] FCM no disponible, saltando envío")
            return False
            
        if not token:
            logger.warning("[FCMService] Token vacío, no se puede enviar")
            return False
        
        try:
            # Preparar datos adicionales para la notificación
            notification_data = data or {}
            
            # Convertir todos los valores a string (requerido por FCM)
            string_data = {}
            for key, value in notification_data.items():
                string_data[key] = str(value)
            
            # Agregar datos predeterminados
            string_data.update({
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                'sound': 'default'
            })
            
            logger.info(f"[FCMService] Enviando notificación: {title}")
            logger.debug(f"[FCMService] Token: {token[:20]}...")
            logger.debug(f"[FCMService] Body: {body}")
            
            # Construir mensaje FCM
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data=string_data,
                token=token,
                android=messaging.AndroidConfig(
                    priority='high',
                    notification=messaging.AndroidNotification(
                        title=title,
                        body=body,
                        click_action='FLUTTER_NOTIFICATION_CLICK',
                        sound='default',
                        tag='nexus_tcg_notification',
                        priority='high',
                    ),
                    data=string_data
                )
            )
            
            # Enviar mensaje
            response = messaging.send(message)
            logger.info(f"[FCMService] Notificación enviada correctamente: {response}")
            return True
            
        except Exception as e:
            logger.error(f"[FCMService] Error enviando notificación: {e}")
            return False
    
    @classmethod
    def send_to_demo_token(
        cls, 
        title: str, 
        body: str, 
        data: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        Enviar notificación al token hardcodeado para demo
        
        Args:
            title: Título de la notificación
            body: Cuerpo de la notificación  
            data: Datos adicionales (opcional)
            
        Returns:
            bool: True si se envió exitosamente, False en caso contrario
        """
        demo_token = getattr(settings, 'FCM_DEMO_TOKEN', '')
        
        if not demo_token:
            logger.debug("[FCMService] FCM_DEMO_TOKEN no configurado")
            return False
            
        return cls.send_notification(demo_token, title, body, data)
    
    @classmethod
    def send_to_demo_tokens(
        cls, 
        title: str, 
        body: str, 
        data: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Enviar notificación a todos los tokens de demo configurados
        
        Args:
            title: Título de la notificación
            body: Cuerpo de la notificación  
            data: Datos adicionales (opcional)
            
        Returns:
            Dict con resultados del envío
        """
        # Obtener tokens de la configuración (separados por comas)
        demo_tokens_str = getattr(settings, 'FCM_DEMO_TOKENS', '')
        
        if not demo_tokens_str:
            logger.debug("[FCMService] FCM_DEMO_TOKENS no configurado")
            return {'success': 0, 'failure': 0, 'errors': ['No demo tokens configured']}
        
        # Procesar tokens (limpiar espacios y filtrar vacíos)
        tokens = [token.strip() for token in demo_tokens_str.split(',') if token.strip()]
        
        if not tokens:
            logger.debug("[FCMService] No hay tokens válidos en FCM_DEMO_TOKENS")
            return {'success': 0, 'failure': 0, 'errors': ['No valid tokens found']}
        
        logger.info(f"[FCMService] Enviando a {len(tokens)} tokens de demo")
        return cls.send_to_multiple_tokens(tokens, title, body, data)
    
    @classmethod
    def send_to_multiple_tokens(
        cls, 
        tokens: List[str], 
        title: str, 
        body: str, 
        data: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Enviar notificación a múltiples dispositivos usando send individual
        
        Args:
            tokens: Lista de FCM registration tokens
            title: Título de la notificación
            body: Cuerpo de la notificación
            data: Datos adicionales (opcional)
            
        Returns:
            Dict con resultados del envío
        """
        if not cls.is_available():
            return {'success': 0, 'failure': len(tokens), 'errors': ['FCM no disponible']}
            
        if not tokens:
            return {'success': 0, 'failure': 0, 'errors': ['No tokens provided']}
        
        try:
            logger.info(f"[FCMService] Enviando a {len(tokens)} dispositivos: {title}")
            
            success_count = 0
            failure_count = 0
            errors = []
            
            # Enviar individualmente a cada token
            for i, token in enumerate(tokens):
                try:
                    success = cls.send_notification(token, title, body, data)
                    if success:
                        success_count += 1
                        logger.debug(f"[FCMService] Token {i+1}/{len(tokens)}: ✅ Éxito")
                    else:
                        failure_count += 1
                        logger.debug(f"[FCMService] Token {i+1}/{len(tokens)}: ❌ Falló")
                except Exception as e:
                    failure_count += 1
                    error_msg = f"Token {i+1}: {str(e)}"
                    errors.append(error_msg)
                    logger.error(f"[FCMService] {error_msg}")
            
            logger.info(f"[FCMService] Completado: {success_count} éxitos, {failure_count} fallos")
            
            return {
                'success': success_count,
                'failure': failure_count,
                'errors': errors if errors else None
            }
            
        except Exception as e:
            logger.error(f"[FCMService] Error en envío múltiple: {e}")
            return {
                'success': 0,
                'failure': len(tokens),
                'errors': [str(e)]
            }


# Funciones helper para uso en toda la aplicación
def send_fcm_notification(
    title: str, 
    body: str, 
    token: Optional[str] = None, 
    data: Optional[Dict[str, Any]] = None
) -> bool:
    """
    Función helper para envío rápido de notificaciones FCM
    
    Args:
        title: Título de la notificación
        body: Cuerpo de la notificación
        token: Token específico (si no se proporciona, usa el token demo)
        data: Datos adicionales (opcional)
        
    Returns:
        bool: True si se envió exitosamente
    """
    if token:
        return FCMService.send_notification(token, title, body, data)
    else:
        return FCMService.send_to_demo_token(title, body, data)


def send_fcm_to_demo(title: str, body: str, data: Optional[Dict[str, Any]] = None) -> bool:
    """
    Función helper específica para envío al token demo
    
    Args:
        title: Título de la notificación
        body: Cuerpo de la notificación
        data: Datos adicionales (opcional)
        
    Returns:
        bool: True si se envió exitosamente
    """
    return FCMService.send_to_demo_token(title, body, data)


def send_fcm_to_all_demos(title: str, body: str, data: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """
    Función helper para envío a todos los tokens de demo
    
    Args:
        title: Título de la notificación
        body: Cuerpo de la notificación
        data: Datos adicionales (opcional)
        
    Returns:
        Dict con resultados del envío
    """
    return FCMService.send_to_demo_tokens(title, body, data)
