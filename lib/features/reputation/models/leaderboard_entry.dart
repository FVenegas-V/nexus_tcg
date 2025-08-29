import 'package:equatable/equatable.dart';
import 'reputation_stats.dart';

/// Modelo que representa una entrada en el leaderboard de reputación.
///
/// Corresponde con el endpoint GET /api/users/leaderboard/
/// Incluye información del usuario, posición, y estadísticas destacadas.
class LeaderboardEntry extends Equatable {
  /// Posición en el ranking (1-based)
  final int rank;

  /// ID del usuario
  final int userId;

  /// Nombre de usuario
  final String username;

  /// Nombre completo del usuario (opcional)
  final String? fullName;

  /// URL del avatar (opcional)
  final String? avatarUrl;

  /// Score total de reputación
  final double totalScore;

  /// Nivel de reputación
  final ReputationLevel level;

  /// Número total de valoraciones recibidas
  final int ratingsCount;

  /// Promedio de valoraciones
  final double averageRating;

  /// Cambio de posición vs período anterior
  final RankChange? rankChange;

  /// Insignias/badges especiales del usuario
  final List<String> badges;

  /// Indica si es el usuario actual (para highlighting)
  final bool isCurrentUser;

  /// Fecha de última actividad
  final DateTime? lastActive;

  /// Estado anti-gaming del usuario
  final AntiGamingStatus antiGamingStatus;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.fullName,
    this.avatarUrl,
    required this.totalScore,
    required this.level,
    required this.ratingsCount,
    required this.averageRating,
    this.rankChange,
    this.badges = const [],
    this.isCurrentUser = false,
    this.lastActive,
    required this.antiGamingStatus,
  });

  /// Factory constructor para crear instancia desde JSON del backend
  factory LeaderboardEntry.fromJson(
    Map<String, dynamic> json, {
    int? currentUserId,
  }) {
    final userId = json['user_id'] as int? ?? json['id'] as int;

    return LeaderboardEntry(
      rank: json['rank'] as int,
      userId: userId,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      totalScore: (json['total_score'] as num).toDouble(),
      level: ReputationLevel.fromScore(json['total_score'] as num),
      ratingsCount: json['ratings_count'] as int? ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      rankChange: json['rank_change'] != null
          ? RankChange.fromJson(json['rank_change'] as Map<String, dynamic>)
          : null,
      badges: List<String>.from(json['badges'] as List? ?? []),
      isCurrentUser: currentUserId != null && userId == currentUserId,
      lastActive: json['last_active'] != null
          ? DateTime.parse(json['last_active'] as String)
          : null,
      antiGamingStatus: AntiGamingStatus.fromJson(
        json['anti_gaming_status'] as Map<String, dynamic>? ??
            {'status': 'clean', 'trust_level': 'neutral'},
      ),
    );
  }

  /// Convierte el modelo a Map para serialización
  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'user_id': userId,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'total_score': totalScore,
      'level': level.name,
      'ratings_count': ratingsCount,
      'average_rating': averageRating,
      'rank_change': rankChange?.toJson(),
      'badges': badges,
      'is_current_user': isCurrentUser,
      'last_active': lastActive?.toIso8601String(),
    };
  }

  /// Crea una copia con campos actualizados
  LeaderboardEntry copyWith({
    int? rank,
    int? userId,
    String? username,
    String? fullName,
    String? avatarUrl,
    double? totalScore,
    ReputationLevel? level,
    int? ratingsCount,
    double? averageRating,
    RankChange? rankChange,
    List<String>? badges,
    bool? isCurrentUser,
    DateTime? lastActive,
    AntiGamingStatus? antiGamingStatus,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalScore: totalScore ?? this.totalScore,
      level: level ?? this.level,
      ratingsCount: ratingsCount ?? this.ratingsCount,
      averageRating: averageRating ?? this.averageRating,
      rankChange: rankChange ?? this.rankChange,
      badges: badges ?? this.badges,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      lastActive: lastActive ?? this.lastActive,
      antiGamingStatus: antiGamingStatus ?? this.antiGamingStatus,
    );
  }

  /// Propiedades para comparación con Equatable
  @override
  List<Object?> get props => [
    rank,
    userId,
    username,
    fullName,
    avatarUrl,
    totalScore,
    level,
    ratingsCount,
    averageRating,
    rankChange,
    badges,
    isCurrentUser,
    lastActive,
    antiGamingStatus,
  ];

  // Helpers para UI

  /// Retorna el texto para mostrar el nombre del usuario
  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    return username;
  }

  /// Retorna true si está en el top 3
  bool get isTopThree => rank <= 3;

  /// Retorna true si está en el top 10
  bool get isTopTen => rank <= 10;

  /// Retorna el emoji de la medalla según la posición
  String get medalEmoji {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return ''; // Sin medalla
    }
  }

  /// Retorna el color de fondo para la entrada según la posición
  String get backgroundColorHex {
    if (isCurrentUser) return '#E3F2FD'; // Azul claro para usuario actual

    switch (rank) {
      case 1:
        return '#FFF9C4'; // Amarillo dorado
      case 2:
        return '#F3E5F5'; // Púrpura claro
      case 3:
        return '#E8F5E8'; // Verde claro
      default:
        return isTopTen ? '#F5F5F5' : '#FFFFFF'; // Gris claro para top 10
    }
  }

  /// Retorna true si el usuario ha estado activo recientemente
  bool get isActiveUser {
    if (lastActive == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastActive!);
    return difference.inDays <= 7; // Activo en los últimos 7 días
  }

  /// Retorna el texto de cambio de posición para UI
  String? get rankChangeText {
    final change = rankChange;
    if (change == null) return null;

    switch (change.direction) {
      case RankChangeDirection.up:
        return '↗️ +${change.positions}';
      case RankChangeDirection.down:
        return '↘️ -${change.positions}';
      case RankChangeDirection.same:
        return '➡️ =';
      case RankChangeDirection.newEntry:
        return '🆕 Nuevo';
    }
  }

  /// Retorna el color del cambio de posición
  String? get rankChangeColorHex {
    final change = rankChange;
    if (change == null) return null;

    switch (change.direction) {
      case RankChangeDirection.up:
        return '#4CAF50'; // Verde
      case RankChangeDirection.down:
        return '#F44336'; // Rojo
      case RankChangeDirection.same:
        return '#9E9E9E'; // Gris
      case RankChangeDirection.newEntry:
        return '#2196F3'; // Azul
    }
  }

  /// Retorna true si tiene badges especiales
  bool get hasBadges => badges.isNotEmpty;

  /// Retorna el primer badge para mostrar en UI compacta
  String? get primaryBadge => badges.isNotEmpty ? badges.first : null;

  @override
  String toString() {
    return 'LeaderboardEntry('
        'rank: $rank, '
        'user: $username, '
        'score: $totalScore, '
        'level: ${level.name}, '
        'change: ${rankChange?.direction.name}'
        ')';
  }
}

