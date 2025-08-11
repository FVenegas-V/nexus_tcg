import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';

/// Botón personalizado con gradiente y estado de carga
/// Utilizado en formularios de autenticación para mantener consistencia visual
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        // Gradiente activo o deshabilitado según el estado
        gradient: onPressed != null
            ? AppColors.buttonGradient
            : LinearGradient(
                colors: [
                  AppColors.textHint.withValues(alpha: 0.5),
                  AppColors.textHint.withValues(alpha: 0.5),
                ],
              ),
        borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          child: Center(
            child: isLoading
                // Indicador de carga
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                // Texto del botón
                : Text(text, style: Theme.of(context).textTheme.labelLarge),
          ),
        ),
      ),
    );
  }
}
