// lib/core/utils/logger.dart
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Utilidad de logging para debugging y monitoreo
/// Fase 5-0002: Logger para NotificationService
class Logger {
  static const String _tag = 'NexusTCG';

  /// Log de información general
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log('INFO', message, error, stackTrace);
  }

  /// Log de debugging (solo en debug mode)
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _log('DEBUG', message, error, stackTrace);
    }
  }

  /// Log de warnings
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log('WARNING', message, error, stackTrace);
  }

  /// Log de errores
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message, error, stackTrace);
  }

  /// Método interno para logging
  static void _log(
    String level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [$level] $_tag: $message';

    if (kDebugMode) {
      // En debug, usar print para logging simple
      print(logMessage);

      if (error != null) {
        print('  Error: $error');
      }

      if (stackTrace != null) {
        print('  StackTrace: $stackTrace');
      }
    } else {
      // En producción, usar developer.log
      developer.log(
        message,
        name: _tag,
        level: _getLevelValue(level),
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Convierte string level a valor numérico
  static int _getLevelValue(String level) {
    switch (level) {
      case 'DEBUG':
        return 500;
      case 'INFO':
        return 800;
      case 'WARNING':
        return 900;
      case 'ERROR':
        return 1000;
      default:
        return 800;
    }
  }
}
