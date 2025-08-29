import 'package:equatable/equatable.dart';

/// Modelo que representa el resumen agregado de valoraciones de un usuario.
///
/// Corresponde con el endpoint GET /api/users/{user_id}/ratings/summary/
/// Incluye distribución de estrellas, comentarios destacados, y tendencias.
class RatingSummary extends Equatable {
  /// Total de valoraciones recibidas
  final int totalRatings;

  /// Promedio ponderado de valoraciones
  final double averageRating;

  /// Distribución de valoraciones por estrellas (1-5)
  final StarDistribution starDistribution;

  /// Comentarios destacados (positivos y negativos)
  final List<HighlightedComment> highlightedComments;

  /// Tipos de interacciones más comunes
  final Map<String, int> interactionTypes;

  /// Tendencia de valoraciones (últimos 30 días)
  final RatingTrend trend;

  /// Estadísticas temporales
  final TemporalStats temporalStats;

  /// Fecha de primera valoración
  final DateTime? firstRatingDate;

  /// Fecha de última valoración
  final DateTime? lastRatingDate;

  const RatingSummary({
    required this.totalRatings,
    required this.averageRating,
    required this.starDistribution,
    required this.highlightedComments,
    required this.interactionTypes,
    required this.trend,
    required this.temporalStats,
    this.firstRatingDate,
    this.lastRatingDate,
  });

  /// Factory constructor para crear instancia desde JSON del backend
  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    return RatingSummary(
      totalRatings: json['total_ratings'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      starDistribution: StarDistribution.fromJson(
        json['star_distribution'] as Map<String, dynamic>? ?? {},
      ),
      highlightedComments: (json['highlighted_comments'] as List? ?? [])
          .map(
            (item) => HighlightedComment.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      interactionTypes: Map<String, int>.from(
        json['interaction_types'] as Map<String, dynamic>? ?? {},
      ),
      trend: RatingTrend.fromJson(json['trend'] as Map<String, dynamic>? ?? {}),
      temporalStats: TemporalStats.fromJson(
        json['temporal_stats'] as Map<String, dynamic>? ?? {},
      ),
      firstRatingDate: json['first_rating_date'] != null
          ? DateTime.parse(json['first_rating_date'] as String)
          : null,
      lastRatingDate: json['last_rating_date'] != null
          ? DateTime.parse(json['last_rating_date'] as String)
          : null,
    );
  }

  /// Convierte el modelo a Map para serialización
  Map<String, dynamic> toJson() {
    return {
      'total_ratings': totalRatings,
      'average_rating': averageRating,
      'star_distribution': starDistribution.toJson(),
      'highlighted_comments': highlightedComments
          .map((c) => c.toJson())
          .toList(),
      'interaction_types': interactionTypes,
      'trend': trend.toJson(),
      'temporal_stats': temporalStats.toJson(),
      'first_rating_date': firstRatingDate?.toIso8601String(),
      'last_rating_date': lastRatingDate?.toIso8601String(),
    };
  }

  /// Crea una copia con campos actualizados
  RatingSummary copyWith({
    int? totalRatings,
    double? averageRating,
    StarDistribution? starDistribution,
    List<HighlightedComment>? highlightedComments,
    Map<String, int>? interactionTypes,
    RatingTrend? trend,
    TemporalStats? temporalStats,
    DateTime? firstRatingDate,
    DateTime? lastRatingDate,
  }) {
    return RatingSummary(
      totalRatings: totalRatings ?? this.totalRatings,
      averageRating: averageRating ?? this.averageRating,
      starDistribution: starDistribution ?? this.starDistribution,
      highlightedComments: highlightedComments ?? this.highlightedComments,
      interactionTypes: interactionTypes ?? this.interactionTypes,
      trend: trend ?? this.trend,
      temporalStats: temporalStats ?? this.temporalStats,
      firstRatingDate: firstRatingDate ?? this.firstRatingDate,
      lastRatingDate: lastRatingDate ?? this.lastRatingDate,
    );
  }

  /// Propiedades para comparación con Equatable
  @override
  List<Object?> get props => [
    totalRatings,
    averageRating,
    starDistribution,
    highlightedComments,
    interactionTypes,
    trend,
    temporalStats,
    firstRatingDate,
    lastRatingDate,
  ];

  // Helpers para UI

  /// Retorna el número de valoraciones con comentarios
  int get ratingsWithComments {
    return highlightedComments.length;
  }

  /// Retorna true si tiene suficientes valoraciones para mostrar estadísticas
  bool get hasSignificantData {
    return totalRatings >= 5;
  }

  /// Retorna el porcentaje de valoraciones positivas (4-5 estrellas)
  double get positiveRatingsPercentage {
    if (totalRatings == 0) return 0.0;
    final positive = starDistribution.fiveStars + starDistribution.fourStars;
    return (positive / totalRatings) * 100;
  }

  /// Retorna el porcentaje de valoraciones negativas (1-2 estrellas)
  double get negativeRatingsPercentage {
    if (totalRatings == 0) return 0.0;
    final negative = starDistribution.oneStars + starDistribution.twoStars;
    return (negative / totalRatings) * 100;
  }

  /// Retorna el tipo de interacción más común
  String? get mostCommonInteractionType {
    if (interactionTypes.isEmpty) return null;

    String? maxType;
    int maxCount = 0;

    for (final entry in interactionTypes.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        maxType = entry.key;
      }
    }

    return maxType;
  }

