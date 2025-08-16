import 'package:flutter/foundation.dart';
import '../../../core/models/community.dart';
import '../../../core/providers/communities_state.dart';

/// Provider proxy para mantener compatibilidad con código existente
/// Delega todas las operaciones a CommunitiesState
class CommunitiesProvider extends ChangeNotifier {
  final CommunitiesState _communitiesState;

  CommunitiesProvider(this._communitiesState) {
    // Escuchar cambios en CommunitiesState
    _communitiesState.addListener(_notifyListeners);
  }

  void _notifyListeners() {
    notifyListeners();
  }

  @override
  void dispose() {
    _communitiesState.removeListener(_notifyListeners);
    super.dispose();
  }

  // Getters que delegan a CommunitiesState
  List<Community> get communities => _communitiesState.communities;
  List<Community> get allCommunities => _communitiesState.communities;
  bool get isLoading => _communitiesState.isLoading;
  String? get errorMessage => _communitiesState.error;
  bool get hasError => _communitiesState.error != null;
  bool get isEmpty =>
      _communitiesState.communities.isEmpty && !_communitiesState.isLoading;

  // Propiedades específicas del provider (temporales)
  String _searchQuery = '';
  String _selectedGameType = '';
  String _selectedDifficulty = '';

  String get searchQuery => _searchQuery;
  String get selectedGameType => _selectedGameType;
  String get selectedDifficulty => _selectedDifficulty;

  /// Lista de comunidades suscritas
  List<Community> get subscribedCommunities {
    return _communitiesState.communities
        .where((community) => _communitiesState.isUserMemberOf(community.id))
        .toList();
  }

  /// Tipos de juego disponibles para filtrar
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
  Future<void> loadCommunities() async {
    await _communitiesState.loadCommunities();
  }

  /// Refresca la lista de comunidades
  Future<void> refreshCommunities() async {
    await _communitiesState.refreshAll();
  }

  /// Búsqueda por query
  void searchCommunities(String query) {
    _searchQuery = query;
    // TODO: Implementar filtrado local o usar API
    notifyListeners();
  }

  /// Filtrado por tipo de juego
  void filterByGameType(String? gameType) {
    _selectedGameType = gameType ?? '';
    // TODO: Implementar filtrado local o usar API
    notifyListeners();
  }

  /// Filtrado por dificultad
  void filterByDifficulty(String? difficulty) {
    _selectedDifficulty = difficulty ?? '';
    // TODO: Implementar filtrado local o usar API
    notifyListeners();
  }

  /// Limpiar filtros
  void clearFilters() {
    _searchQuery = '';
    _selectedGameType = '';
    _selectedDifficulty = '';
    notifyListeners();
  }

  /// Cambiar estado de suscripción de una comunidad
  Future<void> toggleSubscription(int communityId) async {
    await _communitiesState.toggleCommunityMembership(communityId);
  }

  /// Obtiene una comunidad por ID
  Community? getCommunityById(int id) {
    try {
      return _communitiesState.communities.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene comunidades por lista de IDs
  List<Community> getCommunitiesByIds(List<int> ids) {
    return _communitiesState.communities
        .where((c) => ids.contains(c.id))
        .toList();
  }

  /// Obtiene estadísticas básicas
  Map<String, int> get stats => {
    'total': _communitiesState.communities.length,
    'subscribed': subscribedCommunities.length,
    'filtered': _communitiesState.communities.length,
  };

  /// Resetea el provider a su estado inicial
  void reset() {
    _searchQuery = '';
    _selectedGameType = '';
    _selectedDifficulty = '';
    notifyListeners();
  }
}
