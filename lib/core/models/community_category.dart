/// Modelo para las categorías de comunidades
class CommunityCategory {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String icon;
  final String color;
  final int communityCount;
  final bool isActive;
  final DateTime createdAt;

  CommunityCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.icon,
    required this.color,
    required this.communityCount,
    required this.isActive,
    required this.createdAt,
  });

  /// Crear desde JSON (API)
  factory CommunityCategory.fromJson(Map<String, dynamic> json) {
    return CommunityCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      color: json['color'] as String? ?? '#2196F3',
      communityCount: json['community_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'icon': icon,
      'color': color,
      'community_count': communityCount,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Copia con modificaciones
  CommunityCategory copyWith({
    int? id,
    String? name,
    String? slug,
    String? description,
    String? icon,
    String? color,
    int? communityCount,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return CommunityCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      communityCount: communityCount ?? this.communityCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'CommunityCategory(id: $id, name: $name, slug: $slug, communityCount: $communityCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
