// lib/core/services/notification_preferences_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/notification_preferences_model.dart';
import '../utils/logger.dart';

/// Servicio para gestionar preferencias de notificaciones
/// Fase 5-0005: API client para configuración de preferencias
class NotificationPreferencesService {
  static final NotificationPreferencesService _instance =
      NotificationPreferencesService._internal();
  factory NotificationPreferencesService() => _instance;
  NotificationPreferencesService._internal();

  String? _authToken;

  /// Configura el token de autenticación
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Obtiene la URL base del backend
  String _getBaseUrl() {
    if (kDebugMode) {
      return 'http://localhost:8000';
    } else {
      return 'https://api.nexustcg.com';
    }
  }

  /// Obtiene las preferencias del usuario
  Future<NotificationPreferencesModel> getPreferences() async {
    try {
      if (_authToken == null) {
        throw Exception('Sin token de autenticación');
      }

      final uri = Uri.parse('${_getBaseUrl()}/api/notifications/preferences/');
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_authToken',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return NotificationPreferencesModel.fromJson(data);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      Logger.error(
        '[NotificationPreferencesService] Error obteniendo preferencias: $e',
      );
      rethrow;
    }
  }

  /// Actualiza las preferencias del usuario
  Future<NotificationPreferencesModel> updatePreferences(
    NotificationPreferencesModel preferences,
  ) async {
    try {
      if (_authToken == null) {
        throw Exception('Sin token de autenticación');
      }

      final uri = Uri.parse('${_getBaseUrl()}/api/notifications/preferences/');
      final response = await http
          .put(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_authToken',
            },
            body: json.encode(preferences.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        Logger.info(
          '[NotificationPreferencesService] Preferencias actualizadas',
        );
        return NotificationPreferencesModel.fromJson(data);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      Logger.error(
        '[NotificationPreferencesService] Error actualizando preferencias: $e',
      );
      rethrow;
    }
  }

  /// Restaura las preferencias a los valores por defecto
  Future<NotificationPreferencesModel> resetToDefaults() async {
    try {
      if (_authToken == null) {
        throw Exception('Sin token de autenticación');
      }

      final uri = Uri.parse(
        '${_getBaseUrl()}/api/notifications/preferences/reset_to_defaults/',
      );
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_authToken',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        Logger.info(
          '[NotificationPreferencesService] Preferencias restauradas a defaults',
        );
        return NotificationPreferencesModel.fromJson(data['preferences']);
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      Logger.error(
        '[NotificationPreferencesService] Error restaurando preferencias: $e',
      );
      rethrow;
    }
  }

  /// Actualiza una preferencia específica
  Future<NotificationPreferencesModel> updateSinglePreference(
    String field,
    dynamic value,
    NotificationPreferencesModel currentPreferences,
  ) async {
    try {
      // Crear copia con el campo actualizado
      NotificationPreferencesModel updatedPreferences;

      switch (field) {
        case 'app_new_posts':
          updatedPreferences = currentPreferences.copyWith(
            appNewPosts: value as bool,
          );
          break;
        case 'app_new_comments':
          updatedPreferences = currentPreferences.copyWith(
            appNewComments: value as bool,
          );
          break;
        case 'app_comment_replies':
          updatedPreferences = currentPreferences.copyWith(
            appCommentReplies: value as bool,
          );
          break;
        case 'app_new_ratings':
          updatedPreferences = currentPreferences.copyWith(
            appNewRatings: value as bool,
          );
          break;
        case 'email_new_ratings':
          updatedPreferences = currentPreferences.copyWith(
            emailNewRatings: value as bool,
          );
          break;
        case 'email_important_comments':
          updatedPreferences = currentPreferences.copyWith(
            emailImportantComments: value as bool,
          );
          break;
        case 'email_weekly_summary':
          updatedPreferences = currentPreferences.copyWith(
            emailWeeklySummary: value as bool,
          );
          break;
        case 'summary_frequency':
          updatedPreferences = currentPreferences.copyWith(
            summaryFrequency: value as String,
          );
          break;
        case 'quiet_hours_start':
          updatedPreferences = currentPreferences.copyWith(
            quietHoursStart: value as String?,
          );
          break;
        case 'quiet_hours_end':
          updatedPreferences = currentPreferences.copyWith(
            quietHoursEnd: value as String?,
          );
          break;
        default:
          throw Exception('Campo de preferencia no reconocido: $field');
      }

      return await updatePreferences(updatedPreferences);
    } catch (e) {
      Logger.error(
        '[NotificationPreferencesService] Error actualizando $field: $e',
      );
      rethrow;
    }
  }
}
