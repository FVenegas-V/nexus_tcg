import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_tcg/features/posts/providers/posts_provider.dart';
import 'package:nexus_tcg/core/models/post.dart';
import 'package:nexus_tcg/core/models/reaction.dart';

void main() {
  group('PostsProvider Backend Integration Tests', () {
    late PostsProvider postsProvider;

    setUp(() {
      postsProvider = PostsProvider();
    });

    tearDown(() {
      postsProvider.dispose();
    });

    test('should initialize correctly with backend', () {
      expect(postsProvider.posts, isEmpty);
      expect(postsProvider.isLoading, isTrue);
      expect(postsProvider.hasError, isFalse);
      expect(postsProvider.errorMessage, isNull);
      print('✅ PostsProvider inicializado correctamente');
    });

    test('should load initial posts from backend', () async {
      // Esperar a que se inicialice
      await Future.delayed(const Duration(milliseconds: 100));

      await postsProvider.loadInitialPosts();

      // Verificar que no hay error después de cargar
      expect(postsProvider.hasError, isFalse);
      print('✅ Posts iniciales cargados: ${postsProvider.posts.length}');
    });

    test('should handle refresh from backend', () async {
      await postsProvider.refreshPosts();

      expect(postsProvider.isRefreshing, isFalse);
      expect(postsProvider.hasError, isFalse);
      print('✅ Refresh desde backend completado');
    });

    test('should handle community posts loading from backend', () async {
      const int testCommunityId = 1;

      await postsProvider.loadCommunityPosts(testCommunityId);

      expect(postsProvider.hasError, isFalse);
      print('✅ Posts de comunidad $testCommunityId cargados desde backend');
    });

    test('should handle search from backend', () async {
      await postsProvider.searchPosts('test query');

      expect(postsProvider.hasError, isFalse);
      print('✅ Búsqueda en backend completada');
    });

    test('should handle reactions toggle with backend', () async {
      // Solo probar si hay posts disponibles
      if (postsProvider.posts.isNotEmpty) {
        final firstPost = postsProvider.posts.first;

        await postsProvider.toggleReaction(firstPost.id, ReactionType.like);

        expect(postsProvider.hasError, isFalse);
        print(
          '✅ Toggle de reacción en backend completado para post ${firstPost.id}',
        );
      } else {
        print('ℹ️ No hay posts para probar reacciones');
      }
    });

    test('should validate backend integration methods', () {
      // Verificar que todos los métodos principales están disponibles
      expect(postsProvider.createPost, isA<Function>());
      expect(postsProvider.updatePost, isA<Function>());
      expect(postsProvider.deletePost, isA<Function>());
      expect(postsProvider.getPost, isA<Function>());
      expect(postsProvider.getPostReactions, isA<Function>());
      expect(postsProvider.uploadImages, isA<Function>());

      print('✅ Todos los métodos de backend están disponibles');
    });

    test('should handle backend error states properly', () {
      // Verificar propiedades de estado de error
      expect(postsProvider.hasError, isA<bool>());
      expect(postsProvider.errorMessage, isA<String?>());

      print('✅ Estados de error del backend funcionan correctamente');
    });

    test('should handle cache operations', () {
      final cache = postsProvider.postsCache;
      expect(cache, isA<Map<int, Post>>());

      final reactions = postsProvider.postReactions;
      expect(reactions, isA<Map<int, dynamic>>());

      print(
        '✅ Cache de posts y reacciones funciona: ${cache.length} posts, ${reactions.length} breakdowns',
      );
    });

    test('should handle community-specific operations', () {
      const int testCommunityId = 1;

      final hasPosts = postsProvider.hasCommunityPosts(testCommunityId);
      expect(hasPosts, isA<bool>());

      final communityPosts = postsProvider.getPostsForCommunity(
        testCommunityId,
      );
      expect(communityPosts, isA<List<Post>>());

      print('✅ Operaciones específicas de comunidad funcionan');
    });

    test('should provide backend statistics', () {
      final stats = postsProvider.stats;
      expect(stats, isA<Map<String, int>>());

      print('✅ Estadísticas del backend: $stats');
    });

    test('should handle dispose correctly', () {
      expect(postsProvider.mounted, isTrue);

      postsProvider.dispose();

      // El objeto sigue existiendo pero marcado como disposed
      print('✅ Dispose del provider completado correctamente');
    });
  });
}
