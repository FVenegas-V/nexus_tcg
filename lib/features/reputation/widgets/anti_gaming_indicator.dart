import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../models/reputation_stats.dart';

/// Widget para mostrar indicadores del sistema anti-gaming
///
/// Muestra:
/// - Nivel de confianza de la reputación
/// - Indicadores de seguridad
/// - Tooltips explicativos
/// - Estados visuales claros
/// - Información de transparencia
class AntiGamingIndicator extends StatelessWidget {
  /// Estado anti-gaming del usuario
  final AntiGamingStatus status;

  /// Tamaño del indicador
  final double size;

  /// Si se debe mostrar el texto explicativo
  final bool showLabel;

  /// Si se debe mostrar información detallada en tooltip
  final bool showTooltip;

  /// Estilo de presentación
  final AntiGamingDisplayStyle style;

  /// Callback cuando se toca el indicador
  final VoidCallback? onTap;

  const AntiGamingIndicator({
    super.key,
    required this.status,
    this.size = 24.0,
    this.showLabel = true,
    this.showTooltip = true,
    this.style = AntiGamingDisplayStyle.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case AntiGamingDisplayStyle.badge:
        return _buildBadgeStyle(context);
      case AntiGamingDisplayStyle.chip:
        return _buildChipStyle(context);
      case AntiGamingDisplayStyle.card:
        return _buildCardStyle(context);
      case AntiGamingDisplayStyle.icon:
        return _buildIconStyle(context);
    }
  }

