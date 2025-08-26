import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_tcg/features/communities/models/community.dart';

void main() {
  group('Community Model Tests', () {
    test('should create a community with required fields', () {
      final community = Community(
        id: 1,
        name: 'Test Community',
        description: 'A test community for TCG players',
        gameType: 'Magic: The Gathering',
        gameTypeId: 1,
        memberCount: 100,
        isSubscribed: false,
        createdAt: DateTime(2023, 1, 1),
        tags: ['Test', 'Community'],
        difficultyLevel: 'Intermedio',
      );

      expect(community.id, equals(1));
      expect(community.name, equals('Test Community'));
      expect(community.description, equals('A test community for TCG players'));
      expect(community.gameType, equals('Magic: The Gathering'));
      expect(community.memberCount, equals(100));
      expect(community.imageUrl, isNull); // Should be null by default
      expect(community.isSubscribed, isFalse);
      expect(community.tags.length, equals(2));
      expect(community.difficultyLevel, equals('Intermedio'));
    });

    test('should create a community with optional imageUrl', () {
      final community = Community(
        id: 2,
        name: 'Image Community',
        description: 'A community with image',
        gameType: 'Pokémon TCG',
        gameTypeId: 2,
        memberCount: 50,
        imageUrl: 'https://example.com/image.jpg',
        isSubscribed: true,
        createdAt: DateTime(2023, 2, 1),
        tags: ['Image'],
        difficultyLevel: 'Avanzado',
      );

      expect(community.imageUrl, equals('https://example.com/image.jpg'));
      expect(community.isSubscribed, isTrue);
    });

    test('should create a copy with modified fields using copyWith', () {
      final originalCommunity = Community(
        id: 3,
        name: 'Original Community',
        description: 'Original description',
        gameType: 'Yu-Gi-Oh!',
        gameTypeId: 3,
        memberCount: 75,
        isSubscribed: false,
        createdAt: DateTime(2023, 3, 1),
        tags: ['Original'],
        difficultyLevel: 'Principiante',
      );

      final modifiedCommunity = originalCommunity.copyWith(
        name: 'Modified Community',
        isSubscribed: true,
        memberCount: 100,
      );

      // Should keep original values for unchanged fields
      expect(modifiedCommunity.id, equals(originalCommunity.id));
      expect(
        modifiedCommunity.description,
        equals(originalCommunity.description),
      );
      expect(modifiedCommunity.gameType, equals(originalCommunity.gameType));
      expect(modifiedCommunity.createdAt, equals(originalCommunity.createdAt));
      expect(modifiedCommunity.tags, equals(originalCommunity.tags));
      expect(
        modifiedCommunity.difficultyLevel,
        equals(originalCommunity.difficultyLevel),
      );

      // Should have new values for modified fields
      expect(modifiedCommunity.name, equals('Modified Community'));
      expect(modifiedCommunity.isSubscribed, isTrue);
      expect(modifiedCommunity.memberCount, equals(100));
    });

    test('should serialize to JSON correctly', () {
      final community = Community(
        id: 4,
        name: 'JSON Community',
        description: 'A community for JSON testing',
        gameType: 'Digimon TCG',
        gameTypeId: 4,
        memberCount: 25,
        imageUrl: 'https://example.com/test.jpg',
        isSubscribed: false,
        createdAt: DateTime(2023, 4, 1),
        tags: ['JSON', 'Test'],
        difficultyLevel: 'Intermedio',
      );

      final json = community.toJson();

      expect(json['id'], equals(4));
      expect(json['name'], equals('JSON Community'));
      expect(json['description'], equals('A community for JSON testing'));
      expect(json['game_type'], equals('Digimon TCG'));
      expect(json['member_count'], equals(25));
      expect(json['image_url'], equals('https://example.com/test.jpg'));
      expect(json['is_subscribed'], isFalse);
      expect(json['tags'], equals(['JSON', 'Test']));
      expect(json['difficulty_level'], equals('Intermedio'));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 5,
        'name': 'From JSON Community',
        'description': 'A community created from JSON',
        'game_type': 'Dragon Ball Super',
        'member_count': 150,
        'image_url': null,
        'is_subscribed': true,
        'created_at': DateTime(2023, 5, 1).toIso8601String(),
        'tags': ['JSON', 'Deserialization'],
        'difficulty_level': 'Avanzado',
      };

      final community = Community.fromJson(json);

      expect(community.id, equals(5));
      expect(community.name, equals('From JSON Community'));
      expect(community.description, equals('A community created from JSON'));
      expect(community.gameType, equals('Dragon Ball Super'));
      expect(community.memberCount, equals(150));
      expect(community.imageUrl, isNull);
      expect(community.isSubscribed, isTrue);
      expect(community.tags, equals(['JSON', 'Deserialization']));
      expect(community.difficultyLevel, equals('Avanzado'));
    });
  });
}
