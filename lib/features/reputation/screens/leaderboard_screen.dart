import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reputation_provider.dart';
import '../models/leaderboard_entry.dart';
import '../models/leaderboard_types.dart';
import '../models/reputation_stats.dart';
import '../widgets/anti_gaming_indicator.dart';
import 'public_profile_screen.dart';

/// Pantalla del leaderboard global de reputación
///
/// Muestra:
/// - Top usuarios por reputación
/// - Filtros por categorías y períodos
/// - Posición del usuario actual
/// - Navegación a perfiles públicos
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  LeaderboardPeriod _selectedPeriod = LeaderboardPeriod.monthly;
  bool _showMyPosition = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadLeaderboard();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadLeaderboard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reputationProvider = Provider.of<ReputationProvider>(
        context,
        listen: false,
      );
      reputationProvider.loadLeaderboard(
        timeRange: _selectedPeriod.apiValue,
        pageSize: 50,
        forceRefresh: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return FadeTransition(opacity: _fadeAnimation, child: _buildBody());
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Leaderboard'),
      centerTitle: true,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(_showMyPosition ? Icons.person : Icons.person_outline),
          onPressed: () {
            setState(() {
              _showMyPosition = !_showMyPosition;
            });
          },
          tooltip: _showMyPosition
              ? 'Ocultar mi posición'
              : 'Mostrar mi posición',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'refresh':
                _loadLeaderboard();
                break;
              case 'help':
                _showHelpDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Actualizar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'help',
              child: ListTile(
                leading: Icon(Icons.help_outline),
                title: Text('Ayuda'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [_buildLeaderboardTab(), _buildStatsTab()],
          ),
        ),
        _buildTabBar(),
      ],
    );
  }

  Widget _buildFilters() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.1)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // Filtro de período
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Período',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<LeaderboardPeriod>(
                value: _selectedPeriod,
                decoration: InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: LeaderboardPeriod.values.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(_getPeriodDisplayName(period)),
                  );
                }).toList(),
                onChanged: (period) {
                  if (period != null) {
                    setState(() {
                      _selectedPeriod = period;
                    });
                    _loadLeaderboard();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(icon: Icon(Icons.leaderboard), text: 'Ranking'),
          Tab(icon: Icon(Icons.analytics), text: 'Estadísticas'),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return Consumer<ReputationProvider>(
      builder: (context, provider, child) {
        if (provider.isLeaderboardLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.hasLeaderboardError) {
          return _buildErrorState(provider.leaderboardError);
        }

        final leaderboard = provider.currentLeaderboard;
        if (leaderboard == null || leaderboard.entries.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async => _loadLeaderboard(),
          child: Column(
            children: [
              if (_showMyPosition) _buildMyPosition(leaderboard),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: leaderboard.entries.length,
                  itemBuilder: (context, index) {
                    final entry = leaderboard.entries[index];
                    return _buildLeaderboardItem(entry, index + 1);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyPosition(LeaderboardResponse leaderboard) {
    final theme = Theme.of(context);
    const currentUserId = 1; // TODO: Get from AuthProvider

    // Buscar la posición del usuario actual
    final myEntry = leaderboard.entries
        .where((entry) => entry.userId == currentUserId)
        .firstOrNull;

    if (myEntry == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No apareces en el top ${leaderboard.entries.length} actual',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final position = leaderboard.entries.indexOf(myEntry) + 1;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#$position',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu posición actual',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${myEntry.totalScore.toStringAsFixed(0)} puntos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.person, color: theme.colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry, int position) {
    final theme = Theme.of(context);
    final isTopThree = position <= 3;
    final medal = _getMedalForPosition(position);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isTopThree ? 2 : 1,
      child: InkWell(
        onTap: () => _navigateToProfile(entry.userId, entry.username),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Posición y medalla
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isTopThree
                      ? _getPositionColor(position).withOpacity(0.1)
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: isTopThree
                      ? Border.all(
                          color: _getPositionColor(position).withOpacity(0.3),
                        )
                      : null,
                ),
                child: Center(
                  child: medal.isNotEmpty
                      ? Text(medal, style: const TextStyle(fontSize: 20))
                      : Text(
                          '#$position',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 12),

              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Text(
                  entry.username.isNotEmpty
                      ? entry.username[0].toUpperCase()
                      : '?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Información del usuario
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.username,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          entry.level.displayName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          entry.level.emoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Score y rating
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.totalScore.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isTopThree ? _getPositionColor(position) : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        entry.averageRating.toStringAsFixed(1),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 8),

              // Indicador anti-gaming
              AntiGamingIndicator(
                status: entry.antiGamingStatus,
                style: AntiGamingDisplayStyle.chip,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsTab() {
    return Consumer<ReputationProvider>(
      builder: (context, provider, child) {
        if (provider.isLeaderboardLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final leaderboard = provider.currentLeaderboard;
        if (leaderboard == null || leaderboard.entries.isEmpty) {
          return _buildEmptyState();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildOverallStats(leaderboard),
              const SizedBox(height: 24),
              _buildTopPerformers(leaderboard),
              const SizedBox(height: 24),
              _buildDistributionStats(leaderboard),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverallStats(LeaderboardResponse leaderboard) {
    final theme = Theme.of(context);
    final entries = leaderboard.entries;

    final avgScore = entries.isNotEmpty
        ? entries.map((e) => e.totalScore).reduce((a, b) => a + b) /
              entries.length
        : 0.0;

    final avgRating = entries.isNotEmpty
        ? entries.map((e) => e.averageRating).reduce((a, b) => a + b) /
              entries.length
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas generales',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Participantes',
                  '${entries.length}',
                  Icons.people,
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Score Promedio',
                  avgScore.toStringAsFixed(0),
                  Icons.trending_up,
                  theme.colorScheme.secondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Rating Promedio',
                  avgRating.toStringAsFixed(1),
                  Icons.star,
                  theme.colorScheme.tertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Score Máximo',
                  entries.isNotEmpty
                      ? entries.first.totalScore.toStringAsFixed(0)
                      : '0',
                  Icons.emoji_events,
                  theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformers(LeaderboardResponse leaderboard) {
    final theme = Theme.of(context);
    final topThree = leaderboard.entries.take(3).toList();

    if (topThree.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 3 destacados',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          ...topThree.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            final position = index + 1;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getPositionColor(position).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getPositionColor(position).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _getMedalForPosition(position),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.username,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${user.totalScore.toStringAsFixed(0)} puntos • ${user.averageRating.toStringAsFixed(1)} ⭐',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(user.level.emoji, style: const TextStyle(fontSize: 20)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDistributionStats(LeaderboardResponse leaderboard) {
    final theme = Theme.of(context);
    final entries = leaderboard.entries;

    // Distribución por niveles
    final levelCounts = <ReputationLevel, int>{};
    for (final entry in entries) {
      levelCounts[entry.level] = (levelCounts[entry.level] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución por niveles',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          ...levelCounts.entries.map((entry) {
            final level = entry.key;
            final count = entry.value;
            final percentage = (count / entries.length * 100);

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(level.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: theme.colorScheme.outline
                              .withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$count (${percentage.toStringAsFixed(1)}%)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _loadLeaderboard,
      tooltip: 'Actualizar ranking',
      child: const Icon(Icons.refresh),
    );
  }

  Widget _buildErrorState(String? message) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Error al cargar el leaderboard',
            style: theme.textTheme.titleMedium,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loadLeaderboard,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text('No hay datos disponibles', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'El ranking aún no tiene participantes',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loadLeaderboard,
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares
  String _getPeriodDisplayName(LeaderboardPeriod period) {
    switch (period) {
      case LeaderboardPeriod.weekly:
        return 'Semanal';
      case LeaderboardPeriod.monthly:
        return 'Mensual';
      case LeaderboardPeriod.quarterly:
        return 'Trimestral';
      case LeaderboardPeriod.yearly:
        return 'Anual';
      case LeaderboardPeriod.allTime:
        return 'Histórico';
    }
  }

  String _getMedalForPosition(int position) {
    switch (position) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  Color _getPositionColor(int position) {
    final theme = Theme.of(context);
    switch (position) {
      case 1:
        return const Color(0xFFFFD700); // Oro
      case 2:
        return const Color(0xFFC0C0C0); // Plata
      case 3:
        return const Color(0xFFCD7F32); // Bronce
      default:
        return theme.colorScheme.primary;
    }
  }

  // Métodos de navegación
  void _navigateToProfile(int userId, String username) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PublicProfileScreen(userId: userId, username: username),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayuda - Leaderboard'),
        content: const SingleChildScrollView(
          child: Text(
            'El leaderboard muestra:\n\n'
            '• Ranking de usuarios por reputación\n'
            '• Filtros por período y categoría\n'
            '• Tu posición actual (si apareces)\n'
            '• Estadísticas generales de la comunidad\n'
            '• Distribución por niveles\n\n'
            'Toca cualquier usuario para ver su perfil público.\n\n'
            'Los datos se actualizan periódicamente.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
