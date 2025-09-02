// lib/core/models/notification_preferences_model.dart

/// Modelo para preferencias de notificaciones del usuario
/// Fase 5-0005: Configuración de Preferencias
class NotificationPreferencesModel {
  // Preferencias in-app
  final bool appNewPosts;
  final bool appNewComments;
  final bool appCommentReplies;
  final bool appNewRatings;

  // Preferencias de email
  final bool emailNewRatings;
  final bool emailImportantComments;
  final bool emailWeeklySummary;
  final String summaryFrequency;

  // Configuración avanzada
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final DateTime? updatedAt;

  const NotificationPreferencesModel({
    required this.appNewPosts,
    required this.appNewComments,
    required this.appCommentReplies,
    required this.appNewRatings,
    required this.emailNewRatings,
    required this.emailImportantComments,
    required this.emailWeeklySummary,
    required this.summaryFrequency,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.updatedAt,
  });

  /// Crea una instancia desde JSON del backend
  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesModel(
      appNewPosts: json['app_new_posts'] ?? true,
      appNewComments: json['app_new_comments'] ?? true,
      appCommentReplies: json['app_comment_replies'] ?? true,
      appNewRatings: json['app_new_ratings'] ?? true,
      emailNewRatings: json['email_new_ratings'] ?? true,
      emailImportantComments: json['email_important_comments'] ?? true,
      emailWeeklySummary: json['email_weekly_summary'] ?? true,
      summaryFrequency: json['summary_frequency'] ?? 'weekly',
      quietHoursStart: json['quiet_hours_start'],
      quietHoursEnd: json['quiet_hours_end'],
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  /// Convierte a JSON para envío al backend
  Map<String, dynamic> toJson() {
    return {
      'app_new_posts': appNewPosts,
      'app_new_comments': appNewComments,
      'app_comment_replies': appCommentReplies,
      'app_new_ratings': appNewRatings,
      'email_new_ratings': emailNewRatings,
      'email_important_comments': emailImportantComments,
      'email_weekly_summary': emailWeeklySummary,
      'summary_frequency': summaryFrequency,
      if (quietHoursStart != null) 'quiet_hours_start': quietHoursStart,
      if (quietHoursEnd != null) 'quiet_hours_end': quietHoursEnd,
    };
  }

  /// Crea una copia con campos modificados
  NotificationPreferencesModel copyWith({
    bool? appNewPosts,
    bool? appNewComments,
    bool? appCommentReplies,
    bool? appNewRatings,
    bool? emailNewRatings,
    bool? emailImportantComments,
    bool? emailWeeklySummary,
    String? summaryFrequency,
    String? quietHoursStart,
    String? quietHoursEnd,
    DateTime? updatedAt,
  }) {
    return NotificationPreferencesModel(
      appNewPosts: appNewPosts ?? this.appNewPosts,
      appNewComments: appNewComments ?? this.appNewComments,
      appCommentReplies: appCommentReplies ?? this.appCommentReplies,
      appNewRatings: appNewRatings ?? this.appNewRatings,
      emailNewRatings: emailNewRatings ?? this.emailNewRatings,
      emailImportantComments:
          emailImportantComments ?? this.emailImportantComments,
      emailWeeklySummary: emailWeeklySummary ?? this.emailWeeklySummary,
      summaryFrequency: summaryFrequency ?? this.summaryFrequency,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Obtiene el texto legible para la frecuencia
  String get summaryFrequencyDisplayName {
    switch (summaryFrequency) {
      case 'immediate':
        return 'Inmediato';
      case 'daily':
        return 'Diario';
      case 'weekly':
        return 'Semanal';
      case 'never':
        return 'Nunca';
      default:
        return 'Semanal';
    }
  }

  /// Verifica si tiene horas silenciosas configuradas
  bool get hasQuietHours {
    return quietHoursStart != null && quietHoursEnd != null;
  }

  /// Obtiene las preferencias por defecto
  static NotificationPreferencesModel get defaults {
    return const NotificationPreferencesModel(
      appNewPosts: true,
      appNewComments: true,
      appCommentReplies: true,
      appNewRatings: true,
      emailNewRatings: true,
      emailImportantComments: true,
      emailWeeklySummary: true,
      summaryFrequency: 'weekly',
    );
  }

  @override
  String toString() {
    return 'NotificationPreferencesModel{'
        'appNewPosts: $appNewPosts, '
        'appNewComments: $appNewComments, '
        'summaryFrequency: $summaryFrequency'
        '}';
  }
}

/// Opciones de frecuencia disponibles
enum FrequencyOption {
  immediate('immediate', 'Inmediato'),
  daily('daily', 'Diario'),
  weekly('weekly', 'Semanal'),
  never('never', 'Nunca');

  const FrequencyOption(this.value, this.displayName);
  final String value;
  final String displayName;

  static FrequencyOption? fromValue(String value) {
    for (final option in FrequencyOption.values) {
      if (option.value == value) return option;
    }
    return null;
  }
}
