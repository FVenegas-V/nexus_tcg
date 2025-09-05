// lib/core/providers/notification_provider.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/notification_service.dart';
import '../services/notification_preferences_service.dart';
import '../services/fcm_service.dart';
import '../utils/logger.dart';

/// Provider que gestiona el ciclo de vida del NotificationService
/// Fase 5-0002: Integración con lifecycle de Flutter
class NotificationProvider extends ChangeNotifier with WidgetsBindingObserver {
  late final NotificationService _notificationService;
  bool _isInitialized = false;

  NotificationProvider() {
    _notificationService = NotificationService();
    WidgetsBinding.instance.addObserver(this);
    Logger.info('[NotificationProvider] Inicializado');
  }

  // === GETTERS DELEGADOS ===

  NotificationService get service => _notificationService;

  List<dynamic> get notifications => _notificationService.notifications;
  int get unreadCount => _notificationService.unreadCount;
  bool get isLoading => _notificationService.isLoading;
  bool get isPolling => _notificationService.isPolling;
  String? get lastError => _notificationService.lastError;
  DateTime? get lastUpdate => _notificationService.lastUpdate;

  // === CONFIGURACIÓN ===

  /// Inicializa el servicio con token de autenticación
  void initialize(String authToken) {
    if (_isInitialized) return;

    Logger.info('[NotificationProvider] Configurando token de autenticación');
    _notificationService.setAuthToken(authToken);

    // Configurar listener para cambios del servicio
    _notificationService.addListener(_onServiceChanged);

    // ✅ EXISTENTE: Iniciar polling (funciona cuando app activa)
    _notificationService.startPolling();

    // 🆕 NUEVO: Inicializar FCM (funciona cuando app cerrada)
    _initializeFCM();

    _isInitialized = true;
    notifyListeners();
  }

  /// Inicializar Firebase Cloud Messaging sin interferir con polling
  void _initializeFCM() async {
    try {
      Logger.info('[NotificationProvider] Inicializando FCM...');
      bool success = await FCMService.initialize();

      if (success) {
        Logger.info('[NotificationProvider] ✅ FCM inicializado correctamente');

        // Mostrar información de debug del FCM
        var debugInfo = FCMService.getDebugInfo();
        Logger.info('[NotificationProvider] FCM Debug Info: $debugInfo');

        // Mostrar token para copiar al backend
        String? token = FCMService.token;
        if (token != null) {
          Logger.info(
            '[NotificationProvider] FCM Token: ${token.substring(0, 20)}...',
          );
        }
      } else {
        Logger.warning('[NotificationProvider] ⚠️ FCM no se pudo inicializar');
      }
    } catch (e) {
      Logger.error('[NotificationProvider] Error inicializando FCM: $e');
    }
  }

  /// Cierra el servicio (logout)
  void shutdown() {
    if (!_isInitialized) return;

    Logger.info('[NotificationProvider] Cerrando servicio de notificaciones');
    _notificationService.removeListener(_onServiceChanged);
    _notificationService.stopPolling();
    _notificationService.setAuthToken(null);

    _isInitialized = false;
    notifyListeners();
  }

  // === LIFECYCLE MANAGEMENT ===

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (_isInitialized) {
      Logger.debug('[NotificationProvider] Cambio de estado de app: $state');
      _notificationService.onAppStateChanged(state);
    }
  }

  // === EVENT HANDLERS ===

  void _onServiceChanged() {
    // Propagar cambios del servicio a los widgets
    notifyListeners();
  }

  // === MÉTODOS DELEGADOS ===

  Future<void> forceRefresh() async {
    if (!_isInitialized) return;
    await _notificationService.forceRefresh();
  }

  Future<void> markAsRead(String notificationId) async {
    if (!_isInitialized) return;
    await _notificationService.markAsRead(notificationId);
  }

  Future<void> markAllAsRead() async {
    if (!_isInitialized) return;
    await _notificationService.markAllAsRead();
  }

  Future<dynamic> getNotificationHistory({
    int page = 1,
    int pageSize = 20,
    String? type,
  }) async {
    if (!_isInitialized) return [];
    return await _notificationService.getNotificationHistory(
      page: page,
      pageSize: pageSize,
      type: type,
    );
  }

  Map<String, dynamic> getStats() {
    return _notificationService.getStats();
  }

  // === CLEANUP ===

  @override
  void dispose() {
    Logger.info('[NotificationProvider] Dispose - limpiando recursos');

    WidgetsBinding.instance.removeObserver(this);

    if (_isInitialized) {
      _notificationService.removeListener(_onServiceChanged);
      _notificationService.stopPolling();
    }

    super.dispose();
  }
}

/// Widget conveniente para configurar el NotificationProvider
class NotificationProviderWrapper extends StatelessWidget {
  final Widget child;
  final String? authToken;

  const NotificationProviderWrapper({
    Key? key,
    required this.child,
    this.authToken,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationProvider>(
      create: (context) {
        final provider = NotificationProvider();

        // Inicializar si hay token
        if (authToken != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.initialize(authToken!);
          });
        }

        return provider;
      },
      child: child,
    );
  }
}

/// Consumer helper para notificaciones
class NotificationConsumer extends StatelessWidget {
  final Widget Function(
    BuildContext context,
    NotificationProvider provider,
    Widget? child,
  )
  builder;
  final Widget? child;

  const NotificationConsumer({Key? key, required this.builder, this.child})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(builder: builder, child: child);
  }
}
