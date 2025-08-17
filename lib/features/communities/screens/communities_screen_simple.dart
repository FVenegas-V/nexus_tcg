import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/communities_provider_new.dart';
import '../widgets/advanced_search_bottom_sheet.dart';
import '../widgets/join_leave_button.dart';

/// Pantalla de Comunidades con datos mock realistas
/// Lista de comunidades TCG
class CommunitiesScreenSimple extends StatefulWidget {
  const CommunitiesScreenSimple({super.key});

  @override
  State<CommunitiesScreenSimple> createState() =>
      _CommunitiesScreenSimpleState();
}

class _CommunitiesScreenSimpleState extends State<CommunitiesScreenSimple> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CommunitiesProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
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
                icon: Stack(
                  children: [
                    Icon(Icons.search, color: Colors.white),
                    // Badge para mostrar si hay filtros activos
                    if (provider.searchQuery.isNotEmpty ||
                        provider.selectedGameType.isNotEmpty ||
                        provider.selectedDifficulty.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.yellow[600],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: const Text(
                            '•',
                            style: TextStyle(color: Colors.white, fontSize: 8),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => _showAdvancedSearch(context, provider),
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
                onRefresh: () => provider.refreshCommunities(),
                color: const Color(0xFFE57373),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
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
    // Obtener la comunidad completa para acceder a los tags
    final provider = context.read<CommunitiesProvider>();
    final community = provider.allCommunities.firstWhere(
      (c) => c.id == communityId,
      orElse: () => provider.allCommunities.first,
    );

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

                      // Tags de la comunidad
                      if (community.tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: community.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '#$tag',
                                style: TextStyle(
                                  color: color.withValues(alpha: 0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),

                // Botón de unirse mejorado con estado dinámico
                Consumer<CommunitiesProvider>(
                  builder: (context, provider, child) {
                    // Usar datos reales de la comunidad
                    final isJoined = community.isSubscribed;
                    final isLoading = provider.isJoinLeaveLoading(community.id);

                    return JoinLeaveButton(
                      isJoined: isJoined,
                      isLoading: isLoading,
                      isCompact: true,
                      onPressed: () async {
                        // Capturar el estado ANTES de la operación
                        final wasJoined = community.isSubscribed;

                        // Hacer la operación real de join/leave
                        await provider.toggleSubscription(community.id);

                        // Mostrar mensaje de éxito si existe
                        if (provider.successMessage != null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(provider.successMessage!),
                                backgroundColor: wasJoined
                                    ? Colors
                                          .orange[600] // Salió de la comunidad
                                    : Colors
                                          .green[600], // Se unió a la comunidad
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                          provider.clearMessages();
                        }

                        // Mostrar mensaje de error si existe
                        if (provider.errorMessage != null) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(provider.errorMessage!),
                                backgroundColor: Colors.red[600],
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                          provider.clearMessages();
                        }
                      },
                    );
                  },
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

  /// Muestra el bottom sheet de búsqueda avanzada
  void _showAdvancedSearch(BuildContext context, CommunitiesProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AdvancedSearchBottomSheet(),
    );
  }
}
