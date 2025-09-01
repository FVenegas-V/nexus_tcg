import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Widget de encabezado con gradiente para las pantallas de autenticación
/// Muestra el logo y nombre de la aplicación sobre un fondo degradado
class GradientHeader extends StatelessWidget {
  const GradientHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtener el tamaño de la pantalla para proporciones correctas
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight =
        screenHeight * 0.35; // Aumentamos un poco para que sea solo fondo

    return Container(
      height: headerHeight,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      // Solo el fondo naranja, sin contenido
    );
  }
}
