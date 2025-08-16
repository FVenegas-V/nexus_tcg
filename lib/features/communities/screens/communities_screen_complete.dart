import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/community.dart';
import '../../../core/providers/communities_state.dart';
import '../widgets/community_card.dart';
import '../widgets/community_filter_sheet.dart';
import '../widgets/game_type_filter_chips.dart';

/// Pantalla de Comunidades - Lista todas las comunidades disponibles
/// Incluye búsqueda, filtros y navegación a detalle - VERSIÓN COMPLETA
class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedGameType;
  String? _selectedDifficulty;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // Cargar datos iniciales cuando se inicia la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final communitiesState = Provider.of<CommunitiesState>(
        context,
        listen: false,
      );
      if (communitiesState.communities.isEmpty && !communitiesState.isLoading) {
        communitiesState.loadInitialData();
        communitiesState.loadCommunities();
      }
    });

    // Scroll infinito
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      // Cargar más comunidades cuando se acerque al final
      _loadMoreCommunities();
    }
  }

  void _loadMoreCommunities() {
    final communitiesState = context.read<CommunitiesState>();
    if (!communitiesState.isLoading) {
      communitiesState.loadCommunities(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        gameType: _selectedGameType,
        difficulty: _selectedDifficulty,
        offset: communitiesState.communities.length,
      );
    }
  }

  void _applyFilters() {
    final communitiesState = context.read<CommunitiesState>();
    communitiesState.loadCommunities(
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
      gameType: _selectedGameType,
      difficulty: _selectedDifficulty,
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommunityFilterSheet(
        selectedGameType: _selectedGameType,
        selectedDifficulty: _selectedDifficulty,
        onFiltersChanged: (gameType, difficulty) {
          setState(() {
            _selectedGameType = gameType;
            _selectedDifficulty = difficulty;
          });
          _applyFilters();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunitiesState>(
      builder: (context, state, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Comunidades',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            actions: [
              // Botón de búsqueda
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showSearchDialog(context, state),
              ),
              // Botón de filtros
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color:
                      (_selectedGameType != null || _selectedDifficulty != null)
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: _showFilterSheet,
              ),
            ],
          ),
          body: Column(
            children: [
              // Barra de búsqueda
              _buildSearchBar(),

              // Chips de filtros activos
              if (_selectedGameType != null || _selectedDifficulty != null)
                _buildActiveFilters(),

              // Chips de tipos de juego
              GameTypeFilterChips(
                gameTypes: state.gameTypes,
                selectedGameType: _selectedGameType,
                onGameTypeSelected: (gameType) {
                  setState(() {
                    _selectedGameType = gameType;
                  });
                  _applyFilters();
                },
              ),

              // Lista de comunidades
              Expanded(child: _buildCommunityList(state)),
            ],
          ),
        );
      },
    );
  }

  /// Construye la barra de búsqueda
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar comunidades...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    _applyFilters();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onSubmitted: (query) {
          setState(() {
            _searchQuery = query;
          });
          _applyFilters();
        },
      ),
    );
  }

  /// Construye los chips de filtros activos
  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: [
          if (_selectedGameType != null)
            Chip(
              label: Text('Juego: $_selectedGameType'),
              onDeleted: () {
                setState(() {
                  _selectedGameType = null;
                });
                _applyFilters();
              },
            ),
          if (_selectedDifficulty != null)
            Chip(
              label: Text('Dificultad: $_selectedDifficulty'),
              onDeleted: () {
                setState(() {
                  _selectedDifficulty = null;
                });
                _applyFilters();
              },
            ),
          if (_selectedGameType != null || _selectedDifficulty != null)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedGameType = null;
                  _selectedDifficulty = null;
                });
                _applyFilters();
              },
              child: const Text('Limpiar todo'),
            ),
        ],
      ),
    );
  }

  /// Construye la lista principal de comunidades
  Widget _buildCommunityList(CommunitiesState state) {
    if (state.isLoading && state.communities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando comunidades...'),
          ],
        ),
      );
    }

    if (state.error != null && state.communities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                state.error ?? 'Error desconocido',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => state.loadCommunities(),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.communities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.group,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              const SizedBox(height: 16),
              const Text(
                'No se encontraron comunidades',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Intenta cambiar los filtros de búsqueda',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedGameType = null;
                    _selectedDifficulty = null;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                  _applyFilters();
                },
                child: const Text('Limpiar filtros'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => state.loadCommunities(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        gameType: _selectedGameType,
        difficulty: _selectedDifficulty,
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.communities.length + (state.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.communities.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final Community community = state.communities[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CommunityCard(
              community: community,
              onTap: () {
                context.push('/community/${community.id}');
              },
              onSubscriptionToggle: () {
                state.toggleCommunityMembership(community.id);
              },
            ),
          );
        },
      ),
    );
  }

  /// Muestra el diálogo de búsqueda
  void _showSearchDialog(BuildContext context, CommunitiesState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Búsqueda de comunidades'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (query) {
                setState(() {
                  _searchQuery = query;
                });
                _applyFilters();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Utiliza la barra de búsqueda y filtros para encontrar comunidades específicas.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _searchQuery = _searchController.text;
              });
              _applyFilters();
              Navigator.pop(context);
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }
}
