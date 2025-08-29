import 'package:flutter/foundation.dart';
import '../models/user_rating.dart';
import '../services/ratings_service.dart';

/// Estados para las operaciones de valoraciones
enum RatingsState {
  initial,
  loading,
  loaded,
  creating,
  updating,
  deleting,
  error,
}

/// Provider para la gestión del estado del sistema de valoraciones
///
/// Maneja:
/// - Creación de nuevas valoraciones
/// - Lista de valoraciones recibidas
/// - Lista de valoraciones dadas
/// - Actualización y eliminación de valoraciones
/// - Rate limiting y validaciones
/// - Cache inteligente con paginación
class RatingsProvider with ChangeNotifier {
  final RatingsService _ratingsService = RatingsService.instance;

  // Estados principales
  RatingsState _state = RatingsState.initial;
  String? _errorMessage;

  // Cache de valoraciones recibidas (por usuario)
  final Map<int, List<UserRating>> _receivedRatingsCache = {};
  final Map<int, RatingsListPagination> _receivedPaginationCache = {};

  // Mis valoraciones dadas
  List<UserRating>? _myRatings;
  RatingsListPagination? _myRatingsPagination;

  // Estado específico para mis valoraciones
  RatingsState _myRatingsState = RatingsState.initial;
  String? _myRatingsError;

  // Rate limiting info
  Map<String, dynamic>? _rateLimits;
  DateTime? _rateLimitsLastFetch;

  // Configuración de cache (2 minutos para valoraciones activas)
  static const Duration _cacheExpiration = Duration(minutes: 2);
  final Map<int, DateTime> _cacheTimestamps = {};

  // ===== GETTERS PÚBLICOS =====

  RatingsState get state => _state;
  RatingsState get myRatingsState => _myRatingsState;
  String? get errorMessage => _errorMessage;
  String? get myRatingsError => _myRatingsError;
  List<UserRating>? get myRatings => _myRatings;
  Map<String, dynamic>? get rateLimits => _rateLimits;

  bool get isLoading => _state == RatingsState.loading;
  bool get isCreating => _state == RatingsState.creating;
  bool get isUpdating => _state == RatingsState.updating;
  bool get isDeleting => _state == RatingsState.deleting;
  bool get hasError => _state == RatingsState.error;
  bool get isMyRatingsLoading => _myRatingsState == RatingsState.loading;
  bool get hasMyRatingsError => _myRatingsState == RatingsState.error;

  // ===== MÉTODOS PÚBLICOS =====

  /// Inicializa el provider con token de autenticación
  void initialize(String? authToken) {
    _ratingsService.initialize(authToken: authToken);
  }

  /// Actualiza el token de autenticación
  void updateAuthToken(String? token) {
    _ratingsService.updateAuthToken(token);
  }

  /// Crea una nueva valoración para un usuario
  Future<bool> rateUser({
    required int ratedUserId,
    required int rating,
    String? comment,
    String interactionType = 'general',
    String? interactionReference,
    int? currentUserId,
  }) async {
    // Validación local primero
    if (currentUserId != null) {
      final validationResult = _ratingsService.canRateUser(
        currentUserId: currentUserId,
        targetUserId: ratedUserId,
      );

      if (validationResult.isError) {
        _errorMessage = validationResult.error;
        _setState(RatingsState.error);
        return false;
      }
    }

    _setState(RatingsState.creating);

    try {
      final result = await _ratingsService.rateUser(
        ratedUserId: ratedUserId,
        rating: rating,
        comment: comment,
        interactionType: interactionType,
        interactionReference: interactionReference,
      );

      result.onSuccess((userRating) {
        // Agregar a mis valoraciones si están cargadas
        if (_myRatings != null && userRating != null) {
          _myRatings!.insert(0, userRating);
        }

        // Invalidar cache del usuario valorado
        _invalidateUserCache(ratedUserId);

        _errorMessage = null;
        _setState(RatingsState.loaded);
        debugPrint('✅ [RATINGS] Valoración creada exitosamente');
      });

      result.onError((error, type) {
        _errorMessage = error;
        _setState(RatingsState.error);
        debugPrint('❌ [RATINGS] Error creando valoración: $error');
      });

      return result.isSuccess;
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _setState(RatingsState.error);
      debugPrint('❌ [RATINGS] Error inesperado: $e');
      return false;
    }
  }

