import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_tcg/features/posts/providers/posts_provider.dart';
import 'package:nexus_tcg/features/posts/models/mock_posts_data.dart';

void main() {
  group('PostsProvider Tests', () {
    late PostsProvider postsProvider;

    setUp(() {
      postsProvider = PostsProvider();
    });

    tearDown(() {
      // Limpiar primero, luego dispose
      postsProvider.clear();
      postsProvider.dispose();
    });

    test('PostsProvider should initialize correctly', () {
      expect(postsProvider.posts, isA<List>());
      expect(postsProvider.isLoading, isA<bool>());
      expect(postsProvider.isLoadingMore, false);
      expect(postsProvider.hasError, false);
      expect(postsProvider.hasReachedEnd, false);
    });

    test('loadInitialPosts should load posts correctly', () async {
      // El provider se inicializa automáticamente, así que esperamos a que termine
      await Future.delayed(const Duration(milliseconds: 900));

      expect(postsProvider.posts.isNotEmpty, true);
      expect(postsProvider.isLoading, false);
      expect(postsProvider.hasError, false);
      expect(postsProvider.posts.length, lessThanOrEqualTo(10));
    });

    test('loadMorePosts should add more posts when available', () async {
      // Esperar carga inicial
      await Future.delayed(const Duration(milliseconds: 900));

      final initialCount = postsProvider.posts.length;

      // Solo intentar cargar más posts si hay disponibles
      if (!postsProvider.hasReachedEnd) {
        await postsProvider.loadMorePosts();
        expect(postsProvider.posts.length, greaterThan(initialCount));
      } else {
        // Si ya llegamos al final, verificar que no se agreguen más posts
        await postsProvider.loadMorePosts();
        expect(postsProvider.posts.length, equals(initialCount));
      }

      expect(postsProvider.isLoadingMore, false);
    });

    test('refreshPosts should reload all posts', () async {
      // Esperar carga inicial
      await Future.delayed(const Duration(milliseconds: 900));

      // Refrescar
      await postsProvider.refreshPosts();

      // Verificar que se recargaron (pueden ser los mismos datos pero el proceso se ejecutó)
      expect(postsProvider.isLoading, false);
      expect(postsProvider.posts.isNotEmpty, true);
    });

    test('toggleLike should update post like status', () async {
      // Esperar carga inicial
      await Future.delayed(const Duration(milliseconds: 900));

      if (postsProvider.posts.isNotEmpty) {
        final post = postsProvider.posts.first;
        final initialLiked = post.isLiked;
        final initialLikesCount = post.likesCount;

        // Toggle like
        postsProvider.toggleLike(post.id);

        final updatedPost = postsProvider.getPostById(post.id);
        expect(updatedPost?.isLiked, !initialLiked);

        if (initialLiked) {
          expect(updatedPost?.likesCount, initialLikesCount - 1);
        } else {
          expect(updatedPost?.likesCount, initialLikesCount + 1);
        }
      }
    });

    test('toggleBookmark should update post bookmark status', () async {
      // Esperar carga inicial
      await Future.delayed(const Duration(milliseconds: 900));

      if (postsProvider.posts.isNotEmpty) {
        final post = postsProvider.posts.first;
        final initialBookmarked = post.isBookmarked;

        // Toggle bookmark
        postsProvider.toggleBookmark(post.id);

        final updatedPost = postsProvider.getPostById(post.id);
        expect(updatedPost?.isBookmarked, !initialBookmarked);
      }
    });

    test('getPostById should return correct post', () async {
      // Esperar carga inicial
      await Future.delayed(const Duration(milliseconds: 900));

      if (postsProvider.posts.isNotEmpty) {
        final post = postsProvider.posts.first;
        final foundPost = postsProvider.getPostById(post.id);

        expect(foundPost, isNotNull);
        expect(foundPost?.id, post.id);
      }
    });

    test('getPostById should return null for non-existent post', () async {
      // Esperar carga inicial
      await Future.delayed(const Duration(milliseconds: 900));

      final foundPost = postsProvider.getPostById(99999);
      expect(foundPost, isNull);
    });

    test('getPostsByCommunity should filter posts correctly', () async {
      // Esperar carga inicial
      await Future.delayed(const Duration(milliseconds: 900));

      if (postsProvider.posts.isNotEmpty) {
        final firstPost = postsProvider.posts.first;
        final communityId = firstPost.community.id;

        final communityPosts = postsProvider.getPostsByCommunity(communityId);

        expect(communityPosts.isNotEmpty, true);
        for (final post in communityPosts) {
          expect(post.community.id, communityId);
        }
      }
    });

    test('getPostsByAuthor should filter posts correctly', () async {
      // Esperar carga inicial
      await Future.delayed(const Duration(milliseconds: 900));

      if (postsProvider.posts.isNotEmpty) {
        final firstPost = postsProvider.posts.first;
        final authorId = firstPost.author.id;

        final authorPosts = postsProvider.getPostsByAuthor(authorId);

        expect(authorPosts.isNotEmpty, true);
        for (final post in authorPosts) {
          expect(post.author.id, authorId);
        }
      }
    });

    test('clear should reset all state', () async {
      // Esperar carga inicial
      await Future.delayed(const Duration(milliseconds: 900));

      // Verificar que hay datos
      expect(postsProvider.posts.isNotEmpty, true);

      // Limpiar
      postsProvider.clear();

      // Verificar que se limpió todo
      expect(postsProvider.posts.isEmpty, true);
      expect(postsProvider.isLoading, false);
      expect(postsProvider.isLoadingMore, false);
      expect(postsProvider.hasError, false);
      expect(postsProvider.hasReachedEnd, false);
    });

    test('isEmpty should return correct status', () async {
      // Al inicio está vacío pero cargando
      expect(postsProvider.isEmpty, false); // porque isLoading es true

      // Esperar carga
      await Future.delayed(const Duration(milliseconds: 900));

      // Ahora no está vacío
      expect(postsProvider.isEmpty, false);

      // Limpiar y verificar
      postsProvider.clear();
      expect(postsProvider.isEmpty, true);
    });
  });

  group('MockPostsData Tests', () {
    test('allPosts should return non-empty list', () {
      final posts = MockPostsData.allPosts;

      expect(posts.isNotEmpty, true);
      expect(posts.length, greaterThan(5));
    });

    test('getMorePosts should generate additional posts', () {
      final morePosts = MockPostsData.getMorePosts(20);

      expect(morePosts.isNotEmpty, true);
      expect(morePosts.length, 10); // Siempre genera 10 posts

      // Verificar que los IDs son secuenciales desde currentCount + 1
      for (int i = 0; i < morePosts.length; i++) {
        expect(morePosts[i].id, 21 + i);
      }
    });

    test('all posts should have required fields', () {
      final posts = MockPostsData.allPosts;

      for (final post in posts) {
        expect(post.id, isA<int>());
        expect(post.content.isNotEmpty, true);
        expect(post.author.username.isNotEmpty, true);
        expect(post.community.name.isNotEmpty, true);
        expect(post.createdAt, isA<DateTime>());
        expect(post.likesCount, isA<int>());
        expect(post.commentsCount, isA<int>());
      }
    });

    test('posts should have realistic data patterns', () {
      final posts = MockPostsData.allPosts;

      // Verificar que hay diferentes comunidades
      final communityIds = posts.map((p) => p.community.id).toSet();
      expect(communityIds.length, greaterThan(1));

      // Verificar que hay diferentes autores
      final authorIds = posts.map((p) => p.author.id).toSet();
      expect(authorIds.length, greaterThan(1));

      // Verificar que hay variedad en likes y comments
      final likeCounts = posts.map((p) => p.likesCount).toSet();
      expect(likeCounts.length, greaterThan(1));
    });
  });
}
