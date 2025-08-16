import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/communities_state.dart';
import '../widgets/community_card.dart';

/// Página de búsqueda avanzada de comunidades
/// Incluye campo de búsqueda y filtros dinámicos
class CommunitySearchPage extends StatefulWidget {
  final String initialQuery;
  final Function(String) onSearchChanged;

  const CommunitySearchPage({
    super.key,
    this.initialQuery = '',
    required this.onSearchChanged,
  });

  @override
  State<CommunitySearchPage> createState() => _CommunitySearchPageState();
}

class _CommunitySearchPageState extends State<CommunitySearchPage> {
  late final TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchHistory = [];
  bool _showHistory = true;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);

    // Enfocar automáticamente el campo de búsqueda
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });

    // Cargar historial de búsqueda (simulado)
    _searchHistory = [
      'Magic comunidades',
      'Pokémon principiantes',
      'Yu-Gi-Oh competitivo',
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      _showHistory = false;
      // Agregar al historial si no existe
      if (!_searchHistory.contains(query.trim())) {
        _searchHistory.insert(0, query.trim());
        // Mantener máximo 10 elementos
        if (_searchHistory.length > 10) {
          _searchHistory = _searchHistory.take(10).toList();
        }
      }
    });

    widget.onSearchChanged(query.trim());
    context.read<CommunitiesState>().searchCommunities(query.trim());
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _showHistory = true;
    });
    widget.onSearchChanged('');
  }

  void _selectHistoryItem(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Buscar comunidades...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: _performSearch,
          onChanged: (value) {
            setState(() {
              _showHistory = value.isEmpty;
            });
          },
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: Consumer<CommunitiesState>(
        builder: (context, state, child) {
          // Mostrar historial cuando no hay búsqueda activa
          if (_showHistory && _searchController.text.isEmpty) {
            return _buildSearchHistory();
          }

          // Mostrar resultados de búsqueda
          if (state.isLoading && state.communities.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Buscando comunidades...'),
                ],
              ),
            );
          }

          if (state.communities.isEmpty && !state.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No se encontraron comunidades',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Intenta con otros términos de búsqueda',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.communities.length,
            itemBuilder: (context, index) {
              final community = state.communities[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CommunityCard(
                  community: community,
                  onTap: () {
                    context.push('/community/${community.id}');
                  },
                  onSubscriptionToggle: () async {
                    final communitiesState = context.read<CommunitiesState>();
                    await communitiesState.toggleCommunityMembership(
                      community.id,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchHistory() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_searchHistory.isNotEmpty) ...[
          Row(
            children: [
              const Text(
                'Búsquedas recientes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchHistory.clear();
                  });
                },
                child: const Text('Limpiar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._searchHistory.map((query) {
            return ListTile(
              leading: const Icon(Icons.history),
              title: Text(query),
              onTap: () => _selectHistoryItem(query),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _searchHistory.remove(query);
                  });
                },
              ),
            );
          }),
        ],

        const SizedBox(height: 24),

        // Sugerencias de búsqueda
        const Text(
          'Sugerencias',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                'Magic principiantes',
                'Pokémon intercambio',
                'Yu-Gi-Oh meta',
                'Dragon Ball casual',
                'One Piece colección',
              ].map((suggestion) {
                return ActionChip(
                  label: Text(suggestion),
                  onPressed: () => _selectHistoryItem(suggestion),
                );
              }).toList(),
        ),
      ],
    );
  }
}
