import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/models/community.dart';
import '../../../core/services/communities_service.dart';
import '../../../core/services/membership_service.dart';

/// Provider para gestión de estado de comunidades
/// Maneja la lista de comunidades, búsqueda, filtros y suscripciones usando APIs reales
class CommunitiesProvider extends ChangeNotifier {
  List<Community> _allCommunities = [];
  List<Community> _filteredCommunities = [];
  String _searchQuery = '';
  String _selectedGameType = '';
  String _selectedDifficulty = '';
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Estados de loading para operaciones específicas
  final Map<int, bool> _joinLeaveLoadingStates = {};

  final CommunitiesService _communitiesService = CommunitiesService();
  final MembershipService _membershipService = MembershipService();

  // Getters
  List<Community> get communities => _filteredCommunities;
  List<Community> get allCommunities => _allCommunities;
  String get searchQuery => _searchQuery;
  String get selectedGameType => _selectedGameType;
  String get selectedDifficulty => _selectedDifficulty;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => _filteredCommunities.isEmpty && !_isLoading;

  /// Verifica si una comunidad específica está en proceso de join/leave
  bool isJoinLeaveLoading(int communityId) {
    return _joinLeaveLoadingStates[communityId] ?? false;
  }

  /// Lista de comunidades suscritas
  List<Community> get subscribedCommunities {
    return _allCommunities
        .where((community) => community.isSubscribed)
        .toList();
  }

  /// Tipos de juego disponibles para filtrar (hardcoded por ahora)
  List<String> get availableGameTypes => [
    'Magic: The Gathering',
    'Pokémon TCG',
    'Yu-Gi-Oh!',
    'Dragon Ball Super',
    'One Piece',
  ];

  /// Niveles de dificultad disponibles para filtrar
  List<String> get availableDifficultyLevels => [
    'principiante',
    'intermedio',
    'avanzado',
  ];

  /// Inicializa el provider cargando las comunidades
  CommunitiesProvider() {
    loadCommunities();
  }

  /// Carga todas las comunidades desde la API
  Future<void> loadCommunities() async {
    print('🔄 CommunitiesProvider: ⚡ LOAD COMMUNITIES CALLED ⚡');
    print('📞 CommunitiesProvider: Stack trace:');
    print(StackTrace.current.toString().split('\n').take(5).join('\n'));

    _setLoading(true);
    _clearError();

    try {
      print('🚀 CommunitiesProvider: Cargando comunidades desde API...');
      final communities = await _communitiesService.getCommunities(
        ordering: '-member_count', // Ordenar por miembros descendente
      );

      print(
        '✅ CommunitiesProvider: ${communities.length} comunidades cargadas',
      );

      // Debug: mostrar estado de suscripción de cada comunidad
      for (var community in communities) {
        print(
          '🏠 Comunidad: ${community.name} - isSubscribed: ${community.isSubscribed}, memberCount: ${community.memberCount}',
        );
      }

      _allCommunities = communities;
      _applyFilters();
      _setLoading(false);
    } catch (e) {
      print('💥 CommunitiesProvider: Error al cargar comunidades: $e');
      print('🔄 CommunitiesProvider: Cargando datos mock como fallback...');

      // Fallback con datos mock si hay error de API
      _allCommunities = _getMockCommunities();
      print(
        '✅ CommunitiesProvider: ${_allCommunities.length} comunidades mock cargadas',
      );
      _applyFilters();
      _setLoading(false);

      // Limpiar cualquier error previo ya que tenemos datos de fallback
      _clearError();
    }
  }

  /// Refresca la lista de comunidades (pull-to-refresh)
  Future<void> refreshCommunities() async {
    print('🔄 CommunitiesProvider: ⚡ REFRESH COMMUNITIES CALLED ⚡');
    print('📞 CommunitiesProvider: Stack trace:');
    print(StackTrace.current.toString().split('\n').take(5).join('\n'));

    _clearError();

    try {
      print('🔄 CommunitiesProvider: Refrescando comunidades...');
      final communities = await _communitiesService.getCommunities(
        ordering: '-member_count',
      );

      print(
        '✅ CommunitiesProvider: ${communities.length} comunidades refrescadas',
      );
      _allCommunities = communities;
      _applyFilters();
      notifyListeners();
    } catch (e) {
      print('💥 CommunitiesProvider: Error al refrescar: $e');
      _setError('Error al refrescar comunidades.');
    }
  }