  /// Obtiene las valoraciones recibidas por un usuario
  Future<List<UserRating>?> getReceivedRatings(
    int userId, {
    int page = 1,
    int pageSize = 10,
    int? minRating,
    int? maxRating,
    String? interactionType,
    String? orderBy = '-created_at',
    bool forceRefresh = false,
  }) async {
    debugPrint(
      '🚀 [RATINGS] getReceivedRatings iniciado para usuario $userId (página $page, tamaño $pageSize)',
    );

    // Verificar cache para la primera página
    if (page == 1 && !forceRefresh && _isReceivedRatingsCached(userId)) {
      debugPrint(
        '🎯 [RATINGS] Usando cache para valoraciones recibidas del usuario $userId',
      );
      return _receivedRatingsCache[userId];
    }

    _setState(RatingsState.loading);
    debugPrint(
      '🔄 [RATINGS] Cargando valoraciones recibidas desde API para usuario $userId',
    );

    try {
      final result = await _ratingsService.getReceivedRatings(
        userId,
        page: page,
        pageSize: pageSize,
        minRating: minRating,
        maxRating: maxRating,
        interactionType: interactionType,
        orderBy: orderBy,
      );

      result.onSuccess((response) {
        if (response != null) {
          if (page == 1) {
            // Primera página: reemplazar datos
            _receivedRatingsCache[userId] = response.ratings;
            _receivedPaginationCache[userId] = response.pagination;
            _cacheTimestamps[userId] = DateTime.now();
          } else {
            // Páginas siguientes: agregar al final
            final existingRatings = _receivedRatingsCache[userId] ?? [];
            _receivedRatingsCache[userId] = [
              ...existingRatings,
              ...response.ratings,
            ];
            _receivedPaginationCache[userId] = response.pagination;
          }
        }

        _errorMessage = null;
        _setState(RatingsState.loaded);
        debugPrint(
          '✅ [RATINGS] Valoraciones recibidas cargadas (usuario $userId, página $page)',
        );
      });

      result.onError((error, type) {
        _errorMessage = error;
        _setState(RatingsState.error);
        debugPrint('❌ [RATINGS] Error cargando valoraciones recibidas: $error');
      });

      return result.data?.ratings;
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _setState(RatingsState.error);
      debugPrint('❌ [RATINGS] Error inesperado: $e');
      return null;
    }
  }

  /// Obtiene las valoraciones que el usuario actual ha dado
  Future<List<UserRating>?> getMyRatings({
    int page = 1,
    int pageSize = 10,
    int? minRating,
    int? maxRating,
    String? interactionType,
    String? orderBy = '-created_at',
    bool forceRefresh = false,
  }) async {
    // Verificar cache para la primera página
    if (page == 1 && !forceRefresh && _myRatings != null) {
      debugPrint('🎯 [RATINGS] Usando cache para mis valoraciones');
      return _myRatings;
    }

    _setMyRatingsState(RatingsState.loading);

    try {
      final result = await _ratingsService.getMyRatings(
        page: page,
        pageSize: pageSize,
        minRating: minRating,
        maxRating: maxRating,
        interactionType: interactionType,
        orderBy: orderBy,
      );

      result.onSuccess((response) {
        if (response != null) {
          if (page == 1) {
            // Primera página: reemplazar datos
            _myRatings = response.ratings;
            _myRatingsPagination = response.pagination;
          } else {
            // Páginas siguientes: agregar al final
            if (_myRatings != null) {
              _myRatings!.addAll(response.ratings);
              _myRatingsPagination = response.pagination;
            } else {
              _myRatings = response.ratings;
              _myRatingsPagination = response.pagination;
            }
          }
        }

        _myRatingsError = null;
        _setMyRatingsState(RatingsState.loaded);
        debugPrint('✅ [RATINGS] Mis valoraciones cargadas (página $page)');
      });

      result.onError((error, type) {
        _myRatingsError = error;
        _setMyRatingsState(RatingsState.error);
        debugPrint('❌ [RATINGS] Error cargando mis valoraciones: $error');
      });

      return result.data?.ratings;
    } catch (e) {
      _myRatingsError = 'Error inesperado: $e';
      _setMyRatingsState(RatingsState.error);
      debugPrint('❌ [RATINGS] Error inesperado: $e');
      return null;
    }
  }

