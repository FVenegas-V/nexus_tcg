// lib/core/services/navigation_service.dart

import 'package:flutter/material.dart';

/// Servicio de navegación global para FCM y notificaciones
/// Permite navegar desde cualquier parte de la app sin context
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Obtener el contexto actual
  static BuildContext? get currentContext => navigatorKey.currentContext;

  /// Navegar a una pantalla específica
  static Future<void> navigateTo(String route, {Object? arguments}) async {
    final context = currentContext;
    if (context != null) {
      await Navigator.pushNamed(context, route, arguments: arguments);
    }
  }

  /// Navegar y reemplazar toda la pila
  static Future<void> navigateAndClearStack(
    String route, {
    Object? arguments,
  }) async {
    final context = currentContext;
    if (context != null) {
      await Navigator.pushNamedAndRemoveUntil(
        context,
        route,
        (route) => false,
        arguments: arguments,
      );
    }
  }

  /// Navegación específica para FCM
  static Future<void> handleFCMNavigation(Map<String, dynamic> data) async {
    try {
      String? navigateTo = data['navigate_to'];

      if (navigateTo == null || navigateTo.isEmpty) {
        // Fallback a notificaciones
        await NavigationService.navigateTo('/notifications');
        return;
      }

      switch (navigateTo) {
        case 'post_detail':
          await _navigateToPost(data);
          break;

        case 'user_profile':
          await _navigateToUserProfile(data);
          break;

        case 'community_detail':
          await _navigateToCommunity(data);
          break;

        case 'notifications_list':
        default:
          await NavigationService.navigateTo('/notifications');
          break;
      }
    } catch (e) {
      // Fallback en caso de error
      await NavigationService.navigateTo('/notifications');
    }
  }

  /// Navegar a post específico
  static Future<void> _navigateToPost(Map<String, dynamic> data) async {
    String? communityId = data['community_id'];
    String? postId = data['post_id'];

    if (communityId != null && postId != null) {
      // Usar las rutas existentes de la app
      await NavigationService.navigateTo(
        '/community/$communityId/post/$postId',
        arguments: data,
      );
    } else {
      await NavigationService.navigateTo('/notifications');
    }
  }

  /// Navegar a perfil de usuario
  static Future<void> _navigateToUserProfile(Map<String, dynamic> data) async {
    String? userId = data['target_user_id'];

    if (userId != null) {
      await NavigationService.navigateTo('/profile/$userId', arguments: data);
    } else {
      await NavigationService.navigateTo('/notifications');
    }
  }

  /// Navegar a comunidad
  static Future<void> _navigateToCommunity(Map<String, dynamic> data) async {
    String? communityId = data['community_id'];

    if (communityId != null) {
      await NavigationService.navigateTo(
        '/community/$communityId',
        arguments: data,
      );
    } else {
      await NavigationService.navigateTo('/notifications');
    }
  }
}
