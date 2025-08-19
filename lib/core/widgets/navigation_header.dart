import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Widget para mostrar navegación contextual y breadcrumbs
class NavigationHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<BreadcrumbItem>? breadcrumbs;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBack;

  const NavigationHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.breadcrumbs,
    this.actions,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumbs si están disponibles
          if (breadcrumbs != null && breadcrumbs!.isNotEmpty) ...[
            _buildBreadcrumbs(context, breadcrumbs!),
            const SizedBox(height: 8),
          ],

          // Header principal
          Row(
            children: [
              // Botón back
              if (showBackButton) ...[
                IconButton(
                  onPressed:
                      onBack ??
                      () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Volver',
                ),
                const SizedBox(width: 8),
              ],

              // Título y subtítulo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Acciones
              if (actions != null) ...actions!,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context, List<BreadcrumbItem> items) {
    final theme = Theme.of(context);

    return Wrap(
      children: items.map((item) {
        final isLast = item == items.last;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.onTap != null)
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    item.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  item.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isLast
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: isLast ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
            if (!isLast) ...[
              Icon(
                Icons.chevron_right,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ],
        );
      }).toList(),
    );
  }
}

/// Item de breadcrumb
class BreadcrumbItem {
  final String title;
  final VoidCallback? onTap;

  const BreadcrumbItem({required this.title, this.onTap});
}

/// Headers predefinidos comunes
class NavigationHeaders {
  static NavigationHeader postDetail({
    required String communityName,
    required String postTitle,
    required BuildContext context,
    List<Widget>? actions,
  }) {
    return NavigationHeader(
      title: postTitle,
      subtitle: 'En $communityName',
      showBackButton: true,
      breadcrumbs: [
        BreadcrumbItem(title: 'Inicio', onTap: () => context.go('/home')),
        BreadcrumbItem(title: communityName, onTap: () => context.pop()),
        BreadcrumbItem(title: 'Post'),
      ],
      actions: actions,
    );
  }

  static NavigationHeader communityDetail({
    required String communityName,
    required BuildContext context,
    List<Widget>? actions,
  }) {
    return NavigationHeader(
      title: communityName,
      subtitle: 'Comunidad',
      showBackButton: true,
      breadcrumbs: [
        BreadcrumbItem(title: 'Inicio', onTap: () => context.go('/home')),
        BreadcrumbItem(
          title: 'Comunidades',
          onTap: () => context.go('/communities'),
        ),
        BreadcrumbItem(title: communityName),
      ],
      actions: actions,
    );
  }

  static NavigationHeader createPost({
    String? communityName,
    required BuildContext context,
  }) {
    return NavigationHeader(
      title: 'Crear post',
      subtitle: communityName != null ? 'En $communityName' : null,
      showBackButton: true,
      breadcrumbs: [
        BreadcrumbItem(title: 'Inicio', onTap: () => context.go('/home')),
        if (communityName != null)
          BreadcrumbItem(title: communityName, onTap: () => context.pop()),
        BreadcrumbItem(title: 'Nuevo post'),
      ],
    );
  }

  static NavigationHeader profile({
    required String username,
    required BuildContext context,
    bool isOwnProfile = true,
    List<Widget>? actions,
  }) {
    return NavigationHeader(
      title: isOwnProfile ? 'Mi perfil' : username,
      subtitle: isOwnProfile ? username : 'Perfil de usuario',
      showBackButton: !isOwnProfile,
      breadcrumbs: [
        BreadcrumbItem(title: 'Inicio', onTap: () => context.go('/home')),
        BreadcrumbItem(title: isOwnProfile ? 'Mi perfil' : 'Perfil'),
      ],
      actions: actions,
    );
  }
}
