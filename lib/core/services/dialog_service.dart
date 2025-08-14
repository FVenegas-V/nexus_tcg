import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Servicio para mostrar diálogos de confirmación y alertas
/// Proporciona métodos reutilizables para acciones críticas
class DialogService {
  /// Muestra un diálogo de confirmación estándar
  ///
  /// [context] Contexto de la aplicación
  /// [title] Título del diálogo
  /// [content] Contenido del mensaje
  /// [confirmText] Texto del botón de confirmación (default: "Confirmar")
  /// [cancelText] Texto del botón de cancelar (default: "Cancelar")
  /// [isDestructive] Si la acción es destructiva (botón rojo)
  ///
  /// Retorna true si el usuario confirma, false si cancela
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool isDestructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: Text(content, style: const TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  cancelText,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDestructive
                      ? Colors.red
                      : AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  confirmText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Muestra un diálogo de confirmación para cerrar sesión
  static Future<bool> showLogoutConfirmDialog(BuildContext context) {
    return showConfirmDialog(
      context: context,
      title: 'Cerrar Sesión',
      content: '¿Estás seguro de que quieres cerrar sesión?',
      confirmText: 'Cerrar Sesión',
      isDestructive: true,
    );
  }

  /// Muestra un diálogo de confirmación para eliminar cuenta
  static Future<bool> showDeleteAccountDialog(BuildContext context) {
    return showConfirmDialog(
      context: context,
      title: 'Eliminar Cuenta',
      content:
          'Esta acción es irreversible. ¿Estás seguro de que quieres eliminar tu cuenta permanentemente?',
      confirmText: 'Eliminar',
      isDestructive: true,
    );
  }

  /// Muestra un diálogo de confirmación para descartar cambios
  static Future<bool> showDiscardChangesDialog(BuildContext context) {
    return showConfirmDialog(
      context: context,
      title: 'Descartar Cambios',
      content: '¿Estás seguro de que quieres salir sin guardar los cambios?',
      confirmText: 'Descartar',
      isDestructive: true,
    );
  }

  /// Muestra un diálogo de confirmación para eliminar contenido
  static Future<bool> showDeleteContentDialog({
    required BuildContext context,
    required String contentType,
    String? additionalInfo,
  }) {
    final content = additionalInfo != null
        ? '¿Estás seguro de que quieres eliminar este $contentType? $additionalInfo'
        : '¿Estás seguro de que quieres eliminar este $contentType?';

    return showConfirmDialog(
      context: context,
      title: 'Eliminar $contentType',
      content: content,
      confirmText: 'Eliminar',
      isDestructive: true,
    );
  }

  /// Muestra un diálogo informativo
  static void showInfoDialog({
    required BuildContext context,
    required String title,
    required String content,
    String buttonText = 'Entendido',
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(content, style: const TextStyle(fontSize: 16)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de éxito
  static void showSuccessDialog({
    required BuildContext context,
    required String title,
    required String content,
    String buttonText = 'Continuar',
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.green.shade700, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(content, style: const TextStyle(fontSize: 16)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onPressed?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de error
  static void showErrorDialog({
    required BuildContext context,
    required String title,
    required String content,
    String buttonText = 'Cerrar',
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(content, style: const TextStyle(fontSize: 16)),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onPressed?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Muestra un bottom sheet con opciones
  static void showOptionsBottomSheet({
    required BuildContext context,
    required String title,
    required List<BottomSheetOption> options,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),

            // Opciones
            ...options.map(
              (option) => ListTile(
                leading: Icon(
                  option.icon,
                  color: option.isDestructive
                      ? Colors.red
                      : AppColors.primaryRed,
                ),
                title: Text(
                  option.title,
                  style: TextStyle(
                    color: option.isDestructive
                        ? Colors.red
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: option.subtitle != null
                    ? Text(option.subtitle!)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  option.onTap();
                },
              ),
            ),

            // Cancelar
            const Divider(),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.grey),
              title: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey),
              ),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opción para bottom sheet
class BottomSheetOption {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const BottomSheetOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.isDestructive = false,
  });
}
