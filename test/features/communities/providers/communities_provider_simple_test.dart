import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_tcg/features/communities/providers/communities_provider.dart';

void main() {
  group('CommunitiesProvider Simplified Tests', () {
    test('should create provider and eventually load communities', () async {
      final provider = CommunitiesProvider();

      // Wait for the provider to load
      await Future.delayed(Duration(milliseconds: 1000));

      // Basic functionality tests
      expect(provider.communities.length, greaterThan(0));
      expect(provider.isLoading, false);
    });

    test('should handle search functionality', () async {
      final provider = CommunitiesProvider();
      await Future.delayed(Duration(milliseconds: 1000));

      // Test search
      provider.searchCommunities('Magic');
      expect(provider.searchQuery, equals('Magic'));

      // Clear search
      provider.searchCommunities('');
      expect(provider.searchQuery, isEmpty);
    });

    test('should get community by valid ID', () async {
      final provider = CommunitiesProvider();
      await Future.delayed(Duration(milliseconds: 1000));

      final community = provider.getCommunityById(1);
      expect(community, isNotNull);
      if (community != null) {
        expect(community.id, equals(1));
      }
    });
  });
}
