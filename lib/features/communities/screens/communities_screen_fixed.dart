import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/community.dart';
import '../providers/communities_provider_new.dart';
import '../../posts/providers/posts_provider.dart';
import '../widgets/community_card.dart';

/// Pantalla de Comunidades - Lista todas las comunidades disponibles
/// Incluye búsqueda, filtros y navegación a detalle - VERSIÓN NUEVA
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
              // Botón de búsqueda
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => _showSearchDialog(context, provider),
              ),
              // Botón de filtros
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color:
                      (provider.selectedGameType.isNotEmpty ||
                          provider.selectedDifficulty.isNotEmpty)
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onPressed: () => _showFiltersDialog(context, provider),
              ),
            ],
          ),
          body: Column(
            children: [
              // Barra de búsqueda
              _buildSearchBar(provider),

              // Chips de filtros activos
              if (provider.selectedGameType.isNotEmpty ||
                  provider.selectedDifficulty.isNotEmpty)
                _buildActiveFilters(provider),

              // Lista de comunidades
              Expanded(child: _buildCommunityList(provider)),
            ],
          ),
        );
      },
    );
  }

  /// Construye la barra de búsqueda
  Widget _buildSearchBar(CommunitiesProvider provider) {
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
  Widget _buildActiveFilters(CommunitiesProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: [
          if (provider.selectedGameType.isNotEmpty)
            Chip(
              label: Text('Juego: ${provider.selectedGameType}'),
              onDeleted: () => provider.filterByGameType(''),
            ),
          if (provider.selectedDifficulty.isNotEmpty)
            Chip(
              label: Text('Dificultad: ${provider.selectedDifficulty}'),
              onDeleted: () => provider.filterByDifficulty(''),
            ),
          if (provider.selectedGameType.isNotEmpty ||
              provider.selectedDifficulty.isNotEmpty)
            TextButton(
              onPressed: () => provider.clearFilters(),
              child: const Text('Limpiar todo'),
            ),
        ],
      ),
    );
  }

  /// Construye la lista principal de comunidades
  Widget _buildCommunityList(CommunitiesProvider provider) {
    if (provider.isLoading && provider.communities.isEmpty) {
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

    if (provider.hasError && provider.communities.isEmpty) {
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
                onPressed: () => provider.loadCommunities(),
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
                onPressed: () => provider.clearFilters(),
                child: const Text('Limpiar filtros'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.refreshCommunities(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.communities.length,
        itemBuilder: (context, index) {
          final Community community = provider.communities[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CommunityCard(
              community: community,
              onTap: () {
                context.push('/community/${community.id}');
              },
              onSubscriptionToggle: () async {
                await provider.toggleSubscription(community.id);

                // Actualizar el feed después de cambio exitoso de suscripción
                if (context.mounted) {
                  try {
                    final postsProvider = context.read<PostsProvider>();
                    debugPrint(
                      '🔄 Actualizando feed después de cambio de suscripción...',
                    );
                    await postsProvider.refreshPosts();
                    debugPrint('✅ Feed actualizado exitosamente');
                  } catch (e) {
                    debugPrint('⚠️ Error al actualizar feed: $e');
                  }
                }
              },
            ),
          );
        },
      ),
    );
  }

  /// Muestra el diálogo de búsqueda
  void _showSearchDialog(BuildContext context, CommunitiesProvider provider) {
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
                provider.searchCommunities(query);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Busca por nombre, descripción, tipo de juego o tags.',
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
              provider.searchCommunities(_searchController.text);
              Navigator.pop(context);
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  /// Muestra el diálogo de filtros
  void _showFiltersDialog(BuildContext context, CommunitiesProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtros'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtro por tipo de juego
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

            // Filtro por dificultad
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.clearFilters();
              Navigator.pop(context);
            },
            child: const Text('Limpiar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
  }
}
