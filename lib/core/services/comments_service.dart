import 'package:flutter/foundation.dart';
import '../../core/models/comment.dart';
import 'http_service.dart';

/// Servicio para manejar todas las operaciones de comentarios
/// Conecta con las 11 APIs de comentarios del backend Django
class CommentsService {
  final HttpService _httpService;

  CommentsService(this._httpService);

  /// Obtiene comentarios de una comunidad con filtros
  /// GET /api/communities/{id}/comments/
  Future<List<Comment>> getComments(
    int communityId, {
    CommentsFilter? filter,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (filter != null) {
        if (filter.ordering != null) {
          queryParams['ordering'] = filter.ordering!.name;
        }
        if (filter.parentId != null) {
          queryParams['parent_id'] = filter.parentId.toString();
        }
        if (filter.isDeleted != null) {
          queryParams['is_deleted'] = filter.isDeleted.toString();
        }
        if (filter.minReactions != null) {
          queryParams['min_reactions'] = filter.minReactions.toString();
        }
        if (filter.search != null && filter.search!.isNotEmpty) {
          queryParams['search'] = filter.search!;
        }
        queryParams['page'] = filter.page.toString();
        queryParams['page_size'] = filter.pageSize.toString();
      }

      final response = await _httpService.get(
        '/api/comments/',
        queryParameters: queryParams,
      );

      final List<dynamic> results = response.data['results'] ?? response.data;
      return results.map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting comments: $e');
      rethrow;
    }
  }

  /// Obtiene comentarios de un post específico
  /// GET /api/comments/by_post/{post_id}/
  Future<List<Comment>> getCommentsByPost(
    int communityId,
    int postId, {
    CommentSortOrder ordering = CommentSortOrder.newest,
  }) async {
    try {
      final response = await _httpService.get(
        '/api/comments/by_post/$postId/',
        queryParameters: {'ordering': ordering.name},
      );

      final List<dynamic> results = response.data['results'] ?? response.data;
      return results.map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting comments by post: $e');
      rethrow;
    }
  }

  /// Obtiene el thread completo de un comentario (con todas las respuestas)
  /// GET /api/comments/{id}/thread/
  Future<Comment> getCommentThread(int communityId, int commentId) async {
    try {
      final response = await _httpService.get(
        '/api/comments/$commentId/thread/',
      );

      return Comment.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error getting comment thread: $e');
      rethrow;
    }
  }

  /// Obtiene detalles de un comentario específico
  /// GET /api/comments/{id}/
  Future<Comment> getComment(int communityId, int commentId) async {
    try {
      final response = await _httpService.get('/api/comments/$commentId/');

      return Comment.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error getting comment: $e');
      rethrow;
    }
  }

  /// Crea un nuevo comentario
  /// POST /api/communities/{id}/comments/
  Future<Comment> createComment(
    int communityId,
    CreateCommentRequest request,
  ) async {
    try {
      final response = await _httpService.post(
        '/api/comments/',
        data: request.toJson(),
      );

      debugPrint('✅ Comment created successfully');
      return Comment.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error creating comment: $e');
      rethrow;
    }
  }

  /// Responde a un comentario específico
  /// POST /api/comments/{id}/reply/
  Future<Comment> replyToComment(
    int communityId,
    int parentCommentId,
    CreateCommentRequest request,
  ) async {
    try {
      final response = await _httpService.post(
        '/api/comments/$parentCommentId/reply/',
        data: request.toJson(),
      );

      debugPrint('✅ Reply created successfully');
      return Comment.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error creating reply: $e');
      rethrow;
    }
  }

  /// Actualiza un comentario existente
  /// PUT /api/comments/{id}/
  Future<bool> updateComment(
    int communityId,
    int commentId,
    UpdateCommentRequest request,
  ) async {
    try {
      await _httpService.put(
        '/api/comments/$commentId/',
        data: request.toJson(),
      );

      debugPrint('✅ Comment updated successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error updating comment: $e');
      rethrow;
    }
  }

  /// Elimina un comentario (soft delete)
  /// DELETE /api/comments/{id}/
  Future<void> deleteComment(int communityId, int commentId) async {
    try {
      await _httpService.delete('/api/comments/$commentId/');

      debugPrint('✅ Comment deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting comment: $e');
      rethrow;
    }
  }

