// lib/widgets/notifications/notification_filters.dart

import 'package:flutter/material.dart';
import '../../core/models/notification_model.dart';

/// Widget para filtrar notificaciones por tipo y estado
/// Fase 5-0003: Filtros en la UI de notificaciones
class NotificationFilters extends StatefulWidget {
  final String? selectedType;
  final bool? showOnlyUnread;
  final Function(String?)? onTypeChanged;
  final Function(bool?)? onUnreadFilterChanged;
  final VoidCallback? onClearFilters;

  const NotificationFilters({
    Key? key,
    this.selectedType,
    this.showOnlyUnread,
    this.onTypeChanged,
    this.onUnreadFilterChanged,
    this.onClearFilters,
  }) : super(key: key);

  @override
  State<NotificationFilters> createState() => _NotificationFiltersState();
}

class _NotificationFiltersState extends State<NotificationFilters> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActiveFilters =
        widget.selectedType != null || widget.showOnlyUnread == true;

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Header del filtro
          ListTile(
            leading: Icon(
              Icons.filter_list,
              color: hasActiveFilters ? theme.colorScheme.primary : null,
            ),
            title: Text(
              'Filtros',
              style: TextStyle(
                fontWeight: hasActiveFilters ? FontWeight.bold : null,
                color: hasActiveFilters ? theme.colorScheme.primary : null,
              ),
            ),
            subtitle: hasActiveFilters ? _buildActiveFiltersText() : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasActiveFilters)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: widget.onClearFilters,
                    tooltip: 'Limpiar filtros',
                  ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),

          // Contenido expandible
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtro por estado
                  Text('Estado', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _buildReadStatusFilter(),

                  const SizedBox(height: 16),

                  // Filtro por tipo
                  Text(
                    'Tipo de notificación',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _buildTypeFilter(),

                  const SizedBox(height: 16),

                  // Botones de acción
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (hasActiveFilters)
                        TextButton(
                          onPressed: widget.onClearFilters,
                          child: const Text('Limpiar'),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isExpanded = false;
                          });
                        },
                        child: const Text('Aplicar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveFiltersText() {
    final filters = <String>[];

    if (widget.showOnlyUnread == true) {
      filters.add('Solo no leídas');
    }

    if (widget.selectedType != null) {
      final type = NotificationType.fromString(widget.selectedType!);
      filters.add(_getTypeDisplayName(type));
    }

    return Text(
      filters.join(', '),
      style: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontSize: 12,
      ),
    );
  }

  Widget _buildReadStatusFilter() {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Todas'),
          selected: widget.showOnlyUnread != true,
          onSelected: (selected) {
            if (selected) {
              widget.onUnreadFilterChanged?.call(null);
            }
          },
        ),
        ChoiceChip(
          label: const Text('Solo no leídas'),
          selected: widget.showOnlyUnread == true,
          onSelected: (selected) {
            widget.onUnreadFilterChanged?.call(selected ? true : null);
          },
        ),
      ],
    );
  }

  Widget _buildTypeFilter() {
    final types = [
      null, // Todas
      ...NotificationType.values,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = widget.selectedType == type?.value;
        final displayName = _getTypeDisplayName(type);

        return FilterChip(
          label: Text(displayName),
          selected: isSelected,
          onSelected: (selected) {
            widget.onTypeChanged?.call(selected ? type?.value : null);
          },
          avatar: type != null
              ? Icon(
                  _getTypeIcon(type),
                  size: 16,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Color(
                          int.parse(
                                _getTypeColor(type).substring(1),
                                radix: 16,
                              ) +
                              0xFF000000,
                        ),
                )
              : null,
        );
      }).toList(),
    );
  }

  String _getTypeDisplayName(NotificationType? type) {
    if (type == null) return 'Todas';

    switch (type) {
      case NotificationType.newPost:
        return 'Nuevas publicaciones';
      case NotificationType.newComment:
        return 'Nuevos comentarios';
      case NotificationType.postReaction:
        return 'Reacciones';
      case NotificationType.securityAlert:
        return 'Alertas de seguridad';
      case NotificationType.system:
        return 'Sistema';
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newPost:
        return Icons.post_add;
      case NotificationType.newComment:
        return Icons.comment;
      case NotificationType.postReaction:
        return Icons.favorite;
      case NotificationType.securityAlert:
        return Icons.security;
      case NotificationType.system:
        return Icons.info;
    }
  }

  String _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.newPost:
        return '#4CAF50';
      case NotificationType.newComment:
        return '#2196F3';
      case NotificationType.postReaction:
        return '#FF5722';
      case NotificationType.securityAlert:
        return '#F44336';
      case NotificationType.system:
        return '#9C27B0';
    }
  }
}

/// Chip simple para mostrar filtro activo
class ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback? onDeleted;

  const ActiveFilterChip({Key? key, required this.label, this.onDeleted})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDeleted,
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      side: BorderSide(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      ),
    );
  }
}

/// Widget compacto para mostrar filtros activos
class ActiveFiltersBar extends StatelessWidget {
  final String? selectedType;
  final bool? showOnlyUnread;
  final Function(String?)? onTypeChanged;
  final Function(bool?)? onUnreadFilterChanged;
  final VoidCallback? onClearAll;

  const ActiveFiltersBar({
    Key? key,
    this.selectedType,
    this.showOnlyUnread,
    this.onTypeChanged,
    this.onUnreadFilterChanged,
    this.onClearAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasFilters = selectedType != null || showOnlyUnread == true;

    if (!hasFilters) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Filtros activos: '),
          Expanded(
            child: Wrap(
              spacing: 8,
              children: [
                if (showOnlyUnread == true)
                  ActiveFilterChip(
                    label: 'No leídas',
                    onDeleted: () => onUnreadFilterChanged?.call(null),
                  ),
                if (selectedType != null)
                  ActiveFilterChip(
                    label: _getTypeDisplayName(selectedType!),
                    onDeleted: () => onTypeChanged?.call(null),
                  ),
              ],
            ),
          ),
          if (hasFilters)
            TextButton(
              onPressed: onClearAll,
              child: const Text('Limpiar todo'),
            ),
        ],
      ),
    );
  }

  String _getTypeDisplayName(String typeValue) {
    final type = NotificationType.fromString(typeValue);
    switch (type) {
      case NotificationType.newPost:
        return 'Publicaciones';
      case NotificationType.newComment:
        return 'Comentarios';
      case NotificationType.postReaction:
        return 'Reacciones';
      case NotificationType.securityAlert:
        return 'Seguridad';
      case NotificationType.system:
        return 'Sistema';
      case null:
        return 'Desconocido';
    }
  }
}
