import 'package:flutter/material.dart';
import '../../../core/models/post.dart';
import '../../../core/models/reaction.dart';

/// Widget para mostrar y manejar las reacciones de un post
///
/// Funcionalidades:
/// - 6 tipos de reacciones (like, love, laugh, wow, sad, angry)
/// - Mostrar breakdown de reacciones
/// - Animaciones al reaccionar
/// - Estado visual del tipo de reacción del usuario
class ReactionsWidget extends StatelessWidget {
  final Post post;
  final Function(ReactionType) onReaction;

  const ReactionsWidget({
    super.key,
    required this.post,
    required this.onReaction,
  });

  @override
  Widget build(BuildContext context) {
    print('🔍 ReactionsWidget - Post ${post.id}:');
    print('  - reactionsCount: ${post.reactionsCount}');
    print('  - reactionsBreakdown.isEmpty: ${post.reactionsBreakdown.isEmpty}');
    print('  - reactionsBreakdown: ${post.reactionsBreakdown}');

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breakdown de reacciones solo si hay reacciones
          if (post.reactionsBreakdown.isNotEmpty &&
              post.reactionsCount > 0) ...[
            _buildReactionsBreakdown(context),
            const SizedBox(height: 16),
          ],

          // Botones de reacciones (que incluyen el contador total)
          _buildReactionButtons(context),
        ],
      ),
    );
  }

  Widget _buildReactionsBreakdown(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: post.reactionsBreakdown.entries.map((entry) {
        final reactionType = ReactionType.fromString(entry.key);
        final count = entry.value;

        // Solo ocultar si count es 0, pero mostrar las que tienen reacciones
        if (count == 0) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(reactionType.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReactionButtons(BuildContext context) {
    return Column(
      children: [
        // Contador total de reacciones
        Row(
          children: [
            Icon(
              Icons.favorite_border,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '${post.reactionsCount} reacciones',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Botones de reacciones con Wrap para evitar overflow
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ReactionType.values.map((reactionType) {
            final isSelected = post.userReaction == reactionType.value;
            final reactionColor = _getReactionColor(reactionType);

            return InkWell(
              onTap: () => onReaction(reactionType),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? reactionColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? Border.all(color: reactionColor, width: 1)
                      : null,
                ),
                child: Text(
                  reactionType.emoji,
                  style: TextStyle(
                    fontSize: 20,
                    color: isSelected ? reactionColor : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Obtener color para cada tipo de reacción
  Color _getReactionColor(ReactionType reactionType) {
    switch (reactionType) {
      case ReactionType.like:
        return const Color(0xFF3578E5); // Azul Facebook
      case ReactionType.love:
        return const Color(0xFFE74C3C); // Rojo
      case ReactionType.laugh:
        return const Color(0xFFF39C12); // Naranja
      case ReactionType.wow:
        return const Color(0xFFF39C12); // Naranja
      case ReactionType.sad:
        return const Color(0xFFF39C12); // Naranja
      case ReactionType.angry:
        return const Color(0xFFE67E22); // Naranja oscuro
    }
  }
}
