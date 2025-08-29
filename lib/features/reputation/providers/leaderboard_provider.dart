import 'package:flutter/foundation.dart';
import '../models/leaderboard_entry.dart';
import '../services/reputation_service.dart';

/// Estados para las operaciones del leaderboard
enum LeaderboardState { initial, loading, loaded, error, refreshing }

/// Provider para la gestión del estado del sistema de leaderboard
///
/// Maneja:
/// - Rankings globales y por categorías
/// - Paginación y cache inteligente
/// - Filtros por periodo de tiempo
/// - Búsqueda de usuarios en rankings
/// - Rankings por popularidad y calidad
/// - Cache optimizado con refrescos inteligentes
class LeaderboardProvider with ChangeNotifier {
  final ReputationService _reputationService = ReputationService.instance;

  // Estados principales
  LeaderboardState _state = LeaderboardState.initial;
  String? _errorMessage;

  // Cache de leaderboards por configuración
  final Map<String, List<LeaderboardEntry>> _leaderboardCache = {};
  final Map<String, LeaderboardPagination> _paginationCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Leaderboard actualmente visible
  List<LeaderboardEntry>? _currentLeaderboard;
  LeaderboardPagination? _currentPagination;
  String? _currentCacheKey;

  // Configuración actual del leaderboard
  String _currentLeaderboardType = 'reputation';
  String _currentPeriod = 'all';
  String? _currentCommunityId;
  int _currentPage = 1;

  // Configuración de cache (5 minutos para leaderboards generales, 1 minuto para refreshes)
  static const Duration _cacheExpiration = Duration(minutes: 5);
  static const Duration _refreshCacheExpiration = Duration(minutes: 1);

  // ===== GETTERS PÚBLICOS =====

  LeaderboardState get state => _state;
  String? get errorMessage => _errorMessage;
  List<LeaderboardEntry>? get currentLeaderboard => _currentLeaderboard;
  LeaderboardPagination? get currentPagination => _currentPagination;
  String get currentLeaderboardType => _currentLeaderboardType;
  String get currentPeriod => _currentPeriod;
  String? get currentCommunityId => _currentCommunityId;
  int get currentPage => _currentPage;

  bool get isLoading => _state == LeaderboardState.loading;
  bool get isRefreshing => _state == LeaderboardState.refreshing;
  bool get hasError => _state == LeaderboardState.error;
  bool get hasData =>
      _currentLeaderboard != null && _currentLeaderboard!.isNotEmpty;
  bool get hasMorePages => _currentPagination?.hasNext ?? false;

  int get totalEntries => _currentPagination?.totalEntries ?? 0;
  int get currentPageSize => _currentLeaderboard?.length ?? 0;

  // ===== MÉTODOS PÚBLICOS =====

  /// Inicializa el provider (ya no necesario ya que ReputationService usa HttpService directamente)
  void initialize(String? authToken) {
    // ReputationService usa automáticamente el token a través de HttpService
    debugPrint(
      '🔧 [LEADERBOARD] Provider inicializado (usando HttpService para autenticación)',
    );
  }

  /// Actualiza el token de autenticación (ya no necesario)
  void updateAuthToken(String? token) {
    // ReputationService usa automáticamente el token a través de HttpService
    debugPrint(
      '🔧 [LEADERBOARD] Token actualizado automáticamente via HttpService',
    );
  }

  /// Carga el leaderboard principal (por defecto: reputación, todos los tiempos)
  Future<void> loadMainLeaderboard({bool forceRefresh = false}) async {
    await loadLeaderboard(
      leaderboardType: 'reputation',
      period: 'all',
      forceRefresh: forceRefresh,
    );
  }

