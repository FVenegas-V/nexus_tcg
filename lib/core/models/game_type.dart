/// Modelo para GameType basado en el serializer del backend
class GameType {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String? icon;
  final bool isActive;
  final bool isFeatured;
  final int communityCount;
  final int playerCount;
  final DateTime createdAt;

  const GameType({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.icon,
    required this.isActive,
    required this.isFeatured,
    required this.communityCount,
    required this.playerCount,
    required this.createdAt,
  });

  /// Crear GameType desde JSON (backend response)
  factory GameType.fromJson(Map<String, dynamic> json) {
    return GameType(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description:
          json['description'] as String? ?? '', // Default empty if null
      icon:
          json['icon'] as String? ??
          json['logo_url'] as String?, // Try both fields
      isActive: json['is_active'] as bool? ?? true, // Default true if null
      isFeatured:
          json['is_featured'] as bool? ?? false, // Default false if null
      communityCount: json['community_count'] as int? ?? 0, // Default 0 if null
      playerCount: json['player_count'] as int? ?? 0, // Default 0 if null
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(), // Default to now if null
    );
  }

  /// Convertir GameType a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon': icon,
      'is_active': isActive,
      'is_featured': isFeatured,
      'community_count': communityCount,
      'player_count': playerCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'GameType(id: $id, name: $name, communities: $communityCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameType && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
