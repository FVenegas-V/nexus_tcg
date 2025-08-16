import '../config/api_config.dart';
import '../models/membership.dart';
import 'http_service.dart';

/// Servicio para gestión de membresías de comunidades
class MembershipService {
  static final MembershipService _instance = MembershipService._internal();
  factory MembershipService() => _instance;
  MembershipService._internal();

  final HttpService _httpService = HttpService();

  /// Unirse a una comunidad
  Future<Map<String, dynamic>> joinCommunity(
    int communityId, {
    String? message,
  }) async {
    try {
      print('🚀 Uniéndose a comunidad ID: $communityId');

      Map<String, dynamic> data = {};
      if (message != null) data['message'] = message;

      final response = await _httpService.post(
        '${ApiConfig.communitiesEndpoint}$communityId/join/',
        data: data,
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response data: ${response.data}');

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Te has unido exitosamente',
          'membership': response.data['membership'],
        };
      } else {
        throw Exception(
          response.data['error'] ?? 'Error al unirse a la comunidad',
        );
      }
    } catch (e) {
      print('💥 Error en joinCommunity: $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  /// Salir de una comunidad
  Future<Map<String, dynamic>> leaveCommunity(int communityId) async {
    try {
      print('🚀 Saliendo de comunidad ID: $communityId');

      final response = await _httpService.delete(
        '${ApiConfig.communitiesEndpoint}$communityId/leave/',
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response data: ${response.data}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': response.data['message'] ?? 'Has salido exitosamente',
          'former_role': response.data['former_role'],
        };
      } else {
        throw Exception(
          response.data['error'] ?? 'Error al salir de la comunidad',
        );
      }
    } catch (e) {
      print('💥 Error en leaveCommunity: $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  /// Verificar si el usuario es miembro de una comunidad
  Future<bool> isMemberOfCommunity(int communityId) async {
    try {
      final response = await _httpService.get(
        '${ApiConfig.communitiesEndpoint}$communityId/members/',
      );

      if (response.statusCode == 200) {
        // El endpoint devuelve los miembros, si no hay error significa que el usuario es miembro
        return true;
      } else if (response.statusCode == 403) {
        // No es miembro
        return false;
      } else {
        return false;
      }
    } catch (e) {
      print('💥 Error verificando membresía: $e');
      return false;
    }
  }

  /// Obtener las membresías del usuario actual
  Future<List<CommunityMembership>> getUserMemberships() async {
    try {
      final response = await _httpService.get(
        '${ApiConfig.membershipsEndpoint}my/',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => CommunityMembership.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener membresías');
      }
    } catch (e) {
      print('💥 Error en getUserMemberships: $e');
      return [];
    }
  }

  /// Obtener estadísticas de membresía de una comunidad
  Future<Map<String, dynamic>> getCommunityMembershipStats(
    int communityId,
  ) async {
    try {
      final response = await _httpService.get(
        '${ApiConfig.communitiesEndpoint}$communityId/members/stats/',
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Error al obtener estadísticas de membresía');
      }
    } catch (e) {
      print('💥 Error en getCommunityMembershipStats: $e');
      return {};
    }
  }
}
