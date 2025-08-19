/// Modelo para Reaction basado en las APIs del backend Fase 3
///
/// Representa una reacción de un usuario a un post o comentario con soporte para:
/// - 6 tipos de emoji (like, love, laugh, wow, sad, angry)
/// - Toggle automático inteligente
/// - Breakdown estadístico detallado
/// - Sistema transaccional para consistencia
class Reaction {
  final int id;
  final int userId;
  final String username;
  final ReactionType reactionType;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Referencia al objeto reaccionado (post o comentario)
  final int? postId;
  final int? commentId;

  const Reaction({
    required this.id,
    required this.userId,
    required this.username,
    required this.reactionType,
    required this.createdAt,
    this.updatedAt,
    this.postId,
    this.commentId,
  });

  /// Crear Reaction desde JSON (response del backend)
  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      username: json['username'] as String? ?? 'Usuario',
      reactionType: ReactionType.fromString(json['reaction_type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      postId: json['post_id'] as int?,
      commentId: json['comment_id'] as int?,
    );
  }

  /// Convertir Reaction a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'reaction_type': reactionType.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'post_id': postId,
      'comment_id': commentId,
    };
  }

  /// Crear copia de la Reaction con campos modificados
  Reaction copyWith({
    int? id,
    int? userId,
    String? username,
    ReactionType? reactionType,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? postId,
    int? commentId,
  }) {
    return Reaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      reactionType: reactionType ?? this.reactionType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reaction &&
        other.id == id &&
        other.userId == userId &&
        other.reactionType == reactionType;
  }

  @override
  int get hashCode => Object.hash(id, userId, reactionType);

  @override
  String toString() {
    return 'Reaction{id: $id, userId: $userId, type: ${reactionType.value}, postId: $postId, commentId: $commentId}';
  }
}

/// Enum para los 6 tipos de reacciones soportadas
enum ReactionType {
  like('like'),
  love('love'),
  laugh('laugh'),
  wow('wow'),
  sad('sad'),
  angry('angry');

  const ReactionType(this.value);

  final String value;

  /// Crear ReactionType desde string
  static ReactionType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'like':
        return ReactionType.like;
      case 'love':
        return ReactionType.love;
      case 'laugh':
        return ReactionType.laugh;
      case 'wow':
        return ReactionType.wow;
      case 'sad':
        return ReactionType.sad;
      case 'angry':
        return ReactionType.angry;
      default:
        throw ArgumentError('Tipo de reacción no válido: $value');
    }
  }

  /// Obtener emoji correspondiente al tipo de reacción
  String get emoji {
    switch (this) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.laugh:
        return '😂';
      case ReactionType.wow:
        return '😮';
      case ReactionType.sad:
        return '😢';
      case ReactionType.angry:
        return '😠';
    }
  }

  /// Obtener nombre display del tipo de reacción
  String get displayName {
    switch (this) {
      case ReactionType.like:
        return 'Me gusta';
      case ReactionType.love:
        return 'Me encanta';
      case ReactionType.laugh:
        return 'Me divierte';
      case ReactionType.wow:
        return 'Me asombra';
      case ReactionType.sad:
        return 'Me entristece';
      case ReactionType.angry:
        return 'Me enoja';
    }
  }

  /// Obtener color asociado al tipo de reacción
  String get colorHex {
    switch (this) {
      case ReactionType.like:
        return '#3578E5'; // Azul Facebook
      case ReactionType.love:
        return '#E74C3C'; // Rojo corazón
      case ReactionType.laugh:
        return '#F39C12'; // Amarillo risa
      case ReactionType.wow:
        return '#F39C12'; // Amarillo asombro
      case ReactionType.sad:
        return '#F39C12'; // Amarillo tristeza
      case ReactionType.angry:
        return '#E67E22'; // Naranja enojo
    }
  }
}

/// Clase para breakdown estadístico de reacciones
class ReactionsBreakdown {
  final Map<ReactionType, int> counts;
  final Map<ReactionType, List<String>> usernames; // Usuarios que reaccionaron
  final int totalCount;
  final ReactionType? userReaction; // Reacción del usuario actual

  const ReactionsBreakdown({
    required this.counts,
    required this.usernames,
    required this.totalCount,
    this.userReaction,
  });

  /// Crear ReactionsBreakdown desde JSON
  factory ReactionsBreakdown.fromJson(Map<String, dynamic> json) {
    final Map<ReactionType, int> counts = {};
    final Map<ReactionType, List<String>> usernames = {};

    // Procesar conteos
    if (json['counts'] != null) {
      final Map<String, dynamic> countsData = json['counts'];
      for (final entry in countsData.entries) {
        final type = ReactionType.fromString(entry.key);
        counts[type] = entry.value as int;
      }
    }

    // Procesar usernames
    if (json['usernames'] != null) {
      final Map<String, dynamic> usernamesData = json['usernames'];
      for (final entry in usernamesData.entries) {
        final type = ReactionType.fromString(entry.key);
        usernames[type] = List<String>.from(entry.value);
      }
    }

    return ReactionsBreakdown(
      counts: counts,
      usernames: usernames,
      totalCount: json['total_count'] as int? ?? 0,
      userReaction: json['user_reaction'] != null
          ? ReactionType.fromString(json['user_reaction'])
          : null,
    );
  }

  /// Convertir ReactionsBreakdown a JSON
  Map<String, dynamic> toJson() {
    return {
      'counts': counts.map((key, value) => MapEntry(key.value, value)),
      'usernames': usernames.map((key, value) => MapEntry(key.value, value)),
      'total_count': totalCount,
      'user_reaction': userReaction?.value,
    };
  }

  /// Obtener tipos de reacciones ordenados por cantidad (descendente)
  List<ReactionType> get topReactionTypes {
    final entries = counts.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }

  /// Verificar si hay reacciones
  bool get hasReactions => totalCount > 0;

  /// Obtener el conteo de un tipo específico
  int getCount(ReactionType type) => counts[type] ?? 0;

  /// Obtener los usernames de un tipo específico
  List<String> getUsernames(ReactionType type) => usernames[type] ?? [];

  @override
  String toString() {
    return 'ReactionsBreakdown{totalCount: $totalCount, userReaction: $userReaction, types: ${counts.length}}';
  }
}

/// Clase para crear/toggle una reacción
class ReactionRequest {
  final ReactionType reactionType;

  const ReactionRequest({required this.reactionType});

  Map<String, dynamic> toJson() {
    return {'reaction_type': reactionType.value};
  }
}
