import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../models/mock_posts_data.dart';

/// Provider para gestión de estado del feed de posts
/// Maneja paginación infinita, interacciones y estados de carga
/// Filtra posts por comunidades suscritas del usuario
class PostsProvider extends ChangeNotifier {
  List<Post> _posts = [];
  List<Post> _allPosts = []; // Cache de todos los posts
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  bool _hasReachedEnd = false;
  int _currentPage = 0;
  bool _disposed = false;
  List<int> _subscribedCommunityIds = []; // IDs de comunidades suscritas
  static const int _postsPerPage = 10;

  // Getters
  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => _posts.isEmpty && !_isLoading;
  bool get hasReachedEnd => _hasReachedEnd;

  /// Inicializa el provider cargando los primeros posts
  PostsProvider() {
    // Por defecto, mostrar posts de comunidades suscritas (IDs 1 y 3)
    _subscribedCommunityIds = [1, 3];
    loadInitialPosts();
  }

  /// Actualiza las comunidades suscritas y refresca el feed
  void updateSubscribedCommunities(List<int> communityIds) {
    _subscribedCommunityIds = communityIds;
    refreshPosts();
  }

  /// Carga los primeros posts del feed
  Future<void> loadInitialPosts() async {
    _setLoading(true);
    _clearError();

    try {
      // Simula delay de red
      await Future.delayed(const Duration(milliseconds: 800));

      // Cargar todos los posts primero
      _allPosts = MockPostsData.allPosts;

      // Filtrar por comunidades suscritas y tomar los primeros
      final filteredPosts = _allPosts
          .where((post) => _subscribedCommunityIds.contains(post.community.id))
          .toList();

      final initialPosts = filteredPosts.take(_postsPerPage).toList();

      _posts = initialPosts;
      _currentPage = 1;
      _hasReachedEnd =
          initialPosts.length < _postsPerPage ||
          filteredPosts.length <= _postsPerPage;

      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar posts: ${e.toString()}');
      _setLoading(false);
    }
  }

  /// Carga más posts para paginación infinita
  Future<void> loadMorePosts() async {
    if (_isLoadingMore || _hasReachedEnd) return;

    _setLoadingMore(true);

    try {
      // Simula delay de red
      await Future.delayed(const Duration(milliseconds: 600));

      // Filtrar todos los posts por comunidades suscritas
      final filteredPosts = _allPosts
          .where((post) => _subscribedCommunityIds.contains(post.community.id))
          .toList();

      List<Post> newPosts;

      // Si ya cargamos todos los posts filtrados, generar más dinámicamente
      if (_currentPage * _postsPerPage >= filteredPosts.length) {
        // Solo generar posts de comunidades suscritas
        final generatedPosts = MockPostsData.getMorePosts(_posts.length);
        newPosts = generatedPosts
            .where(
              (post) => _subscribedCommunityIds.contains(post.community.id),
            )
            .toList();
      } else {
        // Cargar siguiente página de posts filtrados
        final startIndex = _currentPage * _postsPerPage;
        newPosts = filteredPosts.skip(startIndex).take(_postsPerPage).toList();
      }

      if (newPosts.isEmpty) {
        _hasReachedEnd = true;
      } else {
        _posts.addAll(newPosts);
        _currentPage++;
      }

      _setLoadingMore(false);
    } catch (e) {
      _setError('Error al cargar más posts: ${e.toString()}');
      _setLoadingMore(false);
    }
  }

  /// Refresca todo el feed (pull-to-refresh)
  Future<void> refreshPosts() async {
    _currentPage = 0;
    _hasReachedEnd = false;
    await loadInitialPosts();
  }

  /// Togglea el like de un post
  void toggleLike(int postId) {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];
      final newLikesCount = post.isLiked
          ? post.likesCount - 1
          : post.likesCount + 1;

      _posts[postIndex] = post.copyWith(
        isLiked: !post.isLiked,
        likesCount: newLikesCount,
      );

      notifyListeners();

      // Simula llamada a API
      _simulateApiCall();
    }
  }

  /// Togglea el bookmark de un post
  void toggleBookmark(int postId) {
    final postIndex = _posts.indexWhere((post) => post.id == postId);
    if (postIndex != -1) {
      final post = _posts[postIndex];

      _posts[postIndex] = post.copyWith(isBookmarked: !post.isBookmarked);

      notifyListeners();

      // Simula llamada a API
      _simulateApiCall();
    }
  }

  /// Obtiene un post por ID
  Post? getPostById(int postId) {
    try {
      return _posts.firstWhere((post) => post.id == postId);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene posts de una comunidad específica
  List<Post> getPostsByCommunity(int communityId) {
    return _posts.where((post) => post.community.id == communityId).toList();
  }

  /// Obtiene posts de un usuario específico
  List<Post> getPostsByAuthor(int authorId) {
    return _posts.where((post) => post.author.id == authorId).toList();
  }

  // Métodos privados para gestión de estado

  void _setLoading(bool loading) {
    if (_disposed) return;
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingMore(bool loadingMore) {
    if (_disposed) return;
    _isLoadingMore = loadingMore;
    notifyListeners();
  }

  void _setError(String error) {
    if (_disposed) return;
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Simula una llamada a API para interacciones
  Future<void> _simulateApiCall() async {
    // En producción, aquí iría la llamada real a la API
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// Limpia todos los datos del provider
  void clear() {
    _posts.clear();
    _currentPage = 0;
    _hasReachedEnd = false;
    _isLoading = false;
    _isLoadingMore = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    clear();
    super.dispose();
  }
}
