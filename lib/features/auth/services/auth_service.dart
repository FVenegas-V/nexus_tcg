import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/http_service.dart';
import '../../../core/config/api_config.dart';

/// Servicio de autenticación que maneja la comunicación con el backend
/// Proporciona métodos para login, registro y gestión de tokens
/// Incluye fallback a datos mock en caso de error de conectividad
class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final HttpService _httpService = HttpService();

  // Flag para habilitar/deshabilitar el uso de APIs reales
  static const bool _useRealApi = true;

  /// Construye los headers necesarios para las peticiones HTTP
  /// Incluye el token de autorización si se proporciona
  static Map<String, String> _getHeaders([String? token]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'Nexus-TCG-Flutter-App/1.0',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Realiza el login del usuario con el backend
  /// Retorna un mapa con el resultado y los datos del usuario
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    if (_useRealApi) {
      try {
        debugPrint('🔐 Intentando login con API real: $username');
        debugPrint('🌐 Base URL: ${ApiConfig.baseUrl}');
        debugPrint('🔗 Endpoint: ${ApiConfig.loginEndpoint}');
        debugPrint(
          '🔗 URL completa: ${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}',
        );
        debugPrint(
          '📝 Datos a enviar: ${{'username': username, 'password': password}}',
        );

        final response = await _httpService.post(
          ApiConfig.loginEndpoint,
          data: {'username': username, 'password': password},
        );

        debugPrint('📊 Status Code recibido: ${response.statusCode}');
        debugPrint('📋 Headers recibidos: ${response.headers}');
        debugPrint('📄 Response data: ${response.data}');

        if (response.statusCode == 200) {
          final data = response.data as Map<String, dynamic>;

          // Guardar tokens de forma segura
          await _saveTokens(
            accessToken: data['access'],
            refreshToken: data['refresh'],
          );

          debugPrint('✅ Login exitoso con API real');
          return {
            'success': true,
            'user': data['user'],
            'token': data['access'],
            'message': 'Login exitoso',
            'isReal': true, // Marcador para identificar autenticación real
          };
        } else {
          debugPrint('❌ Login fallido con código: ${response.statusCode}');
          debugPrint('📄 Response data en error: ${response.data}');

          // Manejo específico de códigos de estado
          if (response.statusCode == 401 || response.statusCode == 400) {
            return {
              'success': false,
              'message': 'Credenciales inválidas',
              'isReal': true,
            };
          } else {
            return {
              'success': false,
              'message': 'Error del servidor (${response.statusCode})',
              'isReal': true,
            };
          }
        }
      } catch (e) {
        debugPrint('🚨 Error en API real: $e');
        debugPrint('🔍 Tipo de error: ${e.runtimeType}');

        // Si es un error HTTP de credenciales (401, 400), mostrar mensaje específico
        if (e.toString().contains('401') ||
            e.toString().contains('400') ||
            e.toString().toLowerCase().contains('credenciales')) {
          return {
            'success': false,
            'message': 'Credenciales inválidas',
            'isReal': true,
          };
        }

        return {
          'success': false,
          'message': 'Error de conexión con el servidor',
          'isReal': true,
        };
      }
    }

    // Fallback a datos mock solo para desarrollo
    return _mockLogin(username, password);
  }

  /// Login mock para desarrollo y fallback
  static Future<Map<String, dynamic>> _mockLogin(
    String username,
    String password,
  ) async {
    debugPrint('🔄 Usando login mock para: $username');

    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 500));

    // Validar credenciales mock
    if ((username == 'demo' && password == 'demo123') ||
        (username == 'admin' && password == 'admin123') ||
        username.isNotEmpty && password.length >= 4) {
      // Generar tokens mock
      final accessToken =
          'mock_access_token_${DateTime.now().millisecondsSinceEpoch}';
      await _saveTokens(
        accessToken: accessToken,
        refreshToken:
            'mock_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
      );

      debugPrint('✅ Login mock exitoso');
      return {
        'success': true,
        'user': {
          'id': 1,
          'username': username,
          'email': '$username@example.com',
          'first_name': username.toUpperCase(),
          'last_name': 'Usuario',
        },
        'token': accessToken,
        'message': 'Login exitoso (datos mock)',
        'isReal': false, // Marcador para identificar autenticación mock
      };
    }

    return {
      'success': false,
      'message': 'Credenciales inválidas',
      'isReal': false,
    };
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
    required String passwordConfirm,
  }) async {
    try {
      final url = '${AppConstants.baseUrl}/api/auth/register/';
      debugPrint('🔄 Intentando registro con URL: $url');
      debugPrint('📧 Email: $email');
      debugPrint('👤 Username: $username');

      final response = await http.post(
        Uri.parse(url),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
          'password_confirm': passwordConfirm,
        }),
      );

      debugPrint('📤 Status Code: ${response.statusCode}');
      debugPrint('📤 Response Headers: ${response.headers}');
      debugPrint('📤 Response Body: ${response.body}');

      if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Endpoint no encontrado. Verificar URL del servidor.',
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Usuario creado exitosamente. Verifica tu email.',
          'user': data['user'],
        };
      }

      return {'success': false, 'message': _extractErrorMessage(data)};
    } catch (e) {
      debugPrint('❌ Error en registro: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final token = await getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'No autenticado'};
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/users/me/'),
        headers: _getHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'user': data};
      }

      if (response.statusCode == 401) {
        await clearTokens();
      }

      return {'success': false, 'message': 'Error al obtener usuario'};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  static Future<void> _saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  static Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  static Future<bool> hasValidTokens() async {
    final accessToken = await getAccessToken();
    return accessToken != null;
  }

  /// Solicita recuperación de contraseña por email
  static Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    if (_useRealApi) {
      try {
        debugPrint('🔄 Solicitando recuperación de contraseña para: $email');

        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/api/auth/password-reset-request/'),
          headers: _getHeaders(),
          body: jsonEncode({'email': email}),
        );

        debugPrint('📡 Status Code: ${response.statusCode}');
        debugPrint('📡 Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'message':
                data['message'] ?? 'Email de recuperación enviado exitosamente',
          };
        } else {
          final data = jsonDecode(response.body);
          return {'success': false, 'message': _extractErrorMessage(data)};
        }
      } catch (e) {
        debugPrint('❌ Error en requestPasswordReset: $e');
        return {'success': false, 'message': 'Error de conexión al servidor'};
      }
    } else {
      // Mock response para desarrollo
      await Future.delayed(const Duration(seconds: 1));
      return {
        'success': true,
        'message': 'Email de recuperación enviado (modo mock)',
      };
    }
  }

  /// Refresca el token de acceso usando el refresh token
  static Future<Map<String, dynamic>> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        return {'success': false, 'message': 'No hay refresh token disponible'};
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/token/refresh/'),
        headers: _getHeaders(),
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access'];

        await _storage.write(key: 'access_token', value: newAccessToken);

        return {'success': true, 'access_token': newAccessToken};
      } else {
        return {'success': false, 'message': 'Error al refrescar token'};
      }
    } catch (e) {
      debugPrint('❌ Error en refreshAccessToken: $e');
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  static String _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data.containsKey('message')) {
        return data['message'];
      }
      if (data.containsKey('detail')) {
        return data['detail'];
      }
      if (data.containsKey('non_field_errors')) {
        final errors = data['non_field_errors'] as List;
        return errors.isNotEmpty ? errors.first : 'Error de validación';
      }

      if (data.isNotEmpty) {
        final firstKey = data.keys.first;
        final firstError = data[firstKey];
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first;
        }
      }
    }
    return 'Error de validación';
  }
}
