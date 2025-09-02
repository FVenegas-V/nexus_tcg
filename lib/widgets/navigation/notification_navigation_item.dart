// lib/widgets/navigation/notification_navigation_item.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/notification_provider.dart';

/// Item de navegación con badge de notificaciones para BottomNavigationBar
/// Fase 5-0003: Integración con navegación principal
class NotificationNavigationItem {
  /// Crea un BottomNavigationBarItem con badge de notificaciones
  static BottomNavigationBarItem create({
    required BuildContext context,
    String label = 'Notificaciones',
    IconData icon = Icons.notifications_outlined,
    IconData activeIcon = Icons.notifications,
  }) {
    return BottomNavigationBarItem(
      icon: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return _NotificationIconWithBadge(
            icon: icon,
            unreadCount: provider.unreadCount,
          );
        },
      ),
      activeIcon: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return _NotificationIconWithBadge(
            icon: activeIcon,
            unreadCount: provider.unreadCount,
            isActive: true,
          );
        },
      ),
      label: label,
    );
  }
}

/// Widget interno para mostrar el ícono con badge
class _NotificationIconWithBadge extends StatelessWidget {
  final IconData icon;
  final int unreadCount;
  final bool isActive;

  const _NotificationIconWithBadge({
    required this.icon,
    required this.unreadCount,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showBadge = unreadCount > 0;

    return Badge(
      label: Text(
        unreadCount > 99 ? '99+' : unreadCount.toString(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
      isLabelVisible: showBadge,
      backgroundColor: theme.colorScheme.error,
      textColor: theme.colorScheme.onError,
      child: Icon(icon),
    );
  }
}

/// Widget para usar en AppBar de otras pantallas
class NotificationAppBarIcon extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;

  const NotificationAppBarIcon({
    Key? key,
    this.onPressed,
    this.icon = Icons.notifications_outlined,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final unreadCount = provider.unreadCount;
        final effectiveTooltip =
            tooltip ??
            'Notificaciones${unreadCount > 0 ? ' ($unreadCount nuevas)' : ''}';

        return IconButton(
          onPressed: onPressed,
          tooltip: effectiveTooltip,
          icon: Badge(
            label: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            isLabelVisible: unreadCount > 0,
            child: Icon(icon),
          ),
        );
      },
    );
  }
}

/// Drawer item para notificaciones
class NotificationDrawerItem extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showPreview;

  const NotificationDrawerItem({Key? key, this.onTap, this.showPreview = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            ListTile(
              leading: Badge(
                label: Text(provider.unreadCount.toString()),
                isLabelVisible: provider.unreadCount > 0,
                child: const Icon(Icons.notifications),
              ),
              title: const Text('Notificaciones'),
              subtitle: provider.unreadCount > 0
                  ? Text('${provider.unreadCount} nuevas')
                  : const Text('No hay nuevas'),
              onTap: onTap,
              trailing: const Icon(Icons.arrow_forward_ios),
            ),

            // Preview de notificaciones recientes
            if (showPreview && provider.notifications.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recientes',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...provider.notifications
                        .take(3)
                        .map(
                          (notification) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              _getNotificationIcon(notification.type),
                              size: 16,
                              color: Color(
                                int.parse(
                                      notification.colorHex.substring(1),
                                      radix: 16,
                                    ) +
                                    0xFF000000,
                              ),
                            ),
                            title: Text(
                              notification.title,
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              notification.timeAgo,
                              style: const TextStyle(fontSize: 10),
                            ),
                            onTap: () {
                              // Cerrar drawer y navegar
                              Navigator.pop(context);
                              onTap?.call();
                            },
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
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

/// Floating Action Button para notificaciones
class NotificationFAB extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool mini;

  const NotificationFAB({Key? key, this.onPressed, this.mini = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        final unreadCount = provider.unreadCount;

        return FloatingActionButton(
          onPressed: onPressed,
          mini: mini,
          child: Badge(
            label: Text(unreadCount.toString()),
            isLabelVisible: unreadCount > 0,
            child: const Icon(Icons.notifications),
          ),
        );
      },
    );
  }
}
