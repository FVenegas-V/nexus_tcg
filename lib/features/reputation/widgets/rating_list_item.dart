import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../models/user_rating.dart';
import '../widgets/rating_stars.dart';

/// Widget para mostrar un rating individual en una lista
///
/// Características:
/// - Información completa del rating
/// - Avatar del usuario
/// - Estrellas interactivas de solo lectura
/// - Comentarios expandibles
/// - Acciones contextuales
/// - Diseño responsive
class RatingListItem extends StatefulWidget {
  /// Rating a mostrar
  final UserRating rating;

  /// Si se debe mostrar el avatar del usuario
  final bool showAvatar;

  /// Si se debe mostrar el comentario completo por defecto
  final bool expandComment;

  /// Callback cuando se toca el item
  final VoidCallback? onTap;

  /// Callback para reportar el rating
  final VoidCallback? onReport;

  /// Callback para responder al rating
  final VoidCallback? onReply;

  /// Si el rating es del usuario actual (para mostrar opciones de edición)
  final bool isOwnRating;

  /// Callback para editar el rating propio
  final VoidCallback? onEdit;

  /// Callback para eliminar el rating propio
  final VoidCallback? onDelete;

  const RatingListItem({
    super.key,
    required this.rating,
    this.showAvatar = true,
    this.expandComment = false,
    this.onTap,
    this.onReport,
    this.onReply,
    this.isOwnRating = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<RatingListItem> createState() => _RatingListItemState();
}

class _RatingListItemState extends State<RatingListItem> {
  bool _isCommentExpanded = false;

  @override
  void initState() {
    super.initState();
    _isCommentExpanded = widget.expandComment;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 12),
              _buildRatingStars(theme),
              if (widget.rating.comment?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                _buildComment(theme),
              ],
              const SizedBox(height: 8),
              _buildFooter(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        if (widget.showAvatar) ...[
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primaryContainer,
            backgroundImage: widget.rating.raterAvatarUrl != null
                ? NetworkImage(widget.rating.raterAvatarUrl!)
                : null,
            child: widget.rating.raterAvatarUrl == null
                ? Text(
                    widget.rating.raterUsername.isNotEmpty
                        ? widget.rating.raterUsername[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AutoSizeText(
                      widget.rating.raterUsername,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isOwnRating)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Mi Valoración',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _formatDate(widget.rating.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _buildActionsButton(theme),
      ],
    );
  }

  Widget _buildRatingStars(ThemeData theme) {
    return Row(
      children: [
        RatingStars(
          rating: widget.rating.rating.toDouble(),
          starSize: 20,
          isInteractive: false,
          showRatingValue: false,
        ),
        const SizedBox(width: 8),
        Text(
          '${widget.rating.rating}/5',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        const Spacer(),
        if (!widget.rating.isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              border: Border.all(color: Colors.red, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, size: 12, color: Colors.red),
                const SizedBox(width: 2),
                Text(
                  'Inactivo',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (widget.rating.isUnderModeration)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              border: Border.all(color: Colors.orange, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pending, size: 12, color: Colors.orange),
                const SizedBox(width: 2),
                Text(
                  'En Revisión',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildComment(ThemeData theme) {
    if (widget.rating.comment == null || widget.rating.comment!.isEmpty) {
      return const SizedBox.shrink();
    }

    final comment = widget.rating.comment!;
    final shouldShowToggle = comment.length > 150;
    final displayText = _isCommentExpanded || !shouldShowToggle
        ? comment
        : '${comment.substring(0, 150)}...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSizeText(
          displayText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          maxLines: _isCommentExpanded ? null : 3,
        ),
        if (shouldShowToggle) ...[
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              setState(() {
                _isCommentExpanded = !_isCommentExpanded;
              });
            },
            child: Text(
              _isCommentExpanded ? 'Ver menos' : 'Ver más',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Row(
      children: [
        // Información del tipo de interacción
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getInteractionTypeLabel(widget.rating.interactionType),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Spacer(),
        _buildActionButtons(theme),
      ],
    );
  }

  Widget _buildActionsButton(ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: theme.colorScheme.onSurfaceVariant,
        size: 20,
      ),
      padding: EdgeInsets.zero,
      iconSize: 20,
      onSelected: (value) {
        switch (value) {
          case 'edit':
            widget.onEdit?.call();
            break;
          case 'delete':
            widget.onDelete?.call();
            break;
          case 'report':
            widget.onReport?.call();
            break;
          case 'reply':
            widget.onReply?.call();
            break;
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        if (widget.isOwnRating) {
          items.addAll([
            PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 18),
                  const SizedBox(width: 8),
                  const Text('Editar'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ]);
        } else {
          items.addAll([
            PopupMenuItem<String>(
              value: 'reply',
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 18),
                  const SizedBox(width: 8),
                  const Text('Responder'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'report',
              child: Row(
                children: [
                  const Icon(Icons.flag, size: 18),
                  const SizedBox(width: 8),
                  const Text('Reportar'),
                ],
              ),
            ),
          ]);
        }

        return items;
      },
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.isOwnRating && widget.onReply != null)
          TextButton.icon(
            onPressed: widget.onReply,
            icon: const Icon(Icons.reply, size: 16),
            label: const Text('Responder'),
            style: TextButton.styleFrom(
              textStyle: theme.textTheme.labelSmall,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
      ],
    );
  }

  String _getInteractionTypeLabel(String interactionType) {
    switch (interactionType) {
      case 'trade':
        return 'Intercambio';
      case 'game':
        return 'Partida';
      case 'community':
        return 'Comunidad';
      case 'general':
        return 'General';
      default:
        return 'Otro';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'hace un momento';
    }
  }
}

/// Widget simplificado para mostrar ratings en listas compactas
class CompactRatingItem extends StatelessWidget {
  final UserRating rating;
  final VoidCallback? onTap;

  const CompactRatingItem({super.key, required this.rating, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: theme.colorScheme.primaryContainer,
        backgroundImage: rating.raterAvatarUrl != null
            ? NetworkImage(rating.raterAvatarUrl!)
            : null,
        child: rating.raterAvatarUrl == null
            ? Text(
                rating.raterUsername.isNotEmpty
                    ? rating.raterUsername[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              rating.raterUsername,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          RatingStars(
            rating: rating.rating.toDouble(),
            starSize: 14,
            isInteractive: false,
            showRatingValue: false,
          ),
        ],
      ),
      subtitle: rating.comment?.isNotEmpty == true
          ? Text(
              rating.comment!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${rating.rating}/5',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            _formatCompactDate(rating.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatCompactDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}m';
    }
  }
}

/// Widget para mostrar estadísticas rápidas de ratings
class RatingQuickStats extends StatelessWidget {
  final List<UserRating> ratings;
  final VoidCallback? onTapViewAll;

  const RatingQuickStats({super.key, required this.ratings, this.onTapViewAll});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (ratings.isEmpty) {
      return const SizedBox.shrink();
    }

    final averageRating =
        ratings.fold(0.0, (sum, rating) => sum + rating.rating) /
        ratings.length;
    final distribution = _calculateDistribution();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Valoraciones',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (onTapViewAll != null)
                  TextButton(
                    onPressed: onTapViewAll,
                    child: const Text('Ver todas'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            averageRating.toStringAsFixed(1),
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          RatingStars(
                            rating: averageRating,
                            starSize: 20,
                            isInteractive: false,
                            showRatingValue: false,
                          ),
                        ],
                      ),
                      Text(
                        '${ratings.length} valoracion${ratings.length != 1 ? 'es' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: distribution.entries.map((entry) {
                      final stars = entry.key;
                      final count = entry.value;
                      final percentage = count / ratings.length;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text('$stars', style: theme.textTheme.labelSmall),
                            const SizedBox(width: 4),
                            const Icon(Icons.star, size: 12),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: percentage,
                                backgroundColor:
                                    theme.colorScheme.surfaceVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              count.toString(),
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Map<int, int> _calculateDistribution() {
    final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (final rating in ratings) {
      distribution[rating.rating] = (distribution[rating.rating] ?? 0) + 1;
    }

    return distribution;
  }
}
