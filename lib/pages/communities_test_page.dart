import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/communities_state.dart';

/// Página de prueba para verificar la conectividad con las APIs
class CommunitiesTestPage extends StatefulWidget {
  const CommunitiesTestPage({super.key});

  @override
  State<CommunitiesTestPage> createState() => _CommunitiesTestPageState();
}

class _CommunitiesTestPageState extends State<CommunitiesTestPage> {
  @override
  void initState() {
    super.initState();
    // HttpService ya está inicializado en main.dart, no necesitamos hacerlo de nuevo

    // Cargar datos iniciales después de que el widget se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunitiesState>().loadInitialData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba APIs Communities'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<CommunitiesState>(
        builder: (context, state, child) {
          if (state.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando datos de las APIs...'),
                ],
              ),
            );
          }

          if (state.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${state.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => state.loadInitialData(),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sección GameTypes
                _buildSection(
                  title: '🎮 GameTypes',
                  count: state.gameTypes.length,
                  onPressed: () => _showGameTypesList(context, state),
                ),
                const SizedBox(height: 16),

                // Sección Tags
                _buildSection(
                  title: '🏷️ Tags',
                  count: state.tags.length,
                  onPressed: () => _showTagsList(context, state),
                ),
                const SizedBox(height: 16),

                // Sección Categories
                _buildSection(
                  title: '📂 Categories',
                  count: state.categories.length,
                  onPressed: () => _showCategoriesList(context, state),
                ),
                const SizedBox(height: 16),

                // Sección Communities
                _buildSection(
                  title: '🌐 Communities',
                  count: state.popularCommunities.length,
                  subtitle: 'Populares cargadas',
                  onPressed: () => _showCommunitiesList(context, state),
                ),
                const SizedBox(height: 16),

                // Botones de prueba adicionales
                const Text(
                  'Pruebas Adicionales:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => state.loadCommunitiesStats(),
                      icon: const Icon(Icons.analytics),
                      label: const Text('Cargar Estadísticas'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => state.loadFeaturedGameTypes(),
                      icon: const Icon(Icons.star),
                      label: const Text('Juegos Destacados'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => state.loadPopularTags(),
                      icon: const Icon(Icons.trending_up),
                      label: const Text('Tags Populares'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => state.refreshAll(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refrescar Todo'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required int count,
    String? subtitle,
    required VoidCallback onPressed,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(title),
        subtitle: Text(subtitle ?? '$count elementos cargados'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onPressed,
      ),
    );
  }

  void _showGameTypesList(BuildContext context, CommunitiesState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GameTypes'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: state.gameTypes.length,
            itemBuilder: (context, index) {
              final gameType = state.gameTypes[index];
              return ListTile(
                leading: gameType.isFeatured
                    ? const Icon(Icons.star, color: Colors.amber)
                    : const Icon(Icons.games),
                title: Text(gameType.name),
                subtitle: Text('${gameType.communityCount} comunidades'),
                trailing: Text(gameType.isActive ? 'Activo' : 'Inactivo'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showTagsList(BuildContext context, CommunitiesState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tags'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: state.tags.length,
            itemBuilder: (context, index) {
              final tag = state.tags[index];
              return ListTile(
                leading: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Color(
                      int.parse(tag.color.replaceFirst('#', '0xFF')),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(tag.name),
                subtitle: Text('Usado ${tag.usageCount} veces'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showCategoriesList(BuildContext context, CommunitiesState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Categories'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: state.categories.length,
            itemBuilder: (context, index) {
              final category = state.categories[index];
              return ListTile(
                leading: const Icon(Icons.category),
                title: Text(category.name),
                subtitle: Text('${category.communityCount} comunidades'),
                trailing: Icon(
                  category.isActive ? Icons.check_circle : Icons.cancel,
                  color: category.isActive ? Colors.green : Colors.red,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _showCommunitiesList(BuildContext context, CommunitiesState state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Communities (Populares)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: state.popularCommunities.length,
            itemBuilder: (context, index) {
              final community = state.popularCommunities[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(community.memberCount.toString()),
                ),
                title: Text(community.name),
                subtitle: Text(
                  '${community.gameType} • ${community.difficultyLevel}',
                ),
                trailing: Icon(
                  community.isPublic ? Icons.public : Icons.lock,
                  color: community.isPublic ? Colors.green : Colors.orange,
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
