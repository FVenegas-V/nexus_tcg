// lib/core/models/notification_model.dart

/// Modelo para representar notificaciones del sistema
/// Fase 5-0002: Frontend Notification Model
class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final String? actionUrl;
  final String? imageUrl;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.metadata,
    this.actionUrl,
    this.imageUrl,
  });

  /// Crea una instancia desde JSON del backend
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Debug logging para ver qué campos llegan
    print('🔔 NotificationModel.fromJson: $json');
    print('🔔 action_url: ${json['action_url']}');
    print('🔔 related_object_url: ${json['related_object_url']}');

    // Manejar tanto response completa como unread response
    final actionUrl = json['action_url'] ?? json['related_object_url'];
    print('🔔 Final actionUrl: $actionUrl');

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? json['notification_type'] ?? 'general',
      title: json['title'] ?? 'Notificación',
      message: json['message'] ?? json['title'] ?? 'Nueva actividad',
      createdAt: _parseDateTime(json),
      isRead: json['is_read'] ?? json['read'] ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      actionUrl: actionUrl,
      imageUrl: json['image_url'],
    );
  }

  /// Parsea la fecha de manera robusta
  static DateTime _parseDateTime(Map<String, dynamic> json) {
    // Intentar parsing de created_at
    if (json['created_at'] != null) {
      final parsed = DateTime.tryParse(json['created_at']);
      if (parsed != null) return parsed;
    }

    // Fallback a tiempo actual si no hay fecha válida
    return DateTime.now();
  }

  /// Convierte a JSON para envío al backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'metadata': metadata,
      'action_url': actionUrl,
      'image_url': imageUrl,
    };
  }

  /// Crea una copia con campos modificados
  NotificationModel copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? metadata,
    String? actionUrl,
    String? imageUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
      actionUrl: actionUrl ?? this.actionUrl,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Obtiene el ícono apropiado según el tipo
  String get iconName {
    switch (type) {
      case 'new_post':
        return 'post_add';
      case 'new_comment':
        return 'comment';
      case 'post_reaction':
        return 'favorite';
      case 'security_alert':
        return 'security';
      case 'system':
        return 'info';
      default:
        return 'notifications';
    }
  }

  /// Obtiene el color apropiado según el tipo
  String get colorHex {
    switch (type) {
      case 'new_post':
        return '#4CAF50'; // Verde
      case 'new_comment':
        return '#2196F3'; // Azul
      case 'post_reaction':
        return '#FF5722'; // Naranja
      case 'security_alert':
        return '#F44336'; // Rojo
      case 'system':
        return '#9C27B0'; // Púrpura
      default:
        return '#757575'; // Gris
    }
  }

  /// Obtiene descripción legible del tipo
  String get typeDescription {
    switch (type) {
      case 'new_post':
        return 'Nueva publicación';
      case 'new_comment':
        return 'Nuevo comentario';
      case 'post_reaction':
        return 'Reacción a publicación';
      case 'security_alert':
        return 'Alerta de seguridad';
      case 'system':
        return 'Notificación del sistema';
      default:
        return 'Notificación';
    }
  }

  /// Verifica si la notificación es reciente (menos de 24 horas)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  /// Formato de tiempo relativo para mostrar en UI
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'ahora';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NotificationModel{id: $id, type: $type, title: $title, isRead: $isRead}';
  }
}

/// Tipos de notificación disponibles
enum NotificationType {
  newPost('new_post'),
  newComment('new_comment'),
  postReaction('post_reaction'),
  securityAlert('security_alert'),
  system('system');

  const NotificationType(this.value);
  final String value;

  static NotificationType? fromString(String value) {
    for (final type in NotificationType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}
