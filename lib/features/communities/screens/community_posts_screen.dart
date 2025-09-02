import 'package:flutter/material.dart';

import '../../../core/models/post.dart';
import '../../../core/services/posts_service.dart';
import '../../posts/screens/create_post_screen.dart';
import '../../posts/widgets/post_card.dart';

/// Pantalla dedicada para mostrar todos los posts de una comunidad
///
/// Permite ver la lista completa de posts con:
/// - Scroll infinito
/// - Refresh to reload
/// - Ordenamiento por fecha
class CommunityPostsScreen extends StatefulWidget {
  final int communityId;
  final String communityName;

  const CommunityPostsScreen({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<CommunityPostsScreen> createState() => _CommunityPostsScreenState();
}

class _CommunityPostsScreenState extends State<CommunityPostsScreen> {
  final PostsService _postsService = PostsService();
  final ScrollController _scrollController = ScrollController();

  List<Post> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadPosts();

    // Configurar scroll infinito
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Manejar scroll para cargar más posts
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  /// Cargar posts iniciales
  Future<void> _loadPosts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final posts = await _postsService.getPosts(
        communityId: widget.communityId,
        ordering: '-created_at',
        page: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        _posts = posts;
        _hasMore = posts.length == _pageSize;
        _isLoading = false;
      });

      print(
        '📝 Loaded ${posts.length} posts for community ${widget.communityId}',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar posts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Cargar más posts (paginación)
  Future<void> _loadMorePosts() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final newPosts = await _postsService.getPosts(
        communityId: widget.communityId,
        ordering: '-created_at',
        page: nextPage,
        pageSize: _pageSize,
      );

      setState(() {
        _posts.addAll(newPosts);
        _currentPage = nextPage;
        _hasMore = newPosts.length == _pageSize;
        _isLoading = false;
      });

      print('📝 Loaded ${newPosts.length} more posts (page $nextPage)');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('❌ Error loading more posts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.communityName, style: const TextStyle(fontSize: 18)),
            Text(
              'Posts (${_posts.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: RefreshIndicator(onRefresh: _loadPosts, child: _buildBody()),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navegar a crear post y esperar resultado
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CreatePostScreen(preselectedCommunityId: widget.communityId),
            ),
          );

          // Si se creó un post exitosamente, recargar
          if (result == true) {
            await _loadPosts();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_posts.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay posts en esta comunidad',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¡Sé el primero en publicar!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _posts.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Mostrar loading indicator al final
        if (index == _posts.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final post = _posts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PostCard(post: post),
        );
      },
    );
  }
}
