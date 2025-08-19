/// Modelo de comentario con soporte para threading de 3 niveles
/// Compatible con el backend Django de comentarios
class Comment {
  final int id;
  final String content;
  final int authorId;
  final String authorUsername;
  final String? authorAvatarUrl;
  final int postId;
  final int? parentId;
  final int threadLevel;
  final String threadPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final bool canEdit;
  final bool canDelete;
  final int reactionsCount;
  final Map<String, int> reactionsBreakdown;
  final String? userReaction;
  final List<Comment> replies;

  const Comment({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorUsername,
    this.authorAvatarUrl,
    required this.postId,
    this.parentId,
    required this.threadLevel,
    required this.threadPath,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    required this.canEdit,
    required this.canDelete,
    required this.reactionsCount,
    required this.reactionsBreakdown,
    this.userReaction,
    required this.replies,
  });

  /// Crea una instancia desde JSON del backend
  factory Comment.fromJson(Map<String, dynamic> json) {
    // Extraer datos del autor desde el objeto 'author'
    final author = json['author'] as Map<String, dynamic>?;

    return Comment(
      id: json['id'] as int,
      content: json['content'] as String,
      authorId: author?['id'] as int,
      authorUsername: author?['username'] as String,
      authorAvatarUrl: author?['avatar_url'] as String?,
      postId: json['post']?['id'] as int? ?? 0, // Fallback si no está presente
      parentId: json['parent_id'] as int?,
      threadLevel: json['thread_level'] as int? ?? 0,
      threadPath: '', // Campo que no está en la respuesta actual
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isDeleted: false, // Campo que no está en la respuesta actual
      canEdit: json['can_edit'] as bool? ?? false,
      canDelete: json['can_delete'] as bool? ?? false,
      reactionsCount: json['reaction_count'] as int? ?? 0,
      reactionsBreakdown: {}, // Campo que no está en la respuesta actual
      userReaction: null, // Campo que no está en la respuesta actual
      replies: [], // Las respuestas se manejarán por separado
    );
  }

  /// Convierte a JSON para enviar al backend
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'author_id': authorId,
      'author_username': authorUsername,
      'author_avatar_url': authorAvatarUrl,
      'post_id': postId,
      'parent_id': parentId,
      'thread_level': threadLevel,
      'thread_path': threadPath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
      'can_edit': canEdit,
      'can_delete': canDelete,
      'reactions_count': reactionsCount,
      'reactions_breakdown': reactionsBreakdown,
      'user_reaction': userReaction,
      'replies': replies.map((e) => e.toJson()).toList(),
    };
  }

  /// Crea una copia con campos modificados
  Comment copyWith({
    int? id,
    String? content,
    int? authorId,
    String? authorUsername,
    String? authorAvatarUrl,
    int? postId,
    int? parentId,
    int? threadLevel,
    String? threadPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    bool? canEdit,
    bool? canDelete,
    int? reactionsCount,
    Map<String, int>? reactionsBreakdown,
    String? userReaction,
    List<Comment>? replies,
  }) {
    return Comment(
      id: id ?? this.id,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      postId: postId ?? this.postId,
      parentId: parentId ?? this.parentId,
      threadLevel: threadLevel ?? this.threadLevel,
      threadPath: threadPath ?? this.threadPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      reactionsBreakdown: reactionsBreakdown ?? this.reactionsBreakdown,
      userReaction: userReaction ?? this.userReaction,
      replies: replies ?? this.replies,
    );
  }

  /// Verifica si es un comentario principal (nivel 0)
  bool get isMainComment => threadLevel == 0;

  /// Verifica si puede tener respuestas (nivel < 2)
  bool get canHaveReplies => threadLevel < 2;

  /// Obtiene el indicador visual de nivel para UI
  String get levelIndicator {
    switch (threadLevel) {
      case 0:
        return '';
      case 1:
        return '↳ ';
      case 2:
        return '  ↳ ';
      default:
        return '   ↳ ';
    }
  }

  /// Verifica si puede ser editado (15 minutos límite)
  bool get canBeEdited {
    if (!canEdit) return false;
    final now = DateTime.now();
    final editWindow = createdAt.add(const Duration(minutes: 15));
    return now.isBefore(editWindow);
  }

  /// Tiempo restante para editar en minutos
  int get editTimeRemainingMinutes {
    if (!canBeEdited) return 0;
    final now = DateTime.now();
    final editWindow = createdAt.add(const Duration(minutes: 15));
    final remaining = editWindow.difference(now);
    return remaining.inMinutes;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Comment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Comment{id: $id, authorUsername: $authorUsername, threadLevel: $threadLevel, content: ${content.length > 50 ? '${content.substring(0, 50)}...' : content}}';
  }
}

/// Request para crear un nuevo comentario
class CreateCommentRequest {
  final String content;
  final int postId;
  final int? parentId;

  const CreateCommentRequest({
    required this.content,
    required this.postId,
    this.parentId,
  });

  factory CreateCommentRequest.fromJson(Map<String, dynamic> json) {
    return CreateCommentRequest(
      content: json['content'] as String,
      postId: json['post_id'] as int,
      parentId: json['parent_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'content': content, 'post_id': postId, 'parent_id': parentId};
  }
}

/// Request para actualizar un comentario existente
class UpdateCommentRequest {
  final String content;

  const UpdateCommentRequest({required this.content});

  factory UpdateCommentRequest.fromJson(Map<String, dynamic> json) {
    return UpdateCommentRequest(content: json['content'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'content': content};
  }
}

/// Filtros para obtener comentarios
enum CommentSortOrder { newest, oldest, mostReacted }

class CommentsFilter {
  final CommentSortOrder? ordering;
  final int? parentId;
  final bool? isDeleted;
  final int? minReactions;
  final String? search;
  final int page;
  final int pageSize;

  const CommentsFilter({
    this.ordering,
    this.parentId,
    this.isDeleted,
    this.minReactions,
    this.search,
    this.page = 1,
    this.pageSize = 20,
  });

  factory CommentsFilter.fromJson(Map<String, dynamic> json) {
    return CommentsFilter(
      ordering: json['ordering'] != null
          ? CommentSortOrder.values.firstWhere(
              (e) => e.name == json['ordering'],
              orElse: () => CommentSortOrder.newest,
            )
          : null,
      parentId: json['parent_id'] as int?,
      isDeleted: json['is_deleted'] as bool?,
      minReactions: json['min_reactions'] as int?,
      search: json['search'] as String?,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ordering': ordering?.name,
      'parent_id': parentId,
      'is_deleted': isDeleted,
      'min_reactions': minReactions,
      'search': search,
      'page': page,
      'page_size': pageSize,
    };
  }

  /// Crea una copia con campos modificados
  CommentsFilter copyWith({
    CommentSortOrder? ordering,
    int? parentId,
    bool? isDeleted,
    int? minReactions,
    String? search,
    int? page,
    int? pageSize,
  }) {
    return CommentsFilter(
      ordering: ordering ?? this.ordering,
      parentId: parentId ?? this.parentId,
      isDeleted: isDeleted ?? this.isDeleted,
      minReactions: minReactions ?? this.minReactions,
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  /// Filtro por defecto para comentarios principales
  static const CommentsFilter mainComments = CommentsFilter(
    ordering: CommentSortOrder.newest,
    parentId: null, // Solo comentarios principales
  );

  /// Filtro para respuestas de un comentario específico
  static CommentsFilter repliesTo(int parentId) => CommentsFilter(
    ordering: CommentSortOrder.oldest, // Respuestas en orden cronológico
    parentId: parentId,
  );
}
