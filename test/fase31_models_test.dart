import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_tcg/core/models/post.dart';
import 'package:nexus_tcg/core/models/post_image.dart';
import 'package:nexus_tcg/core/models/reaction.dart';
import 'package:nexus_tcg/core/services/posts_service.dart';
import 'package:nexus_tcg/core/providers/posts_state.dart';
import 'package:nexus_tcg/core/config/api_config.dart';

void main() {
  group('Fase 3.1 - Posts, Reacciones e Imágenes Tests', () {
    test('ApiConfig tiene todos los endpoints de Fase 3', () {
      expect(ApiConfig.postsEndpoint, '/api/posts/');
      expect(ApiConfig.commentsEndpoint, '/api/comments/');
      expect(ApiConfig.reactionsEndpoint, '/api/reactions/');
      expect(ApiConfig.postImagesEndpoint, '/api/post-images/');
      expect(ApiConfig.baseUrl, isNotEmpty);
    });

    test('Post model - serialización y deserialización', () {
      final postJson = {
        'id': 1,
        'title': 'Test Post',
        'content': 'Contenido de prueba',
        'community_id': 1,
        'community_name': 'Comunidad Test',
        'author_id': 1,
        'author_username': 'testuser',
        'created_at': '2025-08-18T22:00:00Z',
        'comments_count': 5,
        'reactions_count': 10,
        'images': [],
        'reactions_breakdown': {'like': 5, 'love': 3},
      };

      // Test fromJson
      final post = Post.fromJson(postJson);
      expect(post.id, 1);
      expect(post.title, 'Test Post');
      expect(post.content, 'Contenido de prueba');
      expect(post.communityId, 1);
      expect(post.communityName, 'Comunidad Test');
      expect(post.authorId, 1);
      expect(post.authorUsername, 'testuser');
      expect(post.commentsCount, 5);
      expect(post.reactionsCount, 10);
      expect(post.isDeleted, false);

      // Test toJson
      final serialized = post.toJson();
      expect(serialized['id'], 1);
      expect(serialized['title'], 'Test Post');
      expect(serialized['community_id'], 1);
      expect(serialized['comments_count'], 5);

      // Test copyWith
      final updatedPost = post.copyWith(title: 'Título Actualizado');
      expect(updatedPost.title, 'Título Actualizado');
      expect(updatedPost.id, 1); // Otros campos sin cambios
    });

    test('CreatePostRequest - validación y serialización', () {
      final request = CreatePostRequest(
        title: 'Nuevo Post',
        content: 'Contenido del nuevo post',
        communityId: 1,
        imagePaths: ['path/to/image1.jpg', 'path/to/image2.jpg'],
      );

      final json = request.toJson();
      expect(json['title'], 'Nuevo Post');
      expect(json['content'], 'Contenido del nuevo post');
      expect(json['community_id'], 1);
    });

    test('UpdatePostRequest - validación campos opcionales', () {
      // Solo título
      final request1 = UpdatePostRequest(title: 'Nuevo Título');
      final json1 = request1.toJson();
      expect(json1['title'], 'Nuevo Título');
      expect(json1.containsKey('content'), false);

      // Solo contenido
      final request2 = UpdatePostRequest(content: 'Nuevo Contenido');
      final json2 = request2.toJson();
      expect(json2['content'], 'Nuevo Contenido');
      expect(json2.containsKey('title'), false);

      // Ambos campos
      final request3 = UpdatePostRequest(title: 'Título', content: 'Contenido');
      final json3 = request3.toJson();
      expect(json3['title'], 'Título');
      expect(json3['content'], 'Contenido');
    });

    test('ReactionType - tipos y propiedades', () {
      final allTypes = [
        ReactionType.like,
        ReactionType.love,
        ReactionType.laugh,
        ReactionType.wow,
        ReactionType.sad,
        ReactionType.angry,
      ];

      // Verificar que todos los tipos tienen propiedades
      for (final type in allTypes) {
        expect(type.emoji, isNotEmpty);
        expect(type.displayName, isNotEmpty);
        expect(type.value, isNotEmpty);
        expect(type.colorHex, startsWith('#'));
      }

      // Verificar emojis específicos
      expect(ReactionType.like.emoji, '👍');
      expect(ReactionType.love.emoji, '❤️');
      expect(ReactionType.laugh.emoji, '😂');
      expect(ReactionType.wow.emoji, '😮');
      expect(ReactionType.sad.emoji, '😢');
      expect(ReactionType.angry.emoji, '😠');

      // Verificar fromString
      expect(ReactionType.fromString('like'), ReactionType.like);
      expect(ReactionType.fromString('love'), ReactionType.love);
      expect(ReactionType.fromString('laugh'), ReactionType.laugh);

      // Test error en fromString
      expect(() => ReactionType.fromString('invalid'), throwsArgumentError);
    });

    test('Reaction model - serialización completa', () {
      final reactionJson = {
        'id': 1,
        'user_id': 123,
        'username': 'testuser',
        'reaction_type': 'like',
        'created_at': '2025-08-18T22:00:00Z',
        'post_id': 456,
      };

      final reaction = Reaction.fromJson(reactionJson);
      expect(reaction.id, 1);
      expect(reaction.userId, 123);
      expect(reaction.username, 'testuser');
      expect(reaction.reactionType, ReactionType.like);
      expect(reaction.postId, 456);
      expect(reaction.commentId, null);

      // Test toJson
      final serialized = reaction.toJson();
      expect(serialized['id'], 1);
      expect(serialized['user_id'], 123);
      expect(serialized['reaction_type'], 'like');
      expect(serialized['post_id'], 456);
    });

    test('ReactionsBreakdown - estadísticas completas', () {
      final breakdownJson = {
        'counts': {'like': 5, 'love': 3, 'laugh': 2},
        'usernames': {
          'like': ['user1', 'user2', 'user3'],
          'love': ['user4', 'user5'],
          'laugh': ['user6'],
        },
        'total_count': 10,
        'user_reaction': 'like',
      };

      final breakdown = ReactionsBreakdown.fromJson(breakdownJson);
      expect(breakdown.totalCount, 10);
      expect(breakdown.userReaction, ReactionType.like);
      expect(breakdown.getCount(ReactionType.like), 5);
      expect(breakdown.getCount(ReactionType.love), 3);
      expect(breakdown.getCount(ReactionType.wow), 0); // No presente
      expect(breakdown.getUsernames(ReactionType.like), [
        'user1',
        'user2',
        'user3',
      ]);
      expect(breakdown.hasReactions, true);

      // Test topReactionTypes (ordenados por cantidad descendente)
      final topTypes = breakdown.topReactionTypes;
      expect(topTypes.first, ReactionType.like); // 5 reacciones
      expect(topTypes[1], ReactionType.love); // 3 reacciones
      expect(topTypes[2], ReactionType.laugh); // 2 reacciones
    });

    test('PostImage model - metadatos y resoluciones', () {
      final imageJson = {
        'id': 1,
        'post_id': 123,
        'original_filename': 'image.jpg',
        'filename': 'processed_image.webp',
        'file_size': 1024000,
        'content_type': 'image/webp',
        'width': 1200,
        'height': 800,
        'order': 0,
        'uploaded_at': '2025-08-18T22:00:00Z',
        'is_processed': true,
        'original_url': 'http://example.com/original.jpg',
        'thumbnail_url': 'http://example.com/thumb.webp',
        'medium_url': 'http://example.com/medium.webp',
        'large_url': 'http://example.com/large.webp',
        'metadata': {'quality': 90, 'format': 'webp'},
      };

      final image = PostImage.fromJson(imageJson);
      expect(image.id, 1);
      expect(image.postId, 123);
      expect(image.originalFilename, 'image.jpg');
      expect(image.width, 1200);
      expect(image.height, 800);
      expect(image.isProcessed, true);
      expect(image.aspectRatio, 1.5); // 1200/800

      // Test propiedades calculadas
      expect(image.isLandscape, true);
      expect(image.isPortrait, false);
      expect(image.isSquare, false);

      // Test getUrlForResolution
      expect(
        image.getUrlForResolution(ImageResolution.thumbnail),
        'http://example.com/thumb.webp',
      );
      expect(
        image.getUrlForResolution(ImageResolution.medium),
        'http://example.com/medium.webp',
      );
      expect(
        image.getUrlForResolution(ImageResolution.large),
        'http://example.com/large.webp',
      );
      expect(
        image.getUrlForResolution(ImageResolution.original),
        'http://example.com/original.jpg',
      );
    });

    test('ImageUploadRequest y ImageReorderRequest', () {
      // Test ImageUploadRequest
      final uploadRequest = ImageUploadRequest(
        postId: 123,
        imagePaths: ['path1.jpg', 'path2.jpg'],
        orders: [0, 1],
      );

      final uploadJson = uploadRequest.toJson();
      expect(uploadJson['post_id'], 123);
      expect(uploadJson['image_paths'], ['path1.jpg', 'path2.jpg']);
      expect(uploadJson['orders'], [0, 1]);

      // Test ImageReorderRequest
      final reorderRequest = ImageReorderRequest(
        imageIds: [1, 2, 3],
        newOrders: [2, 0, 1],
      );

      final reorderJson = reorderRequest.toJson();
      expect(reorderJson['image_ids'], [1, 2, 3]);
      expect(reorderJson['new_orders'], [2, 0, 1]);
    });

    test('PostsService - inicialización y métodos disponibles', () {
      final postsService = PostsService();

      // Verificar que es singleton
      final postsService2 = PostsService();
      expect(identical(postsService, postsService2), true);
    });

    test('PostsState - estado inicial y propiedades', () {
      final postsState = PostsState();

      // Estado inicial
      expect(postsState.isLoading, false);
      expect(postsState.error, null);
      expect(postsState.isCreatingPost, false);
      expect(postsState.isUploadingImages, false);
      expect(postsState.feedPosts, isEmpty);
      expect(postsState.communityPosts, isEmpty);
      expect(postsState.postsCache, isEmpty);

      // Test stats
      final stats = postsState.stats;
      expect(stats['feedPosts'], 0);
      expect(stats['cachedPosts'], 0);
      expect(stats['communities'], 0);

      // Test hasCommunityPosts
      expect(postsState.hasCommunityPosts(1), false);

      // Test clear
      postsState.clear();
      expect(postsState.feedPosts, isEmpty);
      expect(postsState.error, null);
    });

    test('ReactionRequest - serialización', () {
      final request = ReactionRequest(reactionType: ReactionType.love);
      final json = request.toJson();
      expect(json['reaction_type'], 'love');
    });
  });
}
