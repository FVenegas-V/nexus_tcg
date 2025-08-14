import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/user_service.dart';

/// Estados del perfil de usuario
enum ProfileState {
  initial,
  loading,
  loaded,
  updating,
  changingPassword,
  error,
}

/// Provider para la gestión del estado del perfil de usuario
/// Maneja la carga, actualización y cambio de contraseña
class ProfileProvider with ChangeNotifier {
  ProfileState _state = ProfileState.initial;
  User? _user;
  String? _errorMessage;

  // Getters
  ProfileState get state => _state;
  User? get user => _user;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _state == ProfileState.loading;
  bool get isUpdating => _state == ProfileState.updating;
  bool get isChangingPassword => _state == ProfileState.changingPassword;
  bool get hasError => _state == ProfileState.error;
  bool get hasUser => _user != null;

  /// Carga los datos del perfil del usuario
  Future<void> loadUserProfile() async {
    _setState(ProfileState.loading);

    try {
      final user = await UserService.getUserProfile();
      _user = user;
      _errorMessage = null;
      _setState(ProfileState.loaded);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(ProfileState.error);
      debugPrint('❌ Error cargando perfil: $e');
    }
  }

  /// Actualiza los datos del perfil del usuario
  ///
  /// [firstName] Nuevo nombre
  /// [lastName] Nuevo apellido
  /// [email] Nuevo email
  ///
  /// Retorna true si la actualización fue exitosa
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    if (_user == null) {
      _errorMessage = 'No hay usuario cargado';
      _setState(ProfileState.error);
      return false;
    }

    _setState(ProfileState.updating);

    try {
      // Validaciones del lado del cliente
      if (!UserService.isValidEmail(email)) {
        throw Exception('Email inválido');
      }

      if (!UserService.isValidName(firstName)) {
        throw Exception('Nombre inválido');
      }

      if (!UserService.isValidName(lastName)) {
        throw Exception('Apellido inválido');
      }

      final userData = {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'email': email.trim(),
      };

      final updatedUser = await UserService.updateUserProfile(userData);
      _user = updatedUser;
      _errorMessage = null;
      _setState(ProfileState.loaded);

      debugPrint('✅ Perfil actualizado exitosamente');
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      _setState(ProfileState.error);
      debugPrint('❌ Error actualizando perfil: $e');
      return false;
    }
  }

  /// Cambia la contraseña del usuario
  ///
  /// [currentPassword] Contraseña actual
  /// [newPassword] Nueva contraseña
  /// [confirmPassword] Confirmación de nueva contraseña
  ///
  /// Retorna true si el cambio fue exitoso
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setState(ProfileState.changingPassword);

    try {
      // Validaciones del lado del cliente
      if (newPassword != confirmPassword) {
        throw Exception('Las contraseñas no coinciden');
      }

      if (!UserService.isValidPassword(newPassword)) {
        throw Exception('La contraseña debe tener al menos 8 caracteres');
      }

      if (currentPassword == newPassword) {
        throw Exception('La nueva contraseña debe ser diferente a la actual');
      }

      await UserService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      _errorMessage = null;
      _setState(ProfileState.loaded);

      debugPrint('✅ Contraseña cambiada exitosamente');
      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
      _setState(ProfileState.error);
      debugPrint('❌ Error cambiando contraseña: $e');
      return false;
    }
  }

  /// Limpia el error actual
  void clearError() {
    if (_state == ProfileState.error) {
      _errorMessage = null;
      _setState(_user != null ? ProfileState.loaded : ProfileState.initial);
    }
  }

  /// Recarga el perfil del usuario
  Future<void> refresh() async {
    await loadUserProfile();
  }

  /// Limpia todos los datos del perfil
  void clear() {
    _user = null;
    _errorMessage = null;
    _setState(ProfileState.initial);
  }

  /// Actualiza el usuario desde datos externos (como después del login)
  void updateUserFromData(Map<String, dynamic> userData) {
    try {
      _user = User.fromJson(userData);
      _errorMessage = null;
      _setState(ProfileState.loaded);
      debugPrint('✅ Usuario actualizado desde datos externos');
    } catch (e) {
      debugPrint('❌ Error actualizando usuario desde datos: $e');
      _errorMessage = 'Error al procesar datos del usuario';
      _setState(ProfileState.error);
    }
  }

  /// Actualiza el estado interno
  void _setState(ProfileState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Extrae un mensaje de error legible
  String _extractErrorMessage(String error) {
    // Remover prefijo de la excepción si existe
    if (error.startsWith('UserServiceException: ')) {
      return error.substring('UserServiceException: '.length);
    }
    if (error.startsWith('Exception: ')) {
      return error.substring('Exception: '.length);
    }
    return error;
  }
}
