import 'package:flutter/foundation.dart';
import '../models/game_type.dart';
import '../models/tag.dart';
import '../models/community.dart';
import '../models/membership.dart';
import '../services/communities_service.dart';

/// Provider para manejar el estado global de Communities
class CommunitiesState extends ChangeNotifier {
  final CommunitiesService _communitiesService = CommunitiesService();

  // ==================== ESTADO GENERAL ====================

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==================== GAMETYPES ====================

  List<GameType> _gameTypes = [];
  List<GameType> _featuredGameTypes = [];

  List<GameType> get gameTypes => _gameTypes;
  List<GameType> get featuredGameTypes => _featuredGameTypes;

  /// Cargar todos los GameTypes
  Future<void> loadGameTypes() async {
    try {
      print('🎮 Cargando GameTypes...');
      _gameTypes = await _communitiesService.getGameTypes();
      print('✅ GameTypes cargados: ${_gameTypes.length}');
      _setError(null);
    } catch (e) {
      print('❌ Error cargando GameTypes: $e');
      _setError('Error al cargar tipos de juego: $e');
      rethrow; // Re-lanzar para que loadInitialData pueda capturarlo
    }
  }

  /// Cargar GameTypes destacados
  Future<void> loadFeaturedGameTypes() async {
    try {
      _setLoading(true);
      _featuredGameTypes = await _communitiesService.getFeaturedGameTypes();
      _setError(null);
    } catch (e) {
      _setError('Error al cargar juegos destacados: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Obtener GameType por ID
  Future<GameType?> getGameType(int id) async {
    try {
      // Buscar primero en cache
      final cached = _gameTypes.where((gt) => gt.id == id).firstOrNull;
      if (cached != null) return cached;

      // Si no está en cache, cargar desde API
      return await _communitiesService.getGameType(id);
    } catch (e) {
      _setError('Error al obtener tipo de juego: $e');
      return null;
    }
  }

  // ==================== TAGS ====================

  List<CommunityTag> _tags = [];
  List<CommunityTag> _popularTags = [];

  List<CommunityTag> get tags => _tags;
  List<CommunityTag> get popularTags => _popularTags;

  /// Cargar todos los Tags
  Future<void> loadTags() async {
    try {
      _tags = await _communitiesService.getTags();
      _setError(null);
    } catch (e) {
      _setError('Error al cargar etiquetas: $e');
      rethrow;
    }
  }

  /// Cargar Tags populares
  Future<void> loadPopularTags() async {
    try {
      print('🏷️ Cargando Tags populares...');
      _popularTags = await _communitiesService.getPopularTags();
      print('✅ Tags populares cargados: ${_popularTags.length}');
      _setError(null);
    } catch (e) {
      print('❌ Error cargando Tags populares: $e');
      _setError('Error al cargar etiquetas populares: $e');
      rethrow;
    }
  }

  // ==================== CATEGORIES ====================

  List<CommunityCategory> _categories = [];

  List<CommunityCategory> get categories => _categories;

  /// Cargar todas las Categorías
  Future<void> loadCategories() async {
    try {
      print('📂 Cargando Categories...');
      _categories = await _communitiesService.getCategories();
      print('✅ Categories cargadas: ${_categories.length}');
      _setError(null);
    } catch (e) {
      print('❌ Error cargando Categories: $e');
      _setError('Error al cargar categorías: $e');
      rethrow;
    }
  }

  /// Obtener comunidades de una categoría
  Future<List<Community>> getCommunitiesByCategory(int categoryId) async {
    try {
      return await _communitiesService.getCommunitiesByCategory(categoryId);
    } catch (e) {
      _setError('Error al cargar comunidades de categoría: $e');
      return [];
    }
  }

  // ==================== COMMUNITIES ====================

  List<Community> _communities = [];
  List<Community> _popularCommunities = [];
  Map<String, dynamic>? _communitiesStats;

  List<Community> get communities => _communities;
  List<Community> get popularCommunities => _popularCommunities;
  Map<String, dynamic>? get communitiesStats => _communitiesStats;

  /// Cargar todas las Comunidades con filtros opcionales
  Future<void> loadCommunities({
    String? search,
    String? gameType,
    String? difficulty,
    String? ordering = '-member_count',
    int? limit,
    int? offset,
  }) async {
    try {
      _setLoading(true);
      _communities = await _communitiesService.getCommunities(
        search: search,
        gameType: gameType,
        difficulty: difficulty,
        ordering: ordering,
        limit: limit,
        offset: offset,
      );
      _setError(null);
      // Sincronizar estado de membresías
      _syncMembershipStates();
    } catch (e) {
      _setError('Error al cargar comunidades: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sincroniza el estado de isSubscribed en las comunidades basado en las membresías del usuario
  void _syncMembershipStates() {
    for (int i = 0; i < _communities.length; i++) {
      final community = _communities[i];
      final isSubscribed = isUserMemberOf(community.id);

      if (community.isSubscribed != isSubscribed) {
        _communities[i] = community.copyWith(isSubscribed: isSubscribed);
      }
    }
  }

  /// Cargar comunidades populares
  Future<void> loadPopularCommunities() async {
    try {
      print('🌐 Cargando Popular Communities...');
      _popularCommunities = await _communitiesService.getPopularCommunities();
      print('✅ Popular Communities cargadas: ${_popularCommunities.length}');
      _setError(null);
    } catch (e) {
      print('❌ Error cargando Popular Communities: $e');
      _setError('Error al cargar comunidades populares: $e');
      rethrow;
    }
  }

  /// Cargar estadísticas de comunidades
  Future<void> loadCommunitiesStats() async {
    try {
      _setLoading(true);
      _communitiesStats = await _communitiesService.getCommunitiesStats();
      _setError(null);
    } catch (e) {
      _setError('Error al cargar estadísticas: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Obtener Community por ID
  Future<Community?> getCommunity(int id) async {
    try {
      // Buscar primero en cache
      final cached = _communities.where((c) => c.id == id).firstOrNull;
      if (cached != null) return cached;

      // Si no está en cache, cargar desde API
      return await _communitiesService.getCommunity(id);
    } catch (e) {
      _setError('Error al obtener comunidad: $e');
      return null;
    }
  }

  /// Buscar comunidades por texto
  Future<void> searchCommunities(String query) async {
    await loadCommunities(search: query);
  }

  /// Filtrar comunidades por tipo de juego
  Future<void> filterByGameType(String gameType) async {
    await loadCommunities(gameType: gameType);
  }

  /// Filtrar comunidades por dificultad
  Future<void> filterByDifficulty(String difficulty) async {
    await loadCommunities(difficulty: difficulty);
  }

  // ==================== MEMBERSHIPS ====================

  List<CommunityMembership> _userMemberships = [];
  List<CommunityMembership> _moderators = [];

  List<CommunityMembership> get userMemberships => _userMemberships;
  List<CommunityMembership> get moderators => _moderators;

  /// Cargar membresías del usuario actual
  Future<void> loadUserMemberships(int userId) async {
    try {
      _setLoading(true);
      _userMemberships = await _communitiesService.getUserMemberships(userId);
      _setError(null);
    } catch (e) {
      _setError('Error al cargar membresías: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Cargar moderadores
  Future<void> loadModerators() async {
    try {
      _setLoading(true);
      _moderators = await _communitiesService.getModerators();
      _setError(null);
    } catch (e) {
      _setError('Error al cargar moderadores: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Unirse a una comunidad
  Future<bool> joinCommunity(int communityId, {String? message}) async {
    try {
      _setLoading(true);
      final membership = await _communitiesService.joinCommunity(
        communityId,
        message: message,
      );

      // Agregar a las membresías del usuario
      _userMemberships.add(membership);

      // Actualizar contador de miembros en la comunidad si está en cache
      final communityIndex = _communities.indexWhere(
        (c) => c.id == communityId,
      );
      if (communityIndex != -1) {
        // Crear nueva instancia con member_count actualizado y isSubscribed = true
        final updatedCommunity = Community.fromListJson({
          ..._communities[communityIndex].toJson(),
          'member_count': _communities[communityIndex].memberCount + 1,
        }).copyWith(isSubscribed: true);
        _communities[communityIndex] = updatedCommunity;
      }

      _setError(null);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al unirse a la comunidad: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Salir de una comunidad
  Future<bool> leaveCommunity(int communityId) async {
    try {
      _setLoading(true);
      await _communitiesService.leaveCommunity(communityId);

      // Remover de las membresías del usuario
      _userMemberships.removeWhere((m) => m.communityId == communityId);

      // Actualizar contador de miembros en la comunidad si está en cache
      final communityIndex = _communities.indexWhere(
        (c) => c.id == communityId,
      );
      if (communityIndex != -1) {
        final updatedCommunity = Community.fromListJson({
          ..._communities[communityIndex].toJson(),
          'member_count': (_communities[communityIndex].memberCount - 1)
              .clamp(0, double.infinity)
              .toInt(),
        }).copyWith(isSubscribed: false);
        _communities[communityIndex] = updatedCommunity;
      }

      _setError(null);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al salir de la comunidad: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle membership: unirse o salir de una comunidad según el estado actual
  Future<bool> toggleCommunityMembership(int communityId) async {
    final isCurrentlyMember = isUserMemberOf(communityId);

    if (isCurrentlyMember) {
      return await leaveCommunity(communityId);
    } else {
      return await joinCommunity(communityId);
    }
  }

  /// Verificar si el usuario es miembro de una comunidad
  bool isUserMemberOf(int communityId) {
    return _userMemberships.any(
      (m) => m.communityId == communityId && m.isActive,
    );
  }

  /// Obtener membresía del usuario en una comunidad específica
  CommunityMembership? getUserMembershipFor(int communityId) {
    try {
      return _userMemberships.firstWhere((m) => m.communityId == communityId);
    } catch (e) {
      return null;
    }
  }

  // ==================== MÉTODOS AUXILIARES ====================

  /// Cargar datos iniciales esenciales
  Future<void> loadInitialData() async {
    print('🚀 CommunitiesState: Iniciando carga de datos iniciales...');
    _setLoading(true);

    // Cargar cada API por separado para identificar problemas específicos
    print('1️⃣ Cargando GameTypes...');
    try {
      await loadGameTypes();
      print('✅ GameTypes cargados: ${_gameTypes.length}');
    } catch (e) {
      print('❌ Error GameTypes: $e');
    }

    print('2️⃣ Cargando Categories...');
    try {
      await loadCategories();
      print('✅ Categories cargadas: ${_categories.length}');
    } catch (e) {
      print('❌ Error Categories: $e');
    }

    print('3️⃣ Cargando Popular Tags...');
    try {
      await loadPopularTags();
      print('✅ Popular Tags cargados: ${_popularTags.length}');
    } catch (e) {
      print('❌ Error Popular Tags: $e');
    }

    print('4️⃣ Cargando Popular Communities...');
    try {
      await loadPopularCommunities();
      print('✅ Popular Communities cargadas: ${_popularCommunities.length}');
    } catch (e) {
      print('❌ Error Popular Communities: $e');
    }

    print('5️⃣ Cargando Communities principales...');
    try {
      await loadCommunities();
      print('✅ Communities principales cargadas: ${_communities.length}');
    } catch (e) {
      print('❌ Error Communities principales: $e');
    }

    // Cargar Tags normales también
    print('6️⃣ Cargando Tags normales...');
    try {
      await loadTags();
      print('✅ Tags normales cargados: ${_tags.length}');
    } catch (e) {
      print('❌ Error Tags normales: $e');
    }

    _setLoading(false);
    print('🏁 CommunitiesState: Carga inicial terminada');
    print(
      '📊 Resumen final: ${_gameTypes.length} games, ${_categories.length} categories, ${_tags.length} tags, ${_popularTags.length} popular tags, ${_communities.length} communities principales, ${_popularCommunities.length} popular communities',
    );
  }

  /// Limpiar todos los datos
  void clearData() {
    _gameTypes.clear();
    _featuredGameTypes.clear();
    _tags.clear();
    _popularTags.clear();
    _categories.clear();
    _communities.clear();
    _popularCommunities.clear();
    _userMemberships.clear();
    _moderators.clear();
    _communitiesStats = null;
    _setError(null);
    notifyListeners();
  }

  /// Refrescar todos los datos
  Future<void> refreshAll() async {
    clearData();
    await loadInitialData();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
}

/// Extension para obtener el primer elemento o null
extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    return isEmpty ? null : first;
  }
}
