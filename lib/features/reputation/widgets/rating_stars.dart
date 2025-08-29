import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget para mostrar y permitir seleccionar valoraciones con estrellas
///
/// Características:
/// - Modo de solo lectura y modo interactivo
/// - Soporte para medias estrellas (0.5)
/// - Animaciones fluidas
/// - Colores personalizables
/// - Tamaños configurables
/// - Feedback haptic en selección
class RatingStars extends StatefulWidget {
  /// Valoración actual (1.0 - 5.0)
  final double rating;

  /// Si permite interacción del usuario
  final bool allowHalfRating;

  /// Si es interactivo (permite cambios)
  final bool isInteractive;

  /// Callback cuando cambia la valoración
  final ValueChanged<double>? onRatingChanged;

  /// Tamaño de cada estrella
  final double starSize;

  /// Espaciado entre estrellas
  final double spacing;

  /// Color de las estrellas llenas
  final Color? activeColor;

  /// Color de las estrellas vacías
  final Color? inactiveColor;

  /// Color del borde de las estrellas
  final Color? borderColor;

  /// Si muestra el valor numérico al lado
  final bool showRatingValue;

  /// Formato del texto del valor
  final String? ratingValueFormat;

  /// Si debe animar los cambios
  final bool animated;

  const RatingStars({
    super.key,
    required this.rating,
    this.allowHalfRating = true,
    this.isInteractive = false,
    this.onRatingChanged,
    this.starSize = 24.0,
    this.spacing = 4.0,
    this.activeColor,
    this.inactiveColor,
    this.borderColor,
    this.showRatingValue = false,
    this.ratingValueFormat,
    this.animated = true,
  });

  @override
  State<RatingStars> createState() => _RatingStarsState();
}

