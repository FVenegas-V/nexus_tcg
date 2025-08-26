import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../models/post_image.dart';
import '../models/reaction.dart';
import '../services/posts_service.dart';

/// Provider para manejar el estado global de Posts, Reacciones e Imágenes
///
/// Gestiona:
/// - Feed personalizado y listas de posts
/// - CRUD completo de posts
/// - Sistema de reacciones en tiempo real
/// - Upload y gestión de imágenes
/// - Estados de loading y error
class PostsState extends ChangeNotifier {
  final PostsService _postsService = PostsService();

  // ==================== ESTADO GENERAL ====================

  bool _isLoading = false;
  String? _error;
  bool _isCreatingPost = false;
  bool _isUploadingImages = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isCreatingPost => _isCreatingPost;
  bool get isUploadingImages => _isUploadingImages;

  // ==================== POSTS ====================

  List<Post> _feedPosts = [];
  List<Post> _communityPosts = [];
  Map<int, Post> _postsCache = {}; // Cache por ID para acceso rápido
  Map<int, List<Post>> _postsByCommunity = {}; // Posts agrupados por comunidad

  List<Post> get feedPosts => _feedPosts;
  List<Post> get communityPosts => _communityPosts;
  Map<int, Post> get postsCache => _postsCache;

  // ==================== REACCIONES ====================

  Map<int, ReactionsBreakdown> _postReactions = {}; // Reacciones por post ID

  Map<int, ReactionsBreakdown> get postReactions => _postReactions;

  // ==================== IMÁGENES ====================

  Map<int, List<PostImage>> _postImages = {}; // Imágenes por post ID

  Map<int, List<PostImage>> get postImages => _postImages;

  // ==================== MÉTODOS PÚBLICOS - POSTS ====================

