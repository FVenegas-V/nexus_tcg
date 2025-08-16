import 'package:flutter/foundation.dart';
import '../../../core/services/http_service.dart';
import '../../../core/config/api_config.dart';
import '../models/game_type.dart';
import '../../communities/models/community.dart';

/// Servicio para gestión de tipos de juego (GameTypes)
/// Maneja la comunicación con las APIs de games de la Fase 2
class GameService {
  static final HttpService _httpService = HttpService();

  /// Obtiene todos los tipos de juego disponibles
  ///
  /// [featured] - Si es true, obtiene solo games destacados
  /// [ordering] - Campo de ordenamiento ('name', '-community_count', 'release_year')
  static Future<List<GameType>> getGameTypes({
    bool? featured,
    String? ordering,
  }) async {
    try {
      debugPrint('🎮 Obteniendo lista de GameTypes...');

      // Construir parámetros de query
      final queryParams = <String, dynamic>{};
      if (featured != null) queryParams['featured'] = featured.toString();
      if (ordering != null) queryParams['ordering'] = ordering;

      final response = await _httpService.get(
        '${ApiConfig.baseUrl}/api/games/',
        queryParameters: queryParams,
      );

      // Django devuelve: {"featured":[], "all":[...], "stats":{...}}
      final responseData = response.data;
      final List<dynamic> results;

      if (responseData is Map<String, dynamic>) {
        // Estructura de respuesta de Django
        if (featured == true) {
          results = responseData['featured'] ?? [];
        } else {
          results = responseData['all'] ?? responseData['results'] ?? [];
        }
      } else if (responseData is List) {
        // Lista directa (fallback)
        results = responseData;
      } else {
        results = [];
      }

      final gameTypes = results.map((json) => GameType.fromJson(json)).toList();

      debugPrint('✅ ${gameTypes.length} GameTypes obtenidos');
      return gameTypes;
    } catch (e) {
      debugPrint('🚨 Error obteniendo GameTypes: $e');

      // Fallback a datos mock para desarrollo
      return _getMockGameTypes();
    }
  }

  /// Obtiene solo los GameTypes destacados
  static Future<List<GameType>> getFeaturedGameTypes() async {
    try {
      debugPrint('🌟 Obteniendo GameTypes destacados...');

      final response = await _httpService.get(
        '${ApiConfig.baseUrl}/api/games/featured/',
      );

      // Django devuelve: {"results":[], "count":0}
      final responseData = response.data;
      final List<dynamic> results;

      if (responseData is Map<String, dynamic>) {
        results = responseData['results'] ?? [];
      } else if (responseData is List) {
        results = responseData;
      } else {
        results = [];
      }

      final gameTypes = results.map((json) => GameType.fromJson(json)).toList();

      debugPrint('✅ ${gameTypes.length} GameTypes destacados obtenidos');
      return gameTypes;
    } catch (e) {
      debugPrint('🚨 Error obteniendo GameTypes destacados: $e');

      // Fallback a datos mock filtrados
      final mockGames = _getMockGameTypes();
      return mockGames.where((game) => game.isFeatured).toList();
    }
  }

  /// Obtiene detalle completo de un GameType específico
  static Future<GameType?> getGameType(int gameId) async {
    try {
      debugPrint('🎮 Obteniendo GameType $gameId...');

      final response = await _httpService.get(
        '${ApiConfig.baseUrl}/api/games/$gameId/',
      );

      final gameType = GameType.fromJson(response.data);
      debugPrint('✅ GameType obtenido: ${gameType.name}');
      return gameType;
    } catch (e) {
      debugPrint('🚨 Error obteniendo GameType $gameId: $e');

      // Fallback a datos mock
      final mockGames = _getMockGameTypes();
      return mockGames.firstWhere(
        (game) => game.id == gameId,
        orElse: () => mockGames.first,
      );
    }
  }

  /// Obtiene comunidades de un GameType específico
  static Future<List<Community>> getGameTypeCommunities(int gameId) async {
    try {
      debugPrint('🏘️ Obteniendo comunidades del GameType $gameId...');

      final response = await _httpService.get(
        '${ApiConfig.baseUrl}/api/games/$gameId/communities/',
      );

      final List<dynamic> results = response.data['results'] ?? response.data;
      final communities = results
          .map((json) => Community.fromJson(json))
          .toList();

      debugPrint(
        '✅ ${communities.length} comunidades obtenidas para GameType $gameId',
      );
      return communities;
    } catch (e) {
      debugPrint('🚨 Error obteniendo comunidades del GameType $gameId: $e');

      // Fallback a datos mock
      return _getMockCommunitiesForGame(gameId);
    }
  }

  /// Datos mock para desarrollo y fallback
  static List<GameType> _getMockGameTypes() {
    return [
      GameType(
        id: 1,
        name: 'Magic: The Gathering',
        slug: 'magic-the-gathering',
        description: 'El TCG original creado por Richard Garfield',
        publisher: 'Wizards of the Coast',
        releaseYear: 1993,
        minPlayers: 2,
        maxPlayers: 8,
        isFeatured: true,
        communityCount: 15,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
      ),
      GameType(
        id: 2,
        name: 'Pokemon TCG',
        slug: 'pokemon-tcg',
        description: 'Colecciona, intercambia y batalla con cartas Pokemon',
        publisher: 'The Pokemon Company',
        releaseYear: 1996,
        minPlayers: 2,
        maxPlayers: 2,
        isFeatured: true,
        communityCount: 12,
        createdAt: DateTime.now().subtract(const Duration(days: 300)),
      ),
      GameType(
        id: 3,
        name: 'Yu-Gi-Oh!',
        slug: 'yu-gi-oh',
        description: 'Juego de cartas basado en el popular anime',
        publisher: 'Konami',
        releaseYear: 1999,
        minPlayers: 2,
        maxPlayers: 2,
        isFeatured: true,
        communityCount: 8,
        createdAt: DateTime.now().subtract(const Duration(days: 250)),
      ),
      GameType(
        id: 4,
        name: 'Dragon Ball Super',
        slug: 'dragon-ball-super',
        description: 'TCG oficial de Dragon Ball Super',
        publisher: 'Bandai',
        releaseYear: 2017,
        minPlayers: 2,
        maxPlayers: 2,
        isFeatured: false,
        communityCount: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 100)),
      ),
    ];
  }

  /// Comunidades mock para un game específico
  static List<Community> _getMockCommunitiesForGame(int gameId) {
    // Aquí normalmente tendríamos datos mock más específicos
    // Por ahora devolvemos una lista vacía ya que Community se implementará después
    return [];
  }
}
