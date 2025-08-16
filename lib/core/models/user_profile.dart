/// Modelo para el perfil extendido del usuario
class UserProfile {
  final String? bio;
  final String? location;
  final DateTime? birthDate;
  final List<String> favoriteGames;
  final String? playStyle;
  final String? experienceLevel;
  final String? avatarUrl;
  final String? bannerUrl;
  final String? themePreference;

  // Configuraciones de privacidad
  final bool showEmail;
  final bool showLocation;
  final bool showBirthDate;
  final bool showCommunities;
  final bool showActivityStats;

  // Estadísticas
  final int communitiesCount;
  final int postsCount;
  final int likesReceived;
  final int reputationScore;

  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    this.bio,
    this.location,
    this.birthDate,
    this.favoriteGames = const [],
    this.playStyle,
    this.experienceLevel,
    this.avatarUrl,
    this.bannerUrl,
    this.themePreference = 'system',
    this.showEmail = false,
    this.showLocation = true,
    this.showBirthDate = false,
    this.showCommunities = true,
    this.showActivityStats = true,
    this.communitiesCount = 0,
    this.postsCount = 0,
    this.likesReceived = 0,
    this.reputationScore = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Crear UserProfile desde JSON (API response)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      favoriteGames: List<String>.from(json['favorite_games'] ?? []),
      playStyle: json['play_style'] as String?,
      experienceLevel: json['experience_level'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      themePreference: (json['theme_preference'] as String?) ?? 'system',
      showEmail: (json['show_email'] as bool?) ?? false,
      showLocation: (json['show_location'] as bool?) ?? true,
      showBirthDate: (json['show_birth_date'] as bool?) ?? false,
      showCommunities: (json['show_communities'] as bool?) ?? true,
      showActivityStats: (json['show_activity_stats'] as bool?) ?? true,
      communitiesCount: (json['communities_count'] as int?) ?? 0,
      postsCount: (json['posts_count'] as int?) ?? 0,
      likesReceived: (json['likes_received'] as int?) ?? 0,
      reputationScore: (json['reputation_score'] as int?) ?? 0,
      createdAt: DateTime.parse(
        (json['created_at'] as String?) ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        (json['updated_at'] as String?) ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convertir UserProfile a JSON
  Map<String, dynamic> toJson() {
    return {
      'bio': bio,
      'location': location,
      'birth_date': birthDate?.toIso8601String(),
      'favorite_games': favoriteGames,
      'play_style': playStyle,
      'experience_level': experienceLevel,
      'avatar_url': avatarUrl,
      'banner_url': bannerUrl,
      'theme_preference': themePreference,
      'show_email': showEmail,
      'show_location': showLocation,
      'show_birth_date': showBirthDate,
      'show_communities': showCommunities,
      'show_activity_stats': showActivityStats,
      'communities_count': communitiesCount,
      'posts_count': postsCount,
      'likes_received': likesReceived,
      'reputation_score': reputationScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Crear una copia del perfil con campos actualizados
  UserProfile copyWith({
    String? bio,
    String? location,
    DateTime? birthDate,
    List<String>? favoriteGames,
    String? playStyle,
    String? experienceLevel,
    String? avatarUrl,
    String? bannerUrl,
    String? themePreference,
    bool? showEmail,
    bool? showLocation,
    bool? showBirthDate,
    bool? showCommunities,
    bool? showActivityStats,
    int? communitiesCount,
    int? postsCount,
    int? likesReceived,
    int? reputationScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      bio: bio ?? this.bio,
      location: location ?? this.location,
      birthDate: birthDate ?? this.birthDate,
      favoriteGames: favoriteGames ?? this.favoriteGames,
      playStyle: playStyle ?? this.playStyle,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      themePreference: themePreference ?? this.themePreference,
      showEmail: showEmail ?? this.showEmail,
      showLocation: showLocation ?? this.showLocation,
      showBirthDate: showBirthDate ?? this.showBirthDate,
      showCommunities: showCommunities ?? this.showCommunities,
      showActivityStats: showActivityStats ?? this.showActivityStats,
      communitiesCount: communitiesCount ?? this.communitiesCount,
      postsCount: postsCount ?? this.postsCount,
      likesReceived: likesReceived ?? this.likesReceived,
      reputationScore: reputationScore ?? this.reputationScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calcular edad si la fecha de nacimiento está disponible
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// Obtener estilo de juego formateado
  String get formattedPlayStyle {
    switch (playStyle?.toLowerCase()) {
      case 'competitive':
        return 'Competitivo';
      case 'casual':
        return 'Casual';
      case 'collector':
        return 'Coleccionista';
      default:
        return playStyle ?? 'No especificado';
    }
  }

  /// Obtener nivel de experiencia formateado
  String get formattedExperienceLevel {
    switch (experienceLevel?.toLowerCase()) {
      case 'beginner':
        return 'Principiante';
      case 'intermediate':
        return 'Intermedio';
      case 'expert':
        return 'Experto';
      default:
        return experienceLevel ?? 'No especificado';
    }
  }

  @override
  String toString() {
    return 'UserProfile(bio: ${bio?.substring(0, bio!.length > 50 ? 50 : bio!.length)}...)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.bio == bio &&
        other.location == location &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => bio.hashCode ^ location.hashCode ^ createdAt.hashCode;
}
