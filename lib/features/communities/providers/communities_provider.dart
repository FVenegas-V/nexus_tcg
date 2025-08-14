import 'package:flutter/foundation.dart';
import '../models/community.dart';
import '../models/mock_communities_data.dart';

/// Provider para gestión de estado de comunidades
/// Maneja la lista de comunidades, búsqueda, filtros y suscripciones
class CommunitiesProvider extends ChangeNotifier {
  List<Community> _allCommunities = [];
  List<Community> _filteredCommunities = [];
  String _searchQuery = '';
  String _selectedGameType = '';
  String _selectedDifficulty = '';
  bool _isLoading = false;
  String? _errorMessage;

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

  /// Tipos de juego disponibles para filtrar
  List<String> get availableGameTypes => MockCommunitiesData.availableGameTypes;

  /// Niveles de dificultad disponibles para filtrar
  List<String> get availableDifficultyLevels =>
      MockCommunitiesData.availableDifficultyLevels;

  /// Inicializa el provider cargando las comunidades
  CommunitiesProvider() {
    loadCommunities();
  }

  /// Carga todas las comunidades (simula llamada a API)
  Future<void> loadCommunities() async {
    _setLoading(true);
    _clearError();

    try {
      // Simula delay de red
      await Future.delayed(const Duration(milliseconds: 800));

      _allCommunities = List.from(MockCommunitiesData.allCommunities);
      _applyFilters();
      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar comunidades. Inténtalo de nuevo.');
      _setLoading(false);
    }
  }

  /// Refresca la lista de comunidades (pull-to-refresh)
  Future<void> refreshCommunities() async {
    // No mostrar loading spinner en refresh
    _clearError();

    try {
      // Simula delay de red más corto para refresh
      await Future.delayed(const Duration(milliseconds: 500));

      _allCommunities = List.from(MockCommunitiesData.allCommunities);
      _applyFilters();
      notifyListeners();
    } catch (e) {
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

  /// Cambia el estado de suscripción de una comunidad
  void toggleSubscription(int communityId) {
    final communityIndex = _allCommunities.indexWhere(
      (c) => c.id == communityId,
    );

    if (communityIndex != -1) {
      final community = _allCommunities[communityIndex];

      final updatedCommunity = community.copyWith(
        isSubscribed: !community.isSubscribed,
      );

      _allCommunities[communityIndex] = updatedCommunity;
      _applyFilters();
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

  /// Resetea el provider a su estado inicial
  void reset() {
    _allCommunities.clear();
    _filteredCommunities.clear();
    _searchQuery = '';
    _selectedGameType = '';
    _selectedDifficulty = '';
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