  /// Actualiza una valoración existente
  Future<bool> updateRating(
    int ratingId, {
    int? rating,
    String? comment,
    String? interactionType,
    String? interactionReference,
  }) async {
    _setState(RatingsState.updating);

    try {
      final result = await _ratingsService.updateRating(
        ratingId,
        rating: rating,
        comment: comment,
        interactionType: interactionType,
        interactionReference: interactionReference,
      );

      result.onSuccess((updatedRating) {
        // Actualizar en mis valoraciones si está en la lista
        if (_myRatings != null && updatedRating != null) {
          final index = _myRatings!.indexWhere((r) => r.id == ratingId);
          if (index != -1) {
            _myRatings![index] = updatedRating;
          }
        }

        // Actualizar en cache de valoraciones recibidas si corresponde
        if (updatedRating != null) {
          _updateRatingInCache(updatedRating);
        }

        _errorMessage = null;
        _setState(RatingsState.loaded);
        debugPrint('✅ [RATINGS] Valoración actualizada exitosamente');
      });

      result.onError((error, type) {
        _errorMessage = error;
        _setState(RatingsState.error);
        debugPrint('❌ [RATINGS] Error actualizando valoración: $error');
      });

      return result.isSuccess;
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _setState(RatingsState.error);
      debugPrint('❌ [RATINGS] Error inesperado: $e');
      return false;
    }
  }

  /// Elimina una valoración
  Future<bool> deleteRating(int ratingId) async {
    _setState(RatingsState.deleting);

    try {
      final result = await _ratingsService.deleteRating(ratingId);

      result.onSuccess((_) {
        // Remover de mis valoraciones si está en la lista
        if (_myRatings != null) {
          _myRatings!.removeWhere((r) => r.id == ratingId);
        }

        // Remover del cache de valoraciones recibidas
        _removeRatingFromCache(ratingId);

        _errorMessage = null;
        _setState(RatingsState.loaded);
        debugPrint('✅ [RATINGS] Valoración eliminada exitosamente');
      });

      result.onError((error, type) {
        _errorMessage = error;
        _setState(RatingsState.error);
        debugPrint('❌ [RATINGS] Error eliminando valoración: $error');
      });

      return result.isSuccess;
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _setState(RatingsState.error);
      debugPrint('❌ [RATINGS] Error inesperado: $e');
      return false;
    }
  }

  /// Obtiene información de rate limiting
  Future<Map<String, dynamic>?> getRatingLimits({
    bool forceRefresh = false,
  }) async {
    // Cache de 1 minuto para rate limits
    if (!forceRefresh &&
        _rateLimits != null &&
        _rateLimitsLastFetch != null &&
        DateTime.now().difference(_rateLimitsLastFetch!).inMinutes < 1) {
      return _rateLimits;
    }

    try {
      final result = await _ratingsService.getRatingLimits();

      result.onSuccess((limits) {
        _rateLimits = limits;
        _rateLimitsLastFetch = DateTime.now();
        debugPrint('✅ [RATINGS] Rate limits obtenidos');
      });

      result.onError((error, type) {
        debugPrint('❌ [RATINGS] Error obteniendo rate limits: $error');
      });

      return result.data;
    } catch (e) {
      debugPrint('❌ [RATINGS] Error inesperado obteniendo rate limits: $e');
      return null;
    }
  }

  // ===== MÉTODOS DE CACHE =====

