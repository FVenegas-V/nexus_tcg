import 'package:flutter/foundation.dart';

/// Configuración central para las APIs del backend
class ApiConfig {
  // URL base del backend Django - auto-detecta plataforma
  static String get baseUrl {
    if (kIsWeb) {
      // Para web/Chrome: usar 127.0.0.1 o localhost
      return 'http://127.0.0.1:8000';
    } else {
      // Para Android emulador: usar 10.0.2.2 (IP del host desde emulador)
      return 'http://10.0.2.2:8000'; // IP para emulador Android
      // Para dispositivo real en WiFi: usar IP WiFi de la computadora
      // return 'http://192.168.1.87:8000'; // IP WiFi para dispositivo real
    }
  }

  // Endpoints de autenticación
  static const String registerEndpoint = '/api/auth/register/';
  static const String loginEndpoint = '/api/auth/login/';
  static const String refreshEndpoint = '/api/auth/refresh/';
  static const String profileEndpoint = '/api/users/me/';
  static const String changePasswordEndpoint = '/api/users/me/password/';

  // Endpoints de usuarios
  static const String usersEndpoint = '/api/users/';

  // Endpoints de comunidades
  static const String gamesEndpoint = '/api/games/';
  static const String tagsEndpoint = '/api/tags/';
  static const String communitiesEndpoint = '/api/communities/';
  static const String categoriesEndpoint = '/api/categories/';
  static const String membershipsEndpoint = '/api/memberships/';

  // Endpoints de posts y contenido social (Fase 3)
  static const String postsEndpoint = '/api/posts/';
  static const String commentsEndpoint = '/api/comments/';
  static const String reactionsEndpoint = '/api/reactions/';
  static const String postImagesEndpoint = '/api/post-images/';

  // Configuración de timeouts
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);
  static const Duration sendTimeout = Duration(seconds: 10);

  // Headers comunes
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Construye la URL completa para un endpoint
  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// Headers con autorización
  static Map<String, String> authorizedHeaders(String token) {
    return {...defaultHeaders, 'Authorization': 'Bearer $token'};
  }
}
