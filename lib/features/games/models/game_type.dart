/// Modelo para tipos de juego (TCG)
/// Representa información de un Trading Card Game específico
class GameType {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String publisher;
  final int releaseYear;
  final int minPlayers;
  final int maxPlayers;
  final bool isFeatured;
  final int communityCount;
  final DateTime createdAt;

  const GameType({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.publisher,
    required this.releaseYear,
    required this.minPlayers,
    required this.maxPlayers,
    required this.isFeatured,
    required this.communityCount,
    required this.createdAt,
  });

  /// Rango de jugadores formateado
  String get playersRange {
    if (minPlayers == maxPlayers) {
      return '$minPlayers jugadores';
    }
    return '$minPlayers-$maxPlayers jugadores';
  }

  /// Estado del año de lanzamiento
  String get yearStatus {
    final currentYear = DateTime.now().year;
    final yearsAgo = currentYear - releaseYear;

    if (yearsAgo >= 30) {
      return 'Más de $yearsAgo años en el mercado';
    } else if (yearsAgo >= 10) {
      return '$yearsAgo años establecido';
    } else if (yearsAgo >= 5) {
      return '$yearsAgo años en desarrollo';
    } else {
      return 'Game relativamente nuevo ($yearsAgo años)';
    }
  }

  /// Constructor desde JSON (respuesta de la API)
  factory GameType.fromJson(Map<String, dynamic> json) {
    return GameType(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'] ?? '',
      publisher: json['publisher'] ?? '',
      releaseYear: json['release_year'] ?? DateTime.now().year,
      minPlayers: json['min_players'] ?? 2,
      maxPlayers: json['max_players'] ?? 2,
      isFeatured: json['is_featured'] ?? false,
      communityCount: json['community_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// Convertir a JSON para envío a API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'publisher': publisher,
      'release_year': releaseYear,
      'min_players': minPlayers,
      'max_players': maxPlayers,
      'is_featured': isFeatured,
      'community_count': communityCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Constructor para crear una copia con campos modificados
  GameType copyWith({
    int? id,
    String? name,
    String? slug,
    String? description,
    String? publisher,
    int? releaseYear,
    int? minPlayers,
    int? maxPlayers,
    bool? isFeatured,
    int? communityCount,
    DateTime? createdAt,
  }) {
    return GameType(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      publisher: publisher ?? this.publisher,
      releaseYear: releaseYear ?? this.releaseYear,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      isFeatured: isFeatured ?? this.isFeatured,
      communityCount: communityCount ?? this.communityCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'GameType(id: $id, name: $name, publisher: $publisher)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameType && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