  /// Verifica si las valoraciones recibidas están en cache y son válidas
  bool _isReceivedRatingsCached(int userId) {
    if (!_receivedRatingsCache.containsKey(userId) ||
        !_cacheTimestamps.containsKey(userId)) {
      return false;
    }

    final timestamp = _cacheTimestamps[userId]!;
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    return difference < _cacheExpiration;
  }

  /// Invalida el cache de un usuario específico
  void _invalidateUserCache(int userId) {
    _receivedRatingsCache.remove(userId);
    _receivedPaginationCache.remove(userId);
    _cacheTimestamps.remove(userId);
    debugPrint('🗑️ [RATINGS] Cache invalidado para usuario $userId');
  }

  /// Actualiza una valoración específica en el cache
  void _updateRatingInCache(UserRating updatedRating) {
    for (final userId in _receivedRatingsCache.keys) {
      final ratings = _receivedRatingsCache[userId]!;
      final index = ratings.indexWhere((r) => r.id == updatedRating.id);
      if (index != -1) {
        ratings[index] = updatedRating;
        debugPrint(
          '✏️ [RATINGS] Valoración actualizada en cache para usuario $userId',
        );
        break;
      }
    }
  }

  /// Remueve una valoración específica del cache
  void _removeRatingFromCache(int ratingId) {
    for (final userId in _receivedRatingsCache.keys) {
      final ratings = _receivedRatingsCache[userId]!;
      ratings.removeWhere((r) => r.id == ratingId);
      debugPrint(
        '🗑️ [RATINGS] Valoración removida del cache para usuario $userId',
      );
    }
  }

  /// Limpia todo el cache
  void clearAllCache() {
    _receivedRatingsCache.clear();
    _receivedPaginationCache.clear();
    _cacheTimestamps.clear();
    _myRatings = null;
    _myRatingsPagination = null;
    _rateLimits = null;
    _rateLimitsLastFetch = null;
    debugPrint('🗑️ [RATINGS] Todo el cache limpiado');
  }

  /// Invalida solo mis valoraciones
  void invalidateMyRatings() {
    _myRatings = null;
    _myRatingsPagination = null;
    debugPrint('🗑️ [RATINGS] Cache de mis valoraciones invalidado');
  }

  // ===== MÉTODOS AUXILIARES =====

  /// Obtiene valoraciones recibidas desde cache (sin network)
  List<UserRating>? getCachedReceivedRatings(int userId) {
    if (_isReceivedRatingsCached(userId)) {
      final ratings = _receivedRatingsCache[userId];
      return ratings;
    }
    return null;
  }

  /// Obtiene la paginación de valoraciones recibidas
  RatingsListPagination? getReceivedRatingsPagination(int userId) {
    return _receivedPaginationCache[userId];
  }

  /// Verifica si hay más páginas disponibles para valoraciones recibidas
  bool hasMoreReceivedRatings(int userId) {
    final pagination = _receivedPaginationCache[userId];
    return pagination?.hasNext ?? false;
  }

  /// Verifica si hay más páginas disponibles para mis valoraciones
  bool get hasMoreMyRatings {
    return _myRatingsPagination?.hasNext ?? false;
  }

  /// Obtiene el número total de valoraciones recibidas de un usuario
  int getTotalReceivedRatings(int userId) {
    return _receivedPaginationCache[userId]?.totalCount ?? 0;
  }

  /// Obtiene el número total de mis valoraciones
  int get totalMyRatings {
    return _myRatingsPagination?.totalCount ?? 0;
  }

  /// Busca una valoración específica por ID en el cache
  UserRating? findRatingById(int ratingId) {
    // Buscar en mis valoraciones
    if (_myRatings != null) {
      try {
        return _myRatings!.firstWhere((r) => r.id == ratingId);
      } catch (e) {
        // No encontrada en mis valoraciones
      }
    }

    // Buscar en valoraciones recibidas de todos los usuarios
    for (final ratings in _receivedRatingsCache.values) {
      try {
        return ratings.firstWhere((r) => r.id == ratingId);
      } catch (e) {
        // Continuar buscando
      }
    }

    return null;
  }

