import 'package:flutter/material.dart';

/// Widget para mostrar esqueletos de carga mientras se obtienen datos
class LoadingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const LoadingSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surface;
    final highlightColor = theme.colorScheme.onSurface.withOpacity(0.1);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment(-1 + _animation.value, 0),
              end: Alignment(1 + _animation.value, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// Esqueletos predefinidos para diferentes componentes
class LoadingSkeletons {
  /// Esqueleto para un post card
  static Widget postCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con avatar y usuario
            Row(
              children: [
                const LoadingSkeleton(
                  width: 40,
                  height: 40,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LoadingSkeleton(
                        width: 120,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 4),
                      LoadingSkeleton(
                        width: 80,
                        height: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contenido del post
            LoadingSkeleton(
              width: double.infinity,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            LoadingSkeleton(
              width: 250,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            LoadingSkeleton(
              width: 180,
              height: 16,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 16),

            // Imagen (opcional)
            LoadingSkeleton(
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 16),

            // Footer con reacciones y comentarios
            Row(
              children: [
                LoadingSkeleton(
                  width: 60,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 16),
                LoadingSkeleton(
                  width: 80,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
                const Spacer(),
                LoadingSkeleton(
                  width: 40,
                  height: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Esqueleto para un comentario
  static Widget comment({bool isReply = false}) {
    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 32.0 : 16.0,
        right: 16.0,
        top: 8.0,
        bottom: 8.0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          LoadingSkeleton(
            width: isReply ? 32 : 36,
            height: isReply ? 32 : 36,
            borderRadius: BorderRadius.circular(isReply ? 16 : 18),
          ),
          const SizedBox(width: 12),

          // Contenido
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username y tiempo
                Row(
                  children: [
                    LoadingSkeleton(
                      width: 80,
                      height: 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(width: 8),
                    LoadingSkeleton(
                      width: 60,
                      height: 12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Contenido del comentario
                LoadingSkeleton(
                  width: double.infinity,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                LoadingSkeleton(
                  width: 200,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),

                // Botones de acción
                Row(
                  children: [
                    LoadingSkeleton(
                      width: 50,
                      height: 20,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(width: 16),
                    LoadingSkeleton(
                      width: 70,
                      height: 20,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Lista de esqueletos de posts
  static Widget postsList({int count = 3}) {
    return ListView.builder(
      itemCount: count,
      itemBuilder: (context, index) => postCard(),
    );
  }

  /// Lista de esqueletos de comentarios
  static Widget commentsList({int count = 5}) {
    return ListView.builder(
      itemCount: count,
      itemBuilder: (context, index) {
        // Simular algunos comentarios reply
        final isReply = index % 4 == 2 || index % 4 == 3;
        return comment(isReply: isReply);
      },
    );
  }

  /// Esqueleto simple para texto
  static Widget text({
    double? width,
    double height = 16,
    double? borderRadius,
  }) {
    return LoadingSkeleton(
      width: width ?? 120,
      height: height,
      borderRadius: BorderRadius.circular(borderRadius ?? 4),
    );
  }

  /// Esqueleto para imagen
  static Widget image({double? width, double? height, double? borderRadius}) {
    return LoadingSkeleton(
      width: width ?? double.infinity,
      height: height ?? 200,
      borderRadius: BorderRadius.circular(borderRadius ?? 8),
    );
  }
}
