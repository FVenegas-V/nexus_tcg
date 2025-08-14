/// Modelo de datos para un post en el feed
/// Incluye toda la información necesaria para mostrar posts en la UI
class Post {
  final int id;
  final String content;
  final List<String> imageUrls;
  final PostAuthor author;
  final PostCommunity community;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isBookmarked;

  const Post({
    required this.id,
    required this.content,
    required this.imageUrls,
    required this.author,
    required this.community,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.isBookmarked,
  });

  /// Constructor para crear una copia con campos modificados
  Post copyWith({
    int? id,
    String? content,
    List<String>? imageUrls,
    PostAuthor? author,
    PostCommunity? community,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    bool? isBookmarked,
  }) {
    return Post(
      id: id ?? this.id,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      author: author ?? this.author,
      community: community ?? this.community,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  /// Convierte el modelo a JSON para serialización
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'imageUrls': imageUrls,
      'author': author.toJson(),
      'community': community.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'isLiked': isLiked,
      'isBookmarked': isBookmarked,
    };
  }

  /// Crea un modelo desde JSON para deserialización
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      content: json['content'] as String,
      imageUrls: List<String>.from(json['imageUrls'] as List),
      author: PostAuthor.fromJson(json['author'] as Map<String, dynamic>),
      community: PostCommunity.fromJson(
        json['community'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      likesCount: json['likesCount'] as int,
      commentsCount: json['commentsCount'] as int,
      isLiked: json['isLiked'] as bool,
      isBookmarked: json['isBookmarked'] as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Post && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Post(id: $id, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}, author: ${author.username}, likesCount: $likesCount)';
  }
}

/// Modelo simplificado del autor de un post
class PostAuthor {
  final int id;
  final String username;
  final String? avatarUrl;
  final bool isVerified;

  const PostAuthor({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.isVerified,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatarUrl': avatarUrl,
      'isVerified': isVerified,
    };
  }

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id'] as int,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isVerified: json['isVerified'] as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostAuthor && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Modelo simplificado de la comunidad de un post
class PostCommunity {
  final int id;
  final String name;
  final String gameType;

  const PostCommunity({
    required this.id,
    required this.name,
    required this.gameType,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'gameType': gameType};
  }

  factory PostCommunity.fromJson(Map<String, dynamic> json) {
    return PostCommunity(
      id: json['id'] as int,
      name: json['name'] as String,
      gameType: json['gameType'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostCommunity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
