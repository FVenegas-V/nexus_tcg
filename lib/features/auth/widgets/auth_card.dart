import 'package:flutter/material.dart';
import '../../../core/widgets/nexus_logo.dart';

/// Widget de tarjeta para formularios de autenticación
/// Proporciona un contenedor consistente con título, subtítulo opcional y contenido
class AuthCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool showLogo;

  const AuthCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16, // Menos margin horizontal para tarjeta más ancha
        0, // Sin margin negativo para evitar el error
        16,
        24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Bordes más redondeados
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32), // Más padding interno
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo opcional en la parte superior de la tarjeta
            if (showLogo) ...[
              const Center(
                child: NexusLogo(size: 100), // Logo grande en la tarjeta
              ),
              const SizedBox(height: 24),
            ],
            // Título principal de la tarjeta
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(
                  0xFF2D3748,
                ), // Color más oscuro para mejor contraste
              ),
              textAlign: TextAlign.center,
            ),
            // Subtítulo opcional
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF718096), // Color gris para subtítulo
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32), // Más espacio antes del contenido
            // Contenido del formulario
            child,
          ],
        ),
      ),
    );
  }
}