  /// Estilo de badge simple
  Widget _buildBadgeStyle(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getStatusColors(theme.colorScheme);

    Widget badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.backgroundColor,
        border: Border.all(color: colors.borderColor, width: 1.5),
      ),
      child: Icon(colors.icon, color: colors.iconColor, size: size * 0.6),
    );

    if (showTooltip) {
      badge = Tooltip(message: _getTooltipMessage(), child: badge);
    }

    if (onTap != null) {
      badge = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: badge,
      );
    }

    if (!showLabel) return badge;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(width: 8),
        AutoSizeText(
          _getStatusText(),
          style: TextStyle(
            color: colors.textColor,
            fontWeight: FontWeight.w600,
            fontSize: size * 0.5,
          ),
          maxLines: 1,
        ),
      ],
    );
  }

  /// Estilo de chip
  Widget _buildChipStyle(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getStatusColors(theme.colorScheme);

    Widget chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.4,
        vertical: size * 0.2,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: colors.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(colors.icon, color: colors.iconColor, size: size * 0.6),
          if (showLabel) ...[
            SizedBox(width: size * 0.2),
            AutoSizeText(
              _getStatusText(),
              style: TextStyle(
                color: colors.textColor,
                fontWeight: FontWeight.w600,
                fontSize: size * 0.5,
              ),
              maxLines: 1,
            ),
          ],
        ],
      ),
    );

    if (showTooltip) {
      chip = Tooltip(message: _getTooltipMessage(), child: chip);
    }

    if (onTap != null) {
      chip = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: chip,
      );
    }

    return chip;
  }

  /// Estilo de tarjeta expandida
  Widget _buildCardStyle(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getStatusColors(theme.colorScheme);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.borderColor, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(colors.icon, color: colors.iconColor, size: 20),
                  const SizedBox(width: 8),
                  AutoSizeText(
                    'Verificación Anti-Gaming',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: AutoSizeText(
                  _getStatusText(),
                  style: TextStyle(
                    color: colors.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Descripción
              AutoSizeText(
                _getStatusDescription(),
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
                maxLines: 2,
              ),

              // Métricas de confianza
              if ((1.0 - status.suspicionScore) > 0) ...[
                const SizedBox(height: 8),
                _buildConfidenceBar(theme.colorScheme, colors),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Estilo de solo icono
  Widget _buildIconStyle(BuildContext context) {
    final theme = Theme.of(context);
    final colors = _getStatusColors(theme.colorScheme);

    Widget icon = Icon(colors.icon, color: colors.iconColor, size: size);

    if (showTooltip) {
      icon = Tooltip(message: _getTooltipMessage(), child: icon);
    }

    if (onTap != null) {
      icon = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: icon,
      );
    }

    return icon;
  }

  /// Construye la barra de confianza
  Widget _buildConfidenceBar(ColorScheme colorScheme, _StatusColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AutoSizeText(
              'Confianza',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            AutoSizeText(
              '${((1.0 - status.suspicionScore) * 100).toInt()}%',
              style: TextStyle(
                color: colors.textColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: colorScheme.surfaceVariant,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: 1.0 - status.suspicionScore,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(colors.iconColor),
            ),
          ),
        ),
      ],
    );
  }

  /// Obtiene los colores según el nivel de confianza
  _StatusColors _getStatusColors(ColorScheme colorScheme) {
    switch (status.trustLevel) {
      case TrustLevel.verified:
        return _StatusColors(
          backgroundColor: Colors.green.withOpacity(0.1),
          borderColor: Colors.green,
          iconColor: Colors.green,
          textColor: Colors.green.shade700,
          icon: Icons.verified,
        );

      case TrustLevel.trusted:
        return _StatusColors(
          backgroundColor: Colors.blue.withOpacity(0.1),
          borderColor: Colors.blue,
          iconColor: Colors.blue,
          textColor: Colors.blue.shade700,
          icon: Icons.check_circle,
        );

      case TrustLevel.neutral:
        return _StatusColors(
          backgroundColor: Colors.orange.withOpacity(0.1),
          borderColor: Colors.orange,
          iconColor: Colors.orange,
          textColor: Colors.orange.shade700,
          icon: Icons.warning,
        );

      case TrustLevel.suspicious:
        return _StatusColors(
          backgroundColor: Colors.red.withOpacity(0.1),
          borderColor: Colors.red,
          iconColor: Colors.red,
          textColor: Colors.red.shade700,
          icon: Icons.error,
        );

      case TrustLevel.flagged:
        return _StatusColors(
          backgroundColor: Colors.red.shade900.withOpacity(0.1),
          borderColor: Colors.red.shade900,
          iconColor: Colors.red.shade900,
          textColor: Colors.red.shade900,
          icon: Icons.block,
        );

      case TrustLevel.unknown:
        return _StatusColors(
          backgroundColor: colorScheme.surfaceVariant,
          borderColor: colorScheme.outline,
          iconColor: colorScheme.onSurfaceVariant,
          textColor: colorScheme.onSurfaceVariant,
          icon: Icons.help_outline,
        );
    }
  }

  /// Obtiene el texto del estado
  String _getStatusText() {
    switch (status.trustLevel) {
      case TrustLevel.verified:
        return 'Verificado';
      case TrustLevel.trusted:
        return 'Confiable';
      case TrustLevel.neutral:
        return 'Neutral';
      case TrustLevel.suspicious:
        return 'Sospechoso';
      case TrustLevel.flagged:
        return 'Marcado';
      case TrustLevel.unknown:
        return 'Desconocido';
    }
  }

  /// Obtiene la descripción del estado
  String _getStatusDescription() {
    switch (status.trustLevel) {
      case TrustLevel.verified:
        return 'Reputación completamente verificada por nuestros algoritmos.';
      case TrustLevel.trusted:
        return 'Usuario confiable con historial consistente.';
      case TrustLevel.neutral:
        return 'Usuario con historial neutral, sin patrones destacables.';
      case TrustLevel.suspicious:
        return 'Actividad sospechosa detectada.';
      case TrustLevel.flagged:
        return 'Usuario marcado por múltiples infracciones.';
      case TrustLevel.unknown:
        return 'Información insuficiente para evaluar.';
    }
  }

  /// Obtiene el mensaje del tooltip
  String _getTooltipMessage() {
    final baseMessage = _getStatusDescription();
    final confidence = ((1.0 - status.suspicionScore) * 100).toInt();

    String details = '';
    if (status.flags.isNotEmpty) {
      details = '\n\nFactores detectados:\n${status.flags.join('\n')}';
    }

    return '$baseMessage\n\nNivel de confianza: $confidence%$details';
  }
}

/// Estilos de presentación disponibles
enum AntiGamingDisplayStyle {
  badge, // Badge circular con icono
  chip, // Chip con icono y texto
  card, // Tarjeta expandida con detalles
  icon, // Solo icono
}

/// Clase auxiliar para colores del estado
class _StatusColors {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final IconData icon;

  const _StatusColors({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    required this.icon,
  });
}

/// Widget simplificado para mostrar solo el nivel de confianza
class TrustLevelBadge extends StatelessWidget {
  final TrustLevel trustLevel;
  final double size;

  const TrustLevelBadge({
    super.key,
    required this.trustLevel,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    // Crear un status temporal para usar los colores
    final tempStatus = AntiGamingStatus(
      trustLevel: trustLevel,
      suspicionScore: 0.2, // Equivalente a 0.8 de confianza
      flags: [],
      isUnderReview: false,
    );

    return AntiGamingIndicator(
      status: tempStatus,
      size: size,
      showLabel: false,
      showTooltip: false,
      style: AntiGamingDisplayStyle.icon,
    );
  }
}

/// Widget para mostrar un resumen de seguridad
class SecuritySummary extends StatelessWidget {
  final AntiGamingStatus status;
  final bool showDetails;
  final VoidCallback? onViewDetails;

  const SecuritySummary({
    super.key,
    required this.status,
    this.showDetails = false,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.security, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              AutoSizeText(
                'Seguridad y Transparencia',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (onViewDetails != null)
                TextButton(
                  onPressed: onViewDetails,
                  child: const Text('Ver detalles'),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Estado principal
          AntiGamingIndicator(
            status: status,
            style: AntiGamingDisplayStyle.chip,
            showTooltip: false,
          ),

          // Detalles adicionales
          if (showDetails) ...[
            const SizedBox(height: 12),
            _buildSecurityDetails(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildSecurityDetails(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Puntaje de confianza
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AutoSizeText(
              'Nivel de confianza:',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            AutoSizeText(
              '${((1.0 - status.suspicionScore) * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Barra de progreso
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: theme.colorScheme.surfaceVariant,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: 1.0 - status.suspicionScore,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(_getConfidenceColor()),
            ),
          ),
        ),

        // Factores de riesgo
        if (status.flags.isNotEmpty) ...[
          const SizedBox(height: 12),
          AutoSizeText(
            'Factores considerados:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          ...status.flags
              .take(3)
              .map(
                (factor) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AutoSizeText(
                          factor,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],

        // Estado de revisión
        if (status.isUnderReview) ...[
          const SizedBox(height: 8),
          AutoSizeText(
            'En revisión por el sistema',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Color _getConfidenceColor() {
    final confidence = 1.0 - status.suspicionScore;
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
