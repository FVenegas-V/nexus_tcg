import '../config/api_config.dart';
import '../models/game_type.dart';
import '../models/tag.dart';
import '../models/community.dart';
import '../models/membership.dart';
import 'http_service.dart';

/// Servicio completo para gestión de Communities, GameTypes, Tags y Memberships
class CommunitiesService {
  static final CommunitiesService _instance = CommunitiesService._internal();
  factory CommunitiesService() => _instance;
  CommunitiesService._internal();

  final HttpService _httpService = HttpService();

  // ==================== GAMETYPES ====================

  /// Obtener todos los GameTypes
  Future<List<GameType>> getGameTypes() async {
    try {
      print('🚀 Iniciando getGameTypes...');
      final response = await _httpService.get(ApiConfig.gamesEndpoint);
      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print(
          '🔍 DEBUG GameTypes response.data type: ${response.data.runtimeType}',
        );
        print('🔍 DEBUG GameTypes response.data: ${response.data}');

        // Intentar diferentes estructuras
        if (response.data is List) {
          print(
            '📝 Response is a List, length: ${(response.data as List).length}',
          );
          return (response.data as List)
              .map((json) => GameType.fromJson(json))
              .toList();
        } else if (response.data is Map<String, dynamic>) {
          print('📝 Response is a Map');
          final Map<String, dynamic> data = response.data;
          print('📝 Map keys: ${data.keys.toList()}');

          final List<dynamic> allGames =
              data['all'] ?? data['results'] ?? data['data'] ?? [];
          print('🔍 DEBUG GameTypes allGames length: ${allGames.length}');
          return allGames.map((json) => GameType.fromJson(json)).toList();
        } else {
          throw Exception(
            'Estructura de respuesta no reconocida: ${response.data.runtimeType}',
          );
        }
      } else {
        throw Exception('Error al obtener GameTypes: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error en getGameTypes: $e');
      throw Exception('Error al obtener GameTypes: $e');
    }
  }

  /// Obtener GameType por ID
  Future<GameType> getGameType(int id) async {
    try {
      final response = await _httpService.get('${ApiConfig.gamesEndpoint}$id/');

      if (response.statusCode == 200) {
        return GameType.fromJson(response.data);
      } else {
        throw Exception('GameType no encontrado');
      }
    } catch (e) {
      throw Exception('Error al obtener GameType: $e');
    }
  }

  /// Obtener GameTypes destacados
  Future<List<GameType>> getFeaturedGameTypes() async {
    try {
      final response = await _httpService.get(
        '${ApiConfig.gamesEndpoint}featured/',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => GameType.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener GameTypes destacados');
      }
    } catch (e) {
      throw Exception('Error al obtener GameTypes destacados: $e');
    }
  }

  // ==================== TAGS ====================

  /// Obtener lista de todos los Tags
  Future<List<CommunityTag>> getTags() async {
    try {
      print('🚀 Iniciando getTags...');
      final response = await _httpService.get(ApiConfig.tagsEndpoint);
      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('🔍 DEBUG Tags response.data type: ${response.data.runtimeType}');
        print('🔍 DEBUG Tags response.data: ${response.data}');

        // Intentar diferentes estructuras
        if (response.data is List) {
          print(
            '📝 Response is a List, length: ${(response.data as List).length}',
          );
          return (response.data as List)
              .map((json) => CommunityTag.fromJson(json))
              .toList();
        } else if (response.data is Map<String, dynamic>) {
          print('📝 Response is a Map');
          final Map<String, dynamic> data = response.data;
          print('📝 Map keys: ${data.keys.toList()}');

          final List<dynamic> allTags =
              data['tags'] ??
              data['all'] ??
              data['results'] ??
              data['data'] ??
              [];
          print('🔍 DEBUG Tags allTags length: ${allTags.length}');
          return allTags.map((json) => CommunityTag.fromJson(json)).toList();
        } else {
          throw Exception(
            'Estructura de respuesta no reconocida: ${response.data.runtimeType}',
          );
        }
      } else {
        throw Exception('Error al obtener Tags: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error en getTags: $e');
      throw Exception('Error al obtener Tags: $e');
    }
  }

  /// Obtener Tag por ID
  Future<CommunityTag> getTag(int id) async {
    try {
      final response = await _httpService.get('${ApiConfig.tagsEndpoint}$id/');

      if (response.statusCode == 200) {
        return CommunityTag.fromJson(response.data);
      } else {
        throw Exception('Tag no encontrado');
      }
    } catch (e) {
      throw Exception('Error al obtener Tag: $e');
    }
  }