  /// Carga un leaderboard específico
  Future<List<LeaderboardEntry>?> loadLeaderboard({
    String leaderboardType = 'reputation',
    String period = 'all',
    String? communityId,
    int page = 1,
    int pageSize = 20,
    bool forceRefresh = false,
  }) async {
    // Actualizar configuración actual
    _currentLeaderboardType = leaderboardType;
    _currentPeriod = period;
    _currentCommunityId = communityId;
    _currentPage = page;

    final cacheKey = _buildCacheKey(
      leaderboardType,
      period,
      communityId,
      page,
      pageSize,
    );
    _currentCacheKey = cacheKey;

    // Verificar cache para la primera página
    if (page == 1 && !forceRefresh && _isLeaderboardCached(cacheKey)) {
      _currentLeaderboard = _leaderboardCache[cacheKey];
      _currentPagination = _paginationCache[cacheKey];
      debugPrint('🎯 [LEADERBOARD] Usando cache para $leaderboardType/$period');
      return _currentLeaderboard;
    }

    // Determinar si es un refresh
    final isRefresh = forceRefresh && page == 1 && _currentLeaderboard != null;
    _setState(
      isRefresh ? LeaderboardState.refreshing : LeaderboardState.loading,
    );

    try {
      final result = await _reputationService.getReputationLeaderboard(
        limit: pageSize,
      );

      if (result.isSuccess) {
        final response = LeaderboardResponse.fromJson(result.data!);
        if (page == 1) {
          // Primera página: reemplazar datos
          _leaderboardCache[cacheKey] = response.entries;
          _paginationCache[cacheKey] = response.pagination;
          _currentLeaderboard = response.entries;
          _currentPagination = response.pagination;
        } else {
          // Páginas siguientes: agregar al final
          final existingEntries = _currentLeaderboard ?? <LeaderboardEntry>[];
          final newEntries = [...existingEntries, ...response.entries];
          _leaderboardCache[cacheKey] = newEntries;
          _paginationCache[cacheKey] = response.pagination;
          _currentLeaderboard = newEntries;
          _currentPagination = response.pagination;
        }

        _cacheTimestamps[cacheKey] = DateTime.now();

        _errorMessage = null;
        _setState(LeaderboardState.loaded);
        debugPrint(
          '✅ [LEADERBOARD] Leaderboard cargado: $leaderboardType/$period (página $page)',
        );
        return response.entries;
      } else {
        _errorMessage = result.error ?? 'Error desconocido';
        _setState(LeaderboardState.error);
        debugPrint(
          '❌ [LEADERBOARD] Error cargando leaderboard: ${result.error}',
        );
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error inesperado: $e';
      _setState(LeaderboardState.error);
      debugPrint('❌ [LEADERBOARD] Error inesperado: $e');
      return null;
    }
  }

  /// Carga la siguiente página del leaderboard actual
  Future<bool> loadNextPage() async {
    if (!hasMorePages || isLoading) return false;

    final nextPage = _currentPage + 1;
    final result = await loadLeaderboard(
      leaderboardType: _currentLeaderboardType,
      period: _currentPeriod,
      communityId: _currentCommunityId,
      page: nextPage,
    );

    return result != null;
  }

  /// Refresh del leaderboard actual
  Future<void> refreshCurrentLeaderboard() async {
    if (_currentCacheKey == null) {
      await loadMainLeaderboard(forceRefresh: true);
      return;
    }

    await loadLeaderboard(
      leaderboardType: _currentLeaderboardType,
      period: _currentPeriod,
      communityId: _currentCommunityId,
      page: 1,
      forceRefresh: true,
    );
  }

  /// Busca un usuario específico en el leaderboard
  Future<LeaderboardEntry?> findUserInLeaderboard(
    int userId, {
    String? leaderboardType,
    String? period,
    String? communityId,
  }) async {
    // Por ahora simplificamos la búsqueda al leaderboard actual
    // En una implementación futura se podría crear un endpoint específico
    final searchType = leaderboardType ?? _currentLeaderboardType;
    final searchPeriod = period ?? _currentPeriod;
    final searchCommunity = communityId ?? _currentCommunityId;

    try {
      // Buscar en el leaderboard actual si coincide la configuración
      if (searchType == _currentLeaderboardType &&
          searchPeriod == _currentPeriod &&
          searchCommunity == _currentCommunityId &&
          _currentLeaderboard != null) {
        try {
          final entry = _currentLeaderboard!.firstWhere(
            (e) => e.userId == userId,
          );
          debugPrint(
            '✅ [LEADERBOARD] Usuario $userId encontrado en posición ${entry.rank}',
          );
          return entry;
        } catch (e) {
          // Usuario no encontrado en el leaderboard actual
        }
      }

      // Si no se encuentra, cargar el leaderboard correspondiente
      final result = await loadLeaderboard(
        leaderboardType: searchType,
        period: searchPeriod,
        communityId: searchCommunity,
        pageSize: 100, // Cargar más entradas para buscar el usuario
      );

      if (result != null) {
        try {
          final entry = result.firstWhere((e) => e.userId == userId);
          debugPrint(
            '✅ [LEADERBOARD] Usuario $userId encontrado en posición ${entry.rank}',
          );
          return entry;
        } catch (e) {
          debugPrint(
            '❌ [LEADERBOARD] Usuario $userId no encontrado en el leaderboard',
          );
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ [LEADERBOARD] Error inesperado buscando usuario: $e');
      return null;
    }
  }

  /// Obtiene múltiples leaderboards populares de forma paralela
  Future<Map<String, List<LeaderboardEntry>>> getPopularLeaderboards({
    bool forceRefresh = false,
  }) async {
    const configurations = [
      {'type': 'reputation', 'period': 'week', 'key': 'reputation_week'},
      {'type': 'reputation', 'period': 'month', 'key': 'reputation_month'},
      {'type': 'popularity', 'period': 'week', 'key': 'popularity_week'},
      {'type': 'quality', 'period': 'month', 'key': 'quality_month'},
    ];

    final results = <String, List<LeaderboardEntry>>{};

    // Ejecutar requests en paralelo
    final futures = configurations.map((config) async {
      final result = await loadLeaderboard(
        leaderboardType: config['type']!,
        period: config['period']!,
        pageSize: 10, // Solo top 10 para vista rápida
        forceRefresh: forceRefresh,
      );

      if (result != null) {
        results[config['key']!] = result;
      }
    });

    await Future.wait(futures);

    debugPrint(
      '✅ [LEADERBOARD] ${results.length} leaderboards populares cargados',
    );
    return results;
  }

  /// Cambia el tipo de leaderboard y recarga
  Future<void> switchLeaderboardType(String newType) async {
    if (newType != _currentLeaderboardType) {
      await loadLeaderboard(
        leaderboardType: newType,
        period: _currentPeriod,
        communityId: _currentCommunityId,
      );
    }
  }

  /// Cambia el periodo y recarga
  Future<void> switchPeriod(String newPeriod) async {
    if (newPeriod != _currentPeriod) {
      await loadLeaderboard(
        leaderboardType: _currentLeaderboardType,
        period: newPeriod,
        communityId: _currentCommunityId,
      );
    }
  }

  /// Cambia la comunidad y recarga
  Future<void> switchCommunity(String? newCommunityId) async {
    if (newCommunityId != _currentCommunityId) {
      await loadLeaderboard(
        leaderboardType: _currentLeaderboardType,
        period: _currentPeriod,
        communityId: newCommunityId,
      );
    }
  }

  // ===== MÉTODOS DE CACHE =====

  /// Verifica si un leaderboard está en cache y es válido
  bool _isLeaderboardCached(String cacheKey) {
    if (!_leaderboardCache.containsKey(cacheKey) ||
        !_cacheTimestamps.containsKey(cacheKey)) {
      return false;
    }

    final timestamp = _cacheTimestamps[cacheKey]!;
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    // Cache más corto para refreshes
    final expiration = _state == LeaderboardState.refreshing
        ? _refreshCacheExpiration
        : _cacheExpiration;

    return difference < expiration;
  }

  /// Construye una clave única para el cache
  String _buildCacheKey(
    String leaderboardType,
    String period,
    String? communityId,
    int page,
    int pageSize,
  ) {
    return '${leaderboardType}_${period}_${communityId ?? 'global'}_${page}_$pageSize';
  }

  /// Invalida cache de un tipo específico
  void invalidateLeaderboardType(String leaderboardType) {
    final keysToRemove = _leaderboardCache.keys
        .where((key) => key.startsWith('${leaderboardType}_'))
        .toList();

    for (final key in keysToRemove) {
      _leaderboardCache.remove(key);
      _paginationCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    debugPrint(
      '🗑️ [LEADERBOARD] Cache invalidado para tipo: $leaderboardType',
    );
  }

  /// Invalida cache de un periodo específico
  void invalidatePeriod(String period) {
    final keysToRemove = _leaderboardCache.keys
        .where((key) => key.contains('_${period}_'))
        .toList();

    for (final key in keysToRemove) {
      _leaderboardCache.remove(key);
      _paginationCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    debugPrint('🗑️ [LEADERBOARD] Cache invalidado para periodo: $period');
  }

  /// Invalida cache de una comunidad específica
  void invalidateCommunity(String? communityId) {
    final communityKey = communityId ?? 'global';
    final keysToRemove = _leaderboardCache.keys
        .where((key) => key.contains('_${communityKey}_'))
        .toList();

    for (final key in keysToRemove) {
      _leaderboardCache.remove(key);
      _paginationCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    debugPrint(
      '🗑️ [LEADERBOARD] Cache invalidado para comunidad: $communityKey',
    );
  }

  /// Limpia todo el cache
  void clearAllCache() {
    _leaderboardCache.clear();
    _paginationCache.clear();
    _cacheTimestamps.clear();
    _currentLeaderboard = null;
    _currentPagination = null;
    _currentCacheKey = null;
    debugPrint('🗑️ [LEADERBOARD] Todo el cache limpiado');
  }

  // ===== MÉTODOS AUXILIARES =====

  /// Obtiene un leaderboard desde cache (sin network)
  List<LeaderboardEntry>? getCachedLeaderboard(
    String leaderboardType,
    String period, {
    String? communityId,
    int page = 1,
    int pageSize = 20,
  }) {
    final cacheKey = _buildCacheKey(
      leaderboardType,
      period,
      communityId,
      page,
      pageSize,
    );
    if (_isLeaderboardCached(cacheKey)) {
      return _leaderboardCache[cacheKey];
    }
    return null;
  }

  /// Busca un usuario en el leaderboard actual
  LeaderboardEntry? findUserInCurrentLeaderboard(int userId) {
    if (_currentLeaderboard == null) return null;

    try {
      return _currentLeaderboard!.firstWhere((entry) => entry.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene la posición de un usuario en el leaderboard actual
  int? getUserPositionInCurrent(int userId) {
    final entry = findUserInCurrentLeaderboard(userId);
    return entry?.rank;
  }

  /// Verifica si un usuario está en el top N del leaderboard actual
  bool isUserInTopN(int userId, int n) {
    final position = getUserPositionInCurrent(userId);
    return position != null && position <= n;
  }

  /// Obtiene estadísticas del leaderboard actual
  Map<String, dynamic> getCurrentLeaderboardStats() {
    if (_currentLeaderboard == null || _currentLeaderboard!.isEmpty) {
      return {
        'total_entries': 0,
        'loaded_entries': 0,
        'pages_loaded': 0,
        'average_score': 0.0,
        'top_score': 0.0,
      };
    }

    final scores = _currentLeaderboard!.map((e) => e.totalScore).toList();
    final averageScore = scores.reduce((a, b) => a + b) / scores.length;
    final topScore = scores.isNotEmpty ? scores.first : 0.0;

    return {
      'total_entries': totalEntries,
      'loaded_entries': _currentLeaderboard!.length,
      'pages_loaded': _currentPage,
      'average_score': averageScore,
      'top_score': topScore,
    };
  }

  /// Obtiene los tipos de leaderboard disponibles
  List<String> get availableLeaderboardTypes => [
    'reputation',
    'popularity',
    'quality',
    'activity',
    'helpfulness',
  ];

  /// Obtiene los periodos disponibles
  List<String> get availablePeriods => ['all', 'year', 'month', 'week', 'day'];

  /// Obtiene un nombre amigable para el tipo de leaderboard
  String getLeaderboardTypeName(String type) {
    switch (type) {
      case 'reputation':
        return 'Reputación';
      case 'popularity':
        return 'Popularidad';
      case 'quality':
        return 'Calidad';
      case 'activity':
        return 'Actividad';
      case 'helpfulness':
        return 'Utilidad';
      default:
        return type.toUpperCase();
    }
  }

  /// Obtiene un nombre amigable para el periodo
  String getPeriodName(String period) {
    switch (period) {
      case 'all':
        return 'Todos los tiempos';
      case 'year':
        return 'Este año';
      case 'month':
        return 'Este mes';
      case 'week':
        return 'Esta semana';
      case 'day':
        return 'Hoy';
      default:
        return period.toUpperCase();
    }
  }

  // ===== MÉTODOS PRIVADOS =====

  void _setState(LeaderboardState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  /// Limpia el estado cuando el usuario se desconecta
  @override
  void dispose() {
    clearAllCache();
    _state = LeaderboardState.initial;
    _errorMessage = null;
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
      return 'El leaderboard solicitado no existe.';
    }

    return _errorMessage;
  }

  /// Retorna métricas del cache para debugging
  Map<String, dynamic> getCacheMetrics() {
    return {
      'leaderboard_cache_size': _leaderboardCache.length,
      'pagination_cache_size': _paginationCache.length,
      'cache_timestamps': _cacheTimestamps.length,
      'current_leaderboard_entries': _currentLeaderboard?.length ?? 0,
      'current_cache_key': _currentCacheKey,
      'current_config': {
        'type': _currentLeaderboardType,
        'period': _currentPeriod,
        'community': _currentCommunityId,
        'page': _currentPage,
      },
    };
  }

  /// Retorna información del estado actual para debugging
  String get debugStateInfo {
    return '''
Estado: $_state
Tipo actual: $_currentLeaderboardType
Periodo actual: $_currentPeriod
Comunidad actual: $_currentCommunityId
Página actual: $_currentPage
Entradas cargadas: ${_currentLeaderboard?.length ?? 0}
Total entradas: $totalEntries
Tiene más páginas: $hasMorePages
Error: $_errorMessage
Cache key: $_currentCacheKey
''';
  }
}
