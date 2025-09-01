import 'post_image.dart';

/// Modelo para Post basado en las APIs del backend Fase 3
///
/// Representa un post en una comunidad con soporte para:
/// - Imágenes múltiples con diferentes resoluciones
/// - Contadores de comentarios y reacciones
/// - Sistema de reacciones con 6 tipos de emoji
/// - Soft delete y timestamps completos
class Post {
  final int id;
  final String title;
  final String content;
  final int communityId;
  final String communityName;
  final int authorId;
  final String authorUsername;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool isDeleted;

  // Contadores automáticos (manejados por signals del backend)
  final int commentsCount;
  final int reactionsCount;

  // Imágenes asociadas al post
  final List<PostImage> images;

  // Info de imagen para el feed (optimización)
  final String? thumbnailUrl;
  final bool hasImages;

  // Reacciones del usuario actual
  final String? userReaction; // null si no ha reaccionado, o tipo de reacción

  // Breakdown de reacciones
  final Map<String, int> reactionsBreakdown;

  const Post({
    required this.id,
    required this.title,
    required this.content,
    required this.communityId,
    required this.communityName,
    required this.authorId,
    required this.authorUsername,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.isDeleted = false,
    this.commentsCount = 0,
    this.reactionsCount = 0,
    this.images = const [],
    this.thumbnailUrl,
    this.hasImages = false,
    this.userReaction,
    this.reactionsBreakdown = const {},
  });

  /// Procesa el reactions_breakdown del backend y lo convierte al formato esperado
  static Map<String, int> _parseReactionsBreakdown(dynamic breakdown) {
    print("🔍 DEBUG Post._parseReactionsBreakdown - Input: $breakdown");
    if (breakdown == null) return {};

    // Si tiene la estructura nueva del backend: {total_count: X, breakdown: {...}}
    if (breakdown is Map<String, dynamic> &&
        breakdown.containsKey('breakdown')) {
      print("🔍 DEBUG Post._parseReactionsBreakdown - Formato nuevo detectado");
      final reactionsMap =
          breakdown['breakdown'] as Map<String, dynamic>? ?? {};
      final result = <String, int>{};

      reactionsMap.forEach((key, value) {
        if (value is Map<String, dynamic> && value.containsKey('count')) {
          result[key] = _parseIntSafely(value['count']);
        }
      });

      print("🔍 DEBUG Post._parseReactionsBreakdown - Resultado: $result");
      return result;
    }

    // Si ya es un Map<String, int> directo (formato anterior)
    if (breakdown is Map<String, dynamic> &&
        breakdown.keys.any((key) => breakdown[key] is int)) {
      print(
        "🔍 DEBUG Post._parseReactionsBreakdown - Formato anterior detectado",
      );
      return Map<String, int>.from(breakdown);
    }

    print(
      "🔍 DEBUG Post._parseReactionsBreakdown - Formato no reconocido, retornando vacío",
    );
    return {};
  }

