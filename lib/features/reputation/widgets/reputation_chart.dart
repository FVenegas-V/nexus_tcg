import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/reputation_stats.dart';

extension ListExtension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Widget para mostrar gráficos de reputación
///
/// Características:
/// - Gráfico de línea de evolución temporal
/// - Gráfico de barras de factores
/// - Gráfico circular de distribución
/// - Animaciones suaves
/// - Diseño responsive
class ReputationChart extends StatefulWidget {
  /// Estadísticas de reputación
  final ReputationStats stats;

  /// Tipo de gráfico a mostrar
  final ChartType type;

  /// Altura del gráfico
  final double height;

  /// Si se debe mostrar la leyenda
  final bool showLegend;

  /// Si se debe animar el gráfico
  final bool animate;

  /// Período de tiempo para el gráfico de evolución
  final Duration period;

  /// Callback cuando se toca una barra (recibe el rating 1-5)
  // final Function(int rating)? onBarTap; // ELIMINADO - No necesario

  const ReputationChart({
    super.key,
    required this.stats,
    this.type = ChartType.line,
    this.height = 200.0,
    this.showLegend = true,
    this.animate = true,
    this.period = const Duration(days: 30),
    // this.onBarTap, // ELIMINADO
  });

  @override
  State<ReputationChart> createState() => _ReputationChartState();
}

