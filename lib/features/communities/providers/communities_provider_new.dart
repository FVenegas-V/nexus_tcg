import 'package:flutter/foundation.dart';
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
  bool get hasError => _errorMessage != null;
  bool get isEmpty => _filteredCommunities.isEmpty && !_isLoading;

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
      _allCommunities = communities;
      _applyFilters();
      _setLoading(false);
    } catch (e) {
      print('💥 CommunitiesProvider: Error al cargar comunidades: $e');
      _setError('Error al cargar comunidades. Verifica tu conexión.');
      _setLoading(false);
    }
  }

  /// Refresca la lista de comunidades (pull-to-refresh)
  Future<void> refreshCommunities() async {
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
      '🎯 CommunitiesProvider: Toggling suscripción para ${community.name}',
    );

    try {
      if (community.isSubscribed) {
        // Salir de la comunidad
        print('📤 CommunitiesProvider: Saliendo de comunidad $communityId');
        final result = await _membershipService.leaveCommunity(communityId);

        if (result['success']) {
          print('✅ CommunitiesProvider: Salida exitosa de ${community.name}');

          // Actualizar estado local
          final updatedCommunity = community.copyWith(
            isSubscribed: false,
            memberCount: community.memberCount - 1,
          );
          _allCommunities[communityIndex] = updatedCommunity;
          _applyFilters();
        } else {
          print('❌ CommunitiesProvider: Error al salir: ${result['message']}');
          _setError(result['message']);
        }
      } else {
        // Unirse a la comunidad
        print('📥 CommunitiesProvider: Uniéndose a comunidad $communityId');
        final result = await _membershipService.joinCommunity(communityId);

        if (result['success']) {
          print('✅ CommunitiesProvider: Unión exitosa a ${community.name}');

          // Actualizar estado local
          final updatedCommunity = community.copyWith(
            isSubscribed: true,
            memberCount: community.memberCount + 1,
          );
          _allCommunities[communityIndex] = updatedCommunity;
          _applyFilters();
        } else {
          print('❌ CommunitiesProvider: Error al unirse: ${result['message']}');
          _setError(result['message']);
        }
      }
    } catch (e) {
      print('💥 CommunitiesProvider: Error en toggleSubscription: $e');
      _setError('Error de conexión. Inténtalo de nuevo.');
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
}
