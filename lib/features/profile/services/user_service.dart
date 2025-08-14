import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../features/auth/services/auth_service.dart';
import '../models/user.dart';

/// Excepción personalizada para errores del servicio de usuario
class UserServiceException implements Exception {
  final String message;
  final int? statusCode;

  UserServiceException(this.message, [this.statusCode]);

  @override
  String toString() => 'UserServiceException: $message';
}

/// Servicio para la gestión del perfil de usuario
/// Maneja las operaciones CRUD del perfil y cambio de contraseña
class UserService {
  /// Obtiene los datos del usuario autenticado
  ///
  /// Realiza una petición GET a /api/users/me/
  /// Retorna un objeto [User] con los datos actualizados
  ///
  /// Throws [UserServiceException] si hay error en la petición
  static Future<User> getUserProfile() async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null) {
        throw UserServiceException('No hay token de autenticación');
      }

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/users/me/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return User.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw UserServiceException('Token expirado o inválido', 401);
      } else {
        final errorData = json.decode(response.body);
        throw UserServiceException(
          errorData['detail'] ?? 'Error al obtener perfil de usuario',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is UserServiceException) rethrow;
      throw UserServiceException('Error de conexión: ${e.toString()}');
    }
  }

  /// Actualiza los datos del perfil del usuario
  ///
  /// [userData] Map con los campos a actualizar:
  /// - first_name: Nombre del usuario
  /// - last_name: Apellido del usuario
  /// - email: Email del usuario
  ///
  /// Realiza una petición PUT a /api/users/me/
  /// Retorna un objeto [User] con los datos actualizados
  ///
  /// Throws [UserServiceException] si hay error en la petición
  static Future<User> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null) {
        throw UserServiceException('No hay token de autenticación');
      }

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/api/users/me/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(userData),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return User.fromJson(jsonData);
      } else if (response.statusCode == 401) {
        throw UserServiceException('Token expirado o inválido', 401);
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        final errors = <String>[];

        if (errorData is Map) {
          errorData.forEach((key, value) {
            if (value is List) {
              errors.addAll(value.map((e) => '$key: $e'));
            } else {
              errors.add('$key: $value');
            }
          });
        }

        throw UserServiceException(
          errors.isNotEmpty ? errors.join(', ') : 'Datos inválidos',
          400,
        );
      } else {
        final errorData = json.decode(response.body);
        throw UserServiceException(
          errorData['detail'] ?? 'Error al actualizar perfil',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is UserServiceException) rethrow;
      throw UserServiceException('Error de conexión: ${e.toString()}');
    }
  }

  /// Cambia la contraseña del usuario
  ///
  /// [currentPassword] Contraseña actual
  /// [newPassword] Nueva contraseña
  ///
  /// Realiza una petición PUT a /api/users/me/password/
  ///
  /// Throws [UserServiceException] si hay error en la petición
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await AuthService.getAccessToken();
      if (token == null) {
        throw UserServiceException('No hay token de autenticación');
      }

      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/api/users/me/password/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        // Cambio exitoso, no hay respuesta de datos
        return;
      } else if (response.statusCode == 401) {
        throw UserServiceException('Token expirado o inválido', 401);
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);

        // Manejar errores específicos de contraseña
        if (errorData['current_password'] != null) {
          throw UserServiceException('Contraseña actual incorrecta', 400);
        }

        if (errorData['new_password'] != null) {
          final errors = errorData['new_password'] as List;
          throw UserServiceException(
            'Nueva contraseña inválida: ${errors.join(', ')}',
            400,
          );
        }

        throw UserServiceException('Datos inválidos', 400);
      } else {
        final errorData = json.decode(response.body);
        throw UserServiceException(
          errorData['detail'] ?? 'Error al cambiar contraseña',
          response.statusCode,
        );
      }
    } catch (e) {
      if (e is UserServiceException) rethrow;
      throw UserServiceException('Error de conexión: ${e.toString()}');
    }
  }

  /// Valida que el email tenga formato correcto
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  /// Valida que la contraseña cumpla los requisitos mínimos
  static bool isValidPassword(String password) {
    // Mínimo 8 caracteres
    return password.length >= 8;
  }

  /// Valida que el nombre tenga formato correcto
  static bool isValidName(String name) {
    // Permitir nombres vacíos o con al menos 1 carácter no numérico
    if (name.isEmpty) return true;
    return RegExp(r'^[a-zA-ZÀ-ÿ\u00f1\u00d1\s-]+$').hasMatch(name);
  }
}