  /// Obtener tags populares
  Future<List<CommunityTag>> getPopularTags() async {
    try {
      final response = await _httpService.get(
        '${ApiConfig.tagsEndpoint}popular/',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> popularTags = data['popular_tags'] ?? [];
        return popularTags.map((json) => CommunityTag.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener tags populares');
      }
    } catch (e) {
      throw Exception('Error al obtener tags populares: $e');
    }
  }

  // ==================== CATEGORIES ====================

  /// Obtener lista de todas las Categorías
  Future<List<CommunityCategory>> getCategories() async {
    try {
      final response = await _httpService.get(ApiConfig.categoriesEndpoint);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> results = data['results'] ?? [];
        return results.map((json) => CommunityCategory.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener Categorías: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener Categorías: $e');
    }
  }

  /// Obtener Categoría por ID
  Future<CommunityCategory> getCategory(int id) async {
    try {
      final response = await _httpService.get(
        '${ApiConfig.categoriesEndpoint}$id/',
      );

      if (response.statusCode == 200) {
        return CommunityCategory.fromJson(response.data);
      } else {
        throw Exception('Categoría no encontrada');
      }
    } catch (e) {
      throw Exception('Error al obtener Categoría: $e');
    }
  }

  /// Obtener comunidades de una categoría específica
  Future<List<Community>> getCommunitiesByCategory(int categoryId) async {
    try {
      final response = await _httpService.get(
        '${ApiConfig.categoriesEndpoint}$categoryId/communities/',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Community.fromListJson(json)).toList();
      } else {
        throw Exception('Error al obtener comunidades de categoría');
      }
    } catch (e) {
      throw Exception('Error al obtener comunidades de categoría: $e');
    }
  }

  // ==================== COMMUNITIES ====================

  /// Obtener lista de todas las Comunidades
  Future<List<Community>> getCommunities({
    String? search,
    String? gameType,
    String? difficulty,
    String? ordering,
    int? limit,
    int? offset,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};

      if (search != null) queryParams['search'] = search;
      if (gameType != null) queryParams['game_type'] = gameType;
      if (difficulty != null) queryParams['difficulty_level'] = difficulty;
      if (ordering != null) queryParams['ordering'] = ordering;
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _httpService.get(
        ApiConfig.communitiesEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        // La respuesta viene con estructura paginada
        if (response.data is Map<String, dynamic>) {
          final Map<String, dynamic> data = response.data;
          final List<dynamic> results = data['results'] ?? [];
          return results.map((json) => Community.fromListJson(json)).toList();
        } else if (response.data is List) {
          // Respuesta directa como lista
          final List<dynamic> data = response.data;
          return data.map((json) => Community.fromListJson(json)).toList();
        } else {
          throw Exception('Estructura de respuesta no reconocida');
        }
      } else {
        throw Exception('Error al obtener Comunidades: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener Comunidades: $e');
    }
  }

  /// Obtener Community por ID (detalle completo)
  Future<Community> getCommunity(int id) async {
    try {
      final response = await _httpService.get(
        '${ApiConfig.communitiesEndpoint}$id/',
      );

      if (response.statusCode == 200) {
        return Community.fromDetailJson(response.data);
      } else {
        throw Exception('Comunidad no encontrada');
      }
    } catch (e) {
      throw Exception('Error al obtener Comunidad: $e');
    }
  }

  /// Obtener comunidades populares (más de 100 miembros)
  Future<List<Community>> getPopularCommunities() async {
    try {
      final response = await _httpService.get(
        '${ApiConfig.communitiesEndpoint}popular/',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Community.fromListJson(json)).toList();
      } else {
        throw Exception('Error al obtener comunidades populares');
      }
    } catch (e) {
      throw Exception('Error al obtener comunidades populares: $e');
    }
  }

  /// Obtener estadísticas generales de comunidades
  Future<Map<String, dynamic>> getCommunitiesStats() async {
    try {
      final response = await _httpService.get(
        '${ApiConfig.communitiesEndpoint}stats/',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Error al obtener estadísticas');
      }
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  /// Obtener miembros de una comunidad
  Future<List<CommunityMembership>> getCommunityMembers(int communityId) async {
    try {
      final response = await _httpService.get(
        '${ApiConfig.communitiesEndpoint}$communityId/members/',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => CommunityMembership.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener miembros');
      }
    } catch (e) {
      throw Exception('Error al obtener miembros: $e');
    }
  }

  // ==================== MEMBERSHIPS ====================

  /// Obtener lista de membresías (requiere autenticación)
  Future<List<CommunityMembership>> getMemberships({
    String? role,
    String? status,
    String? gameType,
  }) async {
    try {
      Map<String, dynamic> queryParams = {};

      if (role != null) queryParams['role'] = role;
      if (status != null) queryParams['status'] = status;
      if (gameType != null) queryParams['community__game_type'] = gameType;

      final response = await _httpService.get(
        ApiConfig.membershipsEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => CommunityMembership.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener Membresías: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener Membresías: $e');
    }
  }

  /// Obtener membresías de un usuario específico
  Future<List<CommunityMembership>> getUserMemberships(int userId) async {
    try {
      final response = await _httpService.get(
        '${ApiConfig.membershipsEndpoint}by_user/',
        queryParameters: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => CommunityMembership.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener membresías del usuario');
      }
    } catch (e) {
      throw Exception('Error al obtener membresías del usuario: $e');
    }
  }

  /// Obtener moderadores y administradores
  Future<List<CommunityMembership>> getModerators() async {
    try {
      final response = await _httpService.get(
        '${ApiConfig.membershipsEndpoint}moderators/',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => CommunityMembership.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener moderadores');
      }
    } catch (e) {
      throw Exception('Error al obtener moderadores: $e');
    }
  }

  /// Unirse a una comunidad (requiere autenticación)
  Future<CommunityMembership> joinCommunity(
    int communityId, {
    String? message,
  }) async {
    try {
      Map<String, dynamic> data = {};
      if (message != null) data['message'] = message;

      final response = await _httpService.post(
        '${ApiConfig.communitiesEndpoint}$communityId/join/',
        data: data,
      );

      if (response.statusCode == 201) {
        return CommunityMembership.fromJson(response.data['membership']);
      } else {
        throw Exception('Error al unirse a la comunidad');
      }
    } catch (e) {
      throw Exception('Error al unirse a la comunidad: $e');
    }
  }

  /// Salir de una comunidad (requiere autenticación)
  Future<void> leaveCommunity(int communityId) async {
    try {
      final response = await _httpService.delete(
        '${ApiConfig.communitiesEndpoint}$communityId/leave/',
      );

      if (response.statusCode != 200) {
        throw Exception('Error al salir de la comunidad');
      }
    } catch (e) {
      throw Exception('Error al salir de la comunidad: $e');
    }
  }
}
