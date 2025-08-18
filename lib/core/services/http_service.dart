import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

/// Servicio base HTTP usando Dio para todas las llamadas a la API
class HttpService {
  static final HttpService _instance = HttpService._internal();
  factory HttpService() => _instance;
  HttpService._internal();

  late final Dio _dio;
  bool _isInitialized = false;

  /// Inicializar el servicio HTTP
  void initialize() {
    if (_isInitialized) {
      debugPrint('⚠️ HttpService ya está inicializado');
      return; // Evitar doble inicialización
    }

    debugPrint('🚀 Inicializando HttpService...');
    debugPrint('🌐 Base URL: ${ApiConfig.baseUrl}');

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        sendTimeout: ApiConfig.sendTimeout,
        headers: ApiConfig.defaultHeaders,
      ),
    );

    debugPrint('⏱️ Timeouts configurados:');
    debugPrint('  - Connect: ${ApiConfig.connectTimeout}');
    debugPrint('  - Receive: ${ApiConfig.receiveTimeout}');
    debugPrint('  - Send: ${ApiConfig.sendTimeout}');

    // Agregar interceptors solo en modo debug
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: true,
          logPrint: (object) {
            debugPrint('🌐 HTTP: $object');
          },
        ),
      );
    }

    _isInitialized = true;

    // Interceptor para manejo de errores de autenticación
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            debugPrint('🚨 Error 401: Token expirado o inválido');
            // Aquí podrías disparar un evento para hacer logout automático
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Configurar token de autenticación
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    debugPrint('🔐 Token de autenticación configurado');
  }

  /// Limpiar token de autenticación
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
    debugPrint('🔓 Token de autenticación eliminado');
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      debugPrint('📤 POST Request:');
      debugPrint('  - Path: $path');
      debugPrint('  - Full URL: ${_dio.options.baseUrl}$path');
      debugPrint('  - Data: $data');
      debugPrint('  - Query params: $queryParameters');

      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );

      debugPrint('📥 POST Response:');
      debugPrint('  - Status: ${response.statusCode}');
      debugPrint('  - Data: ${response.data}');

      return response;
    } on DioException catch (e) {
      debugPrint('🚨 POST Error: $e');
      throw _handleDioError(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Manejo centralizado de errores Dio
  Exception _handleDioError(DioException error) {
    String message;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Error de conexión: Tiempo de espera agotado';
        break;
      case DioExceptionType.badResponse:
        message = _handleHttpError(error.response!);
        break;
      case DioExceptionType.cancel:
        message = 'Petición cancelada';
        break;
      case DioExceptionType.connectionError:
        message = 'Error de conexión: Verifique su conexión a internet';
        break;
      default:
        message = 'Error inesperado: ${error.message}';
    }

    debugPrint('🚨 HttpService Error: $message');
    return HttpException(message, error.response?.statusCode);
  }

  /// Manejo específico de errores HTTP
  String _handleHttpError(Response response) {
    switch (response.statusCode) {
      case 400:
        // Intentar extraer mensaje de error específico del backend
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          if (data.containsKey('detail')) {
            return data['detail'].toString();
          }
          if (data.containsKey('error')) {
            return data['error'].toString();
          }
          // Manejar errores de validación de campos
          if (data.containsKey('username')) {
            return 'Error en username: ${data['username']}';
          }
          if (data.containsKey('email')) {
            return 'Error en email: ${data['email']}';
          }
          if (data.containsKey('password')) {
            return 'Error en contraseña: ${data['password']}';
          }
        }
        return 'Datos inválidos';
      case 401:
        return 'No autorizado: Credenciales inválidas';
      case 403:
        return 'Acceso denegado';
      case 404:
        return 'Recurso no encontrado';
      case 422:
        return 'Datos de entrada inválidos';
      case 500:
        return 'Error interno del servidor';
      default:
        return 'Error ${response.statusCode}: ${response.statusMessage}';
    }
  }
}

/// Excepción personalizada para errores HTTP
class HttpException implements Exception {
  final String message;
  final int? statusCode;

  const HttpException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'HttpException: $message${statusCode != null ? ' (${statusCode})' : ''}';
}
