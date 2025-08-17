/// Modelo para Community basado en los serializers del backend
class Community {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String? categoryName;
  final String gameType;
  final String difficultyLevel;
  final List<String> tags;
  final String? rules;
  final bool isPublic;
  final bool isFeatured;
  final int memberCount;
  final int postCount;
  final int? maxMembers;
  final bool requiresApproval;
  final String? imageUrl;
  final String? bannerUrl;
  final String? createdByUsername;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isSubscribed; // Nuevo campo para estado de membresía

  const Community({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.categoryName,
    required this.gameType,
    required this.difficultyLevel,
    required this.tags,
    this.rules,
    required this.isPublic,
    required this.isFeatured,
    required this.memberCount,
    required this.postCount,
    this.maxMembers,
    required this.requiresApproval,
    this.imageUrl,
    this.bannerUrl,
    this.createdByUsername,
    required this.createdAt,
    this.updatedAt,
    this.isSubscribed = false, // Valor por defecto
  });

  /// Crear Community desde JSON (lista - backend response)
  factory Community.fromListJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String,
      categoryName: json['category_name'] as String?,
      gameType: (json['game_type'] is int)
          ? json['game_type'].toString()
          : json['game_type'] as String,
      difficultyLevel: json['difficulty_level'] as String,
      tags: List<String>.from(json['tags'] ?? []), // Incluir tags desde API
      isPublic: json['is_public'] as bool,
      isFeatured: json['is_featured'] as bool? ?? false,
      memberCount: json['member_count'] as int,
      postCount: 0, // No disponible en lista
      requiresApproval: false, // No disponible en lista
      createdByUsername: json['created_by_username'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isSubscribed: json['is_subscribed'] as bool? ?? false, // Desde API
    );
  }

  /// Crear Community desde JSON (detalle - backend response)
  factory Community.fromDetailJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String,
      gameType: (json['game_type'] is int)
          ? json['game_type'].toString()
          : json['game_type'] as String,
      difficultyLevel: json['difficulty_level'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      rules: json['rules'] as String?,
      isPublic: json['is_public'] as bool,
      isFeatured: json['is_featured'] as bool? ?? false,
      memberCount: json['member_count'] as int,
      postCount: json['post_count'] as int,
      maxMembers: json['max_members'] as int?,
      requiresApproval: json['requires_approval'] as bool,
      imageUrl: json['image_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isSubscribed: json['is_subscribed'] as bool? ?? false, // Desde API
    );
  }

  /// Convertir Community a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'category_name': categoryName,
      'game_type': gameType,
      'difficulty_level': difficultyLevel,
      'tags': tags,
      'rules': rules,
      'is_public': isPublic,
      'is_featured': isFeatured,
      'member_count': memberCount,
      'post_count': postCount,
      'max_members': maxMembers,
      'requires_approval': requiresApproval,
      'image_url': imageUrl,
      'banner_url': bannerUrl,
      'created_by_username': createdByUsername,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Community(id: $id, name: $name, members: $memberCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Community && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Crear una copia de la comunidad con campos actualizados
  Community copyWith({
    int? id,
    String? name,
    String? slug,
    String? description,
    String? categoryName,
    String? gameType,
    String? difficultyLevel,
    List<String>? tags,
    String? rules,
    bool? isPublic,
    bool? isFeatured,
    int? memberCount,
    int? postCount,
    int? maxMembers,
    bool? requiresApproval,
    String? imageUrl,
    String? bannerUrl,
    String? createdByUsername,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSubscribed,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      categoryName: categoryName ?? this.categoryName,
      gameType: gameType ?? this.gameType,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      tags: tags ?? this.tags,
      rules: rules ?? this.rules,
      isPublic: isPublic ?? this.isPublic,
      isFeatured: isFeatured ?? this.isFeatured,
      memberCount: memberCount ?? this.memberCount,
      postCount: postCount ?? this.postCount,
      maxMembers: maxMembers ?? this.maxMembers,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      imageUrl: imageUrl ?? this.imageUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      createdByUsername: createdByUsername ?? this.createdByUsername,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSubscribed: isSubscribed ?? this.isSubscribed,
    );
  }
}

/// Modelo para CommunityCategory basado en el serializer del backend
class CommunityCategory {
  final int id;
  final String name;
  final String slug;
  final String description;
  final String? icon;
  final String? color;
  final int communityCount;
  final bool isActive;
  final DateTime createdAt;

  const CommunityCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.icon,
    this.color,
    required this.communityCount,
    required this.isActive,
    required this.createdAt,
  });

  /// Crear CommunityCategory desde JSON (backend response)
  factory CommunityCategory.fromJson(Map<String, dynamic> json) {
    return CommunityCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      communityCount: json['community_count'] as int,
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convertir CommunityCategory a JSON
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

  @override
  String toString() {
    return 'CommunityCategory(id: $id, name: $name, communities: $communityCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
