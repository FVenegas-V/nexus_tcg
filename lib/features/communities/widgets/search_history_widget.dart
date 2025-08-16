import 'package:flutter/material.dart';

/// Widget para mostrar y manejar el historial de búsquedas
/// Guarda las búsquedas en memoria durante la sesión
class SearchHistoryWidget extends StatefulWidget {
  final Function(String)? onSearchSelected;
  final int maxItems;

  const SearchHistoryWidget({
    super.key,
    this.onSearchSelected,
    this.maxItems = 5,
  });

  @override
  State<SearchHistoryWidget> createState() => _SearchHistoryWidgetState();
}

class _SearchHistoryWidgetState extends State<SearchHistoryWidget> {
  // Lista estática para mantener el historial durante la sesión
  static List<String> _searchHistory = [
    'Magic comunidades',
    'Pokémon principiantes',
    'Yu-Gi-Oh competitivo',
    'Dragon Ball meta',
  ];

  void addToHistory(String query) {
    if (query.trim().isEmpty) return;

    setState(() {
      // Remover si ya existe
      _searchHistory.remove(query);
      // Agregar al inicio
      _searchHistory.insert(0, query);
      // Mantener solo los últimos N elementos
      if (_searchHistory.length > widget.maxItems) {
        _searchHistory = _searchHistory.take(widget.maxItems).toList();
      }
    });
  }

  void _removeFromHistory(String query) {
    setState(() {
      _searchHistory.remove(query);
    });
  }

  void _clearAllHistory() {
    setState(() {
      _searchHistory.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_searchHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Búsquedas recientes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _clearAllHistory,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              child: const Text(
                'Limpiar',
                style: TextStyle(color: Color(0xFFE57373), fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        for (String query in _searchHistory) _buildHistoryItem(query),
      ],
    );
  }

  Widget _buildHistoryItem(String query) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: const Icon(Icons.history, color: Color(0xFFE57373), size: 20),
        title: Text(
          query,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close, size: 16, color: Colors.grey),
          onPressed: () => _removeFromHistory(query),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        onTap: () {
          if (widget.onSearchSelected != null) {
            widget.onSearchSelected!(query);
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Clase estática para manejar el historial desde cualquier lugar
class SearchHistoryManager {
  static List<String> _globalHistory = [];
  static const int _maxItems = 10;

  static void addSearch(String query) {
    if (query.trim().isEmpty) return;

    // Remover si ya existe
    _globalHistory.remove(query);
    // Agregar al inicio
    _globalHistory.insert(0, query);
    // Mantener solo los últimos elementos
    if (_globalHistory.length > _maxItems) {
      _globalHistory = _globalHistory.take(_maxItems).toList();
    }
  }

  static List<String> getHistory() {
    return List.from(_globalHistory);
  }

  static void clearHistory() {
    _globalHistory.clear();
  }
}
