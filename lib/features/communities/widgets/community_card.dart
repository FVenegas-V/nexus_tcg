import 'package:flutter/material.dart';
import '../models/community.dart';

/// Widget card para mostrar información de una comunidad
/// Incluye imagen, nombre, descripción, miembros y botón de suscripción
class CommunityCard extends StatelessWidget {
  final Community community;
  final VoidCallback? onTap;
  final VoidCallback? onSubscriptionToggle;

  const CommunityCard({
    super.key,
    required this.community,
    this.onTap,
    this.onSubscriptionToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen de la comunidad con Hero para animación
            Hero(
              tag: 'community-image-${community.id}',
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child:
                    community.imageUrl != null && community.imageUrl!.isNotEmpty
                    ? Image.network(
                        community.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage(context);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : _buildPlaceholderImage(context),
              ),
            ),

            // Contenido del card
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con nombre y suscripción
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nombre de la comunidad
                            Hero(
                              tag: 'community-name-${community.id}',
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  community.name,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Tipo de juego
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                community.gameType,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Botón de suscripción
                      _buildSubscriptionButton(context),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Descripción
                  Text(
                    community.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Footer con información adicional
                  Row(
                    children: [
                      // Número de miembros
                      Icon(
                        Icons.people_outline,
                        size: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatMemberCount(community.memberCount),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Nivel de dificultad
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getDifficultyColor(
                            context,
                            community.difficultyLevel,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      // Indicador de suscripción
                      if (community.isSubscribed)
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye imagen placeholder cuando no hay imagen disponible
  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              community.gameType,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el botón de suscripción
  Widget _buildSubscriptionButton(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onSubscriptionToggle,
      style: FilledButton.styleFrom(
        backgroundColor: community.isSubscribed
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: community.isSubscribed
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(community.isSubscribed ? Icons.check : Icons.add, size: 16),
          const SizedBox(width: 4),
          Text(
            community.isSubscribed ? 'Suscrito' : 'Unirse',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Formatea el número de miembros para mostrar
  String _formatMemberCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k miembros';
    }
    return '$count miembros';
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
