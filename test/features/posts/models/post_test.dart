import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_tcg/features/posts/models/post.dart';

void main() {
  group('Post Model Tests', () {
    final mockAuthor = PostAuthor(
      id: 1,
      username: 'test_user',
      avatarUrl: 'https://example.com/avatar.png',
      isVerified: true,
    );

    final mockCommunity = PostCommunity(
      id: 1,
      name: 'Test Community',
      gameType: 'Magic: The Gathering',
    );

    final mockPost = Post(
      id: 1,
      content: 'Test post content',
      imageUrls: ['https://example.com/image1.png'],
      author: mockAuthor,
      community: mockCommunity,
      createdAt: DateTime(2025, 8, 13),
      likesCount: 42,
      commentsCount: 8,
      isLiked: false,
      isBookmarked: true,
    );

    test('Post model should create instance correctly', () {
      expect(mockPost.id, 1);
      expect(mockPost.content, 'Test post content');
      expect(mockPost.imageUrls.length, 1);
      expect(mockPost.author.username, 'test_user');
      expect(mockPost.community.name, 'Test Community');
      expect(mockPost.likesCount, 42);
      expect(mockPost.commentsCount, 8);
      expect(mockPost.isLiked, false);
      expect(mockPost.isBookmarked, true);
    });

    test('Post copyWith should work correctly', () {
      final updatedPost = mockPost.copyWith(likesCount: 50, isLiked: true);

      expect(updatedPost.id, mockPost.id);
      expect(updatedPost.content, mockPost.content);
      expect(updatedPost.likesCount, 50);
      expect(updatedPost.isLiked, true);
      expect(updatedPost.isBookmarked, mockPost.isBookmarked);
    });

    test('Post toJson should serialize correctly', () {
      final json = mockPost.toJson();

      expect(json['id'], 1);
      expect(json['content'], 'Test post content');
      expect(json['likesCount'], 42);
      expect(json['commentsCount'], 8);
      expect(json['isLiked'], false);
      expect(json['isBookmarked'], true);
      expect(json['author'], isA<Map<String, dynamic>>());
      expect(json['community'], isA<Map<String, dynamic>>());
    });

    test('Post fromJson should deserialize correctly', () {
      final json = {
        'id': 2,
        'content': 'Another test post',
        'imageUrls': <String>[],
        'author': {
          'id': 2,
          'username': 'another_user',
          'avatarUrl': null,
          'isVerified': false,
        },
        'community': {
          'id': 2,
          'name': 'Another Community',
          'gameType': 'Pokemon TCG',
        },
        'createdAt': '2025-08-13T10:00:00.000Z',
        'likesCount': 15,
        'commentsCount': 3,
        'isLiked': true,
        'isBookmarked': false,
      };

      final post = Post.fromJson(json);

      expect(post.id, 2);
      expect(post.content, 'Another test post');
      expect(post.imageUrls, isEmpty);
      expect(post.author.username, 'another_user');
      expect(post.author.isVerified, false);
      expect(post.community.name, 'Another Community');
      expect(post.likesCount, 15);
      expect(post.isLiked, true);
      expect(post.isBookmarked, false);
    });

    test('Post equality should work correctly', () {
      final samePost = Post(
        id: 1,
        content: 'Different content',
        imageUrls: [],
        author: PostAuthor(
          id: 99,
          username: 'different_user',
          isVerified: false,
        ),
        community: PostCommunity(
          id: 99,
          name: 'Different Community',
          gameType: 'Different Game',
        ),
        createdAt: DateTime.now(),
        likesCount: 0,
        commentsCount: 0,
        isLiked: false,
        isBookmarked: false,
      );

      final differentPost = mockPost.copyWith(id: 2);

      expect(mockPost == samePost, true); // Same ID
      expect(mockPost == differentPost, false); // Different ID
    });

    test('Post toString should include key information', () {
      final string = mockPost.toString();

      expect(string, contains('Post(id: 1'));
      expect(string, contains('content: Test post content'));
      expect(string, contains('author: test_user'));
      expect(string, contains('likesCount: 42'));
    });
  });

  group('PostAuthor Model Tests', () {
    test('PostAuthor should serialize and deserialize correctly', () {
      final author = PostAuthor(
        id: 1,
        username: 'test_user',
        avatarUrl: 'https://example.com/avatar.png',
        isVerified: true,
      );

      final json = author.toJson();
      final deserializedAuthor = PostAuthor.fromJson(json);

      expect(deserializedAuthor.id, author.id);
      expect(deserializedAuthor.username, author.username);
      expect(deserializedAuthor.avatarUrl, author.avatarUrl);
      expect(deserializedAuthor.isVerified, author.isVerified);
    });

    test('PostAuthor equality should work correctly', () {
      final author1 = PostAuthor(id: 1, username: 'user1', isVerified: false);
      final author2 = PostAuthor(id: 1, username: 'user2', isVerified: true);
      final author3 = PostAuthor(id: 2, username: 'user1', isVerified: false);

      expect(author1 == author2, true); // Same ID
      expect(author1 == author3, false); // Different ID
    });
  });

  group('PostCommunity Model Tests', () {
    test('PostCommunity should serialize and deserialize correctly', () {
      final community = PostCommunity(
        id: 1,
        name: 'Test Community',
        gameType: 'Magic: The Gathering',
      );

      final json = community.toJson();
      final deserializedCommunity = PostCommunity.fromJson(json);

      expect(deserializedCommunity.id, community.id);
      expect(deserializedCommunity.name, community.name);
      expect(deserializedCommunity.gameType, community.gameType);
    });

    test('PostCommunity equality should work correctly', () {
      final community1 = PostCommunity(
        id: 1,
        name: 'Community1',
        gameType: 'MTG',
      );
      final community2 = PostCommunity(
        id: 1,
        name: 'Community2',
        gameType: 'Pokemon',
      );
      final community3 = PostCommunity(
        id: 2,
        name: 'Community1',
        gameType: 'MTG',
      );

      expect(community1 == community2, true); // Same ID
      expect(community1 == community3, false); // Different ID
    });
  });
}
