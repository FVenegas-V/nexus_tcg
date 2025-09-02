import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/notification_provider.dart';
import '../../core/models/notification_model.dart';
import '../../widgets/notifications/notification_card.dart';
import '../../widgets/notifications/notification_badge.dart';
import '../../widgets/notifications/notification_filters.dart';

/// Pantalla principal de notificaciones con lista paginada
/// Fase 5-0003: UI completa de notificaciones
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<NotificationModel> _allNotifications = [];
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  static const int _pageSize = 20;

  // Filtros
  String? _selectedType;
  bool? _showOnlyUnread;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialNotifications();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadInitialNotifications() async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    try {
      final notifications = await provider.getNotificationHistory(
        page: 1,
        pageSize: _pageSize,
        type: _selectedType,
      );

      // Aplicar filtro local de no leídas si está activo
      final filteredNotifications = _showOnlyUnread == true
          ? notifications.where((n) => !n.isRead).toList()
          : notifications;

      setState(() {
        _allNotifications.clear();
        _allNotifications.addAll(filteredNotifications);
        _currentPage = 1;
        _hasMoreData = notifications.length == _pageSize;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando notificaciones: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    final provider = Provider.of<NotificationProvider>(context, listen: false);

    try {
      final notifications = await provider.getNotificationHistory(
        page: _currentPage + 1,
        pageSize: _pageSize,
        type: _selectedType,
      );

      // Aplicar filtro local de no leídas si está activo
      final filteredNotifications = _showOnlyUnread == true
          ? notifications.where((n) => !n.isRead).toList()
          : notifications;

      setState(() {
        _allNotifications.addAll(filteredNotifications);
        _currentPage++;
        _hasMoreData = notifications.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando más notificaciones: $e')),
        );
      }
    }
  }

  // Métodos para manejar filtros
  void _onTypeFilterChanged(String? type) {
    setState(() {
      _selectedType = type;
    });
    _loadInitialNotifications();
  }

  void _onUnreadFilterChanged(bool? showOnlyUnread) {
    setState(() {
      _showOnlyUnread = showOnlyUnread;
    });
    _loadInitialNotifications();
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _showOnlyUnread = null;
    });
    _loadInitialNotifications();
  }

  Future<void> _markAllAsRead() async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    try {
      await provider.markAllAsRead();

      // Actualizar lista local
      setState(() {
        for (int i = 0; i < _allNotifications.length; i++) {
          _allNotifications[i] = _allNotifications[i].copyWith(isRead: true);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las notificaciones marcadas como leídas'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _onRefresh() async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    // Forzar actualización del servicio
    await provider.forceRefresh();

    // Recargar lista completa
    await _loadInitialNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          // Indicador de polling
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(child: NotificationPollingIndicator()),
          ),

          // Marcar todas como leídas
          Consumer<NotificationProvider>(
            builder: (context, provider, child) {
              final hasUnread = provider.unreadCount > 0;

              return IconButton(
                icon: const Icon(Icons.done_all),
                onPressed: hasUnread ? _markAllAsRead : null,
                tooltip: 'Marcar todas como leídas',
              );
            },
          ),

          // Menú de opciones
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  _onRefresh();
                  break;
                case 'debug':
                  _showDebugDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Actualizar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'debug',
                child: ListTile(
                  leading: Icon(Icons.bug_report),
                  title: Text('Debug Info'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Filtros
              NotificationFilters(
                selectedType: _selectedType,
                showOnlyUnread: _showOnlyUnread,
                onTypeChanged: _onTypeFilterChanged,
                onUnreadFilterChanged: _onUnreadFilterChanged,
                onClearFilters: _clearFilters,
              ),

              // Lista de notificaciones
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: _buildNotificationsList(provider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationsList(NotificationProvider provider) {
    // Estado de carga inicial
    if (_allNotifications.isEmpty && provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando notificaciones...'),
          ],
        ),
      );
    }

    // Estado vacío
    if (_allNotifications.isEmpty && !provider.isLoading) {
      return _buildEmptyState();
    }

    // Lista con notificaciones
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: _allNotifications.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        // Indicador de carga al final
        if (index == _allNotifications.length) {
          return _buildLoadingIndicator();
        }

        final notification = _allNotifications[index];
        return NotificationCard(
          notification: notification,
          onTap: () => _onNotificationTapped(notification),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tienes notificaciones',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Las notificaciones aparecerán aquí cuando tengas actividad nueva',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: _isLoadingMore
          ? const CircularProgressIndicator()
          : const SizedBox.shrink(),
    );
  }

  Future<void> _onNotificationTapped(NotificationModel notification) async {
    print('🔔 DEBUG: Notificación tocada');
    print('🔔 ID: ${notification.id}');
    print('🔔 Título: ${notification.title}');
    print('🔔 ActionURL: ${notification.actionUrl}');

    final provider = Provider.of<NotificationProvider>(context, listen: false);

    try {
      // Marcar como leída si no lo está
      if (!notification.isRead) {
        await provider.markAsRead(notification.id);

        // Actualizar en lista local
        final index = _allNotifications.indexWhere(
          (n) => n.id == notification.id,
        );
        if (index != -1) {
          setState(() {
            _allNotifications[index] = notification.copyWith(isRead: true);
          });
        }
      }

      // Navegar al contenido relacionado si tiene actionUrl
      if (notification.actionUrl != null) {
        print('🔔 DEBUG: Navegando a: ${notification.actionUrl}');
        _navigateToNotificationContent(notification);
      } else {
        print('🔔 DEBUG: No hay actionUrl, mostrando detalles');
        // Mostrar detalles en modal
        _showNotificationDetails(notification);
      }
    } catch (e) {
      print('🔔 ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _navigateToNotificationContent(NotificationModel notification) {
    if (notification.actionUrl == null) {
      print('🔔 DEBUG: actionUrl es null');
      _showNotificationDetails(notification);
      return;
    }

    final actionUrl = notification.actionUrl!;
    print('🔔 DEBUG: Procesando actionUrl: $actionUrl');

    // Parsear la URL para determinar el tipo de navegación
    if (actionUrl.startsWith('/post/')) {
      // Extraer ID del post: /post/123
      final pathSegments = actionUrl.split('/');
      print('🔔 DEBUG: Path segments: $pathSegments');

      if (pathSegments.length >= 3) {
        final postIdStr = pathSegments[2];
        final postId = int.tryParse(postIdStr);

        print('🔔 DEBUG: postIdStr: $postIdStr, postId: $postId');

        if (postId != null) {
          // Navegar al detalle del post usando GoRouter con contexto de notificación
          print('🔔 DEBUG: Navegando a /post/$postId desde notificación');
          context.go('/post/$postId?from=notification');
          return;
        }
      }
    } else if (actionUrl.startsWith('/communities/')) {
      // Navegar a comunidad
      final pathSegments = actionUrl.split('/');
      if (pathSegments.length >= 3) {
        final communityIdStr = pathSegments[2];
        final communityId = int.tryParse(communityIdStr);

        if (communityId != null) {
          context.go('/communities/$communityId');
          return;
        }
      }
    } else if (actionUrl.startsWith('/profile/')) {
      // Navegar a perfil de usuario
      final pathSegments = actionUrl.split('/');
      if (pathSegments.length >= 3) {
        final userIdStr = pathSegments[2];
        final userId = int.tryParse(userIdStr);

        if (userId != null) {
          context.go('/profile/$userId');
          return;
        }
      }
    }

    // Si no se pudo parsear la URL, mostrar detalles
    print('🔔 DEBUG: No se pudo parsear la URL, mostrando detalles');
    _showNotificationDetails(notification);
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getNotificationIcon(notification.type),
              color: Color(
                int.parse(notification.colorHex.substring(1), radix: 16) +
                    0xFF000000,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 8),
            Text(
              'Tipo: ${notification.typeDescription}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Fecha: ${notification.createdAt.toLocal()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          if (notification.actionUrl != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToNotificationContent(notification);
              },
              child: const Text('Ver Post'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
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

  void _showDebugDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: const NotificationDebugInfo(),
        ),
      ),
    );
  }
}
