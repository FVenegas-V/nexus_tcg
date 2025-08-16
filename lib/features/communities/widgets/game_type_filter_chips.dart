import 'package:flutter/material.dart';
import '../../../core/models/game_type.dart';

/// Widget que muestra chips horizontales de filtros por GameType
/// Permite selección única para filtrar comunidades
class GameTypeFilterChips extends StatelessWidget {
  final List<GameType> gameTypes;
  final String? selectedGameType;
  final Function(String?) onGameTypeSelected;

  const GameTypeFilterChips({
    super.key,
    required this.gameTypes,
    required this.selectedGameType,
    required this.onGameTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: gameTypes.length + 1, // +1 para "Todos"
        itemBuilder: (context, index) {
          if (index == 0) {
            // Chip "Todos" para limpiar filtro
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('Todos'),
                selected: selectedGameType == null,
                onSelected: (selected) {
                  if (selected) {
                    onGameTypeSelected(null);
                  }
                },
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                checkmarkColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }

          final gameType = gameTypes[index - 1];
          final isSelected = selectedGameType == gameType.slug;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(gameType.name),
              selected: isSelected,
              onSelected: (selected) {
                onGameTypeSelected(selected ? gameType.slug : null);
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.primary,
              avatar: gameType.icon != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(gameType.icon!),
                      backgroundColor: Colors.transparent,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
