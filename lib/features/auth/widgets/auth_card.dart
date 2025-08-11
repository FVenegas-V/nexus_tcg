import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Widget de tarjeta para formularios de autenticación
/// Proporciona un contenedor consistente con título, subtítulo opcional y contenido
class AuthCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const AuthCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.cardElevation,
      margin: AppConstants.defaultPadding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título principal de la tarjeta
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            // Subtítulo opcional
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            // Contenido del formulario
            child,
          ],
        ),
      ),
    );
  }
}
