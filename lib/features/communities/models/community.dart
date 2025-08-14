/// Modelo de datos para una comunidad TCG
/// Incluye toda la información necesaria para mostrar comunidades en la UI
class Community {
  final int id;
  final String name;
  final String description;
  final String gameType;
  final int memberCount;
  final String? imageUrl; // Ahora es opcional
  final bool isSubscribed;
  final DateTime createdAt;
  final List<String> tags;
  final String difficultyLevel;

  const Community({
    required this.id,
    required this.name,
    required this.description,
    required this.gameType,
    required this.memberCount,
    this.imageUrl, // Ya no es required
    required this.isSubscribed,
    required this.createdAt,
    required this.tags,
    required this.difficultyLevel,
  });

  /// Constructor para crear una copia con campos modificados
  Community copyWith({
    int? id,
    String? name,
    String? description,
    String? gameType,
    int? memberCount,
    String? imageUrl,
    bool? isSubscribed,
    DateTime? createdAt,
    List<String>? tags,
    String? difficultyLevel,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      gameType: gameType ?? this.gameType,
      memberCount: memberCount ?? this.memberCount,
      imageUrl: imageUrl ?? this.imageUrl,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
    );
  }

  /// Convierte el modelo a Map para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'game_type': gameType,
      'member_count': memberCount,
      'image_url': imageUrl,
      'is_subscribed': isSubscribed,
      'created_at': createdAt.toIso8601String(),
      'tags': tags,
      'difficulty_level': difficultyLevel,
    };
  }

  /// Crea un modelo desde Map JSON
  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      gameType: json['game_type'] as String,
      memberCount: json['member_count'] as int,
      imageUrl: json['image_url'] as String?,
      isSubscribed: json['is_subscribed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      tags: List<String>.from(json['tags'] as List? ?? []),
      difficultyLevel: json['difficulty_level'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Community && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Community(id: $id, name: $name, gameType: $gameType, members: $memberCount)';
  }
}
