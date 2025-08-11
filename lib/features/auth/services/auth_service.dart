import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_constants.dart';

/// Servicio de autenticación que maneja la comunicación con el backend
/// Proporciona métodos para login, registro y gestión de tokens
class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

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
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/auth/login/'),
        headers: _getHeaders(),
        body: jsonEncode({'username': username, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveTokens(
          accessToken: data['access'],
          refreshToken: data['refresh'],
        );
        return {
          'success': true,
          'user': data['user'],
          'message': 'Login exitoso',
        };
      }

      return {'success': false, 'message': _extractErrorMessage(data)};
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
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
