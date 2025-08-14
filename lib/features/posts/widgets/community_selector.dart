import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../communities/models/community.dart';
import '../../communities/providers/communities_provider.dart';

/// Widget selector de comunidad para crear posts
/// Permite seleccionar en qué comunidad publicar el post
class CommunitySelector extends StatelessWidget {
  final Community? selectedCommunity;
  final ValueChanged<Community?> onCommunityChanged;
  final String? errorText;

  const CommunitySelector({
    super.key,
    required this.selectedCommunity,
    required this.onCommunityChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comunidad',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        Consumer<CommunitiesProvider>(
          builder: (context, provider, child) {
            // Filtrar solo comunidades suscritas para publicar
            final subscribedCommunities = provider.subscribedCommunities;

            if (subscribedCommunities.isEmpty) {
              return _buildEmptyState(context);
            }

            return _buildDropdown(context, subscribedCommunities);
          },
        ),

        // Mostrar error si existe
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }

  /// Construye el dropdown con las comunidades
  Widget _buildDropdown(BuildContext context, List<Community> communities) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: errorText != null
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Community>(
          value: selectedCommunity,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.group,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Text(
                  'Selecciona una comunidad',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          isExpanded: true,
          icon: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          items: communities.map((Community community) {
            return DropdownMenuItem<Community>(
              value: community,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Icono de la comunidad
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getColorForGameType(community.gameType),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _getIconForGameType(community.gameType),
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Información de la comunidad
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            community.name,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${community.memberCount} miembros',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: onCommunityChanged,
        ),
      ),
    );
  }

  /// Construye el estado cuando no hay comunidades suscritas
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.group_off,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No tienes comunidades',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Únete a una comunidad para poder crear posts',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Obtiene el color para el tipo de juego
  Color _getColorForGameType(String gameType) {
    switch (gameType.toLowerCase()) {
      case 'magic: the gathering':
        return const Color(0xFF1E88E5); // Azul MTG
      case 'pokémon tcg':
        return const Color(0xFFFFD700); // Amarillo Pokémon
      case 'yu-gi-oh!':
        return const Color(0xFF9C27B0); // Púrpura Yu-Gi-Oh
      case 'digimon':
        return const Color(0xFF4CAF50); // Verde Digimon
      case 'dragon ball super':
        return const Color(0xFFFF9800); // Naranja Dragon Ball
      default:
        return const Color(0xFF6C757D); // Gris por defecto
    }
  }

  /// Obtiene el icono para el tipo de juego
  IconData _getIconForGameType(String gameType) {
    switch (gameType.toLowerCase()) {
      case 'magic: the gathering':
        return Icons.auto_fix_high;
      case 'pokémon tcg':
        return Icons.catching_pokemon;
      case 'yu-gi-oh!':
        return Icons.style;
      case 'digimon':
        return Icons.pets;
      case 'dragon ball super':
        return Icons.flash_on;
      default:
        return Icons.casino;
    }
  }
}