  /// Retorna un texto descriptivo del nivel de actividad
  String get activityLevel {
    if (totalRatings == 0) return 'Sin actividad';
    if (totalRatings < 5) return 'Actividad baja';
    if (totalRatings < 20) return 'Actividad moderada';
    if (totalRatings < 50) return 'Actividad alta';
    return 'Muy activo';
  }

  /// Retorna el color para mostrar el promedio en UI
  String get averageRatingColorHex {
    if (averageRating >= 4.5) return '#4CAF50'; // Verde oscuro
    if (averageRating >= 4.0) return '#8BC34A'; // Verde claro
    if (averageRating >= 3.0) return '#FFC107'; // Amarillo
    if (averageRating >= 2.0) return '#FF9800'; // Naranja
    if (averageRating >= 1.0) return '#F44336'; // Rojo
    return '#9E9E9E'; // Gris
  }

  @override
  String toString() {
    return 'RatingSummary('
        'total: $totalRatings, '
        'avg: ${averageRating.toStringAsFixed(1)}, '
        'positive: ${positiveRatingsPercentage.toStringAsFixed(1)}%, '
        'trend: ${trend.direction}'
        ')';
  }
}

/// Modelo que representa la distribución de estrellas
class StarDistribution extends Equatable {
  final int fiveStars;
  final int fourStars;
  final int threeStars;
  final int twoStars;
  final int oneStars;

  const StarDistribution({
    required this.fiveStars,
    required this.fourStars,
    required this.threeStars,
    required this.twoStars,
    required this.oneStars,
  });

  factory StarDistribution.fromJson(Map<String, dynamic> json) {
    return StarDistribution(
      fiveStars: json['5'] as int? ?? json['five_stars'] as int? ?? 0,
      fourStars: json['4'] as int? ?? json['four_stars'] as int? ?? 0,
      threeStars: json['3'] as int? ?? json['three_stars'] as int? ?? 0,
      twoStars: json['2'] as int? ?? json['two_stars'] as int? ?? 0,
      oneStars: json['1'] as int? ?? json['one_stars'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'five_stars': fiveStars,
      'four_stars': fourStars,
      'three_stars': threeStars,
      'two_stars': twoStars,
      'one_stars': oneStars,
    };
  }

  @override
  List<Object?> get props => [
    fiveStars,
    fourStars,
    threeStars,
    twoStars,
    oneStars,
  ];

  /// Retorna el total de valoraciones
  int get total => fiveStars + fourStars + threeStars + twoStars + oneStars;

  /// Retorna lista de valores para gráficos
  List<int> get values => [
    oneStars,
    twoStars,
    threeStars,
    fourStars,
    fiveStars,
  ];

  /// Retorna porcentajes para cada estrella
  List<double> get percentages {
    if (total == 0) return [0, 0, 0, 0, 0];
    return values.map((count) => (count / total) * 100).toList();
  }

  /// Retorna la calificación con más votos
  int get mostVotedRating {
    final maxCount = values.reduce((a, b) => a > b ? a : b);
    final index = values.indexOf(maxCount);
    return index + 1; // Convertir de índice (0-4) a rating (1-5)
  }
}

/// Modelo para comentarios destacados
class HighlightedComment extends Equatable {
  final int ratingId;
  final String raterUsername;
  final String? raterAvatarUrl;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final bool isPositive;