  /// Cargar feed personalizado del usuario
  Future<void> loadFeed({bool refresh = false}) async {
    if (!refresh && _feedPosts.isNotEmpty) return; // Ya cargado

    try {
      _setLoading(true);

      debugPrint('📰 Cargando feed personalizado...');
      final posts = await _postsService.getFeed(pageSize: 20);

      _feedPosts = posts;
      _updatePostsCache(posts);
      _setError(null);

      debugPrint('✅ Feed cargado: ${posts.length} posts');
    } catch (e) {
      debugPrint('❌ Error cargando feed: $e');
      _setError('Error al cargar el feed: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Cargar posts de una comunidad específica
  Future<void> loadCommunityPosts(
    int communityId, {
    bool refresh = false,
  }) async {
    if (!refresh && _postsByCommunity.containsKey(communityId)) {
      _communityPosts = _postsByCommunity[communityId]!;
      notifyListeners();
      return;
    }

    try {
      _setLoading(true);

      debugPrint('📝 Cargando posts de comunidad $communityId...');
      final posts = await _postsService.getPostsByCommunity(
        communityId,
        pageSize: 20,
        ordering: '-created_at', // Más recientes primero
      );

      _communityPosts = posts;
      _postsByCommunity[communityId] = posts;
      _updatePostsCache(posts);
      _setError(null);

      debugPrint('✅ Posts de comunidad cargados: ${posts.length} posts');
    } catch (e) {
      debugPrint('❌ Error cargando posts de comunidad: $e');
      _setError('Error al cargar posts de la comunidad: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Obtener detalle de un post específico
  Future<Post?> getPost(int postId) async {
    // Verificar cache primero
    if (_postsCache.containsKey(postId)) {
      return _postsCache[postId];
    }

    try {
      debugPrint('🔍 Obteniendo post $postId...');
      final post = await _postsService.getPost(postId);

      _postsCache[postId] = post;
      _setError(null);

      debugPrint('✅ Post obtenido exitosamente');
      return post;
    } catch (e) {
      debugPrint('❌ Error obteniendo post: $e');
      _setError('Error al obtener el post: $e');
      return null;
    }
  }

  /// Crear un nuevo post
  Future<Post?> createPost(CreatePostRequest request) async {
    try {
      _setCreatingPost(true);

      debugPrint('🚀 Creando nuevo post...');
      final post = await _postsService.createPost(request);

      // Actualizar listas locales
      _addPostToLists(post);
      _postsCache[post.id] = post;
      _setError(null);

      debugPrint('✅ Post creado exitosamente: ${post.id}');
      return post;
    } catch (e) {
      debugPrint('❌ Error creando post: $e');
      _setError('Error al crear el post: $e');
      return null;
    } finally {
      _setCreatingPost(false);
    }
  }

  /// Actualizar un post existente
  Future<Post?> updatePost(int postId, UpdatePostRequest request) async {
    try {
      _setLoading(true);

      debugPrint('✏️ Actualizando post $postId...');
      final updatedPost = await _postsService.updatePost(postId, request);

      // Actualizar en todas las listas y cache
      _updatePostInLists(updatedPost);
      _postsCache[postId] = updatedPost;
      _setError(null);

      debugPrint('✅ Post actualizado exitosamente');
      return updatedPost;
    } catch (e) {
      debugPrint('❌ Error actualizando post: $e');
      _setError('Error al actualizar el post: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Eliminar un post
  Future<bool> deletePost(int postId) async {
    try {
      _setLoading(true);

      debugPrint('🗑️ Eliminando post $postId...');
      await _postsService.deletePost(postId);

      // Remover de listas locales
      _removePostFromLists(postId);
      _postsCache.remove(postId);
      _postReactions.remove(postId);
      _postImages.remove(postId);
      _setError(null);

      debugPrint('✅ Post eliminado exitosamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error eliminando post: $e');
      _setError('Error al eliminar el post: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Buscar posts por término
  Future<void> searchPosts(String query, {int? communityId}) async {
    if (query.trim().isEmpty) {
      // Si el query está vacío, restaurar la vista original
      if (communityId != null && _postsByCommunity.containsKey(communityId)) {
        _communityPosts = _postsByCommunity[communityId]!;
      } else {
        _communityPosts = [];
      }
      notifyListeners();
      return;
    }

    try {
      _setLoading(true);

      debugPrint('🔍 Buscando posts: "$query"...');
      final posts = await _postsService.searchPosts(
        query,
        communityId: communityId,
        pageSize: 20,
      );

      _communityPosts = posts;
      _updatePostsCache(posts);
      _setError(null);

      debugPrint('✅ Búsqueda completada: ${posts.length} resultados');
    } catch (e) {
      debugPrint('❌ Error en búsqueda: $e');
      _setError('Error en la búsqueda: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== MÉTODOS PÚBLICOS - REACCIONES ====================

  /// Toggle de reacción en un post con actualización optimista
  Future<bool> toggleReaction(int postId, ReactionType reactionType) async {
    // Guardar estado actual para poder revertir si falla
    Post? originalPost;
    ReactionsBreakdown? originalBreakdown;

    if (_postsCache.containsKey(postId)) {
      originalPost = _postsCache[postId];
      originalBreakdown = _postReactions[postId];
    }

    // Update optimista inmediato de la UI
    _updateReactionOptimistically(postId, reactionType);
    notifyListeners(); // Actualizar UI inmediatamente

    try {
      debugPrint('😊 Toggle reacción $reactionType en post $postId...');

      final breakdown = await _postsService.toggleReaction(
        postId,
        reactionType,
      );

      // Actualizar con datos reales del servidor
      _postReactions[postId] = breakdown;

      // Actualizar el post en cache si existe
      debugPrint(
        '🔍 Cache state - Post $postId existe en cache: ${_postsCache.containsKey(postId)}',
      );
      debugPrint(
        '🔍 Cache state - Total posts en cache: ${_postsCache.length}',
      );
      debugPrint('🔍 Cache state - IDs en cache: ${_postsCache.keys.toList()}');

      if (_postsCache.containsKey(postId)) {
        final post = _postsCache[postId]!;

        debugPrint(
          '🔍 DEBUG: breakdown.userReaction = ${breakdown.userReaction?.value}',
        );
        debugPrint('🔍 DEBUG: post.userReaction ANTES = ${post.userReaction}');
        debugPrint('🔍 Actualizando post $postId con datos del servidor:');
        debugPrint('  - Conteo total: ${breakdown.totalCount}');
        debugPrint(
          '  - Reacción del usuario en breakdown: ${breakdown.userReaction?.value}',
        );
        debugPrint('  - Post anterior userReaction: ${post.userReaction}');

        final updatedPost = post.copyWith(
          reactionsCount: breakdown.totalCount,
          userReaction: breakdown.userReaction?.value, // Permitir null
          reactionsBreakdown: breakdown.counts.map(
            (key, value) => MapEntry(key.value, value),
          ),
        );

        // Si no hay reacción del usuario, establecer explícitamente null
        final finalPost = breakdown.userReaction == null
            ? Post(
                id: updatedPost.id,
                title: updatedPost.title,
                content: updatedPost.content,
                communityId: updatedPost.communityId,
                communityName: updatedPost.communityName,
                authorId: updatedPost.authorId,
                authorUsername: updatedPost.authorUsername,
                createdAt: updatedPost.createdAt,
                updatedAt: updatedPost.updatedAt,
                deletedAt: updatedPost.deletedAt,
                isDeleted: updatedPost.isDeleted,
                commentsCount: updatedPost.commentsCount,
                reactionsCount: updatedPost.reactionsCount,
                images: updatedPost.images,
                thumbnailUrl: updatedPost.thumbnailUrl,
                hasImages: updatedPost.hasImages,
                userReaction: null, // Explícitamente null
                reactionsBreakdown: updatedPost.reactionsBreakdown,
              )
            : updatedPost;

        debugPrint(
          '🔍 DEBUG: updatedPost.userReaction DESPUÉS = ${finalPost.userReaction}',
        );

        _postsCache[postId] = finalPost;
        _updatePostInLists(finalPost);
      } else {
        debugPrint(
          '❌ DEBUG: Post $postId NO encontrado en cache para actualizar',
        );
      }

      _setError(null);
      notifyListeners(); // Confirmar actualización con datos del servidor
      debugPrint('✅ Reacción actualizada exitosamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error actualizando reacción: $e');

      // Revertir cambios optimistas en caso de error
      if (originalPost != null) {
        _postsCache[postId] = originalPost;
        _updatePostInLists(originalPost);
      }
      if (originalBreakdown != null) {
        _postReactions[postId] = originalBreakdown;
      } else {
        _postReactions.remove(postId);
      }

      _setError('Error al actualizar la reacción: $e');
      notifyListeners(); // Revertir UI al estado original
      return false;
    }
  }

  /// Actualización optimista de reacción (inmediata en UI)
  void _updateReactionOptimistically(int postId, ReactionType reactionType) {
    if (!_postsCache.containsKey(postId)) return;

    final post = _postsCache[postId]!;
    final currentUserReaction = post.userReaction;
    final currentBreakdown = Map<String, int>.from(post.reactionsBreakdown);
    int newReactionsCount = post.reactionsCount;

    // Simular lógica de toggle
    if (currentUserReaction == reactionType.value) {
      // Usuario ya tiene esta reacción: remover
      currentBreakdown[reactionType.value] =
          (currentBreakdown[reactionType.value] ?? 1) - 1;
      if (currentBreakdown[reactionType.value]! <= 0) {
        currentBreakdown.remove(reactionType.value);
      }
      newReactionsCount = math.max(0, newReactionsCount - 1);

      final updatedPost = post.copyWith(
        reactionsCount: newReactionsCount,
        userReaction: null, // Usuario ya no tiene reacción
        reactionsBreakdown: currentBreakdown,
      );
      _postsCache[postId] = updatedPost;
      _updatePostInLists(updatedPost);
    } else {
      // Usuario cambia o agrega reacción
      if (currentUserReaction != null) {
        // Quitar reacción anterior
        currentBreakdown[currentUserReaction] =
            (currentBreakdown[currentUserReaction] ?? 1) - 1;
        if (currentBreakdown[currentUserReaction]! <= 0) {
          currentBreakdown.remove(currentUserReaction);
        }
      } else {
        // Nueva reacción
        newReactionsCount++;
      }

      // Agregar nueva reacción
      currentBreakdown[reactionType.value] =
          (currentBreakdown[reactionType.value] ?? 0) + 1;

      final updatedPost = post.copyWith(
        reactionsCount: newReactionsCount,
        userReaction: reactionType.value,
        reactionsBreakdown: currentBreakdown,
      );
      _postsCache[postId] = updatedPost;
      _updatePostInLists(updatedPost);
    }
  }

  /// Obtener breakdown de reacciones de un post
  Future<ReactionsBreakdown?> getPostReactions(int postId) async {
    // Verificar cache primero
    if (_postReactions.containsKey(postId)) {
      return _postReactions[postId];
    }

    try {
      debugPrint('📊 Obteniendo reacciones del post $postId...');
      final breakdown = await _postsService.getPostReactions(postId);

      _postReactions[postId] = breakdown;
      _setError(null);

      debugPrint('✅ Reacciones obtenidas exitosamente');
      return breakdown;
    } catch (e) {
      debugPrint('❌ Error obteniendo reacciones: $e');
      _setError('Error al obtener reacciones: $e');
      return null;
    }
  }

  // ==================== MÉTODOS PÚBLICOS - IMÁGENES ====================

  /// Subir imágenes para un post
  Future<bool> uploadImages(ImageUploadRequest request) async {
    try {
      _setUploadingImages(true);

      debugPrint('📸 Subiendo ${request.imagePaths.length} imágenes...');
      final images = await _postsService.uploadImages(request);

      // Actualizar estado local
      _postImages[request.postId] = images;

      // Actualizar el post en cache si existe
      if (_postsCache.containsKey(request.postId)) {
        final post = _postsCache[request.postId]!;
        final updatedPost = post.copyWith(images: images);
        _postsCache[request.postId] = updatedPost;
        _updatePostInLists(updatedPost);
      }

      _setError(null);
      debugPrint('✅ Imágenes subidas exitosamente');
      return true;
    } catch (e) {
      debugPrint('❌ Error subiendo imágenes: $e');
      _setError('Error al subir imágenes: $e');
      return false;
    } finally {
      _setUploadingImages(false);
    }
  }

  /// Obtener imágenes de un post
  Future<List<PostImage>?> getPostImages(int postId) async {
    // Verificar cache primero
    if (_postImages.containsKey(postId)) {
      return _postImages[postId];
    }

    try {
      debugPrint('🖼️ Obteniendo imágenes del post $postId...');
      final images = await _postsService.getPostImages(postId);

      _postImages[postId] = images;
      _setError(null);

      debugPrint('✅ Imágenes obtenidas exitosamente');
      return images;
    } catch (e) {
      debugPrint('❌ Error obteniendo imágenes: $e');
      _setError('Error al obtener imágenes: $e');
      return null;
    }
  }

  // ==================== MÉTODOS PRIVADOS ====================

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setCreatingPost(bool creating) {
    _isCreatingPost = creating;
    notifyListeners();
  }

  void _setUploadingImages(bool uploading) {
    _isUploadingImages = uploading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _updatePostsCache(List<Post> posts) {
    for (final post in posts) {
      _postsCache[post.id] = post;
    }
  }

  void _addPostToLists(Post post) {
    // Agregar al feed si es relevante
    if (_feedPosts.isNotEmpty) {
      _feedPosts.insert(0, post); // Agregar al inicio (más reciente)
    }

    // Agregar a la lista de la comunidad
    if (_postsByCommunity.containsKey(post.communityId)) {
      _postsByCommunity[post.communityId]!.insert(0, post);
    }

    // Si estamos viendo esa comunidad, actualizar también
    if (_communityPosts.isNotEmpty &&
        _communityPosts.first.communityId == post.communityId) {
      _communityPosts.insert(0, post);
    }

    notifyListeners();
  }

  void _updatePostInLists(Post updatedPost) {
    // Actualizar en feed
    final feedIndex = _feedPosts.indexWhere((p) => p.id == updatedPost.id);
    if (feedIndex != -1) {
      _feedPosts[feedIndex] = updatedPost;
    }

    // Actualizar en posts de comunidad
    final communityIndex = _communityPosts.indexWhere(
      (p) => p.id == updatedPost.id,
    );
    if (communityIndex != -1) {
      _communityPosts[communityIndex] = updatedPost;
    }

    // Actualizar en lista de comunidad específica
    if (_postsByCommunity.containsKey(updatedPost.communityId)) {
      final list = _postsByCommunity[updatedPost.communityId]!;
      final index = list.indexWhere((p) => p.id == updatedPost.id);
      if (index != -1) {
        list[index] = updatedPost;
      }
    }

    notifyListeners();
  }

  void _removePostFromLists(int postId) {
    // Remover del feed
    _feedPosts.removeWhere((p) => p.id == postId);

    // Remover de posts de comunidad actual
    _communityPosts.removeWhere((p) => p.id == postId);

    // Remover de todas las listas de comunidades
    for (final list in _postsByCommunity.values) {
      list.removeWhere((p) => p.id == postId);
    }

    notifyListeners();
  }

  // ==================== MÉTODOS DE UTILIDAD ====================

  /// Limpiar todos los datos
  void clear() {
    _feedPosts.clear();
    _communityPosts.clear();
    _postsCache.clear();
    _postsByCommunity.clear();
    _postReactions.clear();
    _postImages.clear();
    _error = null;
    _isLoading = false;
    _isCreatingPost = false;
    _isUploadingImages = false;
    notifyListeners();
  }

  /// Obtener posts por comunidad desde cache
  List<Post> getPostsForCommunity(int communityId) {
    return _postsByCommunity[communityId] ?? [];
  }

  /// Verificar si hay posts cargados para una comunidad
  bool hasCommunityPosts(int communityId) {
    return _postsByCommunity.containsKey(communityId) &&
        _postsByCommunity[communityId]!.isNotEmpty;
  }

  /// Obtener estadísticas rápidas
  Map<String, int> get stats => {
    'feedPosts': _feedPosts.length,
    'cachedPosts': _postsCache.length,
    'communities': _postsByCommunity.length,
  };
}
