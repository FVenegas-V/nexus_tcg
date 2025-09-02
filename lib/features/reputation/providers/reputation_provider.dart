import 'package:flutter/foundation.dart';
import '../models/reputation_stats.dart';
import '../models/rating_summary.dart';
import '../models/leaderboard_entry.dart';
import '../services/reputation_service.dart';

/// Estados para las operaciones de reputación
enum ReputationState { initial, loading, loaded, updating, error }

/// Provider para la gestión del estado del sistema de reputación
///
/// Maneja:
/// - Estadísticas de reputación de usuarios
/// - Resúmenes de valoraciones
/// - Leaderboard global
/// - Cache inteligente
/// - Actualizaciones en tiempo real
class ReputationProvider with ChangeNotifier {
  final ReputationService _reputationService = ReputationService.instance;

  // Estados principales
  ReputationState _state = ReputationState.initial;
  String? _errorMessage;

  // Cache de datos de reputación
  final Map<int, ReputationStats> _reputationCache = {};
  final Map<int, RatingSummary> _summaryCache = {};
  final Map<int, DateTime> _cacheTimestamps = {};
  final Map<int, String> _usernameCache = {};

  // Leaderboard data
  LeaderboardResponse? _currentLeaderboard;
  ReputationState _leaderboardState = ReputationState.initial;
  String? _leaderboardError;

  // Configuración de cache (5 minutos)
  static const Duration _cacheExpiration = Duration(minutes: 5);

  // ===== GETTERS PÚBLICOS =====

  ReputationState get state => _state;
  ReputationState get leaderboardState => _leaderboardState;
  String? get errorMessage => _errorMessage;
  String? get leaderboardError => _leaderboardError;
  LeaderboardResponse? get currentLeaderboard => _currentLeaderboard;

  bool get isLoading => _state == ReputationState.loading;
  bool get isUpdating => _state == ReputationState.updating;
  bool get hasError => _state == ReputationState.error;
  bool get isLeaderboardLoading => _leaderboardState == ReputationState.loading;
  bool get hasLeaderboardError => _leaderboardState == ReputationState.error;

  /// Obtiene el username del cache para un usuario específico
  String? getCachedUsername(int userId) {
    return _usernameCache[userId];
  }

  // ===== MÉTODOS PÚBLICOS =====

  /// Inicializa el provider (ya no necesario ya que ReputationService usa HttpService directamente)
  void initialize(String? authToken) {
    // ReputationService usa automáticamente el token a través de HttpService
    debugPrint(
      '🔧 [REPUTATION] Provider inicializado (usando HttpService para autenticación)',
    );
  }

  /// Actualiza el token de autenticación y limpia errores de autenticación
  void updateAuthToken(String? token) {
    // ReputationService usa automáticamente el token a través de HttpService
    debugPrint(
      '🔧 [REPUTATION] Token actualizado automáticamente via HttpService',
    );

    // Limpiar errores de autenticación cuando se actualiza el token
    if (_errorMessage?.contains('401') == true ||
        _errorMessage?.contains('No autorizado') == true) {
      _errorMessage = null;
      _setState(ReputationState.initial);
      debugPrint('🧹 [REPUTATION] Errores de autenticación limpiados');
    }
  }

  /// Limpia errores de autenticación para permitir nuevos intentos
  void clearAuthErrors() {
    if (_errorMessage?.contains('401') == true ||
        _errorMessage?.contains('No autorizado') == true) {
      _errorMessage = null;
      _setState(ReputationState.initial);
      debugPrint(
        '🧹 [REPUTATION] Errores de autenticación limpiados manualmente',
      );
    }
  }