class _ReputationChartState extends State<ReputationChart>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (widget.animate) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Si showLegend es false, renderizar solo el gráfico sin card
    if (!widget.showLegend) {
      return SizedBox(
        height: widget.height,
        width: double.infinity,
        child: widget.animate
            ? AnimatedBuilder(
                animation: _animation,
                builder: (context, child) => _buildChart(theme),
              )
            : _buildChart(theme),
      );
    }

    // Versión completa con card y leyenda
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            SizedBox(
              height: widget.height,
              child: widget.animate
                  ? AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) => _buildChart(theme),
                    )
                  : _buildChart(theme),
            ),
            if (widget.showLegend) ...[
              const SizedBox(height: 16),
              _buildLegend(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(_getChartIcon(), color: theme.colorScheme.primary, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _getChartTitle(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildTypeSelector(theme),
      ],
    );
  }

  Widget _buildTypeSelector(ThemeData theme) {
    return SegmentedButton<ChartType>(
      segments: const [
        ButtonSegment(
          value: ChartType.line,
          icon: Icon(Icons.show_chart, size: 18),
          label: Text('Línea'),
        ),
        ButtonSegment(
          value: ChartType.bar,
          icon: Icon(Icons.bar_chart, size: 18),
          label: Text('Barras'),
        ),
        ButtonSegment(
          value: ChartType.pie,
          icon: Icon(Icons.pie_chart, size: 18),
          label: Text('Circular'),
        ),
      ],
      selected: {widget.type},
      onSelectionChanged: (Set<ChartType> newSelection) {
        // Esta funcionalidad se implementaría en el widget padre
        // para cambiar el tipo de gráfico
      },
      style: SegmentedButton.styleFrom(
        textStyle: theme.textTheme.labelSmall,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildChart(ThemeData theme) {
    switch (widget.type) {
      case ChartType.line:
        return _buildLineChart(theme);
      case ChartType.bar:
        return _buildBarChart(theme);
      case ChartType.pie:
        return _buildPieChart(theme);
    }
  }

  Widget _buildLineChart(ThemeData theme) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: widget.stats.totalScore > 0
              ? (widget.stats.totalScore / 4).clamp(2.0, 20.0)
              : 5.0,
          verticalInterval: 1, // Una línea por valoración
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outlineVariant,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: theme.colorScheme.outlineVariant,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 35,
              interval: 1, // Mostrar cada valoración
              getTitlesWidget: (value, meta) {
                return _buildBottomTitle(value.toInt(), theme);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: widget.stats.totalScore > 0
                  ? (widget.stats.totalScore / 4).clamp(2.0, 20.0)
                  : 5.0,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return _buildLeftTitle(value.toInt(), theme);
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: theme.colorScheme.outline, width: 1),
        ),
        minX: 0,
        maxX: widget.stats.ratingsCount > 0
            ? widget.stats.ratingsCount.toDouble()
            : 1.0,
        minY: 0,
        maxY: widget.stats.totalScore > 0
            ? (widget.stats.totalScore * 1.2).clamp(5.0, 100.0)
            : 5.0,
        lineBarsData: [
          LineChartBarData(
            spots: _generateLineSpots(),
            isCurved: false, // Línea recta para mostrar mejor los escalones
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
              ],
            ),
            barWidth: 3 * _animation.value,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4 * _animation.value,
                  color: theme.colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withOpacity(0.3 * _animation.value),
                  theme.colorScheme.primary.withOpacity(0.1 * _animation.value),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(ThemeData theme) {
    // Crear gráfico de distribución de valoraciones (1-5 estrellas)
    final ratingDistribution = widget.stats.ratingDistribution;
    final totalRatings = widget.stats.ratingsCount;

    // Si no hay valoraciones, mostrar mensaje
    if (totalRatings == 0) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star_border,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                'Aún no hay valoraciones',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Las valoraciones aparecerán aquí',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxBarValue(ratingDistribution).toDouble(),
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            // Solo tooltip, sin tap callback
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: theme.colorScheme.inverseSurface,
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final rating = groupIndex + 1; // 1-5 estrellas
                final count = ratingDistribution[rating.toString()] ?? 0;
                final percentage = totalRatings > 0
                    ? (count / totalRatings * 100)
                    : 0.0;

                return BarTooltipItem(
                  '$rating ⭐\n$count valoración${count != 1 ? 'es' : ''}\n${percentage.toStringAsFixed(1)}%',
                  TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                getTitlesWidget: (value, meta) {
                  final rating = (value.toInt() + 1);
                  if (rating >= 1 && rating <= 5) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '$rating⭐',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: _getLeftInterval(ratingDistribution),
                getTitlesWidget: (value, meta) {
                  if (value == 0 ||
                      value % _getLeftInterval(ratingDistribution) == 0) {
                    return Text(
                      '${value.toInt()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.5),
              width: 1,
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _getLeftInterval(ratingDistribution),
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
                strokeWidth: 1,
              );
            },
          ),
          barGroups: _generateRatingBars(ratingDistribution, theme),
        ),
      ),
    );
  }

  List<BarChartGroupData> _generateRatingBars(
    Map<String, int> distribution,
    ThemeData theme,
  ) {
    final bars = <BarChartGroupData>[];

    // Colores más atractivos para cada nivel de valoración
    final colors = [
      Colors.redAccent, // 1 estrella
      Colors.deepOrangeAccent, // 2 estrellas
      Colors.amberAccent, // 3 estrellas
      Colors.lightGreenAccent.shade400, // 4 estrellas
      Colors.green, // 5 estrellas
    ];

    for (int i = 1; i <= 5; i++) {
      final count = distribution[i.toString()] ?? 0;

      bars.add(
        BarChartGroupData(
          x: i - 1, // Índice 0-4 para posición
          barRods: [
            BarChartRodData(
              toY: count.toDouble() * _animation.value,
              color: colors[i - 1],
              width: 28, // Ancho ligeramente mayor
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
              // Gradiente sutil para las barras
              gradient: LinearGradient(
                colors: [colors[i - 1], colors[i - 1].withOpacity(0.8)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              // Agregar sombra cuando la barra tiene valor
              borderSide: count > 0
                  ? BorderSide(
                      color: colors[i - 1].withOpacity(0.6),
                      width: 0.5,
                    )
                  : BorderSide.none,
            ),
          ],
        ),
      );
    }

    return bars;
  }

  int _getMaxBarValue(Map<String, int> distribution) {
    if (distribution.isEmpty) return 5;

    final maxValue = distribution.values.isEmpty
        ? 1
        : distribution.values.reduce((a, b) => a > b ? a : b);

    // Agregar un poco de espacio arriba
    return (maxValue + (maxValue * 0.2).ceil()).clamp(1, 100);
  }

  double _getLeftInterval(Map<String, int> distribution) {
    final maxValue = _getMaxBarValue(distribution);

    if (maxValue <= 5) return 1.0;
    if (maxValue <= 10) return 2.0;
    if (maxValue <= 20) return 5.0;
    return 10.0;
  }

  Widget _buildPieChart(ThemeData theme) {
    final factors = widget.stats.breakdown.factors;
    final positiveFactors = factors.where((f) => f.value > 0).toList();

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // Manejar interacciones táctiles si es necesario
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: _generatePieSections(positiveFactors, theme),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    switch (widget.type) {
      case ChartType.line:
        return _buildLineLegend(theme);
      case ChartType.bar:
        return _buildBarLegend(theme);
      case ChartType.pie:
        return _buildPieLegend(theme);
    }
  }

  Widget _buildLineLegend(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Evolución de Reputación (últimos ${widget.period.inDays} días)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBarLegend(ThemeData theme) {
    final factors = widget.stats.breakdown.factors;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: factors.map((factor) {
        final color = Color(
          int.parse(factor.colorHex.substring(1), radix: 16) + 0xFF000000,
        );
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              factor.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPieLegend(ThemeData theme) {
    final factors = widget.stats.breakdown.factors;
    final positiveFactors = factors.where((f) => f.value > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: positiveFactors.map((factor) {
        final color = Color(
          int.parse(factor.colorHex.substring(1), radix: 16) + 0xFF000000,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(factor.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  factor.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                factor.displayValue,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomTitle(int value, ThemeData theme) {
    // Mostrar etiquetas basadas en número de valoraciones
    if (value == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'Sin valoraciones',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 9,
          ),
        ),
      );
    }

    // Para usuarios con valoraciones, mostrar el número
    if (value <= widget.stats.ratingsCount) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          '$value valoración${value > 1 ? 'es' : ''}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 9,
          ),
        ),
      );
    }

    return const Text('');
  }

  Widget _buildLeftTitle(int value, ThemeData theme) {
    return Text(
      value.toString(),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  List<FlSpot> _generateLineSpots() {
    final currentScore = widget.stats.totalScore;
    final ratingsCount = widget.stats.ratingsCount;
    final spots = <FlSpot>[];

    // Si no hay valoraciones, mostrar línea plana en 0
    if (ratingsCount == 0) {
      spots.add(FlSpot(0.0, 0.0));
      spots.add(FlSpot(1.0, 0.0));
      return spots;
    }

    // Crear evolución basada en número de valoraciones (no en días)
    // Cada punto X representa una valoración recibida

    // Empezar desde 0 valoraciones
    spots.add(FlSpot(0.0, 0.0));

    // Agregar un punto por cada valoración
    final scorePerRating = currentScore / ratingsCount;

    for (int i = 1; i <= ratingsCount; i++) {
      final accumulatedScore = scorePerRating * i;
      spots.add(FlSpot(i.toDouble(), accumulatedScore));
    }

    return spots;
  }

  List<PieChartSectionData> _generatePieSections(
    List<ReputationFactor> factors,
    ThemeData theme,
  ) {
    final total = factors.fold(0.0, (sum, factor) => sum + factor.value);

    return factors.asMap().entries.map((entry) {
      final factor = entry.value;
      final percentage = (factor.value / total) * 100;
      final color = Color(
        int.parse(factor.colorHex.substring(1), radix: 16) + 0xFF000000,
      );

      return PieChartSectionData(
        color: color,
        value: factor.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 50 * _animation.value,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: _getContrastColor(color),
        ),
      );
    }).toList();
  }

  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  IconData _getChartIcon() {
    switch (widget.type) {
      case ChartType.line:
        return Icons.show_chart;
      case ChartType.bar:
        return Icons.bar_chart;
      case ChartType.pie:
        return Icons.pie_chart;
    }
  }

  String _getChartTitle() {
    switch (widget.type) {
      case ChartType.line:
        return 'Evolución de Reputación';
      case ChartType.bar:
        return 'Factores de Reputación';
      case ChartType.pie:
        return 'Distribución de Factores';
    }
  }
}

/// Tipos de gráfico disponibles
enum ChartType { line, bar, pie }

/// Widget simplificado para mostrar gráficos rápidos
class QuickReputationChart extends StatelessWidget {
  final ReputationStats stats;
  final double height;
  final ChartType type;

  const QuickReputationChart({
    super.key,
    required this.stats,
    this.height = 120,
    this.type = ChartType.line,
  });

  @override
  Widget build(BuildContext context) {
    return ReputationChart(
      stats: stats,
      type: type,
      height: height,
      showLegend: false,
      animate: false,
    );
  }
}
