import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/communities_provider.dart';

/// Pantalla de Comunidades con datos mock realistas
/// Lista de comunidades TCG
class CommunitiesScreenSimple extends StatefulWidget {
  const CommunitiesScreenSimple({super.key});

  @override
  State<CommunitiesScreenSimple> createState() =>
      _CommunitiesScreenSimpleState();
}

class _CommunitiesScreenSimpleState extends State<CommunitiesScreenSimple> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunitiesProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Buscar comunidades...',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      // Búsqueda en tiempo real
                      provider.searchCommunities(value);
                    },
                    onSubmitted: (value) {
                      provider.searchCommunities(value);
                    },
                  )
                : const Text(
                    'Comunidades',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: const Color(0xFFE57373),
            actions: [
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close : Icons.search,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    if (_isSearching) {
                      // Salir de búsqueda
                      _isSearching = false;
                      _searchController.clear();
                      provider.searchCommunities(''); // Limpiar búsqueda
                    } else {
                      // Entrar en modo búsqueda
                      _isSearching = true;
                    }
                  });
                },
              ),
            ],
          ),
          body: Container(
            color: const Color(0xFFE57373), // Fondo del color del AppBar
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: RefreshIndicator(
                onRefresh: () => provider.loadCommunities(),
                color: const Color(0xFFE57373), // Color coral para el indicador
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  physics:
                      const AlwaysScrollableScrollPhysics(), // Permite scroll siempre para pull-to-refresh
                  children: [
                    // Estados mejorados: loading, error, empty, content
                    if (provider.isLoading)
                      _buildLoadingState()
                    else if (provider.hasError)
                      _buildErrorState(provider.errorMessage, provider)
                    else if (provider.isEmpty)
                      _buildEmptyState(context)
                    else
                      ...provider.communities.map(
                        (community) => Column(
                          children: [
                            _buildCommunityCard(
                              context,
                              community.name,
                              '${community.memberCount} miembros',
                              community.description,
                              _getColorForGameType(community.gameType),
                              _getIconForGameType(community.gameType),
                              community.id,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                  ],
                ), // Cerrar ListView
              ), // Cerrar RefreshIndicator
            ),
          ),
        ); // Cerrar Scaffold
      },
    ); // Cerrar Consumer
  }

  /// Construye una card de comunidad como funcionaba ayer
  Widget _buildCommunityCard(
    BuildContext context,
    String name,
    String members,
    String description,
    Color color,
    IconData icon,
    int communityId,
  ) {
    return Hero(
      tag: 'community-card-$communityId', // Tag único para Hero animation
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navegar al detalle de la comunidad con el ID específico
            context.push('/community/$communityId');
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.1,
              ), // Fondo suave del color del tema
              borderRadius: BorderRadius.circular(
                20,
              ), // Más redondeado como el mockup
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
            ),
            child: Row(
              children: [
                // Ícono de la comunidad en contenedor redondeado
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: color.withValues(alpha: 0.8),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),

                // Información de la comunidad
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        members,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Botón de unirse con estilo del mockup
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Te uniste a $name')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFFFCDD2,
                      ), // Color rosado suave como el mockup
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Unirse',
                      style: TextStyle(
                        color: Color(0xFFD32F2F), // Color rojo para el texto
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ), // Cerrar Row dentro de Container
          ), // Cerrar Container (child de InkWell)
        ), // Cerrar InkWell
      ), // Cerrar Material
    ); // Cerrar Hero
  }

  /// Estado de carga mejorado con branding
  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFFE57373),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Cargando comunidades...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preparando las mejores comunidades TCG',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  /// Estado de error mejorado con retry
  Widget _buildErrorState(String? errorMessage, CommunitiesProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Oops! Algo salió mal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.loadCommunities(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE57373),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Estado vacío mejorado con call-to-action
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay comunidades disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Parece que aún no hay comunidades creadas.\n¡Sé el primero en unirte cuando estén disponibles!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implementar crear comunidad o navegar a sección correspondiente
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Funcionalidad próximamente')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear comunidad'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE57373),
                side: const BorderSide(color: Color(0xFFE57373)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mapea tipo de juego a color
  Color _getColorForGameType(String gameType) {
    switch (gameType.toLowerCase()) {
      case 'magic':
      case 'magic: the gathering':
        return Colors.blue;
      case 'pokemon':
      case 'pokémon':
        return Colors.orange;
      case 'yu-gi-oh':
      case 'yugioh':
        return Colors.purple;
      case 'dragon ball':
      case 'dragon ball super':
        return Colors.red;
      case 'one piece':
        return Colors.green;
      case 'digimon':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  /// Mapea tipo de juego a icono
  IconData _getIconForGameType(String gameType) {
    switch (gameType.toLowerCase()) {
      case 'magic':
      case 'magic: the gathering':
        return Icons.auto_fix_high;
      case 'pokemon':
      case 'pokémon':
        return Icons.catching_pokemon;
      case 'yu-gi-oh':
      case 'yugioh':
        return Icons.style;
      case 'dragon ball':
      case 'dragon ball super':
        return Icons.flash_on;
      case 'one piece':
        return Icons.sailing;
      case 'digimon':
        return Icons.pets;
      default:
        return Icons.groups;
    }
  }
}
