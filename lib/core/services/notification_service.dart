// lib/core/services/notification_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/notification_model.dart';
import '../utils/logger.dart';
import '../config/api_config.dart';

/// Servicio de polling inteligente para notificaciones
/// Fase 5-0002: Frontend Polling Service
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // === CONFIGURACIÓN DE POLLING ===
  Timer? _pollingTimer;
  bool _isPolling = false;
  int _currentInterval = 30; // segundos
  DateTime? _lastCheck;
  int _errorCount = 0;
  bool _isAppInForeground = true;

  // === CONFIGURACIÓN ADAPTATIVA ===
  static const int _normalInterval = 30; // 30 segundos normal
  static const int _backgroundInterval = 60; // 60 segundos en background
  static const int _maxErrorInterval = 300; // 5 minutos máximo en errores
  static const int _maxRetries = 3;

  // === ESTADO DE NOTIFICACIONES ===
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  DateTime? _lastUpdate;
  bool _isLoading = false;
  String? _lastError;

  // === TOKEN DE AUTENTICACIÓN ===
  String? _authToken;

  // === GETTERS PÚBLICOS ===
  List<NotificationModel> get notifications =>
      List.unmodifiable(_notifications);
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isPolling => _isPolling;
  String? get lastError => _lastError;
  DateTime? get lastUpdate => _lastUpdate;

  // === CONFIGURACIÓN ===

  /// Configura el token de autenticación
  void setAuthToken(String? token) {
    _authToken = token;
    if (token == null) {
      stopPolling(); // Detener polling si no hay token
    }
  }

  // === GESTIÓN DEL CICLO DE VIDA ===

  /// Inicia el polling cuando la app está activa
  void startPolling() {
    if (_isPolling) return;

    Logger.info(
      '[NotificationService] Iniciando polling cada $_currentInterval segundos',
    );
    _isPolling = true;
    _errorCount = 0;

    // Primera consulta inmediata
    _checkNotifications();

    // Configurar timer periódico
    _pollingTimer = Timer.periodic(
      Duration(seconds: _currentInterval),
      (_) => _checkNotifications(),
    );

    notifyListeners();
  }

  /// Pausa el polling (cuando app va a background)
  void pausePolling() {
    if (!_isPolling) return;

    Logger.info('[NotificationService] Pausando polling');
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;

    notifyListeners();
  }

  /// Reanuda el polling con intervalo adaptativo
  void resumePolling() {
    if (_isPolling) return;

    Logger.info('[NotificationService] Reanudando polling');

    // Ajustar intervalo según estado de la app
    _currentInterval = _isAppInForeground
        ? _normalInterval
        : _backgroundInterval;

    startPolling();
  }

  /// Maneja cambios de estado de la aplicación
  void onAppStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isAppInForeground = true;
        _currentInterval = _normalInterval;
        if (!_isPolling) resumePolling();
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _isAppInForeground = false;
        pausePolling();
        break;

      case AppLifecycleState.detached:
        pausePolling();
        break;

      case AppLifecycleState.hidden:
        _isAppInForeground = false;
        break;
    }
  }

  /// Detiene completamente el polling (logout, etc.)
  void stopPolling() {
    Logger.info('[NotificationService] Deteniendo polling completamente');
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;

    // Limpiar estado
    _notifications.clear();
    _unreadCount = 0;
    _lastUpdate = null;
    _lastError = null;
    _errorCount = 0;

    notifyListeners();
  }

  // === LÓGICA DE POLLING ===

  /// Consulta las notificaciones al backend
  Future<void> _checkNotifications() async {
    if (_isLoading) return; // Evitar consultas concurrentes

    try {
      _isLoading = true;
      _lastError = null;

      Logger.debug('[NotificationService] Consultando notificaciones...');

      // Obtener token de autenticación
      if (_authToken == null) {
        Logger.warning('[NotificationService] Sin token de autenticación');
        return;
      }

      // Hacer petición HTTP directa
      final uri = Uri.parse('${_getBaseUrl()}/api/notifications/unread/');
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_authToken',
            },
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Actualizar contador
        final newUnreadCount = data['count'] ?? 0;
        final hasNewNotifications = newUnreadCount > _unreadCount;

        _unreadCount = newUnreadCount;

        // Actualizar lista de notificaciones recientes
        if (data['latest'] != null) {
          try {
            final latestData = data['latest'];
            Logger.debug(
              '[NotificationService] Latest data type: ${latestData.runtimeType}',
            );
            Logger.debug('[NotificationService] Latest data: $latestData');

            if (latestData is List) {
              _notifications = latestData
                  .where((item) => item != null && item is Map<String, dynamic>)
                  .map((json) {
                    try {
                      return NotificationModel.fromJson(
                        json as Map<String, dynamic>,
                      );
                    } catch (parseError) {
                      Logger.error(
                        '[NotificationService] Error parseando notificación individual: $parseError',
                      );
                      Logger.error(
                        '[NotificationService] JSON problemático: $json',
                      );
                      return null;
                    }
                  })
                  .where((notification) => notification != null)
                  .cast<NotificationModel>()
                  .toList();

              Logger.debug(
                '[NotificationService] Parseadas ${_notifications.length} notificaciones correctamente',
              );
            } else {
              Logger.warning(
                '[NotificationService] Latest no es una lista: ${latestData.runtimeType}',
              );
              _notifications = [];
            }
          } catch (parseError) {
            Logger.error(
              '[NotificationService] Error general parseando notificaciones: $parseError',
            );
            // Mantener las notificaciones existentes en caso de error de parsing
          }
        } else {
          _notifications = [];
          Logger.debug(
            '[NotificationService] No hay campo latest en la respuesta',
          );
        }

        _lastUpdate = DateTime.now();
        _lastCheck = DateTime.now();
        _errorCount = 0; // Reset error count en éxito

        // Notificar si hay nuevas notificaciones
        if (hasNewNotifications) {
          Logger.info(
            '[NotificationService] Nuevas notificaciones detectadas: $newUnreadCount',
          );
          _onNewNotifications();
        }

        Logger.debug(
          '[NotificationService] Polling exitoso: $_unreadCount notificaciones no leídas',
        );
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      _handlePollingError(e, stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtiene la URL base del backend
  String _getBaseUrl() {
    // Usar la configuración centralizada que maneja emuladores
    return ApiConfig.baseUrl;
  }

  /// Maneja errores de polling con backoff exponencial
  void _handlePollingError(dynamic error, StackTrace? stackTrace) {
    _errorCount++;
    _lastError = error.toString();

    Logger.error(
      '[NotificationService] Error en polling (#$_errorCount): $error',
      error,
      stackTrace,
    );

    // Backoff exponencial: 30s -> 60s -> 120s -> 300s (máximo)
    if (_errorCount >= 2) {
      final backoffInterval = (_currentInterval * (_errorCount - 1)).clamp(
        _normalInterval,
        _maxErrorInterval,
      );

      Logger.warning(
        '[NotificationService] Aplicando backoff: ${backoffInterval}s',
      );

      // Reiniciar timer con nuevo intervalo
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(
        Duration(seconds: backoffInterval),
        (_) => _checkNotifications(),
      );
    }

    // Parar polling si hay demasiados errores consecutivos
    if (_errorCount >= _maxRetries) {
      Logger.error(
        '[NotificationService] Demasiados errores, pausando polling',
      );
      pausePolling();

      // Reintentar en 5 minutos
      Timer(Duration(minutes: 5), () {
        if (!_isPolling) {
          Logger.info(
            '[NotificationService] Reintentando polling después de errores',
          );
          _errorCount = 0;
          resumePolling();
        }
      });
    }
  }

  /// Callback cuando se detectan nuevas notificaciones
  void _onNewNotifications() {
    // Aquí se pueden agregar:
    // - Notificaciones locales
    // - Sonidos/vibraciones
    // - Analytics

    Logger.info(
      '[NotificationService] Notificando nuevas notificaciones a listeners',
    );
  }

  // === MÉTODOS PÚBLICOS PARA UI ===

  /// Fuerza una actualización inmediata
  Future<void> forceRefresh() async {
    Logger.info('[NotificationService] Forzando actualización inmediata');
    await _checkNotifications();
  }

  /// Marca una notificación como leída
  Future<void> markAsRead(String notificationId) async {
    try {
      if (_authToken == null) throw Exception('Sin token de autenticación');

      final uri = Uri.parse(
        '${_getBaseUrl()}/api/notifications/$notificationId/mark_read/',
      );
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        // Actualizar estado local
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
          if (!_notifications[index].isRead) {
            _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
          }
          notifyListeners();
        }

        Logger.debug(
          '[NotificationService] Notificación $notificationId marcada como leída',
        );
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      Logger.error('[NotificationService] Error marcando como leída: $e');
      rethrow;
    }
  }

  /// Marca todas las notificaciones como leídas
  Future<void> markAllAsRead() async {
    try {
      if (_authToken == null) throw Exception('Sin token de autenticación');

      final uri = Uri.parse(
        '${_getBaseUrl()}/api/notifications/mark_all_read/',
      );
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        // Actualizar estado local
        for (int i = 0; i < _notifications.length; i++) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
        _unreadCount = 0;

        notifyListeners();
        Logger.info(
          '[NotificationService] Todas las notificaciones marcadas como leídas',
        );
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      Logger.error(
        '[NotificationService] Error marcando todas como leídas: $e',
      );
      rethrow;
    }
  }

  /// Obtiene el historial completo de notificaciones
  Future<List<NotificationModel>> getNotificationHistory({
    int page = 1,
    int pageSize = 20,
    String? type,
  }) async {
    try {
      if (_authToken == null) throw Exception('Sin token de autenticación');

      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (type != null) {
        queryParams['type'] = type;
      }

      final uri = Uri.parse(
        '${_getBaseUrl()}/api/notifications/',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_authToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['results'] != null) {
          final List<dynamic> notificationsJson = data['results'];
          return notificationsJson
              .map((json) => NotificationModel.fromJson(json))
              .toList();
        }
      } else {
        throw HttpException('HTTP ${response.statusCode}: ${response.body}');
      }

      return [];
    } catch (e) {
      Logger.error('[NotificationService] Error obteniendo historial: $e');
      rethrow;
    }
  }

  // === CONFIGURACIÓN Y UTILIDADES ===

  /// Actualiza el intervalo de polling
  void updatePollingInterval(int seconds) {
    if (seconds < 10 || seconds > 300) {
      Logger.warning('[NotificationService] Intervalo inválido: ${seconds}s');
      return;
    }

    _currentInterval = seconds;

    if (_isPolling) {
      // Reiniciar con nuevo intervalo
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(
        Duration(seconds: _currentInterval),
        (_) => _checkNotifications(),
      );
    }

    Logger.info(
      '[NotificationService] Intervalo actualizado a ${_currentInterval}s',
    );
  }

  /// Obtiene estadísticas del servicio
  Map<String, dynamic> getStats() {
    return {
      'is_polling': _isPolling,
      'current_interval': _currentInterval,
      'unread_count': _unreadCount,
      'total_notifications': _notifications.length,
      'last_update': _lastUpdate?.toIso8601String(),
      'last_check': _lastCheck?.toIso8601String(),
      'error_count': _errorCount,
      'last_error': _lastError,
      'is_app_foreground': _isAppInForeground,
    };
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
