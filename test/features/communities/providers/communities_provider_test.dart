import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_tcg/features/communities/providers/communities_provider.dart';

void main() {
  group('CommunitiesProvider Tests', () {
    late CommunitiesProvider provider;

    setUp(() {
      provider = CommunitiesProvider();
    });

    test('should load communities successfully', () async {
      // Wait for initial load to complete
      await Future.delayed(Duration(milliseconds: 500));

      expect(provider.communities.isNotEmpty, true);
      expect(provider.isLoading, false);
      expect(provider.hasError, false);
    });

    test('should filter communities by search query', () async {
      // Wait for communities to load first
      await Future.delayed(Duration(milliseconds: 500));

      // Search for Magic communities
      provider.searchCommunities('Magic');

      // Should find Magic-related communities
      final magicCommunities = provider.communities
          .where(
            (c) =>
                c.name.toLowerCase().contains('magic') ||
                c.gameType.toLowerCase().contains('magic'),
          )
          .toList();

      expect(magicCommunities.isNotEmpty, true);
    });

    test('should filter communities by game type', () async {
      await Future.delayed(Duration(milliseconds: 500));

      // Filter by Pokemon
      provider.filterByGameType('Pokémon TCG');

      final pokemonCommunities = provider.communities
          .where((c) => c.gameType == 'Pokémon TCG')
          .toList();

      expect(pokemonCommunities.length, greaterThan(0));
    });

    test('should filter communities by difficulty level', () async {
      await Future.delayed(Duration(milliseconds: 500));

      // Filter by Principiante
      provider.filterByDifficulty('Principiante');

      final beginnerCommunities = provider.communities
          .where((c) => c.difficultyLevel == 'Principiante')
          .toList();

      expect(beginnerCommunities.length, greaterThan(0));
    });

    test('should get community by ID', () async {
      await Future.delayed(Duration(milliseconds: 500));

      final community = provider.getCommunityById(1);

      expect(community, isNotNull);
      expect(community!.id, equals(1));
    });

    test('should return null for non-existent community ID', () async {
      await Future.delayed(Duration(milliseconds: 500));

      final community = provider.getCommunityById(999);

      expect(community, isNull);
    });

    test('should clear filters correctly', () async {
      await Future.delayed(Duration(milliseconds: 500));

      // Apply some filters
      provider.searchCommunities('Magic');
      provider.filterByGameType('Magic: The Gathering');

      // Clear filters
      provider.clearFilters();

      // Should show all communities again
      expect(provider.searchQuery, isEmpty);
      expect(provider.selectedGameType, isEmpty);
      expect(provider.selectedDifficulty, isEmpty);
    });

    test('should toggle community subscription', () async {
      await Future.delayed(Duration(milliseconds: 500));

      final community = provider.getCommunityById(1);
      expect(community, isNotNull);

      final initialSubscriptionStatus = community!.isSubscribed;

      provider.toggleSubscription(1);

      final updatedCommunity = provider.getCommunityById(1);
      expect(
        updatedCommunity!.isSubscribed,
        equals(!initialSubscriptionStatus),
      );
    });
  });
}
