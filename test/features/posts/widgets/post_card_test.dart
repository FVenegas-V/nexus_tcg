import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_tcg/features/posts/widgets/post_card.dart';
import 'package:nexus_tcg/core/models/post.dart';
import 'package:nexus_tcg/core/models/post_image.dart';

void main() {
  group('PostCard New Model Tests', () {
    late Post testPost;

    setUp(() {
      testPost = Post(
        id: 1,
        title: 'Post de Prueba',
        content: 'Este es un contenido de prueba para el nuevo PostCard',
        communityId: 1,
        communityName: 'Comunidad Test',
        authorId: 123,
        authorUsername: 'usuario_test',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        commentsCount: 5,
        reactionsCount: 12,
        images: [],
        userReaction: null,
        reactionsBreakdown: {'like': 8, 'love': 3, 'laugh': 1},
      );
    });

    testWidgetWithMaterialApp('should render basic post card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PostCard(post: testPost)),
        ),
      );

      // Verificar que el contenido se muestra correctamente
      expect(find.text('Post de Prueba'), findsOneWidget);
      expect(
        find.text('Este es un contenido de prueba para el nuevo PostCard'),
        findsOneWidget,
      );
      expect(find.text('usuario_test'), findsOneWidget);
      expect(find.text('en Comunidad Test'), findsOneWidget);

      // Verificar contadores
      expect(find.text('12'), findsOneWidget); // reactions count
      expect(find.text('5'), findsOneWidget); // comments count
    });

    testWidgetWithMaterialApp('should render post with images', (tester) async {
      final postWithImages = testPost.copyWith(
        images: [
          PostImage(
            id: 1,
            postId: 1,
            originalFilename: 'test1.jpg',
            filename: 'test1.webp',
            fileSize: 1024,
            contentType: 'image/webp',
            width: 800,
            height: 600,
            order: 0,
            uploadedAt: DateTime.now(),
            isProcessed: true,
            originalUrl: 'https://example.com/test1.jpg',
            thumbnailUrl: 'https://example.com/test1_thumb.webp',
            mediumUrl: 'https://example.com/test1_medium.webp',
            largeUrl: 'https://example.com/test1_large.webp',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PostCard(post: postWithImages)),
        ),
      );

      // Verificar que se muestra el indicador de imágenes
      expect(find.text('1 imagen'), findsOneWidget);
    });

    testWidgetWithMaterialApp('should handle user interactions', (
      tester,
    ) async {
      bool likeTapped = false;
      bool commentTapped = false;
      bool authorTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PostCard(
              post: testPost,
              onLike: () => likeTapped = true,
              onComment: () => commentTapped = true,
              onAuthorTap: () => authorTapped = true,
            ),
          ),
        ),
      );

      // Probar tap en botón de like
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      expect(likeTapped, isTrue);

      // Probar tap en botón de comentarios
      await tester.tap(find.byIcon(Icons.chat_bubble_outline));
      await tester.pump();
      expect(commentTapped, isTrue);

      // Probar tap en nombre de usuario
      await tester.tap(find.text('usuario_test'));
      await tester.pump();
      expect(authorTapped, isTrue);
    });

    testWidgetWithMaterialApp('should show reaction state correctly', (
      tester,
    ) async {
      final postWithReaction = testPost.copyWith(userReaction: 'like');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PostCard(post: postWithReaction)),
        ),
      );

      // Verificar que se muestra el icono de reacción activa
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgetWithMaterialApp('should format time correctly', (tester) async {
      final recentPost = testPost.copyWith(
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PostCard(post: recentPost)),
        ),
      );

      // Verificar que el tiempo se formatea como minutos
      expect(find.textContaining('30m'), findsOneWidget);
    });

    testWidgetWithMaterialApp('should handle empty title', (tester) async {
      final postWithoutTitle = testPost.copyWith(title: '');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PostCard(post: postWithoutTitle)),
        ),
      );

      // Verificar que no se muestra título
      expect(find.text('Post de Prueba'), findsNothing);
      // Pero sí el contenido
      expect(
        find.text('Este es un contenido de prueba para el nuevo PostCard'),
        findsOneWidget,
      );
    });
  });
}

// Helper para tests con MaterialApp
void testWidgetWithMaterialApp(
  String description,
  WidgetTesterCallback callback,
) {
  testWidgets(description, callback);
}
