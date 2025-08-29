import 'package:equatable/equatable.dart';

/// Modelo que representa una valoración entre usuarios.
///
/// Corresponde con el endpoint POST /api/users/ratings/rate-user/
/// y las respuestas de GET /api/users/ratings/{user_id}/received-ratings/
class UserRating extends Equatable {
  /// ID único de la valoración
  final int id;

  /// Usuario que realiza la valoración
  final int raterId;

  /// Nombre de usuario del que valora (para UI)
  final String raterUsername;

  /// Avatar del usuario que valora (opcional)
  final String? raterAvatarUrl;

  /// Usuario que recibe la valoración
  final int ratedUserId;

  /// Nombre de usuario del valorado (para UI)
  final String ratedUsername;

  /// Puntuación de 1 a 5 estrellas
  final int rating;

  /// Comentario opcional de la valoración
  final String? comment;

  /// Tipo de interacción que motivó la valoración
  /// Valores: 'trade', 'game', 'community', 'general'
  final String interactionType;

  /// Referencia a la interacción específica (ej: post_id, trade_id)
  final String? interactionReference;

  /// Indica si la valoración está activa (no fue eliminada)
  final bool isActive;

  /// Indica si la valoración está siendo moderada
  final bool isUnderModeration;

  /// Razón de moderación si aplica
  final String? moderationReason;

  /// Fecha de creación
  final DateTime createdAt;

  /// Fecha de última actualización
  final DateTime updatedAt;

  const UserRating({
    required this.id,
    required this.raterId,
    required this.raterUsername,
    this.raterAvatarUrl,
    required this.ratedUserId,
    required this.ratedUsername,
    required this.rating,
    this.comment,
    required this.interactionType,
    this.interactionReference,
    this.isActive = true,
    this.isUnderModeration = false,
    this.moderationReason,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory constructor para crear instancia desde JSON del backend
  factory UserRating.fromJson(Map<String, dynamic> json) {
    // Extraer información del usuario que califica
    final raterInfo = json['rater_info'] as Map<String, dynamic>?;
    final ratedUserInfo = json['rated_user_info'] as Map<String, dynamic>?;

    return UserRating(
      id: json['id'] as int,
      raterId:
          raterInfo?['id'] as int? ??
          json['rater'] as int? ??
          json['rater_id'] as int? ??
          0,
      raterUsername:
          raterInfo?['username'] as String? ??
          json['rater_username'] as String? ??
          '',
      raterAvatarUrl:
          raterInfo?['avatar_url'] as String? ??
          json['rater_avatar'] as String?,
      ratedUserId:
          ratedUserInfo?['id'] as int? ??
          json['rated_user'] as int? ??
          json['rated_user_id'] as int? ??
          0,
      ratedUsername:
          ratedUserInfo?['username'] as String? ??
          json['rated_username'] as String? ??
          '',
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      interactionType: json['interaction_type'] as String? ?? 'general',
      interactionReference: json['interaction_reference'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isUnderModeration: json['is_under_moderation'] as bool? ?? false,
      moderationReason: json['moderation_reason'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convierte el modelo a Map para envío al backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rater': raterId,
      'rated_user': ratedUserId,
      'rating': rating,
      'comment': comment,
      'interaction_type': interactionType,
      'interaction_reference': interactionReference,
      'is_active': isActive,
      'is_under_moderation': isUnderModeration,
      'moderation_reason': moderationReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Factory para crear payload de nueva valoración
  static Map<String, dynamic> createPayload({
    required int ratedUserId,
    required int rating,
    String? comment,
    String interactionType = 'general',
    String? interactionReference,
  }) {
    return {
      'rated_user': ratedUserId,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      'interaction_type': interactionType,
      if (interactionReference != null)
        'interaction_reference': interactionReference,
    };
  }

  /// Crea una copia con campos actualizados
  UserRating copyWith({
    int? id,
    int? raterId,
    String? raterUsername,
    String? raterAvatarUrl,
    int? ratedUserId,
    String? ratedUsername,
    int? rating,
    String? comment,
    String? interactionType,
    String? interactionReference,
    bool? isActive,
    bool? isUnderModeration,
    String? moderationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserRating(
      id: id ?? this.id,
      raterId: raterId ?? this.raterId,
      raterUsername: raterUsername ?? this.raterUsername,
      raterAvatarUrl: raterAvatarUrl ?? this.raterAvatarUrl,
      ratedUserId: ratedUserId ?? this.ratedUserId,
      ratedUsername: ratedUsername ?? this.ratedUsername,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      interactionType: interactionType ?? this.interactionType,
      interactionReference: interactionReference ?? this.interactionReference,
      isActive: isActive ?? this.isActive,
      isUnderModeration: isUnderModeration ?? this.isUnderModeration,
      moderationReason: moderationReason ?? this.moderationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Propiedades para comparación con Equatable
  @override
  List<Object?> get props => [
    id,
    raterId,
    raterUsername,
    raterAvatarUrl,
    ratedUserId,
    ratedUsername,
    rating,
    comment,
    interactionType,
    interactionReference,
    isActive,
    isUnderModeration,
    moderationReason,
    createdAt,
    updatedAt,
  ];

  /// String representation para debugging
  @override
  String toString() {
    return 'UserRating('
        'id: $id, '
        'rater: $raterUsername($raterId), '
        'rated: $ratedUsername($ratedUserId), '
        'rating: $rating, '
        'comment: ${comment?.substring(0, 20)}..., '
        'type: $interactionType, '
        'active: $isActive'
        ')';
  }

  /// Helpers para UI

  /// Retorna el texto de estrellas para mostrar en UI
  String get starsText {
    return '★' * rating + '☆' * (5 - rating);
  }

  /// Retorna true si tiene comentario
  bool get hasComment => comment != null && comment!.isNotEmpty;

  /// Retorna true si es una valoración reciente (últimas 24 horas)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inHours < 24;
  }

  /// Retorna el color sugerido para la valoración en UI
  String get colorHex {
    switch (rating) {
      case 5:
        return '#4CAF50'; // Verde - Excelente
      case 4:
        return '#8BC34A'; // Verde claro - Muy bueno
      case 3:
        return '#FFC107'; // Amarillo - Bueno
      case 2:
        return '#FF9800'; // Naranja - Regular
      case 1:
        return '#F44336'; // Rojo - Malo
      default:
        return '#9E9E9E'; // Gris - Sin valoración
    }
  }

  /// Retorna el texto descriptivo de la valoración
  String get ratingText {
    switch (rating) {
      case 5:
        return 'Excelente';
      case 4:
        return 'Muy bueno';
      case 3:
        return 'Bueno';
      case 2:
        return 'Regular';
      case 1:
        return 'Malo';
      default:
        return 'Sin valoración';
    }
  }
}
