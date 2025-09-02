// lib/widgets/notifications/notification_badge.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/notification_provider.dart';

/// Badge que muestra el contador de notificaciones no leídas
/// Fase 5-0002: Widget básico de UI para notificaciones
class NotificationBadge extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color? badgeColor;
  final Color? textColor;
  final double? badgeSize;
  final VoidCallback? onTap;
  final bool showZero;

  const NotificationBadge({
    Key? key,
    this.icon = Icons.notifications,
    this.iconSize = 24.0,
    this.badgeColor,
    this.textColor,
    this.badgeSize,
    this.onTap,
    this.showZero = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBadgeColor = badgeColor ?? theme.colorScheme.error;
    final effectiveTextColor = textColor ?? theme.colorScheme.onError;

    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final unreadCount = notificationProvider.unreadCount;
        final showBadge = showZero || unreadCount > 0;

        return GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Ícono principal
              Icon(icon, size: iconSize, color: theme.iconTheme.color),

              // Badge con contador
              if (showBadge)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: BoxConstraints(
                      minWidth: badgeSize ?? 18,
                      minHeight: badgeSize ?? 18,
                    ),
                    decoration: BoxDecoration(
                      color: effectiveBadgeColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyle(
                        color: effectiveTextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// AppBar action para notificaciones
class NotificationAppBarAction extends StatelessWidget {
  final VoidCallback? onPressed;

  const NotificationAppBarAction({Key? key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return IconButton(
          icon: NotificationBadge(onTap: onPressed),
          onPressed: onPressed,
          tooltip: 'Notificaciones (${notificationProvider.unreadCount})',
        );
      },
    );
  }
}

/// Indicador de estado del polling
class NotificationPollingIndicator extends StatelessWidget {
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const NotificationPollingIndicator({
    Key? key,
    this.size = 8.0,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor = activeColor ?? Colors.green;
    final effectiveInactiveColor = inactiveColor ?? Colors.grey;

    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final isPolling = notificationProvider.isPolling;
        final hasError = notificationProvider.lastError != null;

        Color dotColor;
        if (hasError) {
          dotColor = Colors.red;
        } else if (isPolling) {
          dotColor = effectiveActiveColor;
        } else {
          dotColor = effectiveInactiveColor;
        }

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        );
      },
    );
  }
}

/// Widget que muestra información de debug del servicio
class NotificationDebugInfo extends StatelessWidget {
  const NotificationDebugInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final stats = notificationProvider.getStats();

        return Card(
          margin: const EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Estado del Servicio de Notificaciones',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                _buildInfoRow(
                  'Polling activo:',
                  stats['is_polling'].toString(),
                ),
                _buildInfoRow(
                  'Intervalo actual:',
                  '${stats['current_interval']}s',
                ),
                _buildInfoRow('No leídas:', stats['unread_count'].toString()),
                _buildInfoRow(
                  'Total notificaciones:',
                  stats['total_notifications'].toString(),
                ),
                _buildInfoRow('Errores:', stats['error_count'].toString()),

                if (stats['last_update'] != null)
                  _buildInfoRow(
                    'Última actualización:',
                    DateTime.parse(stats['last_update']).toLocal().toString(),
                  ),

                if (stats['last_error'] != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Último error:',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    stats['last_error'],
                    style: TextStyle(color: Colors.red[700], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
