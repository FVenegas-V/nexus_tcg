import 'package:flutter/material.dart';
import '../../../core/models/post.dart';
import '../../../core/models/post_image.dart';

/// Widget card para mostrar un post en el feed
/// Compatible con el nuevo modelo Post del core
class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onBookmark;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onCommunityTap;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onBookmark,
    this.onAuthorTap,
    this.onCommunityTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con autor y comunidad
              _buildPostHeader(context),
              const SizedBox(height: 12),

              // Contenido del post
              _buildPostContent(context),

              // Imágenes si las hay
              if (post.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildPostImages(context),
              ],

              const SizedBox(height: 12),

              // Footer con interacciones
              _buildPostFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context) {
    return Row(
      children: [
        // Avatar del autor
        GestureDetector(
          onTap: onAuthorTap,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              post.authorUsername.isNotEmpty
                  ? post.authorUsername[0].toUpperCase()
                  : 'U',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Información del autor y comunidad
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Autor
              GestureDetector(
                onTap: onAuthorTap,
                child: Row(
                  children: [
                    Text(
                      post.authorUsername,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // TODO: Verificación cuando esté disponible en el modelo
                    // if (post.isVerified) ...[
                    //   const SizedBox(width: 4),
                    //   Icon(
                    //     Icons.verified,
                    //     size: 16,
                    //     color: Theme.of(context).colorScheme.primary,
                    //   ),
                    // ],
                  ],
                ),
              ),

              // Comunidad
              GestureDetector(
                onTap: onCommunityTap,
                child: Text(
                  'en ${post.communityName}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tiempo transcurrido
        Text(
          _formatTime(post.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPostContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título (si existe)
        if (post.title.isNotEmpty) ...[
          Text(
            post.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
        ],

        // Contenido
        Text(post.content, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildPostImages(BuildContext context) {
    if (post.images.isEmpty) return const SizedBox.shrink();

    // Si hay una sola imagen, mostrarla grande
    if (post.images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          post.images.first.getUrlForResolution(ImageResolution.medium),
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 200,
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
      );
    }

    // Si hay múltiples imágenes, mostrar grid
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mostrar las primeras 2-3 imágenes en grid
        SizedBox(
          height: 200,
          child: Row(
            children: [
              // Primera imagen (más grande)
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    post.images.first.getUrlForResolution(
                      ImageResolution.medium,
                    ),
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              if (post.images.length > 1) ...[
                const SizedBox(width: 4),
                // Segunda columna con imágenes más pequeñas
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            post.images[1].getUrlForResolution(
                              ImageResolution.thumbnail,
                            ),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      if (post.images.length > 2) ...[
                        const SizedBox(height: 4),
                        Expanded(
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  post.images[2].getUrlForResolution(
                                    ImageResolution.thumbnail,
                                  ),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),

                              // Overlay con número de imágenes adicionales
                              if (post.images.length > 3)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.black54,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '+${post.images.length - 3}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 8),
        Text(
          '${post.images.length} imagen${post.images.length != 1 ? 'es' : ''}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPostFooter(BuildContext context) {
    return Row(
      children: [
        // Botón de reacción (like por ahora)
        _InteractionButton(
          icon: _hasUserReacted() ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(post.reactionsCount),
          isActive: _hasUserReacted(),
          onTap: onLike,
        ),

        const SizedBox(width: 16),

        // Botón de comentarios
        _InteractionButton(
          icon: Icons.chat_bubble_outline,
          label: _formatCount(post.commentsCount),
          onTap: onComment,
        ),

        const Spacer(),

        // Botón de compartir
        IconButton(
          onPressed: onShare,
          icon: const Icon(Icons.share_outlined),
          iconSize: 20,
        ),

        // Botón de bookmark (deshabilitado por ahora)
        IconButton(
          onPressed: null, // TODO: Implementar cuando esté en el backend
          icon: const Icon(Icons.bookmark_border),
          iconSize: 20,
        ),
      ],
    );
  }

  // Métodos de utilidad

  bool _hasUserReacted() {
    return post.userReaction != null;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'ahora';
    }
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

/// Widget para botones de interacción (like, comment, etc.)
class _InteractionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _InteractionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
