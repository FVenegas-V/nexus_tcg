import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../../../core/services/http_service.dart';
// import '../../reputation/services/reputation_service.dart'; // No necesario ya que ReputationService usa HttpService directamente

/// Estados posibles del proceso de autenticación
enum AuthState {
  initial, // Estado inicial
  loading, // Procesando autenticación
  authenticated, // Usuario autenticado
  unauthenticated, // Usuario no autenticado
  error, // Error en la autenticación
}

/// Provider para gestionar el estado de autenticación de la aplicación
/// Utiliza el patrón ChangeNotifier para notificar cambios a la UI
class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  Map<String, dynamic>? _user;
  String? _errorMessage;
  bool _isRealAuth = false; // Track if using real authentication

  // Getters para acceso al estado
  AuthState get state => _state;
  Map<String, dynamic>? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;
  bool get isRealAuth => _isRealAuth; // Getter for real auth status

  /// Actualiza el estado y notifica a los listeners
  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _setState(AuthState.error);
  }

  void clearError() {
    _errorMessage = null;
    if (_state == AuthState.error) {
      _setState(
        _user != null ? AuthState.authenticated : AuthState.unauthenticated,
      );
    }
  }

  Future<void> checkAuthStatus() async {
    _setState(AuthState.loading);

    try {
      final hasTokens = await AuthService.hasValidTokens();

      if (hasTokens) {
        final result = await AuthService.getCurrentUser();

        if (result['success']) {
          _user = result['user'];

          // Configurar token en los servicios
          final token = await AuthService.getAccessToken();
          if (token != null) {
            HttpService().setAuthToken(token);
            // ReputationService maneja automáticamente la autenticación a través de HttpService
            // ReputationService.instance.updateAuthToken(token);
          }

          _setState(AuthState.authenticated);
        } else {
          await AuthService.clearTokens();
          _setState(AuthState.unauthenticated);
        }
      } else {
        _setState(AuthState.unauthenticated);
      }
    } catch (e) {
      _setError('Error al verificar autenticación');
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _setState(AuthState.loading);
    clearError();

    try {
      final result = await AuthService.login(
        username: username,
        password: password,
      );

      if (result['success']) {
        _user = result['user'];
        _isRealAuth = result['isReal'] ?? false; // Track auth type

        // Configurar token en HttpService si está disponible
        if (result['token'] != null) {
          HttpService().setAuthToken(result['token']);

          // ReputationService usa automáticamente el token a través de HttpService
          // final reputationService = ReputationService.instance;
          // reputationService.updateAuthToken(result['token']);
        }

        _setState(AuthState.authenticated);

        // Show warning if using mock auth
        if (!_isRealAuth) {
          debugPrint(
            '⚠️ ADVERTENCIA: Usando autenticación mock. Las operaciones de comunidades pueden fallar.',
          );
        }

        return true;
      } else {
        _setError(result['message'] ?? 'Credenciales inválidas');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión con el servidor');
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    required String passwordConfirm,
  }) async {
    _setState(AuthState.loading);
    clearError();

    try {
      final result = await AuthService.register(
        email: email,
        username: username,
        password: password,
        passwordConfirm: passwordConfirm,
      );

      if (result['success']) {
        _setState(AuthState.unauthenticated);
        return true;
      } else {
        _setError(result['message']);
        return false;
      }
    } catch (e) {
      _setError('Error de conexión con el servidor');
      return false;
    }
  }

  Future<void> logout() async {
    _setState(AuthState.loading);

    try {
      await AuthService.clearTokens();

      // Limpiar tokens de todos los servicios
      HttpService().clearAuthToken();
      // ReputationService usa automáticamente el token a través de HttpService
      // ReputationService.instance.updateAuthToken(null);

      _user = null;
      _setState(AuthState.unauthenticated);
    } catch (e) {
      _setError('Error al cerrar sesión');
    }
  }

  Future<void> refreshUser() async {
    if (_state != AuthState.authenticated) return;

    try {
      final result = await AuthService.getCurrentUser();

      if (result['success']) {
        _user = result['user'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error refreshing user: $e');
    }
  }

  /// Solicita recuperación de contraseña por email
  Future<bool> requestPasswordReset({required String email}) async {
    _setState(AuthState.loading);

    try {
      final result = await AuthService.requestPasswordReset(email: email);

      if (result['success']) {
        _setState(AuthState.unauthenticated);
        return true;
      } else {
        _setError(result['message'] ?? 'Error al enviar email de recuperación');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión con el servidor');
      return false;
    }
  }
}
