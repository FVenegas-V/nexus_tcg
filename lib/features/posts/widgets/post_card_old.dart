import 'package:flutter/material.dart';
import '../../../core/models/post.dart';

/// Widget card para mostrar un post en el feed
/// Incluye autor, contenido, comunidad, fecha y botones de interacción
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
              if (post.imageUrls.isNotEmpty) ...[
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
            backgroundImage: post.author.avatarUrl != null
                ? NetworkImage(post.author.avatarUrl!)
                : null,
            child: post.author.avatarUrl == null
                ? Text(
                    post.author.username[0].toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(width: 12),

        // Información del autor y comunidad
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre del autor con verificación
              Row(
                children: [
                  GestureDetector(
                    onTap: onAuthorTap,
                    child: Text(
                      post.author.username,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (post.author.isVerified) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ],
              ),

              // Comunidad y fecha
              Row(
                children: [
                  GestureDetector(
                    onTap: onCommunityTap,
                    child: Text(
                      post.community.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    ' • ${_formatTimestamp(post.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Menú de opciones
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showPostOptions(context),
          iconSize: 20,
        ),
      ],
    );
  }

  Widget _buildPostContent(BuildContext context) {
    return Text(
      post.content,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
    );
  }

  Widget _buildPostImages(BuildContext context) {
    if (post.imageUrls.isEmpty) return const SizedBox.shrink();

    // Por ahora solo mostramos placeholder para imágenes
    // En implementación real aquí iría el widget de imágenes
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              '${post.imageUrls.length} imagen${post.imageUrls.length != 1 ? 'es' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostFooter(BuildContext context) {
    return Row(
      children: [
        // Botón de like
        _buildInteractionButton(
          context: context,
          icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(post.likesCount),
          isActive: post.isLiked,
          onPressed: onLike,
        ),

        const SizedBox(width: 24),

        // Botón de comentarios
        _buildInteractionButton(
          context: context,
          icon: Icons.chat_bubble_outline,
          label: _formatCount(post.commentsCount),
          isActive: false,
          onPressed: onComment,
        ),

        const SizedBox(width: 24),

        // Botón de compartir
        _buildInteractionButton(
          context: context,
          icon: Icons.share_outlined,
          label: 'Compartir',
          isActive: false,
          onPressed: onShare,
        ),

        const Spacer(),

        // Botón de bookmark
        IconButton(
          icon: Icon(
            post.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: post.isBookmarked
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          onPressed: onBookmark,
          iconSize: 20,
        ),
      ],
    );
  }

  Widget _buildInteractionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onPressed,
  }) {
    final color = isActive
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'ahora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatCount(int count) {
    if (count < 1000) {
      return count.toString();
    } else if (count < 1000000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    } else {
      return '${(count / 1000000).toStringAsFixed(1)}m';
    }
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: Text(
                post.isBookmarked ? 'Quitar de guardados' : 'Guardar post',
              ),
              onTap: () {
                Navigator.pop(context);
                onBookmark?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Compartir'),
              onTap: () {
                Navigator.pop(context);
                onShare?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text('Reportar'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implementar reportar
              },
            ),
          ],
        ),
      ),
    );
  }
}
