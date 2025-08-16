/// Modelo para tags/etiquetas de comunidades
/// Representa categorías dinámicas para clasificar comunidades
class CommunityTag {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String color; // Color hexadecimal para UI
  final int usageCount;
  final int? createdBy; // ID del usuario que creó el tag
  final DateTime createdAt;

  const CommunityTag({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.color,
    required this.usageCount,
    this.createdBy,
    required this.createdAt,
  });

  /// Color como objeto Color para usar en la UI
  int get colorValue {
    // Remover # si existe y convertir a int
    final colorString = color.replaceAll('#', '');
    return int.parse('FF$colorString', radix: 16);
  }

  /// Indica si es un tag popular (más de 5 usos)
  bool get isPopular => usageCount >= 5;

  /// Indica si es un tag nuevo (menos de 24 horas)
  bool get isNew {
    final now = DateTime.now();
    return now.difference(createdAt).inHours < 24;
  }

  /// Constructor desde JSON (respuesta de la API)
  factory CommunityTag.fromJson(Map<String, dynamic> json) {
    return CommunityTag(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'] ?? '',
      color: json['color'] ?? '#3F51B5', // Azul por defecto
      usageCount: json['usage_count'] ?? 0,
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  /// Constructor para crear desde un string simple (para tags dinámicos)
  factory CommunityTag.fromString(String tagName) {
    return CommunityTag(
      id: 0, // ID temporal para tags nuevos
      name: tagName.toLowerCase().trim(),
      slug: tagName.toLowerCase().replaceAll(' ', '-'),
      description: 'Tag creado dinámicamente: $tagName',
      color: '#9E9E9E', // Gris para tags no oficiales
      usageCount: 0,
      createdAt: DateTime.now(),
    );
  }

  /// Convertir a JSON para envío a API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'color': color,
      'usage_count': usageCount,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Constructor para crear una copia con campos modificados
  CommunityTag copyWith({
    int? id,
    String? name,
    String? slug,
    String? description,
    String? color,
    int? usageCount,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return CommunityTag(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      color: color ?? this.color,
      usageCount: usageCount ?? this.usageCount,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'CommunityTag(id: $id, name: $name, usageCount: $usageCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityTag && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
