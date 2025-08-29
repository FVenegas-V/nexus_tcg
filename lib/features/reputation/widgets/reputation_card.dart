import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../models/reputation_stats.dart';

/// Widget de tarjeta para mostrar información de reputación de un usuario
///
/// Muestra:
/// - Nivel y score de reputación
/// - Progreso hacia siguiente nivel
/// - Estadísticas destacadas
/// - Indicadores visuales de calidad
/// - Estado anti-gaming (opcional)
class ReputationCard extends StatelessWidget {
  /// Estadísticas de reputación a mostrar
  final ReputationStats stats;

  /// Si se debe mostrar información detallada
  final bool showDetails;

  /// Si se debe mostrar el progreso hacia siguiente nivel
  final bool showProgress;

  /// Si es una versión compacta
  final bool isCompact;

  /// Callback cuando se toca la tarjeta
  final VoidCallback? onTap;

  /// Si se debe mostrar el indicador anti-gaming
  final bool showAntiGamingIndicator;

  /// Tema de color personalizado
  final ColorScheme? colorScheme;

  const ReputationCard({
    super.key,
    required this.stats,
    this.showDetails = true,
    this.showProgress = true,
    this.isCompact = false,
    this.onTap,
    this.showAntiGamingIndicator = false,
    this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = colorScheme ?? theme.colorScheme;

    return Card(
      elevation: isCompact ? 2 : 4,
      margin: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 16,
        vertical: isCompact ? 4 : 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: isCompact
              ? _buildCompactLayout(colors)
              : _buildFullLayout(colors),
        ),
      ),
    );
  }

  /// Layout compacto para listas
  Widget _buildCompactLayout(ColorScheme colors) {
    return Row(
      children: [
        // Avatar del nivel con score
        _buildLevelAvatar(colors, size: 40),

        const SizedBox(width: 12),

        // Información principal
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nivel y nombre
              Row(
                children: [
                  Expanded(
                    child: AutoSizeText(
                      stats.level.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  if (showAntiGamingIndicator) ...[
                    const SizedBox(width: 8),
                    _buildAntiGamingIndicator(colors, size: 16),
                  ],
                ],
              ),

              const SizedBox(height: 4),

              // Score y barra de progreso inline
              Row(
                children: [
                  AutoSizeText(
                    '${stats.totalScore.toStringAsFixed(1)} pts',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (showProgress)
                    Expanded(child: _buildProgressBarMini(colors)),
                ],
              ),
            ],
          ),
        ),

        // Flecha si es clickeable
        if (onTap != null) ...[
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: colors.onSurfaceVariant, size: 20),
        ],
      ],
    );
  }

  /// Layout completo para tarjetas principales
  Widget _buildFullLayout(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con nivel y score
        _buildHeader(colors),

        if (showProgress) ...[
          const SizedBox(height: 16),
          _buildProgressSection(colors),
        ],

        if (showDetails) ...[
          const SizedBox(height: 16),
          _buildStatsSection(colors),
        ],

        if (showAntiGamingIndicator) ...[
          const SizedBox(height: 12),
          _buildAntiGamingSection(colors),
        ],
      ],
    );
  }

  /// Header con avatar, nivel y score
  Widget _buildHeader(ColorScheme colors) {
    return Row(
      children: [
        // Avatar del nivel
        _buildLevelAvatar(colors, size: 60),

        const SizedBox(width: 16),

        // Información del nivel
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nivel
              AutoSizeText(
                stats.level.displayName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
                maxLines: 1,
              ),

              const SizedBox(height: 4),

              // Score actual
              AutoSizeText(
                '${stats.totalScore.toStringAsFixed(1)} puntos',
                style: TextStyle(fontSize: 16, color: colors.onSurfaceVariant),
              ),

              // Info adicional del nivel
              const SizedBox(height: 4),
              AutoSizeText(
                'Rango: ${stats.level.minScore} - ${stats.level.maxScore} pts',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Avatar circular con el emoji del nivel
  Widget _buildLevelAvatar(ColorScheme colors, {required double size}) {
    final levelColor = _getLevelColor();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [levelColor, levelColor.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(stats.level.emoji, style: TextStyle(fontSize: size * 0.4)),
      ),
    );
  }

  /// Obtiene el color del nivel
  Color _getLevelColor() {
    final hex = stats.level.colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  /// Sección de progreso hacia siguiente nivel
  Widget _buildProgressSection(ColorScheme colors) {
    final nextLevel = stats.level.nextLevel;
    if (nextLevel == null) {
      return _buildMaxLevelIndicator(colors);
    }

    final progress = stats.progressToNextLevel.clamp(0.0, 1.0);
    final pointsNeeded = nextLevel.minScore - stats.totalScore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Texto de progreso
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AutoSizeText(
              'Progreso hacia ${nextLevel.displayName}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
                fontSize: 14,
              ),
            ),
            AutoSizeText(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colors.primary,
                fontSize: 14,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Barra de progreso
        _buildProgressBar(colors, progress),

        const SizedBox(height: 8),

        // Puntos necesarios
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AutoSizeText(
              '${stats.totalScore.toStringAsFixed(1)} pts',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
            ),
            AutoSizeText(
              pointsNeeded > 0
                  ? '${pointsNeeded.toStringAsFixed(1)} pts restantes'
                  : '¡Nivel alcanzado!',
              style: TextStyle(
                color: pointsNeeded > 0
                    ? colors.onSurfaceVariant
                    : colors.primary,
                fontSize: 12,
                fontWeight: pointsNeeded > 0
                    ? FontWeight.normal
                    : FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Barra de progreso animada
  Widget _buildProgressBar(ColorScheme colors, double progress) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: colors.surfaceVariant,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
          tween: Tween(begin: 0.0, end: progress),
          builder: (context, value, child) {
            return LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(_getLevelColor()),
            );
          },
        ),
      ),
    );
  }

  /// Barra de progreso mini para layout compacto
  Widget _buildProgressBarMini(ColorScheme colors) {
    final nextLevel = stats.level.nextLevel;
    if (nextLevel == null) return const SizedBox.shrink();

    final progress = stats.progressToNextLevel.clamp(0.0, 1.0);

    return Container(
      height: 4,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: colors.surfaceVariant,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation<Color>(_getLevelColor()),
        ),
      ),
    );
  }

  /// Indicador para nivel máximo
  Widget _buildMaxLevelIndicator(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, color: colors.onPrimaryContainer, size: 20),
          const SizedBox(width: 8),
          AutoSizeText(
            '¡Nivel máximo alcanzado!',
            style: TextStyle(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Sección de estadísticas detalladas
  Widget _buildStatsSection(ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        AutoSizeText(
          'Estadísticas',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 12),

        // Grid de estadísticas
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                colors,
                icon: Icons.star_rounded,
                label: 'Valoraciones',
                value: '${stats.ratingsCount}',
              ),
            ),
            Expanded(
              child: _buildStatItem(
                colors,
                icon: Icons.thumb_up_rounded,
                label: 'Promedio',
                value: stats.averageRating.toStringAsFixed(1),
              ),
            ),
            Expanded(
              child: _buildStatItem(
                colors,
                icon: Icons.trending_up_rounded,
                label: 'Cambio',
                value: _getScoreChangeText(),
                valueColor: _getScoreChangeColor(colors),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Item individual de estadística
  Widget _buildStatItem(
    ColorScheme colors, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: colors.primary, size: 24),
        const SizedBox(height: 4),
        AutoSizeText(
          label,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        AutoSizeText(
          value,
          style: TextStyle(
            color: valueColor ?? colors.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ],
    );
  }

  /// Sección de indicador anti-gaming
  Widget _buildAntiGamingSection(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          _buildAntiGamingIndicator(colors, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  'Verificación Anti-Gaming',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                AutoSizeText(
                  'Reputación verificada por nuestros algoritmos',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Indicador visual de anti-gaming
  Widget _buildAntiGamingIndicator(ColorScheme colors, {required double size}) {
    // Usar el status anti-gaming del modelo
    final trustLevel = stats.antiGamingStatus.trustLevel;
    final isHighConfidence = trustLevel == TrustLevel.verified;
    final color = isHighConfidence ? Colors.green : Colors.orange;
    final icon = isHighConfidence ? Icons.verified : Icons.warning_rounded;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1),
      ),
      child: Icon(icon, color: color, size: size * 0.6),
    );
  }

  /// Obtiene el texto del cambio de score
  String _getScoreChangeText() {
    final change = stats.scoreChange;
    if (change == null) return 'N/A';

    if (change > 0) return '+${change.toStringAsFixed(1)}';
    if (change < 0) return change.toStringAsFixed(1);
    return '0.0';
  }

  /// Obtiene el color del cambio de score
  Color _getScoreChangeColor(ColorScheme colors) {
    final change = stats.scoreChange;
    if (change == null) return colors.onSurfaceVariant;

    if (change > 0) return Colors.green;
    if (change < 0) return Colors.red;
    return colors.onSurfaceVariant;
  }
}

/// Widget simplificado solo para mostrar el nivel
class ReputationLevelBadge extends StatelessWidget {
  final ReputationLevel level;
  final double size;
  final bool showLabel;

  const ReputationLevelBadge({
    super.key,
    required this.level,
    this.size = 32,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final hex = level.colorHex.replaceAll('#', '');
    final levelColor = Color(int.parse('FF$hex', radix: 16));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: levelColor,
            boxShadow: [
              BoxShadow(
                color: levelColor.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(level.emoji, style: TextStyle(fontSize: size * 0.5)),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 4),
          AutoSizeText(
            level.displayName,
            style: TextStyle(
              fontSize: size * 0.25,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
