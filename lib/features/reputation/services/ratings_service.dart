import 'package:dio/dio.dart';
import '../models/user_rating.dart';

/// Service para manejar todas las operaciones relacionadas con valoraciones de usuarios.
///
/// Conecta con los endpoints del backend:
/// - POST /api/users/ratings/rate-user/
/// - GET /api/users/ratings/{user_id}/received-ratings/
/// - GET /api/users/ratings/my-ratings/
/// - PUT /api/users/ratings/{rating_id}/
/// - DELETE /api/users/ratings/{rating_id}/
class RatingsService {
  static final RatingsService _instance = RatingsService._internal();
  static RatingsService get instance => _instance;
  RatingsService._internal();

  Dio? _dio;
  bool _isInitialized = false;

  /// Base URL del backend
  static const String _baseUrl = 'http://10.0.2.2:8000'; // Android emulator

  /// Headers comunes para todas las requests
  Map<String, String> get _commonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Inicializa el service con configuración de Dio
  void initialize({String? baseUrl, String? authToken}) {
    if (_isInitialized && _dio != null) {
      // Si ya está inicializado, solo actualizar el token
      updateAuthToken(authToken);
      return;
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? _baseUrl,
        headers: _commonHeaders,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 15),
      ),
    );

    // Interceptor para autenticación automática y logging
    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Agregar token de autorización si está disponible
          if (authToken != null) {
            options.headers['Authorization'] = 'Bearer $authToken';
          }

          print('🌐 [RATINGS REQUEST] ${options.method} ${options.path}');
          if (options.data != null) {
            print('📤 [RATINGS DATA] ${options.data}');
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            '✅ [RATINGS RESPONSE] ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          print(
            '❌ [RATINGS ERROR] ${error.response?.statusCode} ${error.requestOptions.path}',
          );
          print('📝 [RATINGS ERROR DETAILS] ${error.response?.data}');
          handler.next(error);
        },
      ),
    );

    _isInitialized = true;
  }

  /// Actualiza el token de autenticación
  void updateAuthToken(String? token) {
    if (_dio == null) return;

    if (token != null) {
      _dio!.options.headers['Authorization'] = 'Bearer $token';
    } else {
      _dio!.options.headers.remove('Authorization');
    }
  }

  /// Verifica que el servicio esté inicializado
  void _ensureInitialized() {
    if (_dio == null) {
      throw Exception(
        'RatingsService no ha sido inicializado. Llama initialize() primero.',
      );
    }
  }

  // ===== ENDPOINTS DE VALORACIONES =====

  /// Crea una nueva valoración para un usuario
  ///
  /// Endpoint: POST /api/users/ratings/rate-user/
  Future<RatingsServiceResult<UserRating>> rateUser({
    required int ratedUserId,
    required int rating,
    String? comment,
    String interactionType = 'general',
    String? interactionReference,
  }) async {
    try {
      _ensureInitialized();

      // Validación de entrada
      if (rating < 1 || rating > 5) {
        return RatingsServiceResult.error(
          'La valoración debe estar entre 1 y 5 estrellas',
          type: RatingsServiceErrorType.validation,
        );
      }

      final payload = UserRating.createPayload(
        ratedUserId: ratedUserId,
        rating: rating,
        comment: comment,
        interactionType: interactionType,
        interactionReference: interactionReference,
      );

      final response = await _dio!.post(
        '/api/users/ratings/rate_user/', // URL corregida con underscore
        data: payload,
      );

      if (response.statusCode == 201) {
        final ratingData =
            response.data['rating'] as Map<String, dynamic>? ??
            response.data as Map<String, dynamic>;
        final userRating = UserRating.fromJson(ratingData);
        return RatingsServiceResult.success(userRating);
      } else {
        return RatingsServiceResult.error(
          'Error al crear valoración: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return RatingsServiceResult.error('Error inesperado: $e');
    }
  }

  /// Obtiene las valoraciones recibidas por un usuario
  ///
  /// Endpoint: GET /api/users/ratings/{userId}/received-ratings/
  Future<RatingsServiceResult<RatingsListResponse>> getReceivedRatings(
    int userId, {
    int page = 1,
    int pageSize = 10,
    int? minRating,
    int? maxRating,
    String? interactionType,
    String? orderBy = '-created_at',
  }) async {
    try {
      _ensureInitialized();

      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'ordering': orderBy,
      };

      // Agregar filtros opcionales
      if (minRating != null) queryParams['min_rating'] = minRating;
      if (maxRating != null) queryParams['max_rating'] = maxRating;
      if (interactionType != null)
        queryParams['interaction_type'] = interactionType;

      final response = await _dio!.get(
        '/api/users/ratings/$userId/received_ratings/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final ratingsResponse = RatingsListResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        return RatingsServiceResult.success(ratingsResponse);
      } else {
        return RatingsServiceResult.error(
          'Error al obtener valoraciones recibidas: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return RatingsServiceResult.error('Error inesperado: $e');
    }
  }

  /// Obtiene las valoraciones que el usuario actual ha dado
  ///
  /// Endpoint: GET /api/users/ratings/my-ratings/
  Future<RatingsServiceResult<RatingsListResponse>> getMyRatings({
    int page = 1,
    int pageSize = 10,
    int? minRating,
    int? maxRating,
    String? interactionType,
    String? orderBy = '-created_at',
  }) async {
    try {
      _ensureInitialized();

      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        'ordering': orderBy,
      };

      // Agregar filtros opcionales
      if (minRating != null) queryParams['min_rating'] = minRating;
      if (maxRating != null) queryParams['max_rating'] = maxRating;
      if (interactionType != null)
        queryParams['interaction_type'] = interactionType;

      final response = await _dio!.get(
        '/api/users/ratings/my_ratings/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final ratingsResponse = RatingsListResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        return RatingsServiceResult.success(ratingsResponse);
      } else {
        return RatingsServiceResult.error(
          'Error al obtener mis valoraciones: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return RatingsServiceResult.error('Error inesperado: $e');
    }
  }

  /// Actualiza una valoración existente
  ///
  /// Endpoint: PUT /api/users/ratings/{ratingId}/
  Future<RatingsServiceResult<UserRating>> updateRating(
    int ratingId, {
    int? rating,
    String? comment,
    String? interactionType,
    String? interactionReference,
  }) async {
    try {
      _ensureInitialized();

      final data = <String, dynamic>{};

      if (rating != null) {
        if (rating < 1 || rating > 5) {
          return RatingsServiceResult.error(
            'La valoración debe estar entre 1 y 5 estrellas',
            type: RatingsServiceErrorType.validation,
          );
        }
        data['rating'] = rating;
      }

      if (comment != null) data['comment'] = comment;
      if (interactionType != null) data['interaction_type'] = interactionType;
      if (interactionReference != null)
        data['interaction_reference'] = interactionReference;

      if (data.isEmpty) {
        return RatingsServiceResult.error(
          'Debe proporcionar al menos un campo para actualizar',
          type: RatingsServiceErrorType.validation,
        );
      }

      final response = await _dio!.put(
        '/api/users/ratings/$ratingId/',
        data: data,
      );

      if (response.statusCode == 200) {
        final userRating = UserRating.fromJson(
          response.data as Map<String, dynamic>,
        );
        return RatingsServiceResult.success(userRating);
      } else {
        return RatingsServiceResult.error(
          'Error al actualizar valoración: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return RatingsServiceResult.error('Error inesperado: $e');
    }
  }

  /// Elimina una valoración
  ///
  /// Endpoint: DELETE /api/users/ratings/{ratingId}/
  Future<RatingsServiceResult<void>> deleteRating(int ratingId) async {
    try {
      _ensureInitialized();

      final response = await _dio!.delete('/api/users/ratings/$ratingId/');

      if (response.statusCode == 204 || response.statusCode == 200) {
        return RatingsServiceResult.success(null);
      } else {
        return RatingsServiceResult.error(
          'Error al eliminar valoración: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return RatingsServiceResult.error('Error inesperado: $e');
    }
  }

  /// Verifica si el usuario puede valorar a otro usuario
  ///
  /// Esta función realiza validaciones locales antes de enviar la request
  RatingsServiceResult<void> canRateUser({
    required int currentUserId,
    required int targetUserId,
  }) {
    // No puede valorarse a sí mismo
    if (currentUserId == targetUserId) {
      return RatingsServiceResult.error(
        'No puedes valorarte a ti mismo',
        type: RatingsServiceErrorType.validation,
      );
    }

    // Otras validaciones podrían agregarse aquí
    // Por ejemplo: verificar membresía en comunidades comunes, etc.

    return RatingsServiceResult.success(null);
  }

  /// Verifica si el usuario actual ya valoró a un usuario específico
  ///
  /// Retorna la valoración existente si existe, null si no
  Future<RatingsServiceResult<UserRating?>> getExistingRatingForUser(
    int userId,
  ) async {
    try {
      _ensureInitialized();

      // Obtener todas las valoraciones del usuario actual
      final myRatingsResult = await getMyRatings(
        pageSize: 100,
      ); // Obtener más resultados

      if (!myRatingsResult.isSuccess) {
        return RatingsServiceResult.error(
          myRatingsResult.error ?? 'Error al obtener valoraciones',
        );
      }

      final myRatings = myRatingsResult.data!;

      // Buscar si ya existe una valoración para este usuario
      for (final rating in myRatings.ratings) {
        if (rating.ratedUserId == userId) {
          return RatingsServiceResult.success(rating);
        }
      }

      // No se encontró valoración existente
      return RatingsServiceResult.success(null);
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return RatingsServiceResult.error('Error inesperado: $e');
    }
  }

  /// Obtiene estadísticas de rate limiting para el usuario actual
  ///
  /// Endpoint: GET /api/users/rating-limits/
  Future<RatingsServiceResult<Map<String, dynamic>>> getRatingLimits() async {
    try {
      _ensureInitialized();

      final response = await _dio!.get('/api/users/rating-limits/');

      if (response.statusCode == 200) {
        return RatingsServiceResult.success(
          response.data as Map<String, dynamic>,
        );
      } else {
        return RatingsServiceResult.error(
          'Error al obtener límites de valoración: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return RatingsServiceResult.error('Error inesperado: $e');
    }
  }

  // ===== HELPERS PRIVADOS =====

  /// Maneja errores de Dio de forma consistente
  RatingsServiceResult<T> _handleDioError<T>(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return RatingsServiceResult.error(
          'Tiempo de espera agotado. Verifica tu conexión.',
          type: RatingsServiceErrorType.timeout,
        );

      case DioExceptionType.connectionError:
        return RatingsServiceResult.error(
          'Error de conexión. Verifica tu conexión a internet.',
          type: RatingsServiceErrorType.network,
        );

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;

        String message = 'Error del servidor';
        if (responseData is Map<String, dynamic>) {
          message =
              responseData['error']?.toString() ??
              responseData['message']?.toString() ??
              responseData['detail']?.toString() ??
              message;
        } else if (responseData is String) {
          message = responseData;
        }

        switch (statusCode) {
          case 400:
            return RatingsServiceResult.error(
              message,
              type: RatingsServiceErrorType.validation,
              statusCode: statusCode,
            );
          case 401:
            return RatingsServiceResult.error(
              'Sesión expirada. Inicia sesión nuevamente.',
              type: RatingsServiceErrorType.unauthorized,
              statusCode: statusCode,
            );
          case 403:
            return RatingsServiceResult.error(
              'No tienes permisos para realizar esta acción.',
              type: RatingsServiceErrorType.forbidden,
              statusCode: statusCode,
            );
          case 404:
            return RatingsServiceResult.error(
              'Usuario o valoración no encontrada.',
              type: RatingsServiceErrorType.notFound,
              statusCode: statusCode,
            );
          case 409:
            return RatingsServiceResult.error(
              'Ya has valorado a este usuario.',
              type: RatingsServiceErrorType.conflict,
              statusCode: statusCode,
            );
          case 429:
            return RatingsServiceResult.error(
              'Has alcanzado el límite de valoraciones. Intenta más tarde.',
              type: RatingsServiceErrorType.rateLimit,
              statusCode: statusCode,
            );
          default:
            return RatingsServiceResult.error(
              message,
              type: RatingsServiceErrorType.server,
              statusCode: statusCode,
            );
        }

      default:
        return RatingsServiceResult.error(
          'Error inesperado: ${e.message}',
          type: RatingsServiceErrorType.unknown,
        );
    }
  }
}

/// Resultado de operaciones del RatingsService
class RatingsServiceResult<T> {
  final T? data;
  final String? error;
  final RatingsServiceErrorType? errorType;
  final int? statusCode;
  final bool isSuccess;

  const RatingsServiceResult._({
    this.data,
    this.error,
    this.errorType,
    this.statusCode,
    required this.isSuccess,
  });

  /// Constructor para resultados exitosos
  factory RatingsServiceResult.success(T? data) {
    return RatingsServiceResult._(data: data, isSuccess: true);
  }

  /// Constructor para errores
  factory RatingsServiceResult.error(
    String error, {
    RatingsServiceErrorType? type,
    int? statusCode,
  }) {
    return RatingsServiceResult._(
      error: error,
      errorType: type ?? RatingsServiceErrorType.unknown,
      statusCode: statusCode,
      isSuccess: false,
    );
  }

  /// Retorna true si la operación fue exitosa
  bool get isError => !isSuccess;

  /// Ejecuta una función si el resultado es exitoso
  void onSuccess(void Function(T? data) callback) {
    if (isSuccess) {
      callback(data);
    }
  }

  /// Ejecuta una función si el resultado es un error
  void onError(
    void Function(String error, RatingsServiceErrorType? type) callback,
  ) {
    if (isError && error != null) {
      callback(error!, errorType);
    }
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'RatingsServiceResult.success($data)';
    } else {
      return 'RatingsServiceResult.error($error, type: $errorType, status: $statusCode)';
    }
  }
}

/// Tipos de errores del RatingsService
enum RatingsServiceErrorType {
  network, // Problemas de conectividad
  timeout, // Timeout de conexión
  unauthorized, // 401 - Token inválido/expirado
  forbidden, // 403 - Sin permisos
  notFound, // 404 - Recurso no encontrado
  conflict, // 409 - Conflicto (ej: valoración duplicada)
  rateLimit, // 429 - Demasiadas requests
  server, // 5xx - Error del servidor
  validation, // 400 - Datos inválidos
  unknown, // Error desconocido
}

/// Respuesta paginada de valoraciones
class RatingsListResponse {
  final List<UserRating> ratings;
  final RatingsListPagination pagination;
  final RatingsListFilters? filters;

  const RatingsListResponse({
    required this.ratings,
    required this.pagination,
    this.filters,
  });

  factory RatingsListResponse.fromJson(Map<String, dynamic> json) {
    final ratingsData =
        json['results'] as List? ?? json['ratings'] as List? ?? [];

    return RatingsListResponse(
      ratings: ratingsData
          .map((item) => UserRating.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: RatingsListPagination.fromJson(json),
      filters: json['filters'] != null
          ? RatingsListFilters.fromJson(json['filters'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Retorna true si hay más páginas disponibles
  bool get hasMorePages => pagination.hasNext;

  /// Retorna el número total de valoraciones
  int get totalCount => pagination.totalCount;
}

/// Información de paginación para listas de valoraciones
class RatingsListPagination {
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final int pageSize;
  final bool hasNext;
  final bool hasPrevious;

  const RatingsListPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalCount,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory RatingsListPagination.fromJson(Map<String, dynamic> json) {
    return RatingsListPagination(
      currentPage: json['current_page'] as int? ?? json['page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
      totalCount: json['total_count'] as int? ?? json['count'] as int? ?? 0,
      pageSize: json['page_size'] as int? ?? 10,
      hasNext: json['has_next'] as bool? ?? false,
      hasPrevious: json['has_previous'] as bool? ?? false,
    );
  }
}

/// Filtros aplicados a listas de valoraciones
class RatingsListFilters {
  final int? minRating;
  final int? maxRating;
  final String? interactionType;
  final String? orderBy;

  const RatingsListFilters({
    this.minRating,
    this.maxRating,
    this.interactionType,
    this.orderBy,
  });

  factory RatingsListFilters.fromJson(Map<String, dynamic> json) {
    return RatingsListFilters(
      minRating: json['min_rating'] as int?,
      maxRating: json['max_rating'] as int?,
      interactionType: json['interaction_type'] as String?,
      orderBy: json['order_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (minRating != null) 'min_rating': minRating,
      if (maxRating != null) 'max_rating': maxRating,
      if (interactionType != null) 'interaction_type': interactionType,
      if (orderBy != null) 'order_by': orderBy,
    };
  }

  /// Retorna true si hay filtros activos
  bool get hasActiveFilters {
    return minRating != null ||
        maxRating != null ||
        interactionType != null ||
        orderBy != null;
  }
}
