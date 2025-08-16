import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/communities_state.dart';

/// Bottom sheet para filtros avanzados de comunidades
/// Incluye filtros por GameType, Difficulty, Tags, etc.
class CommunityFilterSheet extends StatefulWidget {
  final String? selectedGameType;
  final String? selectedDifficulty;
  final Function(String?, String?) onFiltersChanged;

  const CommunityFilterSheet({
    super.key,
    this.selectedGameType,
    this.selectedDifficulty,
    required this.onFiltersChanged,
  });

  @override
  State<CommunityFilterSheet> createState() => _CommunityFilterSheetState();
}

class _CommunityFilterSheetState extends State<CommunityFilterSheet> {
  String? _tempGameType;
  String? _tempDifficulty;

  static const List<String> _difficulties = [
    'Principiante',
    'Intermedio',
    'Avanzado',
  ];

  @override
  void initState() {
    super.initState();
    _tempGameType = widget.selectedGameType;
    _tempDifficulty = widget.selectedDifficulty;
  }

  void _applyFilters() {
    widget.onFiltersChanged(_tempGameType, _tempDifficulty);
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _tempGameType = null;
      _tempDifficulty = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Limpiar'),
                ),
              ],
            ),
          ),

          // Filtros
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtro por GameType
                  Consumer<CommunitiesState>(
                    builder: (context, state, child) {
                      if (state.gameTypes.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tipo de Juego',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Todos'),
                                selected: _tempGameType == null,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _tempGameType = null;
                                    });
                                  }
                                },
                              ),
                              ...state.gameTypes.map((gameType) {
                                return ChoiceChip(
                                  label: Text(gameType.name),
                                  selected: _tempGameType == gameType.slug,
                                  onSelected: (selected) {
                                    setState(() {
                                      _tempGameType = selected
                                          ? gameType.slug
                                          : null;
                                    });
                                  },
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),

                  // Filtro por Dificultad
                  const Text(
                    'Dificultad',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Todas'),
                        selected: _tempDifficulty == null,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _tempDifficulty = null;
                            });
                          }
                        },
                      ),
                      ..._difficulties.map((difficulty) {
                        return ChoiceChip(
                          label: Text(difficulty),
                          selected: _tempDifficulty == difficulty.toLowerCase(),
                          onSelected: (selected) {
                            setState(() {
                              _tempDifficulty = selected
                                  ? difficulty.toLowerCase()
                                  : null;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _applyFilters,
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