  /// Obtiene las estadísticas de reputación de un usuario
  Future<ReputationStats?> getReputationStats(
    int userId, {
    bool forceRefresh = false,
  }) async {
    // Verificar cache primero
    if (!forceRefresh && _isDataCached(userId)) {
      debugPrint('🎯 [REPUTATION] Usando cache para usuario $userId');
      return _reputationCache[userId];
    }

    // Evitar reintentos si ya hay un error de autenticación
    if (_state == ReputationState.error &&
        _errorMessage?.contains('401') == true) {
      debugPrint(
        '🚫 [REPUTATION] Evitando reintento por error de autenticación',
      );
      return null;
    }

    _setState(ReputationState.loading);

    try {
      final result = await _reputationService.getUserReputationStats(userId);

      if (result.isSuccess) {
        // Adaptar datos de ratings stats a reputation stats
        final data = result.data!;

        // Verificar si tenemos datos válidos
        if (data.containsKey('stats')) {
          // Estructura: { "user": {...}, "stats": {...} }
          final statsData = data['stats'] as Map<String, dynamic>;
          final userData = data['user'] as Map<String, dynamic>;

          // Crear datos adaptados para ReputationStats
          final adaptedData = _adaptRatingStatsToReputationStats(
            statsData,
            userData,
          );

          final stats = ReputationStats.fromJson(adaptedData);
          _reputationCache[userId] = stats;
          _cacheTimestamps[userId] = DateTime.now();
          _usernameCache[userId] = userData['username'] as String;
          _errorMessage = null;
          _setState(ReputationState.loaded);
          debugPrint(
            '✅ [REPUTATION] Estadísticas cargadas para usuario $userId',
          );
          return stats;
        } else {
          // Datos ya adaptados
          final stats = ReputationStats.fromJson(data);
          _reputationCache[userId] = stats;
          _cacheTimestamps[userId] = DateTime.now();
          _errorMessage = null;
          _setState(ReputationState.loaded);
          debugPrint(
            '✅ [REPUTATION] Estadísticas cargadas para usuario $userId',
          );
          return stats;
        }
      } else {
        _errorMessage = result.error ?? 'Error desconocido';
        _setState(ReputationState.error);
        debugPrint(
          '❌ [REPUTATION] Error cargando estadísticas: ${result.error}',
        );
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _setState(ReputationState.error);
      debugPrint('❌ [REPUTATION] Error inesperado: $e');
      return null;
    }
  }

  /// Obtiene el resumen de valoraciones de un usuario
  Future<RatingSummary?> getRatingSummary(
    int userId, {
    bool forceRefresh = false,
  }) async {
    // Verificar cache
    if (!forceRefresh && _isSummaryCached(userId)) {
      debugPrint(
        '🎯 [REPUTATION] Usando cache de resumen para usuario $userId',
      );
      return _summaryCache[userId];
    }

    _setState(ReputationState.loading);

    try {
      final result = await _reputationService.getUserRatingStats(userId);

      if (result.isSuccess) {
        final summary = RatingSummary.fromJson(result.data!);
        _summaryCache[userId] = summary;
        _cacheTimestamps[userId] = DateTime.now();
        _errorMessage = null;
        _setState(ReputationState.loaded);
        debugPrint('✅ [REPUTATION] Resumen cargado para usuario $userId');
        return summary;
      } else {
        _errorMessage = result.error ?? 'Error desconocido';
        _setState(ReputationState.error);
        debugPrint('❌ [REPUTATION] Error cargando resumen: ${result.error}');
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _setState(ReputationState.error);
      debugPrint('❌ [REPUTATION] Error inesperado: $e');
      return null;
    }
  }

  /// Carga el leaderboard con filtros opcionales
  Future<LeaderboardResponse?> loadLeaderboard({
    int page = 1,
    int pageSize = 20,
    String? timeRange,
    ReputationLevel? minLevel,
    String? location,
    List<String>? badges,
    int? currentUserId,
    bool forceRefresh = false,
  }) async {
    // Si es la primera página y no forzamos refresh, verificar cache
    if (page == 1 && !forceRefresh && _currentLeaderboard != null) {
      debugPrint('🎯 [REPUTATION] Usando cache de leaderboard');
      return _currentLeaderboard;
    }

    _setLeaderboardState(ReputationState.loading);

    try {
      final result = await _reputationService.getReputationLeaderboard(
        limit: pageSize,
      );

      if (result.isSuccess) {
        final leaderboard = LeaderboardResponse.fromJson(
          result.data!,
          currentUserId: currentUserId,
        );
        if (page == 1) {
          // Primera página: reemplazar datos
          _currentLeaderboard = leaderboard;
        } else {
          // Páginas siguientes: agregar al final
          if (_currentLeaderboard != null) {
            final updatedEntries = List<LeaderboardEntry>.from(
              _currentLeaderboard!.entries,
            )..addAll(leaderboard.entries);

            _currentLeaderboard = LeaderboardResponse(
              entries: updatedEntries,
              pagination: leaderboard.pagination,
              filters: leaderboard.filters,
              currentUserRank: leaderboard.currentUserRank,
            );
          } else {
            _currentLeaderboard = leaderboard;
          }
        }

        _leaderboardError = null;
        _setLeaderboardState(ReputationState.loaded);
        debugPrint('✅ [REPUTATION] Leaderboard cargado (página $page)');
        return leaderboard;
      } else {
        _leaderboardError = result.error ?? 'Error desconocido';
        _setLeaderboardState(ReputationState.error);
        debugPrint(
          '❌ [REPUTATION] Error cargando leaderboard: ${result.error}',
        );
        return null;
      }
    } catch (e) {
      _leaderboardError = 'Error inesperado: $e';
      _setLeaderboardState(ReputationState.error);
      debugPrint('❌ [REPUTATION] Error inesperado: $e');
      return null;
    }
  }

  /// Recalcula la reputación de un usuario (solo moderadores)
  Future<bool> recalculateReputation(int userId) async {
    _setState(ReputationState.updating);

    try {
      // Por ahora no hay endpoint específico para recalcular, así que solo refrescamos
      debugPrint(
        '⚠️ [REPUTATION] Recálculo no implementado, refrescando datos...',
      );
      await getReputationStats(userId, forceRefresh: true);
      _errorMessage = null;
      _setState(ReputationState.loaded);
      debugPrint(
        '✅ [REPUTATION] Datos de reputación refrescados para usuario $userId',
      );
      return true;
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _setState(ReputationState.error);
      debugPrint('❌ [REPUTATION] Error inesperado: $e');
      return false;
    }
  }

  /// Obtiene estadísticas del sistema (solo administradores)
  Future<Map<String, dynamic>?> getSystemStats() async {
    _setState(ReputationState.loading);

    try {
      // Por ahora no hay endpoint específico para estadísticas del sistema
      debugPrint('⚠️ [REPUTATION] Estadísticas del sistema no implementadas');
      _errorMessage = null;
      _setState(ReputationState.loaded);
      // Retornamos datos de prueba por ahora
      return {
        'total_users': 0,
        'total_reputation_points': 0,
        'average_reputation': 0.0,
        'message': 'Estadísticas del sistema no implementadas',
      };
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _setState(ReputationState.error);
      debugPrint('❌ [REPUTATION] Error inesperado: $e');
      return null;
    }
  }

  // ===== MÉTODOS DE CACHE =====

  /// Verifica si los datos de reputación están en cache y son válidos
  bool _isDataCached(int userId) {
    if (!_reputationCache.containsKey(userId) ||
        !_cacheTimestamps.containsKey(userId)) {
      return false;
    }

    final timestamp = _cacheTimestamps[userId]!;
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    return difference < _cacheExpiration;
  }

  /// Verifica si el resumen está en cache y es válido
  bool _isSummaryCached(int userId) {
    if (!_summaryCache.containsKey(userId) ||
        !_cacheTimestamps.containsKey(userId)) {
      return false;
    }

    final timestamp = _cacheTimestamps[userId]!;
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    return difference < _cacheExpiration;
  }

  /// Limpia el cache de un usuario específico
  void clearUserCache(int userId) {
    _reputationCache.remove(userId);
    _summaryCache.remove(userId);
    _cacheTimestamps.remove(userId);
    debugPrint('🗑️ [REPUTATION] Cache limpiado para usuario $userId');
  }

  /// Limpia todo el cache
  void clearAllCache() {
    _reputationCache.clear();
    _summaryCache.clear();
    _cacheTimestamps.clear();
    _currentLeaderboard = null;
    debugPrint('🗑️ [REPUTATION] Todo el cache limpiado');
  }

  /// Invalida el cache de leaderboard
  void invalidateLeaderboard() {
    _currentLeaderboard = null;
    debugPrint('🗑️ [REPUTATION] Cache de leaderboard invalidado');
  }

  // ===== MÉTODOS AUXILIARES =====

  /// Obtiene datos de reputación desde cache (sin network)
  ReputationStats? getCachedReputationStats(int userId) {
    if (_isDataCached(userId)) {
      return _reputationCache[userId];
    }
    return null;
  }

  /// Obtiene resumen desde cache (sin network)
  RatingSummary? getCachedRatingSummary(int userId) {
    if (_isSummaryCached(userId)) {
      return _summaryCache[userId];
    }
    return null;
  }

  /// Verifica si un usuario está en el leaderboard actual
  LeaderboardEntry? findUserInLeaderboard(int userId) {
    if (_currentLeaderboard == null) return null;

    try {
      return _currentLeaderboard!.entries.firstWhere(
        (entry) => entry.userId == userId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Retorna métricas del cache para debugging
  Map<String, dynamic> getCacheMetrics() {
    return {
      'reputation_cache_size': _reputationCache.length,
      'summary_cache_size': _summaryCache.length,
      'cache_timestamps': _cacheTimestamps.length,
      'has_leaderboard': _currentLeaderboard != null,
      'leaderboard_entries': _currentLeaderboard?.entries.length ?? 0,
    };
  }

  // ===== MÉTODOS PRIVADOS =====

  void _setState(ReputationState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  void _setLeaderboardState(ReputationState newState) {
    if (_leaderboardState != newState) {
      _leaderboardState = newState;
      notifyListeners();
    }
  }

  /// Limpia el estado cuando el usuario se desconecta
  void dispose() {
    clearAllCache();
    _state = ReputationState.initial;
    _leaderboardState = ReputationState.initial;
    _errorMessage = null;
    _leaderboardError = null;
    super.dispose();
  }

  // ===== MÉTODOS PARA UI =====

  /// Retorna un mensaje de error amigable para mostrar en UI
  String? get friendlyErrorMessage {
    if (_errorMessage == null) return null;

    // Convertir errores técnicos en mensajes amigables
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
    if (_errorMessage!.contains('not found') ||
        _errorMessage!.contains('404')) {
      return 'Usuario no encontrado.';
    }

    return _errorMessage;
  }

  /// Retorna el estado como texto para debugging
  String get stateAsString {
    switch (_state) {
      case ReputationState.initial:
        return 'Inicial';
      case ReputationState.loading:
        return 'Cargando...';
      case ReputationState.loaded:
        return 'Cargado';
      case ReputationState.updating:
        return 'Actualizando...';
      case ReputationState.error:
        return 'Error';
    }
  }

  /// Adapta datos de rating stats a la estructura esperada por ReputationStats
  Map<String, dynamic> _adaptRatingStatsToReputationStats(
    Map<String, dynamic> statsData,
    Map<String, dynamic> userData,
  ) {
    // Convertir datos de rating stats a reputation stats
    final totalRatings = statsData['total_ratings'] as int? ?? 0;
    final averageRating =
        (statsData['average_rating'] as num?)?.toDouble() ?? 0.0;

    // Calcular un score básico basado en ratings
    // Fórmula simple: (average_rating * total_ratings) para simular reputation score
    final totalScore = (averageRating * totalRatings.toDouble()).clamp(
      0.0,
      100.0,
    );

    // Calcular progreso real hacia el siguiente nivel
    double progressToNextLevel = 0.0;
    String currentLevel = 'Novato';

    if (totalScore < 100) {
      // Novato -> Aprendiz (necesita 100 puntos)
      currentLevel = 'Novato';
      progressToNextLevel = (totalScore / 100.0).clamp(0.0, 1.0);
    } else if (totalScore < 500) {
      // Aprendiz -> Experto (necesita 500 puntos)
      currentLevel = 'Aprendiz';
      progressToNextLevel = ((totalScore - 100) / 400.0).clamp(0.0, 1.0);
    } else if (totalScore < 1000) {
      // Experto -> Maestro (necesita 1000 puntos)
      currentLevel = 'Experto';
      progressToNextLevel = ((totalScore - 500) / 500.0).clamp(0.0, 1.0);
    } else if (totalScore < 2500) {
      // Maestro -> Leyenda (necesita 2500 puntos)
      currentLevel = 'Maestro';
      progressToNextLevel = ((totalScore - 1000) / 1500.0).clamp(0.0, 1.0);
    } else {
      // Leyenda (nivel máximo)
      currentLevel = 'Leyenda';
      progressToNextLevel = 1.0;
    }

    return {
      'user_id': userData['id'],
      'username': userData['username'],
      'total_score': totalScore,
      'previous_score': totalScore, // Usar mismo valor por simplicidad
      'ratings_count': totalRatings,
      'average_rating': averageRating,
      'rating_distribution':
          statsData['rating_distribution'] ??
          {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
      'level': currentLevel,
      'progress_to_next_level': progressToNextLevel,
      'rank_in_level': 1,
      'total_in_level': 10,
      'global_rank': null,
      'total_users': null,
      'last_updated': DateTime.now().toIso8601String(),
      'breakdown': {
        'base_rating': averageRating,
        'volume_bonus': totalRatings > 5 ? 1.0 : 0.0,
        'consistency_bonus': 0.0,
        'time_decay': 0.0,
        'anti_gaming_penalty': 0.0,
        'special_bonus': 0.0,
      },
      'anti_gaming_analysis': {
        'risk_level': 'low',
        'suspicion_score': 0.0,
        'flags': <String>[],
        'recommendations': <String>[],
      },
    };
  }
}
