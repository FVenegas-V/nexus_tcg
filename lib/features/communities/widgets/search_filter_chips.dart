import 'package:flutter/material.dart';

/// Widget reutilizable para mostrar chips de filtros seleccionables
/// Permite selección múltiple o única según configuración
class SearchFilterChips extends StatelessWidget {
  final List<String> items;
  final List<String> selectedItems;
  final Function(List<String>) onSelectionChanged;
  final bool multiSelect;
  final Color? selectedColor;
  final Color? backgroundColor;

  const SearchFilterChips({
    super.key,
    required this.items,
    required this.selectedItems,
    required this.onSelectionChanged,
    this.multiSelect = true,
    this.selectedColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBgColor = selectedColor ?? const Color(0xFFE57373);
    final defaultBgColor = backgroundColor ?? Colors.grey[100];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);

        return FilterChip(
          label: Text(item),
          selected: isSelected,
          onSelected: (selected) {
            List<String> newSelection = List.from(selectedItems);

            if (multiSelect) {
              // Selección múltiple
              if (selected) {
                newSelection.add(item);
              } else {
                newSelection.remove(item);
              }
            } else {
              // Selección única
              if (selected) {
                newSelection = [item];
              } else {
                newSelection.clear();
              }
            }

            onSelectionChanged(newSelection);
          },
          backgroundColor: defaultBgColor,
          selectedColor: selectedBgColor.withOpacity(0.2),
          checkmarkColor: selectedBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? selectedBgColor : Colors.grey[300]!,
              width: 1,
            ),
          ),
          labelStyle: TextStyle(
            color: isSelected ? selectedBgColor : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            fontSize: 14,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}

/// Widget específico para chips de tags con estilo personalizado
class TagFilterChips extends StatelessWidget {
  final List<String> tags;
  final List<String> selectedTags;
  final Function(List<String>) onSelectionChanged;

  const TagFilterChips({
    super.key,
    required this.tags,
    required this.selectedTags,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        final isSelected = selectedTags.contains(tag);

        return ActionChip(
          label: Text('#$tag'),
          onPressed: () {
            List<String> newSelection = List.from(selectedTags);

            if (isSelected) {
              newSelection.remove(tag);
            } else {
              newSelection.add(tag);
            }

            onSelectionChanged(newSelection);
          },
          backgroundColor: isSelected
              ? const Color(0xFFE57373).withOpacity(0.2)
              : Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected ? const Color(0xFFE57373) : Colors.grey[300]!,
              width: 1,
            ),
          ),
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFFE57373) : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            fontSize: 13,
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
