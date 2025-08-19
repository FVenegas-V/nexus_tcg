import 'package:flutter/foundation.dart';
import '../../../core/models/post.dart';
import '../../../core/models/post_image.dart';
import '../../../core/models/reaction.dart';
import '../../../core/providers/posts_state.dart';

/// Provider para gestión de estado del feed de posts integrado con backend real
///
/// Funcionalidades:
/// - Feed personalizado basado en suscripciones
/// - Paginación infinita con pull-to-refresh
/// - CRUD completo de posts
/// - Sistema de reacciones en tiempo real
/// - Búsqueda y filtrado
/// - Cache inteligente de posts
class PostsProvider extends ChangeNotifier {
  final PostsState _postsState = PostsState();

  // Estados locales adicionales para UI
  bool _isInitialized = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _disposed = false;

  // Getters principales
  List<Post> get posts => _postsState.feedPosts;
  List<Post> get communityPosts => _postsState.communityPosts;
  bool get isLoading =>
      _postsState.isLoading || (!_isInitialized && posts.isEmpty);
  bool get isRefreshing => _isRefreshing;
  bool get isLoadingMore => _isLoadingMore;
  bool get isCreatingPost => _postsState.isCreatingPost;
  bool get isUploadingImages => _postsState.isUploadingImages;
  String? get errorMessage => _postsState.error;
  bool get hasError => _postsState.error != null;
  bool get isEmpty => posts.isEmpty && !isLoading;

  // Getters adicionales
  Map<int, Post> get postsCache => _postsState.postsCache;
  Map<int, ReactionsBreakdown> get postReactions => _postsState.postReactions;

  /// Inicializa el provider y carga el feed inicial
  PostsProvider() {
    _postsState.addListener(_onPostsStateChanged);
    loadInitialPosts();
  }

  @override
  void dispose() {
    _disposed = true;
    _postsState.removeListener(_onPostsStateChanged);
    super.dispose();
  }

  /// Escucha cambios en PostsState y notifica a la UI
  void _onPostsStateChanged() {
    if (!mounted) return;
    notifyListeners();
  }

  /// Carga los primeros posts del feed
  Future<void> loadInitialPosts() async {
    if (_isInitialized) return;

    try {
      debugPrint('📰 Cargando feed inicial...');
      await _postsState.loadFeed(refresh: false);
      _isInitialized = true;
      debugPrint('✅ Feed inicial cargado');
    } catch (e) {
      debugPrint('❌ Error cargando feed inicial: $e');
    }
  }

  /// Refresca el feed completo (pull-to-refresh)
  Future<void> refreshPosts() async {
    if (_isRefreshing) return;

    try {
      _setRefreshing(true);
      _currentPage = 1;

      debugPrint('🔄 Refrescando feed...');
      await _postsState.loadFeed(refresh: true);

      debugPrint('✅ Feed refrescado exitosamente');
    } catch (e) {
      debugPrint('❌ Error refrescando feed: $e');
    } finally {
      _setRefreshing(false);
    }
  }

  /// Carga más posts (infinite scroll)
  Future<void> loadMorePosts() async {
    if (_isLoadingMore || _postsState.isLoading) return;

    try {
      _setLoadingMore(true);
      _currentPage++;

      debugPrint('📄 Cargando página $_currentPage...');

      // TODO: Implementar paginación real cuando el backend la soporte
      // Por ahora, solo evitamos cargar duplicados
      if (_currentPage > 3) {
        debugPrint('📄 Límite de páginas alcanzado');
        return;
      }

      // Simular carga de más posts
      await Future.delayed(const Duration(milliseconds: 500));
      debugPrint('✅ Página $_currentPage cargada');
    } catch (e) {
      debugPrint('❌ Error cargando más posts: $e');
      _currentPage--; // Revertir incremento si falló
    } finally {
      _setLoadingMore(false);
    }
  }

  /// Carga posts de una comunidad específica
  Future<void> loadCommunityPosts(
    int communityId, {
    bool refresh = false,
  }) async {
    try {
      debugPrint('📝 Cargando posts de comunidad $communityId...');
      await _postsState.loadCommunityPosts(communityId, refresh: refresh);
      debugPrint('✅ Posts de comunidad cargados');
    } catch (e) {
      debugPrint('❌ Error cargando posts de comunidad: $e');
    }
  }

  /// Buscar posts por término
  Future<void> searchPosts(String query, {int? communityId}) async {
    try {
      debugPrint('🔍 Buscando: "$query"...');
      await _postsState.searchPosts(query, communityId: communityId);
      debugPrint('✅ Búsqueda completada');
    } catch (e) {
      debugPrint('❌ Error en búsqueda: $e');
    }
  }

