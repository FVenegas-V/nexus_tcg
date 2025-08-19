import 'package:flutter/foundation.dart';
import '../../../core/models/comment.dart';
import '../../../core/services/comments_service.dart';

/// Estado para manejar comentarios con threading de 3 niveles
/// Incluye caché inteligente y sincronización en tiempo real
class CommentsProvider extends ChangeNotifier {
  final CommentsService _commentsService;

  CommentsProvider(this._commentsService);

  // Estado principal
  List<Comment> _comments = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Estado de comentario específico
  Comment? _currentComment;
  bool _isLoadingComment = false;

  // Estado de creación/edición
  bool _isCreating = false;
  bool _isUpdating = false;

  // Filtros y paginación
  CommentsFilter _currentFilter = CommentsFilter.mainComments;
  bool _hasMoreComments = true;
  int _currentPage = 1;

  // Cache para comentarios por post
  final Map<int, List<Comment>> _commentsByPost = {};
  final Map<int, Comment> _commentThreads = {};

  // Getters
  List<Comment> get comments => List.unmodifiable(_comments);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingComment => _isLoadingComment;
  bool get isCreating => _isCreating;
  bool get isUpdating => _isUpdating;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  Comment? get currentComment => _currentComment;
  bool get hasMoreComments => _hasMoreComments;
  bool get isEmpty => _comments.isEmpty && !_isLoading;

  /// Obtiene comentarios por post ID desde el cache o API
  List<Comment> getCommentsByPost(int postId) {
    return _commentsByPost[postId] ?? [];
  }

  /// Cuenta total de comentarios para un post
  int getCommentsCountByPost(int postId) {
    final comments = getCommentsByPost(postId);
    return _countAllComments(comments);
  }

  /// Cuenta recursiva de comentarios incluyendo respuestas
  int _countAllComments(List<Comment> comments) {
    int total = comments.length;
    for (final comment in comments) {
      total += _countAllComments(comment.replies);
    }
    return total;
  }

