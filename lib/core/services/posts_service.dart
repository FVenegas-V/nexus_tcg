import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/post.dart';
import '../models/post_image.dart';
import '../models/reaction.dart';
import 'http_service.dart';

/// Servicio completo para gestión de Posts con todas las funcionalidades de la Fase 3
///
/// Conecta con las 8 APIs REST del backend:
/// - CRUD completo de posts
/// - Feed personalizado por suscripciones
/// - Sistema de reacciones con 6 tipos
/// - Upload múltiple de imágenes
/// - Breakdown estadístico detallado
class PostsService {
  static final PostsService _instance = PostsService._internal();
  factory PostsService() => _instance;
  PostsService._internal();

  final HttpService _httpService = HttpService();

  // ==================== POSTS CRUD ====================

  /// Crear un nuevo post en una comunidad
  ///
  /// Endpoint: POST /api/posts/
  /// Requiere: título, contenido, ID de comunidad
  /// Opcionalmente: imágenes para upload
  Future<Post> createPost(CreatePostRequest request) async {
    try {
      debugPrint('🚀 Creando post en comunidad ${request.communityId}...');

      final endpoint = '${ApiConfig.postsEndpoint}/';

      // Preparar data para envío - crear FormData manualmente
      final formData = FormData();
      formData.fields.add(MapEntry('title', request.title));
      formData.fields.add(MapEntry('content', request.content));
      formData.fields.add(
        MapEntry('community', request.communityId.toString()),
      );

      // Agregar imágenes si existen
      if (request.imagePaths != null && request.imagePaths!.isNotEmpty) {
        debugPrint('📸 Agregando ${request.imagePaths!.length} imágenes...');

        for (int i = 0; i < request.imagePaths!.length; i++) {
          final imagePath = request.imagePaths![i];
          final file = File(imagePath);

          if (await file.exists()) {
            formData.files.add(
              MapEntry(
                'images', // El backend espera este nombre
                await MultipartFile.fromFile(
                  imagePath,
                  filename: file.uri.pathSegments.last,
                ),
              ),
            );
          }
        }
      }

      final response = await _httpService.post(endpoint, data: formData);

      if (response.statusCode == 201) {
        debugPrint('✅ Post creado exitosamente');
        return Post.fromJson(response.data);
      } else {
        throw Exception('Error al crear post: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en createPost: $e');
      rethrow;
    }
  }

  /// Obtener lista de posts con filtros y paginación
  ///
  /// Endpoint: GET /api/posts/
  /// Soporta: filtros, búsqueda, paginación, ordenamiento
  Future<List<Post>> getPosts({
    int? communityId,
    int? authorId,
    String? search,
    String? ordering, // 'created_at', '-created_at', 'title', etc.
    int? page,
    int? pageSize,
  }) async {
    try {
      debugPrint('🔍 Obteniendo posts con filtros...');

      final Map<String, dynamic> queryParams = {};

      if (communityId != null) queryParams['community_id'] = communityId;
      if (authorId != null) queryParams['author_id'] = authorId;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (ordering != null) queryParams['ordering'] = ordering;
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await _httpService.get(
        ApiConfig.postsEndpoint,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Posts obtenidos exitosamente');

        // El backend puede devolver lista directa o paginada
        if (response.data is List) {
          return (response.data as List)
              .map((json) => Post.fromJson(json))
              .toList();
        } else if (response.data is Map && response.data['results'] != null) {
          return (response.data['results'] as List)
              .map((json) => Post.fromJson(json))
              .toList();
        } else {
          throw Exception('Formato de respuesta inesperado');
        }
      } else {
        throw Exception('Error al obtener posts: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en getPosts: $e');
      rethrow;
    }
  }

  /// Obtener feed personalizado basado en suscripciones del usuario
  ///
  /// Endpoint: GET /api/posts/feed/
  /// Devuelve posts de comunidades a las que el usuario está suscrito
  Future<List<Post>> getFeed({int? page, int? pageSize}) async {
    try {
      debugPrint('📰 Obteniendo feed personalizado...');

      final Map<String, dynamic> queryParams = {};
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['page_size'] = pageSize;

      final response = await _httpService.get(
        '${ApiConfig.postsEndpoint}/feed/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Feed obtenido exitosamente');

        if (response.data is List) {
          return (response.data as List)
              .map((json) => Post.fromJson(json))
              .toList();
        } else if (response.data is Map && response.data['results'] != null) {
          return (response.data['results'] as List)
              .map((json) => Post.fromJson(json))
              .toList();
        } else {
          throw Exception('Formato de respuesta inesperado');
        }
      } else {
        throw Exception('Error al obtener feed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en getFeed: $e');
      rethrow;
    }
  }

  /// Obtener detalle de un post específico
  ///
  /// Endpoint: GET /api/posts/{id}/
  /// Incluye: imágenes, contadores, reacción del usuario
  Future<Post> getPost(int postId) async {
    try {
      debugPrint('🔍 Obteniendo post $postId...');

      final response = await _httpService.get(
        '${ApiConfig.postsEndpoint}/$postId/',
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Post obtenido exitosamente');
        return Post.fromJson(response.data);
      } else {
        throw Exception('Error al obtener post: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en getPost: $e');
      rethrow;
    }
  }

  /// Actualizar un post existente
  ///
  /// Endpoint: PUT /api/posts/{id}/
  /// Permite: modificar título y contenido
  Future<Post> updatePost(int postId, UpdatePostRequest request) async {
    try {
      debugPrint('✏️ Actualizando post $postId...');

      final response = await _httpService.put(
        '${ApiConfig.postsEndpoint}/$postId/',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Post actualizado exitosamente');
        return Post.fromJson(response.data);
      } else {
        throw Exception('Error al actualizar post: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en updatePost: $e');
      rethrow;
    }
  }

  /// Eliminar un post (soft delete)
  ///
  /// Endpoint: DELETE /api/posts/{id}/
  /// Nota: Es soft delete, mantiene el post marcado como eliminado
  Future<void> deletePost(int postId) async {
    try {
      debugPrint('🗑️ Eliminando post $postId...');

      final response = await _httpService.delete(
        '${ApiConfig.postsEndpoint}/$postId/',
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('✅ Post eliminado exitosamente');
      } else {
        throw Exception('Error al eliminar post: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en deletePost: $e');
      rethrow;
    }
  }

  // ==================== REACCIONES ====================

  /// Toggle de reacción en un post
  ///
  /// Endpoint: POST /api/posts/{id}/toggle_reaction/
  /// Comportamiento inteligente: si ya tiene la misma reacción la quita,
  /// si tiene otra reacción la cambia, si no tiene ninguna la agrega
  Future<ReactionsBreakdown> toggleReaction(
    int postId,
    ReactionType reactionType,
  ) async {
    try {
      debugPrint('😊 Toggle reacción $reactionType en post $postId...');

      final response = await _httpService.post(
        '${ApiConfig.postsEndpoint}/$postId/toggle_reaction/',
        data: ReactionRequest(reactionType: reactionType).toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Reacción actualizada exitosamente');
        return ReactionsBreakdown.fromJson(response.data);
      } else {
        throw Exception('Error al actualizar reacción: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en toggleReaction: $e');
      rethrow;
    }
  }

  /// Obtener breakdown completo de reacciones de un post
  ///
  /// Endpoint: GET /api/posts/{id}/reactions/
  /// Devuelve: conteos por tipo, usernames, reacción del usuario actual
  Future<ReactionsBreakdown> getPostReactions(int postId) async {
    try {
      debugPrint('📊 Obteniendo reacciones del post $postId...');

      final response = await _httpService.get(
        '${ApiConfig.postsEndpoint}/$postId/reactions/',
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Reacciones obtenidas exitosamente');
        return ReactionsBreakdown.fromJson(response.data);
      } else {
        throw Exception('Error al obtener reacciones: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en getPostReactions: $e');
      rethrow;
    }
  }

  // ==================== IMÁGENES ====================

  /// Upload múltiple de imágenes para un post
  ///
  /// Endpoint: POST /api/post-images/upload/
  /// Soporta: hasta 10MB por imagen, múltiples formatos, orden específico
  Future<List<PostImage>> uploadImages(ImageUploadRequest request) async {
    try {
      debugPrint(
        '📸 Subiendo ${request.imagePaths.length} imágenes para post ${request.postId}...',
      );

      final formData = FormData();
      formData.fields.add(MapEntry('post_id', request.postId.toString()));

      // Agregar archivos de imagen
      for (int i = 0; i < request.imagePaths.length; i++) {
        final imagePath = request.imagePaths[i];
        final file = File(imagePath);

        if (await file.exists()) {
          formData.files.add(
            MapEntry(
              'images',
              await MultipartFile.fromFile(
                imagePath,
                filename: file.uri.pathSegments.last,
              ),
            ),
          );

          // Agregar orden si está especificado
          if (request.orders != null && i < request.orders!.length) {
            formData.fields.add(
              MapEntry('orders', request.orders![i].toString()),
            );
          }
        }
      }

      final response = await _httpService.post(
        '${ApiConfig.baseUrl}/api/post-images/upload/',
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('✅ Imágenes subidas exitosamente');

        if (response.data is List) {
          return (response.data as List)
              .map((json) => PostImage.fromUploadJson(json))
              .toList();
        } else if (response.data is Map && response.data['images'] != null) {
          return (response.data['images'] as List)
              .map((json) => PostImage.fromUploadJson(json))
              .toList();
        } else {
          throw Exception('Formato de respuesta inesperado');
        }
      } else {
        throw Exception('Error al subir imágenes: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en uploadImages: $e');
      rethrow;
    }
  }

  /// Obtener imágenes de un post específico
  ///
  /// Endpoint: GET /api/post-images/by-post/{post_id}/
  /// Devuelve: todas las imágenes ordenadas por el campo 'order'
  Future<List<PostImage>> getPostImages(int postId) async {
    try {
      debugPrint('🖼️ Obteniendo imágenes del post $postId...');

      final response = await _httpService.get(
        '${ApiConfig.baseUrl}/api/post-images/by-post/$postId/',
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Imágenes obtenidas exitosamente');

        if (response.data is List) {
          return (response.data as List)
              .map((json) => PostImage.fromJson(json))
              .toList();
        } else {
          throw Exception('Formato de respuesta inesperado');
        }
      } else {
        throw Exception('Error al obtener imágenes: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en getPostImages: $e');
      rethrow;
    }
  }

  /// Reordenar imágenes existentes de un post
  ///
  /// Endpoint: POST /api/post-images/{id}/reorder/
  /// Permite: cambiar el orden de visualización de las imágenes
  Future<List<PostImage>> reorderImages(
    int imageId,
    ImageReorderRequest request,
  ) async {
    try {
      debugPrint('🔄 Reordenando imágenes...');

      final response = await _httpService.post(
        '${ApiConfig.baseUrl}/api/post-images/$imageId/reorder/',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        debugPrint('✅ Imágenes reordenadas exitosamente');

        if (response.data is List) {
          return (response.data as List)
              .map((json) => PostImage.fromJson(json))
              .toList();
        } else {
          throw Exception('Formato de respuesta inesperado');
        }
      } else {
        throw Exception('Error al reordenar imágenes: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error en reorderImages: $e');
      rethrow;
    }
  }

  // ==================== UTILIDADES ====================

  /// Obtener posts por comunidad (wrapper de conveniencia)
  Future<List<Post>> getPostsByCommunity(
    int communityId, {
    int? page,
    int? pageSize,
    String? ordering,
  }) async {
    return getPosts(
      communityId: communityId,
      page: page,
      pageSize: pageSize,
      ordering: ordering,
    );
  }

  /// Buscar posts por término
  Future<List<Post>> searchPosts(
    String query, {
    int? communityId,
    int? page,
    int? pageSize,
  }) async {
    return getPosts(
      search: query,
      communityId: communityId,
      page: page,
      pageSize: pageSize,
    );
  }

  /// Verificar si el servicio está disponible
  Future<bool> isServiceAvailable() async {
    try {
      final response = await _httpService.get(ApiConfig.postsEndpoint);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ Servicio de posts no disponible: $e');
      return false;
    }
  }
}
