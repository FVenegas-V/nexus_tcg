import 'package:flutter/material.dart';

/// Widget del logo de Nexus TCG que puede usarse en toda la aplicación
class NexusLogo extends StatelessWidget {
  final double size;
  final Color? iconColor;

  const NexusLogo({super.key, this.size = 40, this.iconColor});

  @override
  Widget build(BuildContext context) {
    // Intentar cargar la imagen real del logo
    return Image.asset(
      'assets/icons/nexus_tcg_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback al ícono si la imagen no se carga
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: iconColor ?? Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.diamond,
            size: size * 0.6,
            color: iconColor ?? Colors.white,
          ),
        );
      },
    );
  }
}

/// Widget específico para mostrar solo el ícono de la carta
class NexusCardIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const NexusCardIcon({super.key, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFFF6B6B), // Color coral
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(Icons.diamond, size: size * 0.4, color: Colors.white),
    );
  }
}