  /// Busca comunidades por texto
  void searchCommunities(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Filtra por tipo de juego
  void filterByGameType(String gameType) {
    _selectedGameType = gameType;
    _applyFilters();
  }

  /// Filtra por nivel de dificultad
  void filterByDifficulty(String difficulty) {
    _selectedDifficulty = difficulty;
    _applyFilters();
  }

  /// Limpia todos los filtros
  void clearFilters() {
    _searchQuery = '';
    _selectedGameType = '';
    _selectedDifficulty = '';
    _applyFilters();
  }

  /// Cambia el estado de suscripción de una comunidad usando la API real
  Future<void> toggleSubscription(int communityId) async {
    final communityIndex = _allCommunities.indexWhere(
      (c) => c.id == communityId,
    );

    if (communityIndex == -1) {
      print('❌ CommunitiesProvider: Comunidad $communityId no encontrada');
      return;
    }

    final community = _allCommunities[communityIndex];
    print(
      '🎯 CommunitiesProvider: Toggling suscripción para ${community.name} (isSubscribed: ${community.isSubscribed})',
    );

    // Activar estado de loading para esta comunidad específica
    _joinLeaveLoadingStates[communityId] = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      bool success = false;
      String message = '';

      if (community.isSubscribed) {
        // Salir de la comunidad
        print('📤 CommunitiesProvider: Saliendo de comunidad $communityId');
        final result = await _membershipService.leaveCommunity(communityId);
        success = result['success'];
        message = result['message'];

        if (success) {
          print('✅ CommunitiesProvider: Salida exitosa de ${community.name}');
          // Actualizar estado local inmediatamente
          final updatedCommunity = community.copyWith(
            isSubscribed: false,
            memberCount: community.memberCount - 1,
          );
          _allCommunities[communityIndex] = updatedCommunity;
          print(
            '🔄 CommunitiesProvider: Estado actualizado - isSubscribed: ${updatedCommunity.isSubscribed}, memberCount: ${updatedCommunity.memberCount}',
          );
          _successMessage = 'Has salido de ${community.name}';
          _applyFilters();
        }
      } else {
        // Unirse a la comunidad
        print('📥 CommunitiesProvider: Uniéndose a comunidad $communityId');
        final result = await _membershipService.joinCommunity(communityId);
        success = result['success'];
        message = result['message'];

        if (success) {
          print('✅ CommunitiesProvider: Unión exitosa a ${community.name}');
          // Actualizar estado local inmediatamente
          final updatedCommunity = community.copyWith(
            isSubscribed: true,
            memberCount: community.memberCount + 1,
          );
          _allCommunities[communityIndex] = updatedCommunity;
          print(
            '🔄 CommunitiesProvider: Estado actualizado - isSubscribed: ${updatedCommunity.isSubscribed}, memberCount: ${updatedCommunity.memberCount}',
          );
          _successMessage = 'Te has unido a ${community.name}';
          _applyFilters();
        }
      }

      if (!success) {
        print('❌ CommunitiesProvider: Error en operación: $message');
        _setError(message);
      }
    } catch (e) {
      print('💥 CommunitiesProvider: Error en toggleSubscription: $e');
      _setError('Error de conexión. Inténtalo de nuevo.');
    } finally {
      // Desactivar estado de loading
      _joinLeaveLoadingStates[communityId] = false;
      notifyListeners();
    }
  }

