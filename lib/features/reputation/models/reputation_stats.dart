import 'package:equatable/equatable.dart';

/// Modelo que representa las estadísticas de reputación de un usuario.
///
/// Corresponde con el endpoint GET /api/users/{user_id}/reputation-stats/
/// Incluye scores, breakdown de factores, y datos para visualización.
class ReputationStats extends Equatable {
  /// Score total de reputación del usuario
  final double totalScore;

  /// Score anterior para mostrar cambios
  final double? previousScore;

  /// Número total de valoraciones recibidas
  final int ratingsCount;

  /// Promedio de valoraciones (1.0 - 5.0)
  final double averageRating;

  /// Distribución de valoraciones por estrellas (1-5)
  final Map<String, int> ratingDistribution;

  /// Nivel de reputación basado en el score
  final ReputationLevel level;

  /// Progreso hacia el siguiente nivel (0.0 - 1.0)
  final double progressToNextLevel;

  /// Breakdown de factores que componen la reputación
  final ReputationBreakdown breakdown;

  /// Indicadores del sistema anti-gaming
  final AntiGamingStatus antiGamingStatus;

  /// Posición en el ranking global (opcional)
  final int? globalRank;

  /// Total de usuarios para calcular percentil
  final int? totalUsers;

  /// Fecha de última actualización
  final DateTime lastUpdated;

  const ReputationStats({
    required this.totalScore,
    this.previousScore,
    required this.ratingsCount,
    required this.averageRating,
    required this.ratingDistribution,
    required this.level,
    required this.progressToNextLevel,
    required this.breakdown,
    required this.antiGamingStatus,
    this.globalRank,
    this.totalUsers,
    required this.lastUpdated,
  });

