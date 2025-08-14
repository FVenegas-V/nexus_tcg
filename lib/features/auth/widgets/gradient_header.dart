import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/nexus_logo.dart';

/// Widget de encabezado con gradiente para las pantallas de autenticación
/// Muestra el logo y nombre de la aplicación sobre un fondo degradado
class GradientHeader extends StatelessWidget {
  const GradientHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener el tamaño de la pantalla para proporciones correctas
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight =
        screenHeight * 0.4; // Un poco más de altura para el efecto

    return Container(
      height: headerHeight,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo de Nexus TCG con tamaño prominente
              const NexusLogo(size: 60),
              const SizedBox(height: 8),
              // Texto del logo como en el mockup
              const Text(
                'NEXUS\nTCG',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
