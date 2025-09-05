// lib/core/services/fcm_service.dart

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/logger.dart';
import 'navigation_service.dart';

/// Servicio Firebase Cloud Messaging para Nexus TCG
/// Fase 5-0006: Demo de notificaciones push con navegación específica
///
/// Diseñado para complementar (no reemplazar) el sistema de polling existente.
/// FCM funciona cuando la app está cerrada/en background.
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _fcmToken;
  static bool _initialized = false;

  // === INICIALIZACIÓN ===

  /// Inicializar Firebase y FCM
  static Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      Logger.info('[FCMService] Inicializando Firebase Core y FCM...');

      // Inicializar Firebase Core
      await Firebase.initializeApp();

      // Solicitar permisos
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        Logger.info('[FCMService] ✅ Permisos de notificación concedidos');
      } else {
        Logger.warning('[FCMService] ❌ Permisos de notificación denegados');
        return false;
      }

      // Configurar handlers de mensajes
      await _setupMessageHandlers();

      // Obtener token FCM
      _fcmToken = await _getFCMToken();

      _initialized = true;
      Logger.info('[FCMService] ✅ FCM inicializado correctamente');
      return true;
    } catch (e) {
      Logger.error('[FCMService] ❌ Error inicializando FCM: $e');
      return false;
    }
  }

  // === HANDLERS DE MENSAJES ===

  /// Configurar handlers para diferentes estados de la app
  static Future<void> _setupMessageHandlers() async {
    // Mensaje cuando la app está en foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Mensaje cuando la app está en background
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Cuando el usuario toca una notificación
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Verificar si la app se abrió desde una notificación
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      Logger.info('[FCMService] App abierta desde notificación inicial');
      _handleNotificationTap(initialMessage);
    }
  }

  /// Handler para mensajes cuando la app está en foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    Logger.info('[FCMService] 📱 Mensaje recibido en foreground');
    Logger.info('Título: ${message.notification?.title}');
    Logger.info('Cuerpo: ${message.notification?.body}');
    Logger.debug('[FCMService] Foreground: Dejando que polling maneje la UI');
  }

  /// Handler para mensajes en background
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    Logger.info('[FCMService] 🔔 Mensaje recibido en background');
    Logger.info('Título: ${message.notification?.title}');
    Logger.info('Cuerpo: ${message.notification?.body}');
    // FCM automáticamente muestra la notificación del sistema
  }

  /// Handler para cuando el usuario toca una notificación
  static void _handleNotificationTap(RemoteMessage message) {
    Logger.info('[FCMService] 👆 Usuario tocó notificación');
    Logger.info('Título: ${message.notification?.title}');
    Logger.info('Datos: ${message.data}');

    // 🎯 NAVEGACIÓN ESPECÍFICA IMPLEMENTADA
    _performSpecificNavigation(message);
  }

  /// Realizar navegación específica según los datos de la notificación
  static Future<void> _performSpecificNavigation(RemoteMessage message) async {
    try {
      String? type = message.data['type'];
      String? userId = message.data['user_id'];
      String? navigateTo = message.data['navigate_to'];

      Logger.info(
        '[FCMService] Notificación tocada - Tipo: $type, Usuario: $userId',
      );
      Logger.info('[FCMService] 🎯 Navegación solicitada: $navigateTo');

      // 🎯 USAR NAVIGATION SERVICE PARA NAVEGACIÓN REAL
      await NavigationService.handleFCMNavigation(message.data);
    } catch (e) {
      Logger.error('[FCMService] Error manejando tap de notificación: $e');
      // Fallback en caso de error
      await NavigationService.navigateTo('/notifications');
    }
  }

  // === TOKEN MANAGEMENT ===

  /// Obtener token FCM
  static Future<String?> _getFCMToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        Logger.info(
          '[FCMService] Token FCM obtenido: ${token.substring(0, 20)}...',
        );
        return token;
      } else {
        Logger.warning('[FCMService] No se pudo obtener token FCM');
        return null;
      }
    } catch (e) {
      Logger.error('[FCMService] Error obteniendo token FCM: $e');
      return null;
    }
  }

  // === API PÚBLICA ===

  /// Verificar si FCM está inicializado y disponible
  static bool get isInitialized => _initialized;

  /// Obtener el token FCM actual
  static String? get token => _fcmToken;

  /// Re-obtener token FCM (útil si se necesita refrescar)
  static Future<String?> refreshToken() async {
    return await _getFCMToken();
  }

  /// Verificar estado de permisos
  static Future<AuthorizationStatus> getPermissionStatus() async {
    NotificationSettings settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  /// Suscribirse a un topic (para futuras implementaciones)
  static Future<void> subscribeToTopic(String topic) async {
    if (!_initialized) return;

    try {
      await _messaging.subscribeToTopic(topic);
      Logger.info('[FCMService] Suscrito al topic: $topic');
    } catch (e) {
      Logger.error('[FCMService] Error suscribiéndose al topic $topic: $e');
    }
  }

  /// Desuscribirse de un topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    if (!_initialized) return;

    try {
      await _messaging.unsubscribeFromTopic(topic);
      Logger.info('[FCMService] Desuscrito del topic: $topic');
    } catch (e) {
      Logger.error('[FCMService] Error desuscribiéndose del topic $topic: $e');
    }
  }

  /// Información de debug del servicio
  static Map<String, dynamic> getDebugInfo() {
    return {
      'initialized': _initialized,
      'token_available': _fcmToken != null,
      'token_prefix': _fcmToken?.substring(0, 20) ?? 'null',
    };
  }
}

/// Handler global para mensajes en background (requerido por Firebase)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  Logger.info('[FCMService] Background message: ${message.messageId}');
}