class _RatingStarsState extends State<RatingStars>
    with TickerProviderStateMixin {
  double _currentRating = 0.0;
  double _hoverRating = 0.0;
  bool _isHovering = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating.clamp(0.0, 5.0);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(RatingStars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating) {
      setState(() {
        _currentRating = widget.rating.clamp(0.0, 5.0);
      });
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
    final effectiveActiveColor =
        widget.activeColor ?? theme.colorScheme.primary;
    final effectiveInactiveColor =
        widget.inactiveColor ?? theme.colorScheme.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Estrellas
        ...List.generate(
          5,
          (index) =>
              _buildStar(index, effectiveActiveColor, effectiveInactiveColor),
        ),

        // Valor numérico opcional
        if (widget.showRatingValue) ...[
          const SizedBox(width: 8),
          _buildRatingValueText(theme),
        ],
      ],
    );
  }

  /// Construye una estrella individual
  Widget _buildStar(int index, Color activeColor, Color inactiveColor) {
    final starNumber = index + 1;
    final displayRating = _isHovering ? _hoverRating : _currentRating;

    return GestureDetector(
      onTap: widget.isInteractive ? () => _handleStarTap(starNumber) : null,
      onTapDown: widget.isInteractive ? (_) => _animatePress() : null,
      onTapUp: widget.isInteractive ? (_) => _resetAnimation() : null,
      onTapCancel: widget.isInteractive ? _resetAnimation : null,
      child: MouseRegion(
        onEnter: widget.isInteractive
            ? (_) => _handleMouseEnter(starNumber)
            : null,
        onExit: widget.isInteractive ? (_) => _handleMouseExit() : null,
        child: Container(
          padding: EdgeInsets.all(widget.spacing / 2),
          child: widget.animated
              ? AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    final isCurrentStar =
                        _isHovering && _hoverRating >= starNumber;
                    final scale = isCurrentStar ? _scaleAnimation.value : 1.0;

                    return Transform.scale(
                      scale: scale,
                      child: _buildStarIcon(
                        starNumber,
                        displayRating,
                        activeColor,
                        inactiveColor,
                      ),
                    );
                  },
                )
              : _buildStarIcon(
                  starNumber,
                  displayRating,
                  activeColor,
                  inactiveColor,
                ),
        ),
      ),
    );
  }

  /// Construye el icono de la estrella con el color apropiado
  Widget _buildStarIcon(
    int starNumber,
    double displayRating,
    Color activeColor,
    Color inactiveColor,
  ) {
    final difference = displayRating - (starNumber - 1);

    Widget starIcon;

    if (difference >= 1.0) {
      // Estrella completamente llena
      starIcon = Icon(Icons.star, size: widget.starSize, color: activeColor);
    } else if (difference >= 0.5 && widget.allowHalfRating) {
      // Media estrella
      starIcon = _buildHalfStar(activeColor, inactiveColor);
    } else if (difference > 0.0 && difference < 0.5 && widget.allowHalfRating) {
      // Fracción menor que media estrella (mostrar como vacía)
      starIcon = Icon(
        Icons.star_outline,
        size: widget.starSize,
        color: inactiveColor,
      );
    } else {
      // Estrella vacía
      starIcon = Icon(
        Icons.star_outline,
        size: widget.starSize,
        color: inactiveColor,
      );
    }

    // Agregar borde si está especificado
    if (widget.borderColor != null) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: widget.borderColor!, width: 1.0),
        ),
        padding: const EdgeInsets.all(2),
        child: starIcon,
      );
    }

    return starIcon;
  }

  /// Construye una media estrella usando un Stack
  Widget _buildHalfStar(Color activeColor, Color inactiveColor) {
    return SizedBox(
      width: widget.starSize,
      height: widget.starSize,
      child: Stack(
        children: [
          // Estrella vacía como base
          Icon(Icons.star_outline, size: widget.starSize, color: inactiveColor),
          // Media estrella llena
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 0.5,
              child: Icon(
                Icons.star,
                size: widget.starSize,
                color: activeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el texto del valor de la valoración
  Widget _buildRatingValueText(ThemeData theme) {
    final displayRating = _isHovering ? _hoverRating : _currentRating;
    final format = widget.ratingValueFormat ?? '%.1f';

    return Text(
      format.contains('%')
          ? format.replaceFirst(
              RegExp(r'%\.\d+f'),
              displayRating.toStringAsFixed(1),
            )
          : displayRating.toStringAsFixed(1),
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Maneja el tap en una estrella
  void _handleStarTap(int starNumber) {
    double newRating;

    if (widget.allowHalfRating) {
      // Si ya está en esa estrella, alternar entre media y completa
      if (_currentRating == starNumber.toDouble()) {
        newRating = starNumber - 0.5;
      } else if (_currentRating == starNumber - 0.5) {
        newRating = starNumber.toDouble();
      } else {
        newRating = starNumber.toDouble();
      }
    } else {
      newRating = starNumber.toDouble();
    }

    // Permitir "deseleccionar" si ya está en 1 estrella
    if (_currentRating == 1.0 && newRating == 1.0) {
      newRating = 0.0;
    }

    setState(() {
      _currentRating = newRating.clamp(0.0, 5.0);
    });

    widget.onRatingChanged?.call(_currentRating);

    // Feedback háptico
    HapticFeedback.selectionClick();
  }

  /// Maneja cuando el mouse entra en una estrella
  void _handleMouseEnter(int starNumber) {
    setState(() {
      _isHovering = true;
      _hoverRating = starNumber.toDouble();
    });
  }

  /// Maneja cuando el mouse sale del widget
  void _handleMouseExit() {
    setState(() {
      _isHovering = false;
      _hoverRating = 0.0;
    });
  }

  /// Anima el press de una estrella
  void _animatePress() {
    _animationController.forward();
  }

  /// Resetea la animación
  void _resetAnimation() {
    _animationController.reverse();
  }
}

/// Widget simplificado para mostrar solo la valoración (sin interacción)
class RatingDisplay extends StatelessWidget {
  final double rating;
  final double starSize;
  final bool showValue;
  final Color? color;
  final int? maxStars;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.starSize = 16.0,
    this.showValue = true,
    this.color,
    this.maxStars = 5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingStars(
          rating: rating,
          starSize: starSize,
          spacing: 2.0,
          activeColor: effectiveColor,
          inactiveColor: effectiveColor.withOpacity(0.3),
          showRatingValue: false,
          animated: false,
        ),
        if (showValue) ...[
          const SizedBox(width: 6),
          Text(
            '${rating.toStringAsFixed(1)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget para el selector de valoración con título y descripción
class RatingSelector extends StatelessWidget {
  final String title;
  final String? description;
  final double currentRating;
  final ValueChanged<double> onRatingChanged;
  final bool allowHalfRating;
  final double starSize;
  final bool required;

  const RatingSelector({
    super.key,
    required this.title,
    this.description,
    required this.currentRating,
    required this.onRatingChanged,
    this.allowHalfRating = true,
    this.starSize = 32.0,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Row(
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 16),
              ),
            ],
          ],
        ),

        // Descripción opcional
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        const SizedBox(height: 12),

        // Selector de estrellas
        Row(
          children: [
            RatingStars(
              rating: currentRating,
              isInteractive: true,
              allowHalfRating: allowHalfRating,
              onRatingChanged: onRatingChanged,
              starSize: starSize,
              spacing: 8.0,
              showRatingValue: true,
              animated: true,
            ),
            const Spacer(),
            // Texto descriptivo de la valoración
            _buildRatingDescription(theme),
          ],
        ),
      ],
    );
  }

  /// Construye la descripción textual de la valoración
  Widget _buildRatingDescription(ThemeData theme) {
    String description;
    Color color;

    if (currentRating >= 4.5) {
      description = 'Excelente';
      color = Colors.green;
    } else if (currentRating >= 3.5) {
      description = 'Muy bueno';
      color = Colors.lightGreen;
    } else if (currentRating >= 2.5) {
      description = 'Bueno';
      color = Colors.orange;
    } else if (currentRating >= 1.5) {
      description = 'Regular';
      color = Colors.deepOrange;
    } else if (currentRating >= 0.5) {
      description = 'Malo';
      color = Colors.red;
    } else {
      description = 'Sin valorar';
      color = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        description,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Widget compacto para mostrar el promedio y número de valoraciones
class RatingSummary extends StatelessWidget {
  final double averageRating;
  final int totalRatings;
  final double starSize;
  final bool showDistribution;
  final VoidCallback? onTap;

  const RatingSummary({
    super.key,
    required this.averageRating,
    required this.totalRatings,
    this.starSize = 18.0,
    this.showDistribution = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Estrellas y promedio
            RatingDisplay(
              rating: averageRating,
              starSize: starSize,
              showValue: true,
            ),

            const SizedBox(width: 8),

            // Número de valoraciones
            Text(
              '($totalRatings)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            // Flecha si es clickeable
            if (onTap != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