/// Modelo que representa el cambio de posición en el ranking
class RankChange extends Equatable {
  /// Dirección del cambio
  final RankChangeDirection direction;

  /// Número de posiciones que cambió
  final int positions;

  /// Período de tiempo del cambio (días)
  final int periodDays;

  const RankChange({
    required this.direction,
    required this.positions,
    required this.periodDays,
  });

  factory RankChange.fromJson(Map<String, dynamic> json) {
    return RankChange(
      direction: RankChangeDirection.fromString(
        json['direction'] as String? ?? 'same',
      ),
      positions: json['positions'] as int? ?? 0,
      periodDays: json['period_days'] as int? ?? 7,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'direction': direction.name,
      'positions': positions,
      'period_days': periodDays,
    };
  }

  @override
  List<Object?> get props => [direction, positions, periodDays];

  /// Retorna true si es un cambio significativo (>= 3 posiciones)
  bool get isSignificant => positions >= 3;

  /// Retorna el texto descriptivo del cambio
  String get description {
    switch (direction) {
      case RankChangeDirection.up:
        return 'Subió $positions ${positions == 1 ? 'posición' : 'posiciones'}';
      case RankChangeDirection.down:
        return 'Bajó $positions ${positions == 1 ? 'posición' : 'posiciones'}';
      case RankChangeDirection.same:
        return 'Mantuvo su posición';
      case RankChangeDirection.newEntry:
        return 'Nueva entrada al ranking';
    }
  }
}

/// Enum para direcciones de cambio de ranking
enum RankChangeDirection {
  up('up', 'Subió', '↗️'),
  down('down', 'Bajó', '↘️'),
  same('same', 'Igual', '➡️'),
  newEntry('new', 'Nuevo', '🆕');