  const HighlightedComment({
    required this.ratingId,
    required this.raterUsername,
    this.raterAvatarUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.isPositive,
  });

  factory HighlightedComment.fromJson(Map<String, dynamic> json) {
    return HighlightedComment(
      ratingId: json['rating_id'] as int,
      raterUsername: json['rater_username'] as String,
      raterAvatarUrl: json['rater_avatar'] as String?,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      isPositive: json['is_positive'] as bool? ?? (json['rating'] as int) >= 4,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating_id': ratingId,
      'rater_username': raterUsername,
      'rater_avatar': raterAvatarUrl,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'is_positive': isPositive,
    };
  }

  @override
  List<Object?> get props => [
    ratingId,
    raterUsername,
    raterAvatarUrl,
    rating,
    comment,
    createdAt,
    isPositive,
  ];

  /// Retorna el texto de estrellas
  String get starsText => '★' * rating + '☆' * (5 - rating);

  /// Retorna true si el comentario es reciente (últimos 7 días)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inDays < 7;
  }
}

/// Modelo para tendencias de valoraciones
class RatingTrend extends Equatable {
  final TrendDirection direction;
  final double changePercentage;
  final int periodDays;
  final double currentPeriodAverage;
  final double previousPeriodAverage;

  const RatingTrend({
    required this.direction,
    required this.changePercentage,
    required this.periodDays,
    required this.currentPeriodAverage,
    required this.previousPeriodAverage,
  });

  factory RatingTrend.fromJson(Map<String, dynamic> json) {
    return RatingTrend(
      direction: TrendDirection.fromString(
        json['direction'] as String? ?? 'stable',
      ),
      changePercentage: (json['change_percentage'] as num?)?.toDouble() ?? 0.0,
      periodDays: json['period_days'] as int? ?? 30,
      currentPeriodAverage:
          (json['current_period_average'] as num?)?.toDouble() ?? 0.0,
      previousPeriodAverage:
          (json['previous_period_average'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'direction': direction.name,
      'change_percentage': changePercentage,
      'period_days': periodDays,
      'current_period_average': currentPeriodAverage,
      'previous_period_average': previousPeriodAverage,
    };
  }

  @override
  List<Object?> get props => [
    direction,
    changePercentage,
    periodDays,
    currentPeriodAverage,
    previousPeriodAverage,
  ];

  /// Retorna true si la tendencia es significativa (> 5% de cambio)
  bool get isSignificant => changePercentage.abs() > 5.0;
}

/// Enum para direcciones de tendencia
enum TrendDirection {
  improving('improving', 'Mejorando', '📈', '#4CAF50'),
  declining('declining', 'Declinando', '📉', '#F44336'),
  stable('stable', 'Estable', '➡️', '#9E9E9E');

  const TrendDirection(this.name, this.displayName, this.emoji, this.colorHex);

  final String name;
  final String displayName;
  final String emoji;
  final String colorHex;

  static TrendDirection fromString(String value) {
    return TrendDirection.values.firstWhere(
      (direction) => direction.name == value,
      orElse: () => TrendDirection.stable,
    );
  }
}

/// Modelo para estadísticas temporales
class TemporalStats extends Equatable {
  final Map<String, double> last7Days;
  final Map<String, double> last30Days;
  final Map<String, double> last90Days;

  const TemporalStats({
    required this.last7Days,
    required this.last30Days,
    required this.last90Days,
  });

  factory TemporalStats.fromJson(Map<String, dynamic> json) {
    return TemporalStats(
      last7Days: Map<String, double>.from(
        (json['last_7_days'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
      ),
      last30Days: Map<String, double>.from(
        (json['last_30_days'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
      ),
      last90Days: Map<String, double>.from(
        (json['last_90_days'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ) ??
            {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'last_7_days': last7Days,
      'last_30_days': last30Days,
      'last_90_days': last90Days,
    };
  }

  @override
  List<Object?> get props => [last7Days, last30Days, last90Days];

  /// Retorna true si hay actividad reciente
  bool get hasRecentActivity => last7Days.isNotEmpty;
}
