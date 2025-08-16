import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/communities_provider_new.dart';
import 'search_filter_chips.dart';
import 'search_history_widget.dart';

/// Bottom Sheet modal para búsqueda avanzada de comunidades
/// Incluye campo de búsqueda, filtros, tags y historial
class AdvancedSearchBottomSheet extends StatefulWidget {
  const AdvancedSearchBottomSheet({super.key});

  @override
  State<AdvancedSearchBottomSheet> createState() =>
      _AdvancedSearchBottomSheetState();
}

class _AdvancedSearchBottomSheetState extends State<AdvancedSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<String> _selectedGameTypes = [];
  List<String> _selectedDifficulties = [];
  List<String> _selectedTags = [];

  @override
  void initState() {
    super.initState();

    // Inicializar con filtros actuales del provider
    final provider = context.read<CommunitiesProvider>();
    _searchController.text = provider.searchQuery;
    if (provider.selectedGameType.isNotEmpty) {
      _selectedGameTypes = [provider.selectedGameType];
    }
    if (provider.selectedDifficulty.isNotEmpty) {
      _selectedDifficulties = [provider.selectedDifficulty];
    }

    // Auto-focus en el campo de búsqueda
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunitiesProvider>(
      builder: (context, provider, child) {
        return Container(
          height:
              MediaQuery.of(context).size.height * 0.85, // 85% de la pantalla
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            children: [
              // Handle del bottom sheet
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: Color(0xFFE57373),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Búsqueda Avanzada',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE57373),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _clearAllFilters(provider),
                      child: const Text(
                        'Limpiar todo',
                        style: TextStyle(color: Color(0xFFE57373)),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campo de búsqueda
                      _buildSearchField(),
                      const SizedBox(height: 24),

                      // Filtros por tipo de juego
                      _buildGameTypeFilters(provider),
                      const SizedBox(height: 24),

                      // Filtros por dificultad
                      _buildDifficultyFilters(provider),
                      const SizedBox(height: 24),

                      // Tags populares
                      _buildPopularTags(),
                      const SizedBox(height: 24),

                      // Historial de búsquedas
                      const SearchHistoryWidget(),
                      const SizedBox(height: 24),

                      // Contador de resultados
                      _buildResultsCounter(provider),
                    ],
                  ),
                ),
              ),

              // Botones de acción
              _buildActionButtons(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: const InputDecoration(
          hintText: 'Buscar comunidades...',
          prefixIcon: Icon(Icons.search, color: Color(0xFFE57373)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          // Búsqueda en tiempo real (con debounce)
          setState(() {}); // Para actualizar el contador
        },
      ),
    );
  }

  Widget _buildGameTypeFilters(CommunitiesProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de juego',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SearchFilterChips(
          items: provider.availableGameTypes,
          selectedItems: _selectedGameTypes,
          onSelectionChanged: (selected) {
            setState(() {
              _selectedGameTypes = selected;
            });
          },
          multiSelect: true,
        ),
      ],
    );
  }

  Widget _buildDifficultyFilters(CommunitiesProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nivel de dificultad',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        SearchFilterChips(
          items: provider.availableDifficultyLevels,
          selectedItems: _selectedDifficulties,
          onSelectionChanged: (selected) {
            setState(() {
              _selectedDifficulties = selected;
            });
          },
          multiSelect: false, // Solo una dificultad
        ),
      ],
    );
  }

  Widget _buildPopularTags() {
    // Mock data - en el futuro se conectará con la API
    final popularTags = [
      'competitivo',
      'casual',
      'torneo',
      'principiantes',
      'meta',
      'deck building',
      'estrategia',
      'coleccionista',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags populares',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: popularTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text('#$tag'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              backgroundColor: Colors.grey[100],
              selectedColor: const Color(0xFFE57373).withOpacity(0.2),
              checkmarkColor: const Color(0xFFE57373),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFFE57373) : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsCounter(CommunitiesProvider provider) {
    final totalResults = _calculateResults(provider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE57373).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFE57373), size: 20),
          const SizedBox(width: 8),
          Text(
            '$totalResults comunidades encontradas',
            style: const TextStyle(
              color: Color(0xFFE57373),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CommunitiesProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE57373)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Color(0xFFE57373),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _applyFilters(provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE57373),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Aplicar filtros',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateResults(CommunitiesProvider provider) {
    // Simular cálculo de resultados basado en filtros actuales
    // En una implementación real, esto haría una consulta al provider
    int baseCount = provider.communities.length;

    if (_searchController.text.isNotEmpty) {
      baseCount = (baseCount * 0.7).round(); // Simular filtrado por búsqueda
    }

    if (_selectedGameTypes.isNotEmpty) {
      baseCount = (baseCount * 0.8).round(); // Simular filtrado por juego
    }

    if (_selectedDifficulties.isNotEmpty) {
      baseCount = (baseCount * 0.9).round(); // Simular filtrado por dificultad
    }

    return baseCount;
  }

  void _applyFilters(CommunitiesProvider provider) {
    // Aplicar búsqueda de texto
    if (_searchController.text != provider.searchQuery) {
      provider.searchCommunities(_searchController.text);
    }

    // Aplicar filtros de tipo de juego
    if (_selectedGameTypes.isNotEmpty) {
      provider.filterByGameType(_selectedGameTypes.first);
    } else {
      provider.clearGameTypeFilter();
    }

    // Aplicar filtros de dificultad
    if (_selectedDifficulties.isNotEmpty) {
      provider.filterByDifficulty(_selectedDifficulties.first);
    } else {
      provider.clearDifficultyFilter();
    }

    // TODO: Implementar filtros por tags

    // Guardar en historial si hay búsqueda
    if (_searchController.text.isNotEmpty) {
      _saveToHistory(_searchController.text);
    }

    Navigator.pop(context);
  }

  void _clearAllFilters(CommunitiesProvider provider) {
    setState(() {
      _searchController.clear();
      _selectedGameTypes.clear();
      _selectedDifficulties.clear();
      _selectedTags.clear();
    });

    provider.searchCommunities('');
    provider.clearGameTypeFilter();
    provider.clearDifficultyFilter();
  }

  void _saveToHistory(String query) {
    // TODO: Implementar guardado en SharedPreferences
    print('Guardando en historial: $query');
  }
}
