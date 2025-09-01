import 'package:flutter/material.dart';

/// Paleta de colores de la aplicación Nexus TCG
class AppColors {
  // Colores principales basados en el mockup
  static const Color primaryRed = Color(0xFFE74C3C);
  static const Color secondaryOrange = Color(0xFFF39C12);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;

  // Colores de texto
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textHint = Color(0xFF95A5A6);

  // Colores de estado
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color successGreen = Color(0xFF27AE60);

  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryRed, secondaryOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF8B1E1E), Color(0xFFF08A8A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

/// Constantes globales de la aplicación
class AppConstants {
  // Configuración de la aplicación
  static const String appName = 'Nexus TCG';
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Valores de diseño
  static const double borderRadius = 16.0;
  static const double buttonBorderRadius = 25.0;
  static const double cardElevation = 8.0;

  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(24.0);
}