  /// Crear un nuevo post
  Future<Post?> createPost(CreatePostRequest request) async {
    try {
      debugPrint('🚀 Creando post...');
      final post = await _postsState.createPost(request);

      if (post != null) {
        debugPrint('✅ Post creado: ${post.id}');
        // Refrescar feed para mostrar el nuevo post
        await refreshPosts();
      }

      return post;
    } catch (e) {
      debugPrint('❌ Error creando post: $e');
      return null;
    }
  }

  /// Actualizar un post existente
  Future<Post?> updatePost(int postId, UpdatePostRequest request) async {
    try {
      debugPrint('✏️ Actualizando post $postId...');
      final post = await _postsState.updatePost(postId, request);

      if (post != null) {
        debugPrint('✅ Post actualizado');
      }

      return post;
    } catch (e) {
      debugPrint('❌ Error actualizando post: $e');
      return null;
    }
  }

  /// Eliminar un post
  Future<bool> deletePost(int postId) async {
    try {
      debugPrint('🗑️ Eliminando post $postId...');
      final success = await _postsState.deletePost(postId);

      if (success) {
        debugPrint('✅ Post eliminado');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error eliminando post: $e');
      return false;
    }
  }

  /// Toggle de reacción en un post
  Future<void> toggleReaction(int postId, ReactionType reactionType) async {
    try {
      debugPrint('😊 Toggle reacción $reactionType en post $postId...');

      final success = await _postsState.toggleReaction(postId, reactionType);

      if (success) {
        debugPrint('✅ Reacción actualizada');
      }
    } catch (e) {
      debugPrint('❌ Error actualizando reacción: $e');
    }
  }

  /// Obtener detalle de un post
  Future<Post?> getPost(int postId) async {
    try {
      debugPrint('🔍 Obteniendo post $postId...');
      final post = await _postsState.getPost(postId);

      if (post != null) {
        debugPrint('✅ Post obtenido');
      }

      return post;
    } catch (e) {
      debugPrint('❌ Error obteniendo post: $e');
      return null;
    }
  }

  /// Obtener post por ID (para mantener compatibilidad)
  Post? getPostById(int postId) {
    return _postsState.postsCache[postId];
  }

  /// Obtener posts de una comunidad específica (para mantener compatibilidad)
  List<Post> getPostsByCommunity(int communityId) {
    return _postsState.getPostsForCommunity(communityId);
  }

  /// Obtener posts de un usuario específico
  List<Post> getPostsByAuthor(int authorId) {
    return posts.where((post) => post.authorId == authorId).toList();
  }

  /// Toggle like (mapea a reacción like)
  void toggleLike(int postId) {
    toggleReaction(postId, ReactionType.like);
  }

  /// Toggle bookmark (TODO: implementar cuando se agregue al backend)
  void toggleBookmark(int postId) {
    debugPrint('🔖 Bookmark toggle pendiente de implementación en backend');
    // TODO: Implementar cuando se agregue endpoint de bookmarks
  }

  /// Obtener breakdown de reacciones de un post
  Future<ReactionsBreakdown?> getPostReactions(int postId) async {
    try {
      debugPrint('📊 Obteniendo reacciones del post $postId...');
      final breakdown = await _postsState.getPostReactions(postId);

      if (breakdown != null) {
        debugPrint('✅ Reacciones obtenidas');
      }

      return breakdown;
    } catch (e) {
      debugPrint('❌ Error obteniendo reacciones: $e');
      return null;
    }
  }

  /// Subir imágenes para un post
  Future<bool> uploadImages(ImageUploadRequest request) async {
    try {
      debugPrint('📸 Subiendo imágenes...');
      final success = await _postsState.uploadImages(request);

      if (success) {
        debugPrint('✅ Imágenes subidas');
      }

      return success;
    } catch (e) {
      debugPrint('❌ Error subiendo imágenes: $e');
      return false;
    }
  }

  // ==================== MÉTODOS PRIVADOS ====================

  void _setRefreshing(bool refreshing) {
    _isRefreshing = refreshing;
    notifyListeners();
  }

  void _setLoadingMore(bool loadingMore) {
    _isLoadingMore = loadingMore;
    notifyListeners();
  }

  // ==================== MÉTODOS DE UTILIDAD ====================

  /// Limpiar todos los datos
  void clear() {
    _postsState.clear();
    _isInitialized = false;
    _currentPage = 1;
    _isRefreshing = false;
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Verificar si hay posts en cache para una comunidad
  bool hasCommunityPosts(int communityId) {
    return _postsState.hasCommunityPosts(communityId);
  }

  /// Obtener posts de una comunidad desde cache
  List<Post> getPostsForCommunity(int communityId) {
    return _postsState.getPostsForCommunity(communityId);
  }

  /// Obtener estadísticas
  Map<String, int> get stats => _postsState.stats;

  /// Verificar si mounted (para evitar errores en dispose)
  bool get mounted => !_disposed;
}
