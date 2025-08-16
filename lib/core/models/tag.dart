/// Modelo para CommunityTag basado en el serializer del backend
class CommunityTag {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String color;
  final bool isActive;
  final int usageCount;
  final DateTime createdAt;

  const CommunityTag({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.color,
    required this.isActive,
    required this.usageCount,
    required this.createdAt,
  });

  /// Crear CommunityTag desde JSON (backend response)
  factory CommunityTag.fromJson(Map<String, dynamic> json) {
    return CommunityTag(
      id:
          json['id'] as int? ??
          0, // Default 0 if null (for popular tags without id)
      name: json['name'] as String,
      slug:
          json['slug'] as String? ??
          json['name'] as String, // Use name as slug if slug missing
      description: json['description'] as String?,
      color: json['color'] as String? ?? '#2196F3', // Default blue if null
      isActive: json['is_active'] as bool? ?? true, // Default true if null
      usageCount: json['usage_count'] as int? ?? 0, // Default 0 if null
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(), // Default to now if null
    );
  }

  /// Convertir CommunityTag a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'color': color,
      'is_active': isActive,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'CommunityTag(id: $id, name: $name, usage: $usageCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityTag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
