import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar estados vacíos
/// con ilustración, título, descripción y acción opcional
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionText;
  final VoidCallback? onActionPressed;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionText,
    this.onActionPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono principal
            Icon(
              icon,
              size: 64,
              color: iconColor ?? theme.colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 16),

            // Título
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Descripción
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            // Botón de acción opcional
            if (actionText != null && onActionPressed != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add),
                label: Text(actionText!),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Estados predefinidos comunes
class EmptyStates {
  static EmptyStateWidget noPosts({VoidCallback? onCreatePost}) {
    return EmptyStateWidget(
      icon: Icons.article_outlined,
      title: 'No hay posts',
      description: 'Sé el primero en compartir algo con la comunidad',
      actionText: onCreatePost != null ? 'Crear post' : null,
      onActionPressed: onCreatePost,
    );
  }

  static EmptyStateWidget noComments({VoidCallback? onAddComment}) {
    return EmptyStateWidget(
      icon: Icons.comment_outlined,
      title: 'No hay comentarios',
      description: 'Inicia la conversación siendo el primero en comentar',
      actionText: onAddComment != null ? 'Comentar' : null,
      onActionPressed: onAddComment,
    );
  }

  static EmptyStateWidget noCommunities({VoidCallback? onJoinCommunity}) {
    return EmptyStateWidget(
      icon: Icons.groups_outlined,
      title: 'No perteneces a comunidades',
      description: 'Únete a comunidades para ver posts y participar',
      actionText: onJoinCommunity != null ? 'Explorar comunidades' : null,
      onActionPressed: onJoinCommunity,
    );
  }

  static EmptyStateWidget searchNoResults(String query) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'Sin resultados',
      description:
          'No encontramos resultados para "$query".\nIntenta con otros términos.',
    );
  }

  static EmptyStateWidget error({String? message, VoidCallback? onRetry}) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: 'Algo salió mal',
      description: message ?? 'Hubo un problema al cargar el contenido',
      actionText: onRetry != null ? 'Reintentar' : null,
      onActionPressed: onRetry,
      iconColor: Colors.red,
    );
  }
}
