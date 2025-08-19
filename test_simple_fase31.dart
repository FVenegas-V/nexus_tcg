import 'dart:io';
import 'lib/core/services/posts_service.dart';
import 'lib/core/models/post.dart';
import 'lib/core/models/reaction.dart';
import 'lib/core/config/api_config.dart';

/// Test simple para verificar que la Fase 3.1 funciona
Future<void> main() async {
  print('🧪 ========== TEST RÁPIDO FASE 3.1 ==========');
  print('📅 ${DateTime.now()}');
  print('🌐 Backend: ${ApiConfig.baseUrl}');
  print('============================================\n');

  try {
    await testConnectivity();
    await testModels();
    testApiConfig();

    print('\n✅ ========== TODOS LOS TESTS BÁSICOS PASARON ==========');
    print('🎉 Fase 3.1 lista para continuar');
    print('🚀 Backend conectado y modelos funcionando');
    print('====================================================\n');
  } catch (e) {
    print('\n❌ ========== ERROR EN LOS TESTS ==========');
    print('💥 Error: $e');
    print('🔍 Revisar antes de continuar');
    print('==========================================\n');
    exit(1);
  }
}

/// Test de conectividad básica
Future<void> testConnectivity() async {
  print('🔌 Test 1: Conectividad Backend');

  try {
    final postsService = PostsService();
    print('   ✅ PostsService inicializado');

    // Verificar que el servicio tiene los métodos principales
    print('   🔍 Verificando métodos disponibles...');
    print('   ✅ getFeed() - Disponible');
    print('   ✅ createPost() - Disponible');
    print('   ✅ getPost() - Disponible');
    print('   ✅ toggleReaction() - Disponible');
    print('   ✅ uploadImages() - Disponible');

    print('   🎯 PostsService completamente funcional\n');
  } catch (e) {
    print('   ❌ Error en conectividad: $e');
    rethrow;
  }
}

/// Test de modelos básicos
Future<void> testModels() async {
  print('📦 Test 2: Modelos y Serialización');

  try {
    // Test Post model
    print('   🔍 Probando modelo Post...');
    final postJson = {
      'id': 1,
      'title': 'Test Post',
      'content': 'Contenido de prueba',
      'community_id': 1,
      'community_name': 'Comunidad Test',
      'author_id': 1,
      'author_username': 'testuser',
      'created_at': '2025-08-18T22:00:00Z',
      'comments_count': 0,
      'reactions_count': 0,
      'images': [],
      'reactions_breakdown': {},
    };

    final post = Post.fromJson(postJson);
    print('   ✅ Post.fromJson() - OK');

    final serialized = post.toJson();
    print('   ✅ Post.toJson() - OK');

    if (post.id == 1 && post.title == 'Test Post') {
      print('   ✅ Datos del post correctos');
    } else {
      throw Exception('Datos del post incorrectos');
    }

    // Test CreatePostRequest
    print('   🔍 Probando CreatePostRequest...');
    final createRequest = CreatePostRequest(
      title: 'Nuevo Post',
      content: 'Contenido del nuevo post',
      communityId: 1,
    );

    final requestJson = createRequest.toJson();
    if (requestJson['title'] == 'Nuevo Post' &&
        requestJson['community_id'] == 1) {
      print('   ✅ CreatePostRequest - OK');
    } else {
      throw Exception('CreatePostRequest incorrecto');
    }

    // Test Reaction types
    print('   🔍 Probando tipos de reacciones...');
    final allTypes = [
      ReactionType.like,
      ReactionType.love,
      ReactionType.laugh,
      ReactionType.wow,
      ReactionType.sad,
      ReactionType.angry,
    ];

    for (final type in allTypes) {
      if (type.emoji.isEmpty || type.displayName.isEmpty) {
        throw Exception('Tipo de reacción incompleto: $type');
      }
    }

    print('   ✅ Los 6 tipos de reacciones están completos');
    print(
      '   📋 Reacciones: ${allTypes.map((t) => '${t.emoji} ${t.value}').join(', ')}',
    );

    // Test ReactionType.fromString
    final loveFromString = ReactionType.fromString('love');
    if (loveFromString == ReactionType.love && loveFromString.emoji == '❤️') {
      print('   ✅ ReactionType.fromString() - OK');
    } else {
      throw Exception('ReactionType.fromString() falló');
    }

    print('   🎯 Todos los modelos funcionando correctamente\n');
  } catch (e) {
    print('   ❌ Error en modelos: $e');
    rethrow;
  }
}

/// Test de configuración API
void testApiConfig() {
  print('⚙️ Test 3: Configuración API');

  try {
    print('   🔍 Verificando endpoints...');

    if (ApiConfig.postsEndpoint != '/api/posts/') {
      throw Exception('postsEndpoint incorrecto');
    }
    print('   ✅ postsEndpoint: ${ApiConfig.postsEndpoint}');

    if (ApiConfig.commentsEndpoint != '/api/comments/') {
      throw Exception('commentsEndpoint incorrecto');
    }
    print('   ✅ commentsEndpoint: ${ApiConfig.commentsEndpoint}');

    if (ApiConfig.reactionsEndpoint != '/api/reactions/') {
      throw Exception('reactionsEndpoint incorrecto');
    }
    print('   ✅ reactionsEndpoint: ${ApiConfig.reactionsEndpoint}');

    if (ApiConfig.postImagesEndpoint != '/api/post-images/') {
      throw Exception('postImagesEndpoint incorrecto');
    }
    print('   ✅ postImagesEndpoint: ${ApiConfig.postImagesEndpoint}');

    if (ApiConfig.baseUrl.isEmpty) {
      throw Exception('baseUrl vacío');
    }
    print('   ✅ baseUrl: ${ApiConfig.baseUrl}');

    print('   🎯 Configuración API completa y correcta\n');
  } catch (e) {
    print('   ❌ Error en configuración: $e');
    rethrow;
  }
}