  /// Verifica si el usuario puede crear más valoraciones según rate limits
  bool canCreateMoreRatings() {
    if (_rateLimits == null) return true; // Si no tenemos info, asumir que sí

    final remainingToday = _rateLimits!['remaining_today'] as int? ?? 0;
    return remainingToday > 0;
  }

  /// Obtiene mensaje descriptivo del rate limit
  String? getRateLimitMessage() {
    if (_rateLimits == null) return null;

    final remainingToday = _rateLimits!['remaining_today'] as int? ?? 0;
    final limitPerDay = _rateLimits!['limit_per_day'] as int? ?? 0;

    if (remainingToday <= 0) {
      return 'Has alcanzado el límite diario de $limitPerDay valoraciones. Intenta mañana.';
    }

    if (remainingToday <= 3) {
      return 'Te quedan $remainingToday valoraciones por hoy.';
    }

    return null;
  }

  // ===== MÉTODOS PRIVADOS =====

  void _setState(RatingsState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  void _setMyRatingsState(RatingsState newState) {
    if (_myRatingsState != newState) {
      _myRatingsState = newState;
      notifyListeners();
    }
  }

  /// Limpia el estado cuando el usuario se desconecta
  @override
  void dispose() {
    clearAllCache();
    _state = RatingsState.initial;
    _myRatingsState = RatingsState.initial;
    _errorMessage = null;
    _myRatingsError = null;
    super.dispose();
  }

  // ===== MÉTODOS PARA UI =====

  /// Retorna un mensaje de error amigable para mostrar en UI
  String? get friendlyErrorMessage {
    if (_errorMessage == null) return null;

    // Convertir errores técnicos en mensajes amigables
    if (_errorMessage!.toLowerCase().contains('ya has valorado')) {
      return 'Ya has valorado a este usuario anteriormente.';
    }
    if (_errorMessage!.toLowerCase().contains('no puedes valorarte')) {
      return 'No puedes valorarte a ti mismo.';
    }
    if (_errorMessage!.toLowerCase().contains('límite')) {
      return 'Has alcanzado el límite de valoraciones por hoy.';
    }
    if (_errorMessage!.contains('connection')) {
      return 'Problemas de conexión. Verifica tu internet.';
    }
    if (_errorMessage!.contains('timeout')) {
      return 'La conexión tardó demasiado. Intenta de nuevo.';
    }
    if (_errorMessage!.contains('unauthorized') ||
        _errorMessage!.contains('401')) {
      return 'Tu sesión ha expirado. Inicia sesión nuevamente.';
    }

    return _errorMessage;
  }

  /// Verifica si el usuario actual ya valoró a un usuario específico
  ///
  /// Busca en el cache local primero, luego consulta al servidor si es necesario
  Future<RatingsServiceResult<UserRating?>> getExistingRatingForUser(
    int userId,
  ) async {
    try {
      // Nota: Este método requiere que el provider ya esté inicializado
      // desde el contexto donde se llama

      // Primero verificar en el cache local de mis valoraciones
      if (_myRatings != null) {
        for (final rating in _myRatings!) {
          if (rating.ratedUserId == userId) {
            return RatingsServiceResult.success(rating);
          }
        }
      }

      // Si no está en cache, consultar al servidor
      return await _ratingsService.getExistingRatingForUser(userId);
    } catch (e) {
      debugPrint('❌ [RATINGS] Error verificando valoración existente: $e');
      return RatingsServiceResult.error('Error al verificar valoración: $e');
    }
  }

  /// Retorna métricas del cache para debugging
  Map<String, dynamic> getCacheMetrics() {
    return {
      'received_ratings_cache_size': _receivedRatingsCache.length,
      'received_pagination_cache_size': _receivedPaginationCache.length,
      'my_ratings_count': _myRatings?.length ?? 0,
      'has_rate_limits': _rateLimits != null,
      'cache_timestamps': _cacheTimestamps.length,
    };
  }
}
