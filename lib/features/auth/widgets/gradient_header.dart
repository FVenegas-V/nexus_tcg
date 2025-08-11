import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Widget de encabezado con gradiente para las pantallas de autenticación
/// Muestra el logo y nombre de la aplicación sobre un fondo degradado
class GradientHeader extends StatelessWidget {
  const GradientHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono temporal del logo (reemplazar con imagen real)
              Icon(Icons.diamond, size: 40, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
