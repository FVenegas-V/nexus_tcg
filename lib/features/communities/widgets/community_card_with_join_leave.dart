import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/community.dart';
import '../providers/communities_provider_new.dart';
import 'join_leave_button.dart';

/// Widget de tarjeta de comunidad con funcionalidad join/leave integrada
class CommunityCardWithJoinLeave extends StatelessWidget {
  final Community community;
  final VoidCallback? onTap;

  const CommunityCardWithJoinLeave({
    super.key,
    required this.community,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getThemeColor(theme, community.gameType);

    return Consumer<CommunitiesProvider>(
      builder: (context, provider, child) {
        return Hero(
          tag: 'community_${community.id}',
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap:
                  onTap ??
                  () {
                    context.push('/community/${community.id}');
                  },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Ícono de la comunidad
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _getGameTypeIcon(community.gameType),
                        color: color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Información de la comunidad
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            community.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            community.gameType,
                            style: TextStyle(
                              fontSize: 14,
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 16,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${community.memberCount} miembros',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              if (community.difficultyLevel.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getDifficultyColor(
                                      community.difficultyLevel,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getDifficultyColor(
                                        community.difficultyLevel,
                                      ),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    community.difficultyLevel.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _getDifficultyColor(
                                        community.difficultyLevel,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Botón de join/leave
                    JoinLeaveButton(
                      isJoined: community.isSubscribed,
                      isLoading: provider.isJoinLeaveLoading(community.id),
                      isCompact: true,
                      onPressed: () async {
                        await provider.toggleSubscription(community.id);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                community.isSubscribed
                                    ? 'Has salido de ${community.name}'
                                    : 'Te has unido a ${community.name}',
                              ),
                              backgroundColor: community.isSubscribed
                                  ? Colors.orange
                                  : Colors.green,
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'Deshacer',
                                onPressed: () {
                                  provider.toggleSubscription(community.id);
                                },
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Obtiene el color del tema basado en el tipo de juego
  Color _getThemeColor(ThemeData theme, String gameType) {
    switch (gameType.toLowerCase()) {
      case 'magic: the gathering':
        return const Color(0xFF8B4513);
      case 'pokémon tcg':
        return const Color(0xFFFFD700);
      case 'yu-gi-oh!':
        return const Color(0xFF4B0082);
      case 'dragon ball super':
        return const Color(0xFFFF4500);
      case 'one piece':
        return const Color(0xFF1E90FF);
      default:
        return theme.colorScheme.primary;
    }
  }

  /// Obtiene el ícono basado en el tipo de juego
  IconData _getGameTypeIcon(String gameType) {
    switch (gameType.toLowerCase()) {
      case 'magic: the gathering':
        return Icons.auto_awesome;
      case 'pokémon tcg':
        return Icons.catching_pokemon;
      case 'yu-gi-oh!':
        return Icons.visibility;
      case 'dragon ball super':
        return Icons.flash_on;
      case 'one piece':
        return Icons.sailing;
      default:
        return Icons.groups;
    }
  }

  /// Obtiene el color basado en el nivel de dificultad
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'principiante':
        return Colors.green;
      case 'intermedio':
        return Colors.orange;
      case 'avanzado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
