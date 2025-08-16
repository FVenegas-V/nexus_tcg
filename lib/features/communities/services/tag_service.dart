import 'package:flutter/foundation.dart';
import '../../../core/services/http_service.dart';
import '../../../core/config/api_config.dart';
import '../models/community_tag.dart';

/// Servicio para gestión de tags de comunidades
/// Maneja la comunicación con las APIs de tags de la Fase 2
class TagService {
  static final HttpService _httpService = HttpService();

  /// Obtiene todos los tags disponibles
  ///
  /// [minUsage] - Mínimo número de usos para filtrar tags
  /// [ordering] - Campo de ordenamiento ('name', '-usage_count')
  static Future<List<CommunityTag>> getTags({
    int? minUsage,
    String? ordering,
  }) async {
    try {
      debugPrint('🏷️ Obteniendo lista de tags...');

      // Construir parámetros de query
      final queryParams = <String, dynamic>{};
      if (minUsage != null) queryParams['min_usage'] = minUsage.toString();
      if (ordering != null) queryParams['ordering'] = ordering;

      final response = await _httpService.get(
        '${ApiConfig.baseUrl}/api/tags/',
        queryParameters: queryParams,
      );

      // Django devuelve: {"tags":[], "total_count":0, "showing":0}
      final responseData = response.data;
      final List<dynamic> results;

      if (responseData is Map<String, dynamic>) {
        results = responseData['tags'] ?? responseData['results'] ?? [];
      } else if (responseData is List) {
        results = responseData;
      } else {
        results = [];
      }

      final tags = results.map((json) => CommunityTag.fromJson(json)).toList();

      debugPrint('✅ ${tags.length} tags obtenidos');
      return tags;
    } catch (e) {
      debugPrint('🚨 Error obteniendo tags: $e');

      // Fallback a datos mock para desarrollo
      return _getMockTags();
    }
  }

  /// Obtiene los tags más populares (top 10)
  static Future<List<CommunityTag>> getPopularTags() async {
    try {
      debugPrint('🌟 Obteniendo tags populares...');

      final response = await _httpService.get(
        '${ApiConfig.baseUrl}/api/tags/popular/',
      );

      // Django devuelve: {"popular_tags":[], "total_popular":0}
      final responseData = response.data;
      final List<dynamic> results;

      if (responseData is Map<String, dynamic>) {
        results = responseData['popular_tags'] ?? responseData['results'] ?? [];
      } else if (responseData is List) {
        results = responseData;
      } else {
        results = [];
      }

      final tags = results.map((json) => CommunityTag.fromJson(json)).toList();

      debugPrint('✅ ${tags.length} tags populares obtenidos');
      return tags;
    } catch (e) {
      debugPrint('🚨 Error obteniendo tags populares: $e');

      // Fallback a datos mock filtrados por popularidad
      final mockTags = _getMockTags();
      mockTags.sort((a, b) => b.usageCount.compareTo(a.usageCount));
      return mockTags.take(10).toList();
    }
  }

  /// Busca tags por nombre o descripción
  ///
  /// [query] - Término de búsqueda
  static Future<List<CommunityTag>> searchTags(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      debugPrint('🔍 Buscando tags con query: "$query"');

      final response = await _httpService.get(
        '${ApiConfig.baseUrl}/api/tags/search/',
        queryParameters: {'q': query},
      );

      // Django devuelve: {"query":"...", "tags":[], "count":0}
      final responseData = response.data;
      final List<dynamic> results;

      if (responseData is Map<String, dynamic>) {
        results = responseData['tags'] ?? responseData['results'] ?? [];
      } else if (responseData is List) {
        results = responseData;
      } else {
        results = [];
      }

      final tags = results.map((json) => CommunityTag.fromJson(json)).toList();

      debugPrint('✅ ${tags.length} tags encontrados para "$query"');
      return tags;
    } catch (e) {
      debugPrint('🚨 Error buscando tags: $e');

      // Fallback a búsqueda local en datos mock
      final mockTags = _getMockTags();
      final queryLower = query.toLowerCase();
      return mockTags
          .where(
            (tag) =>
                tag.name.toLowerCase().contains(queryLower) ||
                tag.description.toLowerCase().contains(queryLower),
          )
          .toList();
    }
  }

  /// Obtiene sugerencias de autocompletado para tags
  ///
  /// [prefix] - Prefijo para autocompletado
  static Future<List<CommunityTag>> getTagSuggestions(String prefix) async {
    if (prefix.trim().isEmpty) return [];

    try {
      debugPrint('💡 Obteniendo sugerencias para prefix: "$prefix"');

      final response = await _httpService.get(
        '${ApiConfig.baseUrl}/api/tags/suggestions/',
        queryParameters: {'prefix': prefix},
      );

      final List<dynamic> results = response.data['results'] ?? response.data;
      final tags = results.map((json) => CommunityTag.fromJson(json)).toList();

      debugPrint('✅ ${tags.length} sugerencias obtenidas para "$prefix"');
      return tags;
    } catch (e) {
      debugPrint('🚨 Error obteniendo sugerencias: $e');

      // Fallback a sugerencias locales
      final mockTags = _getMockTags();
      final prefixLower = prefix.toLowerCase();
      return mockTags
          .where((tag) => tag.name.toLowerCase().startsWith(prefixLower))
          .take(5)
          .toList();
    }
  }

  /// Convierte una lista de strings en CommunityTag objects
  /// Útil para manejar tags dinámicos en JSON
  static List<CommunityTag> convertStringTagsToObjects(
    List<dynamic> tagStrings,
  ) {
    return tagStrings.map((tagString) {
      if (tagString is String) {
        return CommunityTag.fromString(tagString);
      } else if (tagString is Map<String, dynamic>) {
        return CommunityTag.fromJson(tagString);
      } else {
        return CommunityTag.fromString(tagString.toString());
      }
    }).toList();
  }

  /// Datos mock para desarrollo y fallback
  static List<CommunityTag> _getMockTags() {
    return [
      CommunityTag(
        id: 1,
        name: 'competitive',
        slug: 'competitive',
        description: 'Para comunidades enfocadas en competencia',
        color: '#FF5722',
        usageCount: 15,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      CommunityTag(
        id: 2,
        name: 'casual',
        slug: 'casual',
        description: 'Juego relajado y divertido',
        color: '#4CAF50',
        usageCount: 12,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
      ),
      CommunityTag(
        id: 3,
        name: 'trading',
        slug: 'trading',
        description: 'Enfocado en intercambio de cartas',
        color: '#2196F3',
        usageCount: 8,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      CommunityTag(
        id: 4,
        name: 'tournament',
        slug: 'tournament',
        description: 'Organización de torneos',
        color: '#9C27B0',
        usageCount: 6,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      CommunityTag(
        id: 5,
        name: 'beginner',
        slug: 'beginner',
        description: 'Ideal para principiantes',
        color: '#FFC107',
        usageCount: 10,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      CommunityTag(
        id: 6,
        name: 'collection',
        slug: 'collection',
        description: 'Coleccionistas de cartas',
        color: '#795548',
        usageCount: 4,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }
}
