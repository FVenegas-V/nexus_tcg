import 'package:flutter/foundation.dart';
import '../../../core/services/http_service.dart';

/// Clase para manejar respuestas de la API
class ApiResponse {
  final bool isSuccess;
  final Map<String, dynamic>? data;
  final String? error;

  ApiResponse({required this.isSuccess, this.data, this.error});
}

class ReputationService {
  static final ReputationService _instance = ReputationService._internal();
  static ReputationService get instance => _instance;

  ReputationService._internal();

  final HttpService _httpService = HttpService();

  /// Obtener estadísticas de reputación de un usuario (usando endpoint de ratings temporalmente)
  Future<ApiResponse> getUserReputationStats(int userId) async {
    try {
      debugPrint(
        '🔍 ReputationService: Obteniendo estadísticas de reputación para usuario $userId',
      );

      // TEMPORAL: Usar endpoint de ratings stats hasta que se resuelva el endpoint de reputation
      final response = await _httpService.get(
        '/api/users/ratings/$userId/stats/',
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('✅ ReputationService: Estadísticas obtenidas exitosamente');
        return ApiResponse(
          isSuccess: true,
          data: response.data is Map<String, dynamic>
              ? response.data
              : {'data': response.data},
        );
      } else if (response.statusCode == 404) {
        debugPrint(
          'ℹ️ ReputationService: Usuario sin datos de ratings, retornando datos por defecto',
        );
        return ApiResponse(
          isSuccess: true,
          data: {
            'user': {'id': userId, 'username': 'Usuario'},
            'reputation': {
              'score': 0,
              'rating_count': 0,
              'percentile': 0,
              'last_updated': null,
            },
            'breakdown': {},
          },
        );
      } else {
        debugPrint(
          '❌ ReputationService: Error en respuesta: ${response.statusCode}',
        );
        return ApiResponse(
          isSuccess: false,
          error:
              'Error HTTP ${response.statusCode} al obtener estadísticas de reputación',
        );
      }
    } catch (e) {
      debugPrint('❌ ReputationService: Excepción al obtener estadísticas: $e');
      return ApiResponse(isSuccess: false, error: 'Error de conexión: $e');
    }
  }

  /// Obtener estadísticas de calificaciones de un usuario
  Future<ApiResponse> getUserRatingStats(int userId) async {
    try {
      debugPrint(
        '🔍 ReputationService: Obteniendo estadísticas de calificaciones para usuario $userId',
      );

      final response = await _httpService.get(
        '/api/users/ratings/$userId/stats/',
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint(
          '✅ ReputationService: Estadísticas de calificaciones obtenidas exitosamente',
        );
        return ApiResponse(
          isSuccess: true,
          data: response.data is Map<String, dynamic>
              ? response.data
              : {'data': response.data},
        );
      } else if (response.statusCode == 404) {
        debugPrint(
          'ℹ️ ReputationService: Usuario sin datos de ratings, retornando datos por defecto',
        );
        return ApiResponse(
          isSuccess: true,
          data: {
            'total_ratings': 0,
            'average_rating': 0.0,
            'rating_distribution': {'1': 0, '2': 0, '3': 0, '4': 0, '5': 0},
            'recent_ratings': [],
          },
        );
      } else {
        debugPrint(
          '❌ ReputationService: Error en respuesta: ${response.statusCode}',
        );
        return ApiResponse(
          isSuccess: false,
          error:
              'Error HTTP ${response.statusCode} al obtener estadísticas de calificaciones',
        );
      }
    } catch (e) {
      debugPrint(
        '❌ ReputationService: Excepción al obtener estadísticas de calificaciones: $e',
      );
      return ApiResponse(isSuccess: false, error: 'Error de conexión: $e');
    }
  }

  /// Obtener leaderboard de reputación
  Future<ApiResponse> getReputationLeaderboard({int limit = 10}) async {
    try {
      debugPrint(
        '🔍 ReputationService: Obteniendo leaderboard de reputación (límite: $limit)',
      );

      final response = await _httpService.get(
        '/api/users/reputation/system-stats/',
      );

      if (response.statusCode == 200 && response.data != null) {
        debugPrint('✅ ReputationService: Leaderboard obtenido exitosamente');
        return ApiResponse(
          isSuccess: true,
          data: response.data is Map<String, dynamic>
              ? response.data
              : {'data': response.data},
        );
      } else {
        debugPrint(
          '❌ ReputationService: Error en respuesta: ${response.statusCode}',
        );
        return ApiResponse(
          isSuccess: false,
          error: 'Error HTTP ${response.statusCode} al obtener leaderboard',
        );
      }
    } catch (e) {
      debugPrint('❌ ReputationService: Excepción al obtener leaderboard: $e');
      return ApiResponse(isSuccess: false, error: 'Error de conexión: $e');
    }
  }

  /// Obtener datos completos del perfil de reputación (combinando estadísticas y calificaciones)
  Future<ApiResponse> getFullReputationProfile(int userId) async {
    try {
      debugPrint(
        '🔍 ReputationService: Obteniendo perfil completo de reputación para usuario $userId',
      );

      // Obtener estadísticas de reputación
      final reputationStats = await getUserReputationStats(userId);
      if (!reputationStats.isSuccess) {
        return reputationStats;
      }

      // Obtener estadísticas de calificaciones
      final ratingStats = await getUserRatingStats(userId);
      if (!ratingStats.isSuccess) {
        return ratingStats;
      }

      // Combinar los datos
      final combinedData = {
        'reputation_stats': reputationStats.data,
        'rating_stats': ratingStats.data,
      };

      debugPrint('✅ ReputationService: Perfil completo obtenido exitosamente');
      return ApiResponse(isSuccess: true, data: combinedData);
    } catch (e) {
      debugPrint(
        '❌ ReputationService: Excepción al obtener perfil completo: $e',
      );
      return ApiResponse(isSuccess: false, error: 'Error de conexión: $e');
    }
  }
}