  /// Parsea un valor a int de forma segura
  static int _parseIntSafely(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Crear Post desde JSON (response del backend)
  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? json['excerpt'] as String? ?? '',

      // Manejar comunidad (puede venir como objeto o campos planos)
      communityId:
          json['community_id'] as int? ??
          (json['community'] != null
              ? (json['community']['id'] is int
                    ? json['community']['id'] as int
                    : int.tryParse(json['community']['id'].toString()) ?? 0)
              : 0),
      communityName:
          json['community_name'] as String? ??
          (json['community'] != null
              ? json['community']['name'] as String?
              : null) ??
          'Comunidad',

      // Manejar autor (puede venir como objeto o campos planos)
      authorId:
          json['author_id'] as int? ??
          (json['author'] != null
              ? (json['author']['id'] is int
                    ? json['author']['id'] as int
                    : int.tryParse(json['author']['id'].toString()) ?? 0)
              : 0),
      authorUsername:
          json['author_username'] as String? ??
          (json['author'] != null
              ? json['author']['username'] as String?
              : null) ??
          'Usuario',

      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,

      // Manejar contadores (diferentes nombres en backend)
      commentsCount: _parseIntSafely(
        json['comments_count'] ?? json['comment_count'],
      ),
      reactionsCount: _parseIntSafely(
        json['reactions_count'] ?? json['reaction_count'],
      ),

      images: json['images'] != null
          ? (json['images'] as List)
                .map((img) => PostImage.fromJson(img))
                .toList()
          : [],

      // Info de imagen para el feed
      thumbnailUrl: json['thumbnail_url'] as String?,
      hasImages: json['has_images'] as bool? ?? false,

      userReaction: json['user_reaction'] as String?,
      reactionsBreakdown: () {
        print(
          "🔍 DEBUG Post.fromJson - Post ${json['id']} iniciando parsing reaction_breakdown",
        );
        print(
          "🔍 DEBUG Post.fromJson - json['reaction_breakdown'] != null: ${json['reaction_breakdown'] != null}",
        );
        print(
          "🔍 DEBUG Post.fromJson - json['reaction_breakdown']: ${json['reaction_breakdown']}",
        );

        if (json['reaction_breakdown'] != null) {
          print(
            "🔍 DEBUG Post.fromJson - Procesando reaction_breakdown para post ${json['id']}",
          );
          final result = Post._parseReactionsBreakdown(
            json['reaction_breakdown'],
          );
          print(
            "🔍 DEBUG Post.fromJson - Post ${json['id']} reactionsBreakdown final: $result",
          );
          return result;
        } else {
          print(
            "🔍 DEBUG Post.fromJson - Post ${json['id']} reaction_breakdown es null, retornando {}",
          );
          return <String, int>{};
        }
      }(),
    );
  }

  /// Convertir Post a JSON (para envío al backend)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'community_id': communityId,
      'author_id': authorId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
      'is_deleted': isDeleted,
      'comments_count': commentsCount,
      'reactions_count': reactionsCount,
      'images': images.map((img) => img.toJson()).toList(),
      'thumbnail_url': thumbnailUrl,
      'has_images': hasImages,
      'user_reaction': userReaction,
      'reactions_breakdown': reactionsBreakdown,
    };
  }

  /// Crear copia del Post con campos modificados
  Post copyWith({
    int? id,
    String? title,
    String? content,
    int? communityId,
    String? communityName,
    int? authorId,
    String? authorUsername,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isDeleted,
    int? commentsCount,
    int? reactionsCount,
    List<PostImage>? images,
    String? thumbnailUrl,
    bool? hasImages,
    String? userReaction,
    Map<String, int>? reactionsBreakdown,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      communityId: communityId ?? this.communityId,
      communityName: communityName ?? this.communityName,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      commentsCount: commentsCount ?? this.commentsCount,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      images: images ?? this.images,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      hasImages: hasImages ?? this.hasImages,
      userReaction: userReaction ?? this.userReaction,
      reactionsBreakdown: reactionsBreakdown ?? this.reactionsBreakdown,
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
    return 'Post{id: $id, title: $title, authorUsername: $authorUsername, commentsCount: $commentsCount, reactionsCount: $reactionsCount}';
  }
}

/// Clase para crear un nuevo post
class CreatePostRequest {
  final String title;
  final String content;
  final int communityId;
  final List<String>? imagePaths; // Rutas locales de imágenes para upload

  const CreatePostRequest({
    required this.title,
    required this.content,
    required this.communityId,
    this.imagePaths,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'community':
          communityId, // El backend espera 'community' no 'community_id'
    };
  }
}

/// Clase para actualizar un post existente
class UpdatePostRequest {
  final String? title;
  final String? content;

  const UpdatePostRequest({this.title, this.content});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (content != null) data['content'] = content;
    return data;
  }
}
