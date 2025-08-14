import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../models/community.dart';
import '../providers/communities_provider.dart';

/// Pantalla de detalle de una comunidad específica
/// Muestra información completa, posts y permite suscribirse
class CommunityDetailScreen extends StatelessWidget {
  final int communityId;

  const CommunityDetailScreen({super.key, required this.communityId});

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunitiesProvider>(
      builder: (context, provider, child) {
        final community = provider.getCommunityById(communityId);

        if (community == null) {
          return _buildNotFoundScreen(context);
        }

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
            ],
          ),

          // Botón flotante de suscripción
          floatingActionButton: _buildSubscriptionFAB(
            context,
            community,
            provider,
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
          Row(
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
              const SizedBox(width: 12),
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
          _buildStatItem(
            context,
            icon: Icons.people,
            label: 'Miembros',
            value: _formatMemberCount(community.memberCount),
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
            value:
                '${(community.memberCount * 0.15).round()}', // Mock calculation
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

  /// Construye la sección de posts (mock)
  Widget _buildPostsSection(BuildContext context, Community community) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Posts recientes',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // TODO: Navegar a todos los posts
                },
                child: const Text('Ver todos'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Posts mock
          ..._buildMockPosts(context),
        ],
      ),
    );
  }

  /// Construye posts mock para la vista previa
  List<Widget> _buildMockPosts(BuildContext context) {
    return [
      _buildMockPost(
        context,
        author: 'CardMaster_99',
        content:
            '¿Alguien sabe si el nuevo set está ya disponible en las tiendas locales?',
        timeAgo: '2h',
        likes: 15,
      ),
      const SizedBox(height: 12),
      _buildMockPost(
        context,
        author: 'ProPlayer_TCG',
        content:
            'Acabo de armar mi nuevo mazo competitivo. ¡Los resultados han sido increíbles!',
        timeAgo: '5h',
        likes: 28,
      ),
      const SizedBox(height: 12),
      _buildMockPost(
        context,
        author: 'CollectorLife',
        content:
            'Intercambio cartas raras. Tengo duplicados de la edición especial.',
        timeAgo: '1d',
        likes: 7,
      ),
    ];
  }

  /// Construye un post mock individual
  Widget _buildMockPost(
    BuildContext context, {
    required String author,
    required String content,
    required String timeAgo,
    required int likes,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  author[0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.favorite_border,
                size: 18,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                likes.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.comment_outlined,
                size: 18,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 4),
              Text(
                '${(likes * 0.3).round()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye el botón flotante de suscripción
  Widget _buildSubscriptionFAB(
    BuildContext context,
    Community community,
    CommunitiesProvider provider,
  ) {
    return FloatingActionButton.extended(
      onPressed: () {
        provider.toggleSubscription(community.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              community.isSubscribed
                  ? 'Te has desuscrito de ${community.name}'
                  : 'Te has suscrito a ${community.name}',
            ),
          ),
        );
      },
      icon: Icon(community.isSubscribed ? Icons.check : Icons.add),
      label: Text(community.isSubscribed ? 'Suscrito' : 'Unirse'),
      backgroundColor: community.isSubscribed
          ? Theme.of(context).colorScheme.secondary
          : Theme.of(context).colorScheme.primary,
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
}
