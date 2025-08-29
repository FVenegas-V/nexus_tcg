import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reputation_provider.dart';
import '../providers/ratings_provider.dart';
import '../models/reputation_stats.dart';
import '../widgets/reputation_card.dart';
import '../widgets/anti_gaming_indicator.dart';

/// Pantalla principal del dashboard de reputación del usuario actual
class ReputationDashboardScreen extends StatefulWidget {
  const ReputationDashboardScreen({super.key});

  @override
  State<ReputationDashboardScreen> createState() =>
      _ReputationDashboardScreenState();
}

class _ReputationDashboardScreenState extends State<ReputationDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadInitialData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final reputationProvider = Provider.of<ReputationProvider>(
        context,
        listen: false,
      );
      final ratingsProvider = Provider.of<RatingsProvider>(
        context,
        listen: false,
      );

      const currentUserId = 1; // TODO: Obtener del AuthProvider

      reputationProvider.getReputationStats(currentUserId);
      ratingsProvider.getReceivedRatings(currentUserId);
      ratingsProvider.getMyRatings();
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
      title: const Text('Mi Reputación'),
      centerTitle: true,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: () => _showHelpDialog(),
          tooltip: 'Ayuda',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer2<ReputationProvider, RatingsProvider>(
      builder: (context, reputationProvider, ratingsProvider, child) {
        if (reputationProvider.isLoading || ratingsProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (reputationProvider.hasError) {
          return _buildErrorState(reputationProvider.errorMessage);
        }

        const currentUserId = 1; // TODO: Get from AuthProvider
        final stats = reputationProvider.getCachedReputationStats(
          currentUserId,
        );

        if (stats == null) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            _buildQuickStats(stats),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(stats, ratingsProvider),
                  _buildStatsTab(stats),
                  _buildAnalyticsTab(stats),
                ],
              ),
            ),
            _buildTabBar(),
          ],
        );
      },
    );
  }

  Widget _buildQuickStats(ReputationStats stats) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Tarjeta principal de reputación
          ReputationCard(
            stats: stats,
            showDetails: true,
            showProgress: true,
            onTap: () => _showReputationDetails(stats),
          ),

          const SizedBox(height: 16),

          // Métricas rápidas
          Row(
            children: [
              Expanded(
                child: _buildQuickMetric(
                  'Posición Global',
                  stats.globalRank?.toString() ?? 'N/A',
                  Icons.leaderboard,
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickMetric(
                  'Valoraciones',
                  '${stats.ratingsCount}',
                  Icons.star,
                  theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickMetric(
                  'Promedio',
                  stats.averageRating.toStringAsFixed(1),
                  Icons.trending_up,
                  theme.colorScheme.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetric(
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
        borderRadius: BorderRadius.circular(12),
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
          Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
          Tab(icon: Icon(Icons.bar_chart), text: 'Estadísticas'),
          Tab(icon: Icon(Icons.analytics), text: 'Análisis'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    ReputationStats stats,
    RatingsProvider ratingsProvider,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressSection(stats),
          const SizedBox(height: 24),
          _buildRecentRatingsSection(ratingsProvider),
          const SizedBox(height: 24),
          _buildTrustSection(stats),
        ],
      ),
    );
  }

  Widget _buildProgressSection(ReputationStats stats) {
    final theme = Theme.of(context);

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
            'Progreso hacia siguiente nivel',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Nivel actual
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  stats.level.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.level.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${stats.totalScore.toStringAsFixed(0)} puntos',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Barra de progreso
          LinearProgressIndicator(
            value: stats.progressToNextLevel,
            backgroundColor: theme.colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Progreso: ${(stats.progressToNextLevel * 100).toStringAsFixed(1)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRatingsSection(RatingsProvider ratingsProvider) {
    final theme = Theme.of(context);
    const currentUserId = 1; // TODO: Get from AuthProvider
    final ratings =
        ratingsProvider.getCachedReceivedRatings(currentUserId) ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valoraciones recientes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (ratings.isNotEmpty)
                TextButton(
                  onPressed: () => _showAllRatings(),
                  child: const Text('Ver todas'),
                ),
            ],
          ),

          const SizedBox(height: 16),

          if (ratings.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.star_border,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aún no has recibido valoraciones',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            ...ratings
                .take(3)
                .map(
                  (rating) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Text(
                          rating.raterUsername.isNotEmpty
                              ? rating.raterUsername[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(rating.raterUsername),
                      subtitle: Text(rating.comment ?? 'Sin comentario'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          5,
                          (index) => Icon(
                            index < rating.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                        ),
                      ),
                      onTap: () => _showRatingDetails(rating),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildTrustSection(ReputationStats stats) {
    final theme = Theme.of(context);

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
            'Estado de confianza',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          AntiGamingIndicator(
            status: stats.antiGamingStatus,
            style: AntiGamingDisplayStyle.card,
            showLabel: true,
            showTooltip: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(ReputationStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildBreakdownChart(stats),
          const SizedBox(height: 24),
          _buildStatsCards(stats),
        ],
      ),
    );
  }

  Widget _buildBreakdownChart(ReputationStats stats) {
    final theme = Theme.of(context);

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
            'Factores de reputación',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          ...stats.breakdown.factors.map(
            (factor) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Text(factor.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          factor.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        LinearProgressIndicator(
                          value: (factor.value.abs() / 100).clamp(0.0, 1.0),
                          backgroundColor: theme.colorScheme.outline
                              .withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            factor.value >= 0
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    factor.value >= 0
                        ? '+${factor.value.toStringAsFixed(1)}'
                        : factor.value.toStringAsFixed(1),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: factor.value >= 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(ReputationStats stats) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Score Total',
                stats.totalScore.toStringAsFixed(0),
                Icons.emoji_events,
                theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Promedio',
                stats.averageRating.toStringAsFixed(2),
                Icons.star,
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
                'Valoraciones',
                stats.ratingsCount.toString(),
                Icons.rate_review,
                theme.colorScheme.tertiary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Percentil',
                stats.percentile != null
                    ? '${stats.percentile!.toStringAsFixed(1)}%'
                    : 'N/A',
                Icons.trending_up,
                theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
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

  Widget _buildAnalyticsTab(ReputationStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTrendInsights(stats),
          const SizedBox(height: 24),
          _buildRecommendations(stats),
        ],
      ),
    );
  }

  Widget _buildTrendInsights(ReputationStats stats) {
    final theme = Theme.of(context);

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
            'Análisis de rendimiento',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          _buildInsightItem(
            Icons.trending_up,
            'Puntuación actual',
            'Tienes ${stats.totalScore.toStringAsFixed(0)} puntos de reputación',
            theme.colorScheme.primary,
          ),

          const SizedBox(height: 12),

          _buildInsightItem(
            Icons.star,
            'Calidad de valoraciones',
            'Promedio de ${stats.averageRating.toStringAsFixed(1)} estrellas en ${stats.ratingsCount} valoraciones',
            theme.colorScheme.secondary,
          ),

          const SizedBox(height: 12),

          _buildInsightItem(
            Icons.security,
            'Estado de confianza',
            'Nivel: ${stats.antiGamingStatus.trustLevel.displayName}',
            _getTrustLevelColor(stats.antiGamingStatus.trustLevel),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations(ReputationStats stats) {
    final theme = Theme.of(context);

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
            'Recomendaciones para mejorar',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          ...(_getRecommendations(stats)).map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(rec, style: theme.textTheme.bodyMedium)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showTipsDialog(),
      icon: const Icon(Icons.tips_and_updates),
      label: const Text('Tips'),
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
          Text('Error al cargar datos', style: theme.textTheme.titleMedium),
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
            onPressed: _loadInitialData,
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
            Icons.dashboard,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text('Datos no disponibles', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Aún no tienes datos de reputación',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loadInitialData,
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  // Métodos auxiliares
  Color _getTrustLevelColor(TrustLevel trustLevel) {
    final theme = Theme.of(context);
    switch (trustLevel) {
      case TrustLevel.verified:
        return theme.colorScheme.primary;
      case TrustLevel.trusted:
        return theme.colorScheme.secondary;
      case TrustLevel.neutral:
        return theme.colorScheme.tertiary;
      case TrustLevel.suspicious:
        return theme.colorScheme.error.withOpacity(0.7);
      case TrustLevel.flagged:
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  List<String> _getRecommendations(ReputationStats stats) {
    final recommendations = <String>[];

    if (stats.ratingsCount < 10) {
      recommendations.add(
        'Participa más en transacciones para recibir más valoraciones',
      );
    }

    if (stats.averageRating < 4.0) {
      recommendations.add(
        'Mejora la calidad de tus servicios para obtener mejores valoraciones',
      );
    }

    if (stats.antiGamingStatus.suspicionScore > 0.3) {
      recommendations.add(
        'Mantén interacciones auténticas para mejorar tu puntuación de confianza',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        '¡Excelente trabajo! Continúa manteniendo tu alta reputación',
      );
    }

    return recommendations;
  }

  // Métodos de navegación y diálogos
  void _showReputationDetails(ReputationStats stats) {
    // TODO: Implementar navegación a detalles
  }

  void _showAllRatings() {
    // TODO: Implementar navegación a todas las valoraciones
  }

  void _showRatingDetails(rating) {
    // TODO: Implementar diálogo de detalles de valoración
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayuda - Dashboard de Reputación'),
        content: const SingleChildScrollView(
          child: Text(
            'Tu dashboard muestra:\n\n'
            '• Resumen de tu puntuación y nivel actual\n'
            '• Progreso hacia el siguiente nivel\n'
            '• Valoraciones recientes recibidas\n'
            '• Factores que componen tu reputación\n'
            '• Análisis y recomendaciones personalizadas\n\n'
            'Los datos se actualizan automáticamente.',
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

  void _showTipsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tips para mejorar tu reputación'),
        content: const SingleChildScrollView(
          child: Text(
            '💡 Sé activo en la comunidad\n'
            '💡 Completa transacciones de manera honesta\n'
            '💡 Responde rápidamente a mensajes\n'
            '💡 Mantén descripciones precisas\n'
            '💡 Resuelve conflictos de manera constructiva\n'
            '💡 Ayuda a otros usuarios cuando puedas',
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