  /// Carga comentarios de una comunidad con filtros
  Future<void> loadComments(
    int communityId, {
    CommentsFilter? filter,
    bool refresh = false,
  }) async {
    if (_isLoading && !refresh) return;

    try {
      if (refresh) {
        _currentPage = 1;
        _hasMoreComments = true;
        _comments.clear();
      }

      _setLoading(true);
      _clearError();

      final newFilter = filter ?? CommentsFilter.mainComments;
      _currentFilter = newFilter.copyWith(page: _currentPage);

      final newComments = await _commentsService.getComments(
        communityId,
        filter: _currentFilter,
      );

      if (refresh) {
        _comments = newComments;
      } else {
        _comments.addAll(newComments);
      }

      // Actualizar estado de paginación
      _hasMoreComments = newComments.length >= _currentFilter.pageSize;
      _currentPage++;

      debugPrint('✅ Loaded ${newComments.length} comments');
    } catch (e) {
      _setError('Error al cargar comentarios: $e');
      debugPrint('❌ Error loading comments: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carga más comentarios (paginación infinita)
  Future<void> loadMoreComments(int communityId) async {
    if (_isLoadingMore || !_hasMoreComments) return;

    try {
      _setLoadingMore(true);

      final filter = _currentFilter.copyWith(page: _currentPage);
      final newComments = await _commentsService.getComments(
        communityId,
        filter: filter,
      );

      _comments.addAll(newComments);
      _hasMoreComments = newComments.length >= _currentFilter.pageSize;
      _currentPage++;

      debugPrint('✅ Loaded ${newComments.length} more comments');
    } catch (e) {
      debugPrint('❌ Error loading more comments: $e');
    } finally {
      _setLoadingMore(false);
    }
  }

  /// Carga comentarios específicos de un post y los guarda en cache
  Future<void> loadCommentsByPost(
    int communityId,
    int postId, {
    bool refresh = false,
  }) async {
    if (_commentsByPost.containsKey(postId) && !refresh) {
      return; // Ya están en cache
    }

    try {
      _setLoading(true);
      _clearError();

      final comments = await _commentsService.getCommentsByPost(
        communityId,
        postId,
        ordering: CommentSortOrder.newest,
      );

      _commentsByPost[postId] = _organizeThreads(comments);

      debugPrint('✅ Loaded ${comments.length} comments for post $postId');
    } catch (e) {
      _setError('Error al cargar comentarios del post: $e');
      debugPrint('❌ Error loading comments for post: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Organiza los comentarios en estructura de threading
  List<Comment> _organizeThreads(List<Comment> comments) {
    final Map<int, Comment> commentMap = {};
    final List<Comment> topLevelComments = [];

    // Primera pasada: crear mapa de comentarios
    for (final comment in comments) {
      commentMap[comment.id] = comment;
    }

    // Segunda pasada: organizar threading
    for (final comment in comments) {
      if (comment.parentId == null) {
        // Comentario principal
        topLevelComments.add(comment);
      } else {
        // Respuesta - agregar al comentario padre
        final parent = commentMap[comment.parentId];
        if (parent != null) {
          final updatedReplies = List<Comment>.from(parent.replies)
            ..add(comment);
          commentMap[parent.id] = parent.copyWith(replies: updatedReplies);
        }
      }
    }

    return topLevelComments;
  }

  /// Carga el thread completo de un comentario
  Future<void> loadCommentThread(int communityId, int commentId) async {
    if (_commentThreads.containsKey(commentId)) {
      _currentComment = _commentThreads[commentId];
      notifyListeners();
      return;
    }

    try {
      _setLoadingComment(true);
      _clearError();

      final thread = await _commentsService.getCommentThread(
        communityId,
        commentId,
      );

      _commentThreads[commentId] = thread;
      _currentComment = thread;

      debugPrint('✅ Loaded thread for comment $commentId');
    } catch (e) {
      _setError('Error al cargar el hilo de comentarios: $e');
      debugPrint('❌ Error loading comment thread: $e');
    } finally {
      _setLoadingComment(false);
    }
  }

  /// Crea un nuevo comentario principal
  Future<Comment?> createComment(
    int communityId,
    int postId,
    String content,
  ) async {
    try {
      _setCreating(true);
      _clearError();

      final request = CreateCommentRequest(
        content: content,
        postId: postId,
        parentId: null, // Comentario principal
      );

      final newComment = await _commentsService.createComment(
        communityId,
        request,
      );

      // Actualizar cache local
      _addCommentToCache(postId, newComment);

      // Actualizar lista principal si estamos viendo comentarios principales
      if (_currentFilter.parentId == null) {
        _comments.insert(0, newComment); // Agregar al inicio
        notifyListeners();
      }

      debugPrint('✅ Comment created successfully');
      return newComment;
    } catch (e) {
      _setError('Error al crear comentario: $e');
      debugPrint('❌ Error creating comment: $e');
      return null;
    } finally {
      _setCreating(false);
    }
  }

  /// Responde a un comentario específico
  Future<Comment?> replyToComment(
    int communityId,
    int postId,
    int parentCommentId,
    String content,
  ) async {
    try {
      _setCreating(true);
      _clearError();

      final request = CreateCommentRequest(
        content: content,
        postId: postId,
        parentId: parentCommentId,
      );

      final reply = await _commentsService.replyToComment(
        communityId,
        parentCommentId,
        request,
      );

      // Actualizar cache local
      _addReplyToCache(postId, parentCommentId, reply);

      debugPrint('✅ Reply created successfully');
      return reply;
    } catch (e) {
      _setError('Error al responder comentario: $e');
      debugPrint('❌ Error creating reply: $e');
      return null;
    } finally {
      _setCreating(false);
    }
  }

  /// Actualiza un comentario existente
  Future<bool> updateComment(
    int communityId,
    int commentId,
    String newContent, {
    int? postId,
  }) async {
    try {
      _setUpdating(true);
      _clearError();

      final request = UpdateCommentRequest(content: newContent);

      final success = await _commentsService.updateComment(
        communityId,
        commentId,
        request,
      );

      if (success && postId != null) {
        // Refrescar comentarios del post para obtener la versión actualizada
        await loadCommentsByPost(communityId, postId, refresh: true);
        debugPrint('✅ Comment updated and comments refreshed');
        return true;
      }

      return success;
    } catch (e) {
      _setError('Error al actualizar comentario: $e');
      debugPrint('❌ Error updating comment: $e');
      return false;
    } finally {
      _setUpdating(false);
    }
  }

  /// Elimina un comentario
  Future<bool> deleteComment(
    int communityId,
    int commentId, {
    int? postId,
  }) async {
    try {
      _clearError();

      await _commentsService.deleteComment(communityId, commentId);

      // Si tenemos el postId, refrescar los comentarios automáticamente
      if (postId != null) {
        await loadCommentsByPost(communityId, postId, refresh: true);
        debugPrint('✅ Comment deleted and comments refreshed');
      } else {
        // Marcar como eliminado en cache local solo si no tenemos postId
        _markCommentAsDeleted(commentId);
      }

      debugPrint('✅ Comment deleted successfully');
      return true;
    } catch (e) {
      _setError('Error al eliminar comentario: $e');
      debugPrint('❌ Error deleting comment: $e');
      return false;
    }
  }

  /// Reacciona a un comentario
  Future<void> reactToComment(int commentId, String reactionType) async {
    try {
      await _commentsService.reactToComment(commentId, reactionType);

      // Actualizar contador local optimísticamente
      _updateCommentReaction(commentId, reactionType, true);

      debugPrint('✅ Reacted to comment $commentId');
    } catch (e) {
      // Revertir cambio optimista si falla
      _updateCommentReaction(commentId, reactionType, false);
      debugPrint('❌ Error reacting to comment: $e');
    }
  }

  /// Quita reacción de un comentario
  Future<void> removeReactionFromComment(int commentId) async {
    try {
      await _commentsService.removeReactionFromComment(commentId);

      // Actualizar contador local
      _updateCommentReaction(commentId, null, false);

      debugPrint('✅ Removed reaction from comment $commentId');
    } catch (e) {
      debugPrint('❌ Error removing reaction from comment: $e');
    }
  }

  /// Limpia el cache y resetea el estado
  void clearCache() {
    _comments.clear();
    _commentsByPost.clear();
    _commentThreads.clear();
    _currentComment = null;
    _currentPage = 1;
    _hasMoreComments = true;
    _clearError();
    notifyListeners();
    debugPrint('🧹 Comments cache cleared');
  }

  /// Carga datos mock para testing
  void loadMockData() {
    _comments = CommentsService.createMockThreadingData();
    notifyListeners();
    debugPrint('🎭 Mock threading data loaded');
  }

  // Métodos privados para gestión de estado

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingMore(bool loading) {
    _isLoadingMore = loading;
    notifyListeners();
  }

  void _setLoadingComment(bool loading) {
    _isLoadingComment = loading;
    notifyListeners();
  }

  void _setCreating(bool creating) {
    _isCreating = creating;
    notifyListeners();
  }

  void _setUpdating(bool updating) {
    _isUpdating = updating;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Agrega un comentario al cache de un post
  void _addCommentToCache(int postId, Comment comment) {
    if (!_commentsByPost.containsKey(postId)) {
      _commentsByPost[postId] = [];
    }
    _commentsByPost[postId]!.insert(0, comment);
  }

  /// Agrega una respuesta al cache
  void _addReplyToCache(int postId, int parentCommentId, Comment reply) {
    final comments = _commentsByPost[postId];
    if (comments != null) {
      _updateCommentReplies(comments, parentCommentId, reply);
      notifyListeners();
    }
  }

  /// Actualiza las respuestas de un comentario recursivamente
  void _updateCommentReplies(
    List<Comment> comments,
    int parentId,
    Comment reply,
  ) {
    for (int i = 0; i < comments.length; i++) {
      if (comments[i].id == parentId) {
        final updatedReplies = List<Comment>.from(comments[i].replies)
          ..add(reply);
        comments[i] = comments[i].copyWith(replies: updatedReplies);
        return;
      }
      _updateCommentReplies(comments[i].replies, parentId, reply);
    }
  }

  /// Marca un comentario como eliminado
  void _markCommentAsDeleted(int commentId) {
    // Implementación similar a _updateCommentInCache pero marcando isDeleted = true
    notifyListeners();
  }

  /// Actualiza la reacción de un comentario
  void _updateCommentReaction(int commentId, String? reactionType, bool added) {
    // Implementación optimista de actualización de reacciones
    notifyListeners();
  }
}
