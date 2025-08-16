import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/communities_provider_new.dart';
import '../widgets/community_card.dart';
import '../widgets/community_filter_sheet.dart';
import 'community_search_page.dart';

/// Página principal del sistema de Communities
/// Muestra lista de comunidades con filtros y búsqueda
class CommunitiesListPage extends StatefulWidget {
  const CommunitiesListPage({super.key});

  @override
  State<CommunitiesListPage> createState() => _CommunitiesListPageState();
}

class _CommunitiesListPageState extends State<CommunitiesListPage> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedGameType;
  String? _selectedDifficulty;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // Cargar datos iniciales si no están cargados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final communitiesState = context.read<CommunitiesProvider>();
      if (communitiesState.communities.isEmpty && !communitiesState.isLoading) {
        communitiesState.loadCommunities();
        communitiesState.loadCommunities();
      }
    });

    // Scroll infinito
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
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
    final communitiesState = context.read<CommunitiesProvider>();
    if (!communitiesState.isLoading) {
      communitiesState.loadCommunities();
    }
  }

  void _applyFilters() {
    final communitiesState = context.read<CommunitiesProvider>();
    communitiesState.loadCommunities();
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

  void _navigateToSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CommunitySearchPage(
          initialQuery: _searchQuery,
          onSearchChanged: (query) {
            setState(() {
              _searchQuery = query;
            });
            _applyFilters();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Communities'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _navigateToSearch,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Consumer<CommunitiesProvider>(
        builder: (context, state, child) {
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

          if (state.errorMessage != null && state.communities.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      state.loadCommunities();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await state.refreshCommunities();
              _applyFilters();
            },
            child: Column(
              children: [
                // Filtros rápidos por GameType
                // Filter chips temporalmente deshabilitados
                // TODO: Implementar cuando se tenga List<GameType>
                /*if (state.availableGameTypes.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: GameTypeFilterChips(
                      gameTypes: state.availableGameTypes,
                      selectedGameType: _selectedGameType,
                      onGameTypeSelected: (gameType) {
                        setState(() {
                          _selectedGameType = gameType;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
                  const Divider(height: 1),
                ],*/

                // Lista de comunidades
                Expanded(
                  child: state.communities.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.group, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No hay comunidades disponibles',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Sé el primero en crear una comunidad',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount:
                              state.communities.length +
                              (state.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= state.communities.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final community = state.communities[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: CommunityCard(
                                community: community,
                                onTap: () {
                                  // Navegar a detalle de comunidad
                                  context.push('/community/${community.id}');
                                },
                                onSubscriptionToggle: () async {
                                  // Cambiar estado de suscripción
                                  await state.toggleSubscription(community.id);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
