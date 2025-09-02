import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/community.dart';
import '../../../core/models/post.dart';
import '../../../core/services/communities_service.dart';
import '../../../core/services/posts_service.dart';
import '../providers/communities_provider_new.dart';
import '../../posts/providers/posts_provider.dart';
import '../../posts/widgets/post_card.dart';
import '../../posts/screens/create_post_screen.dart';
import 'community_posts_screen.dart';

/// Pantalla de detalle de una comunidad específica
/// Muestra información completa, posts y permite suscribirse
class CommunityDetailScreen extends StatefulWidget {
  final int communityId;

  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  Community? _communityDetail;
  bool _isLoadingDetail = true;
  String? _errorMessage;
  final CommunitiesService _communitiesService = CommunitiesService();

  // Variables para manejar posts de la comunidad
  List<Post> _communityPosts = [];
  bool _isLoadingPosts = true;
  final PostsService _postsService = PostsService();

  @override
  void initState() {
    super.initState();
    _loadCommunityDetail();
    _loadCommunityPosts();
  }

  /// Cargar el detalle completo de la comunidad
  Future<void> _loadCommunityDetail() async {
    try {
      setState(() {
        _isLoadingDetail = true;
        _errorMessage = null;
      });

      final communityDetail = await _communitiesService.getCommunity(
        widget.communityId,
      );

      // Debug: verificar qué postCount está llegando
      print('🏘️ Community detail loaded: ${communityDetail.name}');
      print('🏘️ PostCount from backend: ${communityDetail.postCount}');
      print('🏘️ IsSubscribed from backend: ${communityDetail.isSubscribed}');

      if (mounted) {
        setState(() {
          _communityDetail = communityDetail;
          _isLoadingDetail = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingDetail = false;
        });
      }
    }
  }

  /// Actualizar silenciosamente el detalle de la comunidad sin mostrar loading
  Future<void> _refreshCommunityDetail() async {
    try {
      final communityDetail = await _communitiesService.getCommunity(
        widget.communityId,
      );

      print('🔄 Community detail refreshed silently: ${communityDetail.name}');
      print('🔄 IsSubscribed after refresh: ${communityDetail.isSubscribed}');

      if (mounted) {
        setState(() {
          _communityDetail = communityDetail;
        });
      }
    } catch (e) {
      print('❌ Error refreshing community detail: $e');
      // No mostramos error UI para no interrumpir la experiencia
    }
  }