  const RankChangeDirection(this.name, this.displayName, this.emoji);

  final String name;
  final String displayName;
  final String emoji;

  static RankChangeDirection fromString(String value) {
    return RankChangeDirection.values.firstWhere(
      (direction) => direction.name == value,
      orElse: () => RankChangeDirection.same,
    );
  }
}

/// Clase auxiliar para construir leaderboards con paginación
class LeaderboardResponse extends Equatable {
  /// Lista de entradas del leaderboard
  final List<LeaderboardEntry> entries;

  /// Información de paginación
  final LeaderboardPagination pagination;

  /// Filtros aplicados
  final LeaderboardFilters filters;

  /// Posición del usuario actual (si está en la lista)
  final int? currentUserRank;

  const LeaderboardResponse({
    required this.entries,
    required this.pagination,
    required this.filters,
    this.currentUserRank,
  });

  factory LeaderboardResponse.fromJson(
    Map<String, dynamic> json, {
    int? currentUserId,
  }) {
    final entriesData =
        json['results'] as List? ?? json['entries'] as List? ?? [];

    return LeaderboardResponse(
      entries: entriesData
          .map(
            (item) => LeaderboardEntry.fromJson(
              item as Map<String, dynamic>,
              currentUserId: currentUserId,
            ),
          )
          .toList(),
      pagination: LeaderboardPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? json,
      ),
      filters: LeaderboardFilters.fromJson(
        json['filters'] as Map<String, dynamic>? ?? {},
      ),
      currentUserRank: json['current_user_rank'] as int?,
    );
  }

  @override
  List<Object?> get props => [entries, pagination, filters, currentUserRank];

  /// Retorna true si hay más páginas disponibles
  bool get hasMorePages => pagination.hasNext;

  /// Retorna la entrada del usuario actual si está en la lista
  LeaderboardEntry? get currentUserEntry {
    try {
      return entries.firstWhere((entry) => entry.isCurrentUser);
    } catch (e) {
      return null;
    }
  }
}

/// Modelo para información de paginación del leaderboard
class LeaderboardPagination extends Equatable {
  final int currentPage;
  final int totalPages;
  final int totalEntries;
  final int pageSize;
  final bool hasNext;
  final bool hasPrevious;

  const LeaderboardPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalEntries,
    required this.pageSize,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory LeaderboardPagination.fromJson(Map<String, dynamic> json) {
    return LeaderboardPagination(
      currentPage: json['current_page'] as int? ?? json['page'] as int? ?? 1,
      totalPages: json['total_pages'] as int? ?? 1,
      totalEntries: json['total_entries'] as int? ?? json['count'] as int? ?? 0,
      pageSize: json['page_size'] as int? ?? 20,
      hasNext: json['has_next'] as bool? ?? false,
      hasPrevious: json['has_previous'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    currentPage,
    totalPages,
    totalEntries,
    pageSize,
    hasNext,
    hasPrevious,
  ];
}

/// Modelo para filtros del leaderboard
class LeaderboardFilters extends Equatable {
  final String? timeRange; // 'week', 'month', 'year', 'all'
  final ReputationLevel? minLevel;
  final String? location;
  final List<String> badges;

  const LeaderboardFilters({
    this.timeRange,
    this.minLevel,
    this.location,
    this.badges = const [],
  });

  factory LeaderboardFilters.fromJson(Map<String, dynamic> json) {
    return LeaderboardFilters(
      timeRange: json['time_range'] as String?,
      minLevel: json['min_level'] != null
          ? ReputationLevel.values.firstWhere(
              (level) => level.name == json['min_level'],
              orElse: () => ReputationLevel.novato,
            )
          : null,
      location: json['location'] as String?,
      badges: List<String>.from(json['badges'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (timeRange != null) 'time_range': timeRange,
      if (minLevel != null) 'min_level': minLevel!.name,
      if (location != null) 'location': location,
      if (badges.isNotEmpty) 'badges': badges,
    };
  }

  @override
  List<Object?> get props => [timeRange, minLevel, location, badges];

  /// Retorna true si hay filtros activos
  bool get hasActiveFilters {
    return timeRange != null ||
        minLevel != null ||
        location != null ||
        badges.isNotEmpty;
  }
}