  /// Obtiene una comunidad por ID
  Community? getCommunityById(int id) {
    try {
      return _allCommunities.firstWhere((community) => community.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Aplica todos los filtros activos
  void _applyFilters() {
    List<Community> filtered = List.from(_allCommunities);

    // Filtro de búsqueda por texto
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((community) {
        return community.name.toLowerCase().contains(query) ||
            community.description.toLowerCase().contains(query) ||
            community.gameType.toLowerCase().contains(query) ||
            community.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    // Filtro por tipo de juego
    if (_selectedGameType.isNotEmpty) {
      filtered = filtered
          .where((community) => community.gameType == _selectedGameType)
          .toList();
    }

    // Filtro por dificultad
    if (_selectedDifficulty.isNotEmpty) {
      filtered = filtered
          .where(
            (community) => community.difficultyLevel == _selectedDifficulty,
          )
          .toList();
    }

    _filteredCommunities = filtered;
    notifyListeners();
  }

  /// Establece el estado de carga
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Establece un mensaje de error
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Limpia el mensaje de error
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Limpia el filtro por tipo de juego
  void clearGameTypeFilter() {
    _selectedGameType = '';
    _applyFilters();
  }

  /// Limpia el filtro por dificultad
  void clearDifficultyFilter() {
    _selectedDifficulty = '';
    _applyFilters();
  }

  /// Limpia todos los filtros y búsqueda
  void clearAllFilters() {
    _searchQuery = '';
    _selectedGameType = '';
    _selectedDifficulty = '';
    _applyFilters();
  }

  /// Datos mock como fallback cuando la API no está disponible
  List<Community> _getMockCommunities() {
    return [
      Community(
        id: 1,
        name: "Magic Players Chile",
        slug: "magic-players-chile",
        description:
            "Comunidad oficial de jugadores de Magic: The Gathering en Chile. Organizamos torneos, drafts y eventos casuales.",
        gameType: "Magic: The Gathering",
        difficultyLevel: "intermedio",
        tags: ["competitivo", "torneos", "drafts", "casual", "magic"],
        isPublic: true,
        isFeatured: false,
        memberCount: 1,
        postCount: 0,
        requiresApproval: false,
        createdByUsername: "admin",
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        isSubscribed: false,
      ),
      Community(
        id: 2,
        name: "Pokémon TCG Principiantes",
        slug: "pokemon-tcg-principiantes",
        description:
            "Espacio para nuevos jugadores de Pokémon TCG. Ayudamos con reglas, deck building y primeros pasos.",
        gameType: "Pokémon TCG",
        difficultyLevel: "principiante",
        tags: ["principiante", "aprender", "pokemon", "casual", "nuevo"],
        isPublic: true,
        isFeatured: false,
        memberCount: 1,
        postCount: 0,
        requiresApproval: false,
        createdByUsername: "admin",
        createdAt: DateTime.now().subtract(Duration(days: 25)),
        isSubscribed: false,
      ),
      Community(
        id: 3,
        name: "Yu-Gi-Oh! Meta Decks",
        slug: "yugioh-meta-deck-discussion",
        description:
            "Análisis del meta actual, estrategias avanzadas y discusión de cartas competitivas.",
        gameType: "Yu-Gi-Oh!",
        difficultyLevel: "avanzado",
        tags: ["meta", "competitivo", "estrategia", "yugioh", "avanzado"],
        isPublic: true,
        isFeatured: true,
        memberCount: 1,
        postCount: 0,
        requiresApproval: false,
        createdByUsername: "admin",
        createdAt: DateTime.now().subtract(Duration(days: 20)),
        isSubscribed: false,
      ),
      Community(
        id: 4,
        name: "Dragon Ball Super",
        slug: "dragon-ball-super-community",
        description:
            "Comunidad de Dragon Ball Super Card Game. Torneos, intercambios y estrategias.",
        gameType: "Dragon Ball Super",
        difficultyLevel: "intermedio",
        tags: ["dragon-ball", "anime", "competitivo", "casual", "comunidad"],
        isPublic: true,
        isFeatured: false,
        memberCount: 1,
        postCount: 0,
        requiresApproval: false,
        createdByUsername: "admin",
        createdAt: DateTime.now().subtract(Duration(days: 15)),
        isSubscribed: false,
      ),
    ];
  }
}