  /// Restaura un comentario eliminado
  /// POST /api/comments/{id}/restore/
  Future<Comment> restoreComment(int communityId, int commentId) async {
    try {
      final response = await _httpService.post(
        '/api/comments/$commentId/restore/',
      );

      debugPrint('✅ Comment restored successfully');
      return Comment.fromJson(response.data);
    } catch (e) {
      debugPrint('❌ Error restoring comment: $e');
      rethrow;
    }
  }

  /// Obtiene mis comentarios en una comunidad
  /// GET /api/comments/my_comments/
  Future<List<Comment>> getMyComments(
    int communityId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _httpService.get(
        '/api/comments/my_comments/',
        queryParameters: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
      );

      final List<dynamic> results = response.data['results'] ?? response.data;
      return results.map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error getting my comments: $e');
      rethrow;
    }
  }

  /// Reacciona a un comentario
  /// Utiliza el ReactionService para mantener consistencia
  Future<void> reactToComment(int commentId, String reactionType) async {
    try {
      await _httpService.post(
        '/api/reactions/comments/$commentId/react/',
        data: {'reaction_type': reactionType},
      );

      debugPrint('✅ Reaction to comment added successfully');
    } catch (e) {
      debugPrint('❌ Error reacting to comment: $e');
      rethrow;
    }
  }

  /// Quita la reacción de un comentario
  Future<void> removeReactionFromComment(int commentId) async {
    try {
      await _httpService.delete('/api/reactions/comments/$commentId/react/');

      debugPrint('✅ Reaction from comment removed successfully');
    } catch (e) {
      debugPrint('❌ Error removing reaction from comment: $e');
      rethrow;
    }
  }

  /// Obtiene el breakdown de reacciones de un comentario
  Future<Map<String, dynamic>> getCommentReactions(int commentId) async {
    try {
      final response = await _httpService.get(
        '/api/reactions/comments/$commentId/reactions/',
      );

      return response.data;
    } catch (e) {
      debugPrint('❌ Error getting comment reactions: $e');
      rethrow;
    }
  }

  /// Utility: Construye un comentario mock para testing
  static Comment createMockComment({
    int id = 1,
    String content = 'Este es un comentario de prueba',
    int authorId = 1,
    String authorUsername = 'TestUser',
    int postId = 1,
    int? parentId,
    int threadLevel = 0,
    List<Comment> replies = const [],
  }) {
    return Comment(
      id: id,
      content: content,
      authorId: authorId,
      authorUsername: authorUsername,
      authorAvatarUrl: null,
      postId: postId,
      parentId: parentId,
      threadLevel: threadLevel,
      threadPath: threadLevel == 0 ? id.toString() : '$parentId/$id',
      createdAt: DateTime.now().subtract(Duration(minutes: threadLevel * 5)),
      updatedAt: DateTime.now().subtract(Duration(minutes: threadLevel * 5)),
      isDeleted: false,
      canEdit: true,
      canDelete: true,
      reactionsCount: 0,
      reactionsBreakdown: {},
      userReaction: null,
      replies: replies,
    );
  }

  /// Utility: Crea datos mock para testing del threading
  static List<Comment> createMockThreadingData() {
    final mainComment = createMockComment(
      id: 1,
      content: '¿Alguien tiene consejos para mejorar mi mazo de control?',
      authorUsername: 'ControlMaster',
      threadLevel: 0,
    );

    final reply1 = createMockComment(
      id: 2,
      content: 'Te recomiendo agregar más contrahechizos',
      authorUsername: 'MetaGuru',
      parentId: 1,
      threadLevel: 1,
    );

    final reply2 = createMockComment(
      id: 3,
      content: 'También considera cartas de card draw',
      authorUsername: 'StrategyExpert',
      parentId: 1,
      threadLevel: 1,
    );

    final nestedReply = createMockComment(
      id: 4,
      content: '¿Qué contrahechizos específicos recomendarías?',
      authorUsername: 'ControlMaster',
      parentId: 2,
      threadLevel: 2,
    );

    return [mainComment, reply1, reply2, nestedReply];
  }
}