  /// Factory constructor para crear instancia desde JSON del backend
  factory ReputationStats.fromJson(Map<String, dynamic> json) {
    return ReputationStats(
      totalScore: (json['total_score'] as num).toDouble(),
      previousScore: json['previous_score'] != null
          ? (json['previous_score'] as num).toDouble()
          : null,
      ratingsCount: json['ratings_count'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      ratingDistribution: Map<String, int>.from(
        json['rating_distribution'] as Map<String, dynamic>? ??
            {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
      ),
      level: ReputationLevel.fromScore(json['total_score'] as num? ?? 0),
      progressToNextLevel:
          (json['progress_to_next_level'] as num?)?.toDouble() ?? 0.0,
      breakdown: ReputationBreakdown.fromJson(
        json['breakdown'] as Map<String, dynamic>? ?? {},
      ),
      antiGamingStatus: AntiGamingStatus.fromJson(
        json['anti_gaming_status'] as Map<String, dynamic>? ?? {},
      ),
      globalRank: json['global_rank'] as int?,
      totalUsers: json['total_users'] as int?,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : DateTime.now(),
    );
  }

  /// Convierte el modelo a Map para serialización
  Map<String, dynamic> toJson() {
    return {
      'total_score': totalScore,
      'previous_score': previousScore,
      'ratings_count': ratingsCount,
      'average_rating': averageRating,
      'rating_distribution': ratingDistribution,
      'level': level.name,
      'progress_to_next_level': progressToNextLevel,
      'breakdown': breakdown.toJson(),
      'anti_gaming_status': antiGamingStatus.toJson(),
      'global_rank': globalRank,
      'total_users': totalUsers,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  /// Crea una copia con campos actualizados
  ReputationStats copyWith({
    double? totalScore,
    double? previousScore,
    int? ratingsCount,
    double? averageRating,
    Map<String, int>? ratingDistribution,
    ReputationLevel? level,
    double? progressToNextLevel,
    ReputationBreakdown? breakdown,
    AntiGamingStatus? antiGamingStatus,
    int? globalRank,
    int? totalUsers,
    DateTime? lastUpdated,
  }) {
    return ReputationStats(
      totalScore: totalScore ?? this.totalScore,
      previousScore: previousScore ?? this.previousScore,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      averageRating: averageRating ?? this.averageRating,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
      level: level ?? this.level,
      progressToNextLevel: progressToNextLevel ?? this.progressToNextLevel,
      breakdown: breakdown ?? this.breakdown,
      antiGamingStatus: antiGamingStatus ?? this.antiGamingStatus,
      globalRank: globalRank ?? this.globalRank,
      totalUsers: totalUsers ?? this.totalUsers,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Propiedades para comparación con Equatable
  @override
  List<Object?> get props => [
    totalScore,
    previousScore,
    ratingsCount,
    averageRating,
    ratingDistribution,
    level,
    progressToNextLevel,
    breakdown,
    antiGamingStatus,
    globalRank,
    totalUsers,
    lastUpdated,
  ];

  // Helpers para UI

  /// Retorna el cambio de score vs anterior
  double? get scoreChange {
    if (previousScore == null) return null;
    return totalScore - previousScore!;
  }

  /// Retorna true si el score ha mejorado
  bool get hasImproved {
    final change = scoreChange;
    return change != null && change > 0;
  }

  /// Retorna true si el score ha empeorado
  bool get hasDeclined {
    final change = scoreChange;
    return change != null && change < 0;
  }

  /// Retorna el percentil del usuario (0-100)
  double? get percentile {
    if (globalRank == null || totalUsers == null || totalUsers == 0)
      return null;
    return ((totalUsers! - globalRank!) / totalUsers!) * 100;
  }

  /// Retorna texto descriptivo del percentil
  String? get percentileText {
    final p = percentile;
    if (p == null) return null;

    if (p >= 95) return 'Top 5%';
    if (p >= 90) return 'Top 10%';
    if (p >= 75) return 'Top 25%';
    if (p >= 50) return 'Top 50%';
    return 'Bottom ${(100 - p).round()}%';
  }

  /// Retorna true si es elegible para funciones especiales
  bool get isEligibleForSpecialFeatures {
    return totalScore >= 500 &&
        antiGamingStatus.trustLevel == TrustLevel.verified;
  }

  @override
  String toString() {
    return 'ReputationStats('
        'score: $totalScore, '
        'level: ${level.name}, '
        'ratings: $ratingsCount, '
        'avg: ${averageRating.toStringAsFixed(1)}, '
        'rank: $globalRank'
        ')';
  }
}

/// Enum que representa los niveles de reputación
enum ReputationLevel {
  novato(0, 99, 'Novato', '🌱'),
  aprendiz(100, 499, 'Aprendiz', '⭐'),
  experto(500, 999, 'Experto', '🏆'),
  maestro(1000, 2499, 'Maestro', '👑'),
  leyenda(2500, 9999, 'Leyenda', '💎');

  const ReputationLevel(
    this.minScore,
    this.maxScore,
    this.displayName,
    this.emoji,
  );

  final int minScore;
  final int maxScore;
  final String displayName;
  final String emoji;

  /// Factory para determinar nivel basado en score
  static ReputationLevel fromScore(num score) {
    final intScore = score.toInt();

    if (intScore >= leyenda.minScore) return leyenda;
    if (intScore >= maestro.minScore) return maestro;
    if (intScore >= experto.minScore) return experto;
    if (intScore >= aprendiz.minScore) return aprendiz;
    return novato;
  }

  /// Retorna el siguiente nivel
  ReputationLevel? get nextLevel {
    switch (this) {
      case novato:
        return aprendiz;
      case aprendiz:
        return experto;
      case experto:
        return maestro;
      case maestro:
        return leyenda;
      case leyenda:
        return null; // Nivel máximo
    }
  }

  /// Retorna el color hexadecimal para UI
  String get colorHex {
    switch (this) {
      case novato:
        return '#9E9E9E'; // Gris
      case aprendiz:
        return '#2196F3'; // Azul
      case experto:
        return '#4CAF50'; // Verde
      case maestro:
        return '#FF9800'; // Naranja
      case leyenda:
        return '#9C27B0'; // Púrpura
    }
  }
}

/// Modelo que representa el breakdown detallado de factores de reputación
class ReputationBreakdown extends Equatable {
  final double baseRating;
  final double volumeBonus;
  final double consistencyBonus;
  final double timeDecay;
  final double antiGamingPenalty;
  final double specialBonus;

  const ReputationBreakdown({
    required this.baseRating,
    required this.volumeBonus,
    required this.consistencyBonus,
    required this.timeDecay,
    required this.antiGamingPenalty,
    required this.specialBonus,
  });

  factory ReputationBreakdown.fromJson(Map<String, dynamic> json) {
    return ReputationBreakdown(
      baseRating: (json['base_rating'] as num?)?.toDouble() ?? 0.0,
      volumeBonus: (json['volume_bonus'] as num?)?.toDouble() ?? 0.0,
      consistencyBonus: (json['consistency_bonus'] as num?)?.toDouble() ?? 0.0,
      timeDecay: (json['time_decay'] as num?)?.toDouble() ?? 0.0,
      antiGamingPenalty:
          (json['anti_gaming_penalty'] as num?)?.toDouble() ?? 0.0,
      specialBonus: (json['special_bonus'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_rating': baseRating,
      'volume_bonus': volumeBonus,
      'consistency_bonus': consistencyBonus,
      'time_decay': timeDecay,
      'anti_gaming_penalty': antiGamingPenalty,
      'special_bonus': specialBonus,
    };
  }

  @override
  List<Object?> get props => [
    baseRating,
    volumeBonus,
    consistencyBonus,
    timeDecay,
    antiGamingPenalty,
    specialBonus,
  ];

  /// Lista de factores para mostrar en UI
  List<ReputationFactor> get factors {
    return [
      ReputationFactor('Valoraciones Base', baseRating, '⭐'),
      if (volumeBonus > 0) ReputationFactor('Bonus Volumen', volumeBonus, '📈'),
      if (consistencyBonus > 0)
        ReputationFactor('Bonus Consistencia', consistencyBonus, '🎯'),
      if (timeDecay < 0)
        ReputationFactor('Decaimiento Temporal', timeDecay, '⏰'),
      if (antiGamingPenalty < 0)
        ReputationFactor('Penalización Gaming', antiGamingPenalty, '🛡️'),
      if (specialBonus > 0)
        ReputationFactor('Bonus Especial', specialBonus, '🌟'),
    ];
  }
}

/// Modelo que representa el estado del sistema anti-gaming
class AntiGamingStatus extends Equatable {
  final TrustLevel trustLevel;
  final double suspicionScore;
  final List<String> flags;
  final bool isUnderReview;

  const AntiGamingStatus({
    required this.trustLevel,
    required this.suspicionScore,
    required this.flags,
    required this.isUnderReview,
  });

  factory AntiGamingStatus.fromJson(Map<String, dynamic> json) {
    return AntiGamingStatus(
      trustLevel: TrustLevel.fromString(
        json['trust_level'] as String? ?? 'unknown',
      ),
      suspicionScore: (json['suspicion_score'] as num?)?.toDouble() ?? 0.0,
      flags: List<String>.from(json['flags'] as List? ?? []),
      isUnderReview: json['is_under_review'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trust_level': trustLevel.name,
      'suspicion_score': suspicionScore,
      'flags': flags,
      'is_under_review': isUnderReview,
    };
  }

  @override
  List<Object?> get props => [trustLevel, suspicionScore, flags, isUnderReview];

  bool get hasFlags => flags.isNotEmpty;
  bool get isTrusted => trustLevel == TrustLevel.verified;
}

/// Enum para niveles de confianza anti-gaming
enum TrustLevel {
  verified('verified', 'Verificado', '✅'),
  trusted('trusted', 'Confiable', '🟢'),
  neutral('neutral', 'Neutral', '🟡'),
  suspicious('suspicious', 'Sospechoso', '🟠'),
  flagged('flagged', 'Marcado', '🔴'),
  unknown('unknown', 'Desconocido', '❓');

  const TrustLevel(this.name, this.displayName, this.emoji);

  final String name;
  final String displayName;
  final String emoji;

  static TrustLevel fromString(String value) {
    return TrustLevel.values.firstWhere(
      (level) => level.name == value,
      orElse: () => TrustLevel.unknown,
    );
  }
}

/// Clase auxiliar para mostrar factores individuales en UI
class ReputationFactor extends Equatable {
  final String name;
  final double value;
  final String emoji;

  const ReputationFactor(this.name, this.value, this.emoji);

  @override
  List<Object?> get props => [name, value, emoji];

  String get displayValue {
    if (value >= 0) {
      return '+${value.toStringAsFixed(1)}';
    } else {
      return value.toStringAsFixed(1);
    }
  }

  String get colorHex {
    if (value > 0) return '#4CAF50'; // Verde para positivos
    if (value < 0) return '#F44336'; // Rojo para negativos
    return '#9E9E9E'; // Gris para neutros
  }
}