  /// Cargar los posts específicos de esta comunidad
  Future<void> _loadCommunityPosts() async {
    try {
      setState(() {
        _isLoadingPosts = true;
      });

      final posts = await _postsService.getPosts(
        communityId: widget.communityId,
        ordering: '-created_at', // Más recientes primero
        pageSize: 50, // Aumentar para mostrar más posts
      );

      // Debug: verificar cuántos posts se cargaron
      print(
        '📝 Posts loaded for community ${widget.communityId}: ${posts.length}',
      );

      // Debug crítico: mostrar cada post y su comunidad
      for (int i = 0; i < posts.length && i < 5; i++) {
        final post = posts[i];
        print(
          '🔍 Post $i: "${post.title}" - Community: ${post.communityName} (ID: ${post.communityId})',
        );
      }

      if (mounted) {
        setState(() {
          _communityPosts = posts;
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      print('❌ Error loading community posts: $e');
      if (mounted) {
        setState(() {
          _communityPosts = [];
          _isLoadingPosts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si está cargando el detalle, mostrar loading
    if (_isLoadingDetail) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Si hubo error cargando el detalle
    if (_errorMessage != null) {
      return _buildErrorScreen(context);
    }

    // Si no hay detalle, usar datos del provider como fallback
    final community =
        _communityDetail ??
        context.read<CommunitiesProvider>().getCommunityById(
          widget.communityId,
        );

    if (community == null) {
      return _buildNotFoundScreen(context);
    }

    return Consumer<CommunitiesProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // AppBar expandible con imagen
              _buildSliverAppBar(context, community, provider),

              // Contenido principal
              SliverToBoxAdapter(
                child: Hero(
                  tag:
                      'community-card-${community.id}', // Mismo tag que en la lista
                  child: Material(
                    color: Colors.transparent,
                    child: SingleChildScrollView(
                      physics:
                          const NeverScrollableScrollPhysics(), // Evita doble scroll
                      child: Padding(
                        padding: const EdgeInsets.only(
                          bottom: 100,
                        ), // Espacio para FABs
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Información de la comunidad
                            _buildCommunityInfo(context, community),

                            // Estadísticas
                            _buildCommunityStats(context, community),

                            // Tags de la comunidad
                            _buildCommunityTags(context, community),

                            // Sección de posts (mock)
                            _buildPostsSection(context, community),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Botones flotantes: suscripción y crear post
          floatingActionButton: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón para crear post (solo si está suscrito)
                if (community.isSubscribed) ...[
                  FloatingActionButton(
                    heroTag: "create_post_fab",
                    onPressed: () async {
                      // Navegar a crear post y esperar resultado
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreatePostScreen(
                            preselectedCommunityId: community.id,
                          ),
                        ),
                      );

                      // Si se creó un post exitosamente, recargar
                      if (result == true) {
                        await _loadCommunityPosts();
                        await _refreshCommunityDetail();
                      }
                    },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 12),
                ],
                // Botón de suscripción
                _buildSubscriptionFAB(context, community, provider),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Construye la pantalla de "no encontrado"
  Widget _buildNotFoundScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comunidad no encontrada')),
      body: Center(
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
              Text(
                'Comunidad no encontrada',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'La comunidad que buscas no existe o ha sido eliminada.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la pantalla de error
  Widget _buildErrorScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
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
                'Error al cargar comunidad',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Error desconocido',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadCommunityDetail,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye el SliverAppBar con imagen de la comunidad
  Widget _buildSliverAppBar(
    BuildContext context,
    Community community,
    CommunitiesProvider provider,
  ) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Hero(
          tag: 'community-name-${community.id}',
          child: Material(
            color: Colors.transparent,
            child: Text(
              community.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
          ),
        ),
        background: Hero(
          tag: 'community-image-${community.id}',
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
            child: community.imageUrl != null && community.imageUrl!.isNotEmpty
                ? Image.network(
                    community.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderBackground(context, community);
                    },
                  )
                : _buildPlaceholderBackground(context, community),
          ),
        ),
      ),
      actions: [
        // Botón de compartir
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            // TODO: Implementar compartir comunidad
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Función de compartir próximamente'),
              ),
            );
          },
        ),
        // Botón de favoritos
        IconButton(
          icon: Icon(
            community.isSubscribed ? Icons.favorite : Icons.favorite_border,
            color: community.isSubscribed ? Colors.red : null,
          ),
          onPressed: () {
            provider.toggleSubscription(community.id);
          },
        ),
      ],
    );
  }

  /// Construye el fondo placeholder para la imagen
  Widget _buildPlaceholderBackground(
    BuildContext context,
    Community community,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              community.gameType,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la información principal de la comunidad
  Widget _buildCommunityInfo(BuildContext context, Community community) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipo de juego y dificultad
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  community.gameType,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(
                    context,
                    community.difficultyLevel,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getDifficultyColor(
                      context,
                      community.difficultyLevel,
                    ),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getDifficultyIcon(community.difficultyLevel),
                      size: 16,
                      color: _getDifficultyColor(
                        context,
                        community.difficultyLevel,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      community.difficultyLevel,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getDifficultyColor(
                          context,
                          community.difficultyLevel,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Descripción
          Text(
            'Descripción',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            community.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  /// Construye las estadísticas de la comunidad
  Widget _buildCommunityStats(BuildContext context, Community community) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () => _showMembersList(context, community),
            child: _buildStatItem(
              context,
              icon: Icons.people,
              label: 'Miembros',
              value: _formatMemberCount(community.memberCount),
            ),
          ),
          _buildStatItem(
            context,
            icon: Icons.calendar_today,
            label: 'Creada',
            value: _formatDate(community.createdAt),
          ),
          _buildStatItem(
            context,
            icon: Icons.article,
            label: 'Posts',
            value: '${community.postCount}', // Usar valor real del backend
          ),
        ],
      ),
    );
  }

  /// Construye un item de estadística individual
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  /// Construye los tags de la comunidad
  Widget _buildCommunityTags(BuildContext context, Community community) {
    if (community.tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temas populares',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: community.tags
                .map(
                  (tag) => Chip(
                    label: Text(tag),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  /// Construye la sección de posts reales de la comunidad
  Widget _buildPostsSection(BuildContext context, Community community) {
    return Consumer<PostsProvider>(
      builder: (context, postsProvider, child) {
        // Usar los posts cargados específicamente para esta comunidad
        final postsToShow = _communityPosts.length > 6
            ? _communityPosts.take(6).toList()
            : _communityPosts;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Posts recientes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Mostrar contador de posts real del backend
                  Text(
                    '${community.postCount} posts',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommunityPostsScreen(
                            communityId: widget.communityId,
                            communityName: community.name,
                          ),
                        ),
                      );
                    },
                    child: const Text('Ver todos'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mostrar loading si se están cargando los posts
              if (_isLoadingPosts)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              // Posts reales o mensaje si no hay
              else if (postsToShow.isEmpty)
                _buildNoPosts(context)
              else
                ...postsToShow
                    .map(
                      (post) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PostCard(
                          post: post,
                          onTap: () {
                            final targetRoute =
                                '/post/${post.id}?from=community&communityId=${community.id}';
                            print(
                              '🏘️ Navegando desde comunidad: $targetRoute',
                            );
                            context.push(targetRoute);
                          },
                          onLike: () => postsProvider.toggleLike(post.id),
                          onComment: () {
                            final targetRoute =
                                '/post/${post.id}?from=community&communityId=${community.id}';
                            print(
                              '🏘️ Navegando desde comunidad (comment): $targetRoute',
                            );
                            context.push(targetRoute);
                          },
                          onShare: () => _showShareSnackbar(context),
                          onBookmark: () =>
                              postsProvider.toggleBookmark(post.id),
                          onAuthorTap: () {
                            // Navegar a perfil público del autor
                            context.go(
                              '/reputation/user/${post.authorId}?username=${post.authorUsername}',
                            );
                          },
                          onCommunityTap: () {
                            /* Ya estamos en la comunidad */
                          },
                        ),
                      ),
                    )
                    .toList(),
            ],
          ),
        );
      },
    );
  }

  /// Widget cuando no hay posts en la comunidad
  Widget _buildNoPosts(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.post_add_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay posts aún',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Sé el primero en compartir algo en esta comunidad',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Muestra un snackbar para compartir
  void _showShareSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Post compartido!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Construye el botón flotante de suscripción
  Widget _buildSubscriptionFAB(
    BuildContext context,
    Community community,
    CommunitiesProvider provider,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: FloatingActionButton.extended(
        heroTag: "community_subscription_fab",
        backgroundColor: provider.isJoinLeaveLoading(community.id)
            ? Theme.of(context).colorScheme.surfaceVariant
            : (community.isSubscribed
                  ? Theme.of(context).colorScheme.secondary
                  : Theme.of(context).colorScheme.primary),
        onPressed: provider.isJoinLeaveLoading(community.id)
            ? null
            : () async {
                final wasSubscribed = community.isSubscribed;

                // Mostrar feedback inmediato optimista
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        wasSubscribed
                            ? 'Saliendo de ${community.name}...'
                            : 'Uniéndose a ${community.name}...',
                      ),
                      backgroundColor: Colors.blue,
                      duration: const Duration(milliseconds: 1500),
                    ),
                  );
                }

                try {
                  // Operación principal de suscripción
                  await provider.toggleSubscription(community.id);

                  // Actualizar UI inmediatamente después del toggle exitoso
                  if (context.mounted) {
                    // Actualizar silenciosamente el detalle de la comunidad
                    _refreshCommunityDetail();

                    // Mostrar mensaje de éxito
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          wasSubscribed
                              ? 'Has salido de ${community.name}'
                              : 'Te has unido a ${community.name}',
                        ),
                        backgroundColor: wasSubscribed
                            ? Colors.orange
                            : Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );

                    // Actualizar feed en background sin bloquear UI
                    _updateFeedInBackground();
                  }
                } catch (e) {
                  // Manejar errores
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: provider.isJoinLeaveLoading(community.id)
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  community.isSubscribed
                      ? Icons.check_circle
                      : Icons.add_circle,
                  key: ValueKey(
                    community.isSubscribed ? 'subscribed' : 'unsubscribed',
                  ),
                ),
        ),
        label: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            provider.isJoinLeaveLoading(community.id)
                ? 'Procesando...'
                : (community.isSubscribed ? 'Unido' : 'Unirse'),
            key: ValueKey(
              provider.isJoinLeaveLoading(community.id)
                  ? 'loading'
                  : (community.isSubscribed ? 'subscribed' : 'unsubscribed'),
            ),
          ),
        ),
      ),
    );
  }

  /// Formatea el número de miembros
  String _formatMemberCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }

  /// Formatea la fecha de creación
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} años';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} meses';
    } else {
      return '${difference.inDays} días';
    }
  }

  /// Obtiene el ícono según el nivel de dificultad
  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'principiante':
        return Icons.star_outline;
      case 'intermedio':
        return Icons.star_half;
      case 'avanzado':
        return Icons.star;
      default:
        return Icons.help_outline;
    }
  }

  /// Obtiene el color según el nivel de dificultad
  Color _getDifficultyColor(BuildContext context, String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'principiante':
        return Colors.green;
      case 'intermedio':
        return Colors.orange;
      case 'avanzado':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }

  /// Muestra el modal con la lista de miembros de la comunidad
  void _showMembersList(BuildContext context, Community community) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de arrastre
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Título
                  Text(
                    'Miembros de ${community.name}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${community.memberCount} miembros',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Lista de miembros (placeholder por ahora)
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: 10, // Placeholder - en futuro será dinámico
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            child: Text(
                              'M${index + 1}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text('Miembro ${index + 1}'),
                          subtitle: Text('Unido hace ${index + 1} días'),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                          onTap: () {
                            // TODO: Navegar al perfil del miembro
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Perfil de Miembro ${index + 1}'),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Actualizar el feed en background sin bloquear la UI
  Future<void> _updateFeedInBackground() async {
    // Ejecutar en el siguiente frame para no bloquear la UI actual
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final postsProvider = context.read<PostsProvider>();
        debugPrint('🔄 Actualizando feed en background...');
        await postsProvider.refreshPosts();
        debugPrint('✅ Feed actualizado exitosamente en background');
      } catch (e) {
        debugPrint('⚠️ Error al actualizar feed en background: $e');
      }
    });
  }
}
