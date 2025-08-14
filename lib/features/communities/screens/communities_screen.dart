import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/community.dart';
import '../providers/communities_provider.dart';
import '../widgets/community_card_fixed.dart';

/// Pantalla de Comunidades - Lista todas las comunidades disponibles
/// Incluye búsqueda, filtros y navegación a detalle
class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunitiesProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Comunidades',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            actions: [
              // Botón de filtros
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color:
                      provider.selectedGameType.isNotEmpty ||
                          provider.selectedDifficulty.isNotEmpty
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: () => _showFiltersBottomSheet(context, provider),
              ),
            ],
          ),
          body: Column(
            children: [
              // Barra de búsqueda
              _buildSearchBar(context, provider),

              // Chips de filtros activos
              if (provider.selectedGameType.isNotEmpty ||
                  provider.selectedDifficulty.isNotEmpty)
                _buildActiveFilters(context, provider),

              // Lista de comunidades o estado de carga/error
              Expanded(child: _buildCommunityList(context, provider)),
            ],
          ),
        );
      },
    );
  }

  /// Construye la barra de búsqueda
  Widget _buildSearchBar(BuildContext context, CommunitiesProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar comunidades...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: provider.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    provider.searchCommunities('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (query) {
          provider.searchCommunities(query);
        },
      ),
    );
  }

  /// Construye los chips de filtros activos
  Widget _buildActiveFilters(
    BuildContext context,
    CommunitiesProvider provider,
  ) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (provider.selectedGameType.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(provider.selectedGameType),
                onDeleted: () => provider.filterByGameType(''),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            ),
          if (provider.selectedDifficulty.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(provider.selectedDifficulty),
                onDeleted: () => provider.filterByDifficulty(''),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.secondaryContainer,
              ),
            ),
          TextButton(
            onPressed: provider.clearFilters,
            child: const Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }

  /// Construye la lista principal de comunidades
  Widget _buildCommunityList(
    BuildContext context,
    CommunitiesProvider provider,
  ) {
    if (provider.isLoading) {
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

    if (provider.hasError) {
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
                provider.errorMessage ?? 'Error desconocido',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: provider.loadCommunities,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
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
                onPressed: provider.clearFilters,
                child: const Text('Limpiar filtros'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.refreshCommunities,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: provider.communities.length,
        itemBuilder: (context, index) {
          final Community community = provider.communities[index];
          return CommunityCard(
            communityId: community.id,
            onTap: () {
              context.push('/community/${community.id}');
            },
            onSubscriptionToggle: () {
              provider.toggleSubscription(community.id);
            },
          );
        },
      ),
    );
  }

  /// Muestra el bottom sheet de filtros
  void _showFiltersBottomSheet(
    BuildContext context,
    CommunitiesProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    provider.clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Limpiar'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Tipo de juego:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: provider.availableGameTypes.map((gameType) {
                final isSelected = provider.selectedGameType == gameType;
                return FilterChip(
                  label: Text(gameType),
                  selected: isSelected,
                  onSelected: (selected) {
                    provider.filterByGameType(selected ? gameType : '');
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Nivel de dificultad:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: provider.availableDifficultyLevels.map((difficulty) {
                final isSelected = provider.selectedDifficulty == difficulty;
                return FilterChip(
                  label: Text(difficulty),
                  selected: isSelected,
                  onSelected: (selected) {
                    provider.filterByDifficulty(selected ? difficulty : '');
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Aplicar filtros'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
