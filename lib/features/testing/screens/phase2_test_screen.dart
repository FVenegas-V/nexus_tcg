import 'package:flutter/material.dart';
import '../../games/models/game_type.dart';
import '../../games/services/game_service.dart';
import '../../communities/models/community_tag.dart';
import '../../communities/services/tag_service.dart';

/// Pantalla de prueba para las APIs de la Fase 2
/// Permite probar GameTypes y Tags
class Phase2TestScreen extends StatefulWidget {
  const Phase2TestScreen({super.key});

  @override
  State<Phase2TestScreen> createState() => _Phase2TestScreenState();
}

class _Phase2TestScreenState extends State<Phase2TestScreen> {
  List<GameType> _gameTypes = [];
  List<GameType> _featuredGames = [];
  List<CommunityTag> _tags = [];
  List<CommunityTag> _popularTags = [];
  bool _isLoadingGames = false;
  bool _isLoadingTags = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadGameTypes(), _loadTags()]);
  }

  Future<void> _loadGameTypes() async {
    setState(() => _isLoadingGames = true);
    try {
      final games = await GameService.getGameTypes();
      final featured = await GameService.getFeaturedGameTypes();
      setState(() {
        _gameTypes = games;
        _featuredGames = featured;
      });
    } catch (e) {
      debugPrint('Error loading game types: $e');
    } finally {
      setState(() => _isLoadingGames = false);
    }
  }

  Future<void> _loadTags() async {
    setState(() => _isLoadingTags = true);
    try {
      final tags = await TagService.getTags();
      final popular = await TagService.getPopularTags();
      setState(() {
        _tags = tags;
        _popularTags = popular;
      });
    } catch (e) {
      debugPrint('Error loading tags: $e');
    } finally {
      setState(() => _isLoadingTags = false);
    }
  }

  Future<void> _searchTags(String query) async {
    if (query.isEmpty) {
      await _loadTags();
      return;
    }

    setState(() => _isLoadingTags = true);
    try {
      final searchResults = await TagService.searchTags(query);
      setState(() => _tags = searchResults);
    } catch (e) {
      debugPrint('Error searching tags: $e');
    } finally {
      setState(() => _isLoadingTags = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Pruebas Fase 2'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección de GameTypes
            _buildGameTypesSection(),
            const SizedBox(height: 32),

            // Sección de Tags
            _buildTagsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.videogame_asset, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              'GameTypes',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_isLoadingGames)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // GameTypes destacados
        if (_featuredGames.isNotEmpty) ...[
          Text(
            '⭐ Destacados (${_featuredGames.length})',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _featuredGames.length,
              itemBuilder: (context, index) {
                final game = _featuredGames[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildGameTypeCard(game, isFeatured: true),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Todos los GameTypes
        Text(
          '🎮 Todos los Games (${_gameTypes.length})',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _gameTypes.length,
          itemBuilder: (context, index) {
            return _buildGameTypeCard(_gameTypes[index]);
          },
        ),
      ],
    );
  }

  Widget _buildGameTypeCard(GameType game, {bool isFeatured = false}) {
    return Card(
      color: isFeatured ? Colors.blue.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    game.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (game.isFeatured)
                  const Icon(Icons.star, color: Colors.amber, size: 16),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              game.publisher,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${game.communityCount} comunidades',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            if (!isFeatured) ...[
              const SizedBox(height: 4),
              Text(
                game.playersRange,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.label, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Tags',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (_isLoadingTags)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Búsqueda de tags
        TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar tags...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
            _searchTags(value);
          },
        ),
        const SizedBox(height: 16),

        // Tags populares
        if (_popularTags.isNotEmpty && _searchQuery.isEmpty) ...[
          Text(
            '🔥 Populares (${_popularTags.length})',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _popularTags
                .map((tag) => _buildTagChip(tag, isPopular: true))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Todos los tags
        Text(
          _searchQuery.isEmpty
              ? '🏷️ Todos los Tags (${_tags.length})'
              : '🔍 Resultados (${_tags.length})',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (_tags.isEmpty && !_isLoadingTags)
          const Text('No se encontraron tags')
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) => _buildTagChip(tag)).toList(),
          ),
      ],
    );
  }

  Widget _buildTagChip(CommunityTag tag, {bool isPopular = false}) {
    return Chip(
      label: Text(tag.name, style: const TextStyle(fontSize: 12)),
      backgroundColor: isPopular
          ? Colors.orange.shade100
          : Color(tag.colorValue).withOpacity(0.2),
      side: BorderSide(color: Color(tag.colorValue), width: 1),
      labelStyle: TextStyle(
        color: Color(tag.colorValue),
        fontWeight: isPopular ? FontWeight.w600 : FontWeight.normal,
      ),
      avatar: Text(
        tag.usageCount.toString(),
        style: TextStyle(
          fontSize: 10,
          color: Color(tag.colorValue),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
