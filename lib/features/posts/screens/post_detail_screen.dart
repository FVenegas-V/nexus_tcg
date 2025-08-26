import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/post.dart';
import '../../../core/models/reaction.dart';
import '../../../core/services/http_service.dart';
import '../../../core/services/comments_service.dart';
import '../providers/posts_provider.dart';
import '../providers/comments_provider.dart';
import '../widgets/post_card.dart';
import '../widgets/reactions_widget.dart';
import '../widgets/comments_list_widget.dart';

/// Pantalla de detalle de un post individual
///
/// Funcionalidades:
/// - Vista completa del post con imágenes
/// - Sistema de reacciones completo (6 tipos)
/// - Sección de comentarios (preparada para futuro)
/// - Acciones de post (editar, eliminar, compartir)
class PostDetailScreen extends StatefulWidget {
  final int postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  Post? _post;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  /// Cargar detalle del post
  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final postsProvider = context.read<PostsProvider>();
      final post = await postsProvider.getPost(widget.postId);

      if (mounted) {
        setState(() {
          _post = post;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Refrescar el post
  Future<void> _refreshPost() async {
    await _loadPost();
  }

  /// Manejar reacción al post
  Future<void> _handleReaction(ReactionType reactionType) async {
    if (_post == null) return;

    try {
      final postsProvider = context.read<PostsProvider>();
      await postsProvider.toggleReaction(_post!.id, reactionType);

      // No necesitamos setState porque el Consumer se actualiza automáticamente
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reaccionar: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Manejar acción de compartir
  void _handleShare() {
    // TODO: Implementar compartir real
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Post compartido!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Manejar navegación al perfil del autor
  void _handleAuthorTap() {
    if (_post == null) return;

    // TODO: Implementar navegación al perfil
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Perfil de ${_post!.authorUsername} próximamente'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Manejar navegación a la comunidad
  void _handleCommunityTap() {
    if (_post == null) return;

    // TODO: Implementar navegación a la comunidad
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Comunidad ${_post!.communityName} próximamente'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Verificar si puede navegar hacia atrás, sino ir al home
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Post'),
        elevation: 0,
        actions: [
          // Menú de opciones del post
          if (_post != null)
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined),
                      SizedBox(width: 12),
                      Text('Compartir'),
                    ],
                  ),
                ),
                // TODO: Mostrar edit/delete solo si es el autor
                // if (_post!.authorId == currentUserId) ...[
                //   const PopupMenuItem(
                //     value: 'edit',
                //     child: Row(
                //       children: [
                //         Icon(Icons.edit_outlined),
                //         SizedBox(width: 12),
                //         Text('Editar'),
                //       ],
                //     ),
                //   ),
                //   const PopupMenuItem(
                //     value: 'delete',
                //     child: Row(
                //       children: [
                //         Icon(Icons.delete_outline, color: Colors.red),
                //         SizedBox(width: 12),
                //         Text('Eliminar', style: TextStyle(color: Colors.red)),
                //       ],
                //     ),
                //   ),
                // ],
              ],
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_post == null) {
      return _buildNotFoundState();
    }

    return _buildPostDetail();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando post...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
              'Error al cargar el post',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshPost,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
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
              'Post no encontrado',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'El post que buscas no existe o ha sido eliminado',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostDetail() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CommentsProvider(CommentsService(HttpService())),
        ),
      ],
      child: RefreshIndicator(
        onRefresh: _refreshPost,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post principal
              PostCard(
                post: _post!,
                onAuthorTap: _handleAuthorTap,
                onCommunityTap: _handleCommunityTap,
                onShare: _handleShare,
                // En el detalle, los likes se manejan con el widget de reacciones
                onLike: null,
              ),

              const Divider(height: 1),

              // Widget de reacciones completo con Consumer para actualizaciones
              Consumer<PostsProvider>(
                builder: (context, postsProvider, child) {
                  // Obtener el post más actualizado del provider
                  final currentPost =
                      postsProvider.postsCache[_post!.id] ?? _post!;
                  return ReactionsWidget(
                    post: currentPost,
                    onReaction: _handleReaction,
                  );
                },
              ),

              const Divider(height: 1),

              // Sección de comentarios
              _buildCommentsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Container(
      width: double.infinity,
      child: CommentsListWidget(
        communityId: _post!.communityId,
        postId: _post!.id,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        _handleShare();
        break;
      case 'edit':
        // TODO: Implementar edición
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Edición próximamente'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 'delete':
        // TODO: Implementar eliminación con confirmación
        _showDeleteConfirmation();
        break;
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar post'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este post? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implementar eliminación real
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Eliminación próximamente'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
