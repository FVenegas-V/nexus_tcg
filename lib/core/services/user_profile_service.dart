import '../config/api_config.dart';
import 'http_service.dart';

/// Servicio para gestión de perfiles de usuario extendidos
class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final HttpService _httpService = HttpService();

  /// Obtener perfil completo del usuario actual
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      print('🚀 UserProfileService: Obteniendo perfil del usuario...');

      final response = await _httpService.get(
        '${ApiConfig.usersEndpoint}me/profile/',
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        // Extraer solo la parte del perfil de la respuesta
        return responseData['profile'] as Map<String, dynamic>?;
      } else {
        throw Exception('Error al obtener perfil: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error en getUserProfile: $e');
      print('🔄 Retornando datos mock para desarrollo...');

      // Retornar datos mock para desarrollo
      return {
        'bio': '',
        'location': '',
        'birth_date': null,
        'favorite_games': <String>[],
        'play_style': '',
        'experience_level': '',
        'avatar_url': null,
        'banner_url': null,
        'theme_preference': 'system',
        'show_email': false,
        'show_location': true,
        'show_birth_date': false,
        'show_communities': true,
        'show_activity_stats': true,
        'communities_count': 0,
        'posts_count': 0,
        'likes_received': 0,
        'reputation_score': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Actualizar perfil del usuario actual
  Future<Map<String, dynamic>> updateUserProfile({
    String? bio,
    String? location,
    List<String>? favoriteGames,
    String? playStyle,
    String? experienceLevel,
    bool? showEmail,
    bool? showLocation,
    bool? showBirthDate,
    bool? showCommunities,
    bool? showActivityStats,
  }) async {
    try {
      print('🚀 UserProfileService: Actualizando perfil del usuario...');

      Map<String, dynamic> data = {};

      if (bio != null) data['bio'] = bio;
      if (location != null) data['location'] = location;
      if (favoriteGames != null) data['favorite_games'] = favoriteGames;
      if (playStyle != null) data['play_style'] = playStyle;
      if (experienceLevel != null) data['experience_level'] = experienceLevel;
      if (showEmail != null) data['show_email'] = showEmail;
      if (showLocation != null) data['show_location'] = showLocation;
      if (showBirthDate != null) data['show_birth_date'] = showBirthDate;
      if (showCommunities != null) data['show_communities'] = showCommunities;
      if (showActivityStats != null)
        data['show_activity_stats'] = showActivityStats;

      print('📦 Datos a enviar: $data');

      final response = await _httpService.put(
        '${ApiConfig.usersEndpoint}me/profile/',
        data: data,
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response data: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Perfil actualizado exitosamente',
          'profile': response.data,
        };
      } else {
        throw Exception(response.data['error'] ?? 'Error al actualizar perfil');
      }
    } catch (e) {
      print('💥 Error en updateUserProfile: $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  /// Obtener perfil público de otro usuario
  Future<Map<String, dynamic>?> getPublicUserProfile(int userId) async {
    try {
      print(
        '🚀 UserProfileService: Obteniendo perfil público del usuario $userId...',
      );

      final response = await _httpService.get(
        '${ApiConfig.usersEndpoint}$userId/profile/',
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response data: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Error al obtener perfil público: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Error en getPublicUserProfile: $e');
      return null;
    }
  }

  /// Buscar usuarios
  Future<List<Map<String, dynamic>>> searchUsers({
    String? query,
    String? game,
    String? location,
    int page = 1,
  }) async {
    try {
      print('🚀 UserProfileService: Buscando usuarios...');

      Map<String, dynamic> queryParams = {'page': page};
      if (query != null) queryParams['q'] = query;
      if (game != null) queryParams['game'] = game;
      if (location != null) queryParams['location'] = location;

      final response = await _httpService.get(
        '${ApiConfig.usersEndpoint}search/',
        queryParameters: queryParams,
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response data: ${response.data}');

      if (response.statusCode == 200) {
        final results = response.data['results'] as List;
        return results.cast<Map<String, dynamic>>();
      } else {
        throw Exception(
          'Error en búsqueda de usuarios: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('💥 Error en searchUsers: $e');
      return [];
    }
  }
}
