import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/posts_provider.dart';
import '../widgets/post_card.dart';
import '../../../core/widgets/nexus_logo.dart';

/// Pantalla principal del feed de posts con paginación infinita
/// Implementa pull-to-refresh, scroll infinito y estados de carga
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Cargar más posts cuando estemos cerca del final
      context.read<PostsProvider>().loadMorePosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Logo de Nexus TCG
            const NexusCardIcon(size: 32),
            const SizedBox(width: 12),
            const Text(
              'NEXUS TCG',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () {
              // TODO: Implementar búsqueda
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implementar notificaciones
            },
          ),
        ],
        elevation: 0,
      ),
      body: Consumer<PostsProvider>(
        builder: (context, postsProvider, child) {
          if (postsProvider.isLoading) {
            return _buildLoadingState();
          }

          if (postsProvider.hasError) {
            return _buildErrorState(postsProvider.errorMessage!);
          }

          if (postsProvider.isEmpty) {
            return _buildEmptyState();
          }

          return _buildFeedList(postsProvider);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/create-post');
        },
        tooltip: 'Crear post',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando posts...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
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
              'Error al cargar el feed',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<PostsProvider>().loadInitialPosts();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.post_add_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay posts aún',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sé el primero en crear un post en tu comunidad favorita',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navegar a crear post
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear post'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedList(PostsProvider postsProvider) {
    return RefreshIndicator(
      onRefresh: () => postsProvider.refreshPosts(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount:
            postsProvider.posts.length +
            (postsProvider.isLoadingMore ? 1 : 0) +
            (postsProvider.hasReachedEnd ? 1 : 0),
        itemBuilder: (context, index) {
          // Posts normales
          if (index < postsProvider.posts.length) {
            final post = postsProvider.posts[index];
            return PostCard(
              post: post,
              onTap: () => _onPostTap(post.id),
              onLike: () => postsProvider.toggleLike(post.id),
              onComment: () => _onCommentTap(post.id),
              onShare: () => _onShareTap(post.id),
              onBookmark: () => postsProvider.toggleBookmark(post.id),
              onAuthorTap: () => _onAuthorTap(post.author.id),
              onCommunityTap: () => _onCommunityTap(post.community.id),
            );
          }

          // Indicador de carga al final
          if (postsProvider.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando más posts...'),
                  ],
                ),
              ),
            );
          }

          // Mensaje de final alcanzado
          if (postsProvider.hasReachedEnd) {
            return Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  '¡Has llegado al final del feed!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _onPostTap(int postId) {
    // TODO: Navegar a detalle del post
    debugPrint('Post tapped: $postId');
  }

  void _onCommentTap(int postId) {
    // TODO: Navegar a comentarios del post
    debugPrint('Comment tapped: $postId');
  }

  void _onShareTap(int postId) {
    // TODO: Implementar compartir post
    debugPrint('Share tapped: $postId');

    // Por ahora, mostrar snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Post compartido!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onAuthorTap(int authorId) {
    // TODO: Navegar a perfil del autor
    debugPrint('Author tapped: $authorId');
  }

  void _onCommunityTap(int communityId) {
    // TODO: Navegar a detalle de la comunidad
    debugPrint('Community tapped: $communityId');
  }
}
