// lib/widgets/notifications/notification_toast.dart

import 'package:flutter/material.dart';
import '../../core/models/notification_model.dart';

/// Widget para mostrar notificaciones emergentes tipo toast/snackbar
/// Fase 5-0003: Notificaciones emergentes cuando llegan nuevas
class NotificationToast {
  /// Muestra una notificación emergente usando SnackBar
  static void showSnackBar(
    BuildContext context,
    NotificationModel notification, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
    VoidCallback? onActionPressed,
    String? actionLabel,
  }) {
    final theme = Theme.of(context);
    final typeColor = Color(
      int.parse(notification.colorHex.substring(1), radix: 16) + 0xFF000000,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: theme.colorScheme.surface,
        content: GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              // Icono del tipo
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: typeColor,
                  size: 16,
                ),
              ),

              const SizedBox(width: 12),

              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      notification.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        action: onActionPressed != null && actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onActionPressed,
                textColor: typeColor,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: typeColor.withOpacity(0.2)),
        ),
      ),
    );
  }

  /// Muestra un banner persistente en la parte superior
  static void showBanner(
    BuildContext context,
    NotificationModel notification, {
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    final theme = Theme.of(context);
    final typeColor = Color(
      int.parse(notification.colorHex.substring(1), radix: 16) + 0xFF000000,
    );

    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Icon(
                _getNotificationIcon(notification.type),
                color: typeColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      notification.message,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: typeColor.withOpacity(0.1),
        actions: [
          if (onTap != null)
            TextButton(onPressed: onTap, child: const Text('Ver')),
          TextButton(
            onPressed:
                onDismiss ??
                () {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                },
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  static IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'new_post':
        return Icons.post_add;
      case 'new_comment':
        return Icons.comment;
      case 'post_reaction':
        return Icons.favorite;
      case 'security_alert':
        return Icons.security;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }
}

/// Widget overlay para notificaciones emergentes personalizadas
class NotificationOverlay extends StatefulWidget {
  final NotificationModel notification;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationOverlay({
    Key? key,
    required this.notification,
    this.duration = const Duration(seconds: 5),
    this.onTap,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<NotificationOverlay> createState() => _NotificationOverlayState();

  /// Muestra el overlay en la pantalla
  static void show(
    BuildContext context,
    NotificationModel notification, {
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onTap,
    VoidCallback? onDismiss,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => NotificationOverlay(
        notification: notification,
        duration: duration,
        onTap: () {
          entry.remove();
          onTap?.call();
        },
        onDismiss: () {
          entry.remove();
          onDismiss?.call();
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _NotificationOverlayState extends State<NotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);

    // Iniciar animación de entrada
    _animationController.forward();

    // Auto-dismiss después del duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _animationController.reverse();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeColor = Color(
      int.parse(widget.notification.colorHex.substring(1), radix: 16) +
          0xFF000000,
    );

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.surface,
                border: Border.all(color: typeColor.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  // Icono
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      NotificationToast._getNotificationIcon(
                        widget.notification.type,
                      ),
                      color: typeColor,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Contenido
                  Expanded(
                    child: GestureDetector(
                      onTap: widget.onTap,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.notification.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.notification.message,
                            style: theme.textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Botón cerrar
                  IconButton(
                    onPressed: _dismiss,
                    icon: const Icon(Icons.close),
                    iconSize: 16,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
