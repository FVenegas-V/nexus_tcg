// lib/widgets/notifications/notification_card.dart

import 'package:flutter/material.dart';
import '../../core/models/notification_model.dart';

/// Card personalizado para mostrar notificaciones individuales
/// Fase 5-0003: UI Cards para lista de notificaciones
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final bool showActions;

  const NotificationCard({
    Key? key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
    this.showActions = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    // Color del tipo de notificación
    final typeColor = Color(
      int.parse(notification.colorHex.substring(1), radix: 16) + 0xFF000000,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      elevation: isUnread ? 2 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isUnread
                ? Border.all(color: typeColor.withOpacity(0.3), width: 1)
                : null,
            color: isUnread ? typeColor.withOpacity(0.05) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icono, título y tiempo
              Row(
                children: [
                  // Icono del tipo
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: typeColor,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Título y tipo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: isUnread
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isUnread ? null : Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          notification.typeDescription,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: typeColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tiempo relativo y badge de no leída
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        notification.timeAgo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      if (isUnread) ...[
                        const SizedBox(height: 4),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: typeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Mensaje
              Text(
                notification.message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isUnread ? null : Colors.grey[600],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Acciones opcionales
              if (showActions) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isUnread)
                      TextButton.icon(
                        onPressed: onMarkAsRead,
                        icon: const Icon(Icons.done, size: 16),
                        label: const Text('Marcar leída'),
                        style: TextButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
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

/// Card compacto para mostrar en listas pequeñas
class CompactNotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const CompactNotificationCard({
    Key? key,
    required this.notification,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    final typeColor = Color(
      int.parse(notification.colorHex.substring(1), radix: 16) + 0xFF000000,
    );

    return ListTile(
      onTap: onTap,
      dense: true,
      leading: CircleAvatar(
        backgroundColor: typeColor.withOpacity(0.1),
        radius: 16,
        child: Icon(
          _getNotificationIcon(notification.type),
          color: typeColor,
          size: 16,
        ),
      ),
      title: Text(
        notification.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        notification.message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            notification.timeAgo,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
              fontSize: 10,
            ),
          ),
          if (isUnread) ...[
            const SizedBox(height: 2),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: typeColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
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

/// Widget para mostrar notificaciones recientes en drawer o popup
class NotificationsList extends StatelessWidget {
  final List<NotificationModel> notifications;
  final VoidCallback? onSeeAll;
  final Function(NotificationModel)? onNotificationTap;

  const NotificationsList({
    Key? key,
    required this.notifications,
    this.onSeeAll,
    this.onNotificationTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No hay notificaciones recientes',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        ...notifications
            .take(5)
            .map(
              (notification) => CompactNotificationCard(
                notification: notification,
                onTap: () => onNotificationTap?.call(notification),
              ),
            ),

        if (notifications.length > 5 || onSeeAll != null)
          ListTile(
            dense: true,
            leading: const Icon(Icons.more_horiz),
            title: const Text('Ver todas las notificaciones'),
            onTap: onSeeAll,
          ),
      ],
    );
  }
}
