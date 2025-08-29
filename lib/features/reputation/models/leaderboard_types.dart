/// Enums y tipos auxiliares para el sistema de leaderboard

/// Enum para períodos de tiempo del leaderboard
enum LeaderboardPeriod {
  weekly('week', 'Semanal', 7),
  monthly('month', 'Mensual', 30),
  quarterly('quarter', 'Trimestral', 90),
  yearly('year', 'Anual', 365),
  allTime('all', 'Histórico', 0);

  const LeaderboardPeriod(this.apiValue, this.displayName, this.days);

  final String apiValue;
  final String displayName;
  final int days;

  static LeaderboardPeriod fromString(String value) {
    return LeaderboardPeriod.values.firstWhere(
      (period) => period.apiValue == value,
      orElse: () => LeaderboardPeriod.monthly,
    );
  }
}

/// Enum para categorías del leaderboard
enum LeaderboardCategory {
  overall('overall', 'General'),
  trading('trading', 'Intercambios'),
  community('community', 'Comunidad'),
  helpfulness('helpfulness', 'Utilidad');

  const LeaderboardCategory(this.apiValue, this.displayName);

  final String apiValue;
  final String displayName;

  static LeaderboardCategory fromString(String value) {
    return LeaderboardCategory.values.firstWhere(
      (category) => category.apiValue == value,
      orElse: () => LeaderboardCategory.overall,
    );
  }
}
