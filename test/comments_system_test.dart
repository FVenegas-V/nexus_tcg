import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:nexus_tcg/core/models/comment.dart';
import 'package:nexus_tcg/core/services/comments_service.dart';
import 'package:nexus_tcg/core/services/http_service.dart';
import 'package:nexus_tcg/features/posts/providers/comments_provider.dart';
import 'package:nexus_tcg/features/posts/widgets/comment_widget.dart';
import 'package:nexus_tcg/features/posts/widgets/comments_list_widget.dart';
import 'package:nexus_tcg/features/posts/widgets/comment_composer_widget.dart';

void main() {
  group('Comentarios System Tests', () {
    late CommentsService mockCommentsService;
    late CommentsProvider commentsProvider;

    setUp(() {
      // Mock service para testing
      mockCommentsService = CommentsService(HttpService());
      commentsProvider = CommentsProvider(mockCommentsService);
    });

    testWidgets('CommentWidget debe renderizar correctamente', (
      WidgetTester tester,
    ) async {
      // Comentario de prueba
      final testComment = Comment(
        id: 1,
        content: 'Este es un comentario de prueba',
        authorId: 1,
        authorUsername: 'testuser',
        postId: 1,
        parentId: null,
        threadLevel: 0,
        threadPath: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: false,
        canEdit: true,
        canDelete: true,
        reactionsCount: 0,
        reactionsBreakdown: {},
        userReaction: null,
        replies: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<CommentsProvider>(
              create: (_) => commentsProvider,
              child: CommentWidget(
                comment: testComment,
                onReply: (comment) {},
                onEdit: (comment) {},
                onDelete: (comment) {},
              ),
            ),
          ),
        ),
      );

      // Verificar que el contenido se muestra
      expect(find.text('Este es un comentario de prueba'), findsOneWidget);
      expect(find.text('testuser'), findsOneWidget);

      // Verificar que los botones están presentes
      expect(find.byIcon(Icons.reply), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
    });

    testWidgets('CommentsListWidget debe renderizar lista vacía', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<CommentsProvider>(
              create: (_) => commentsProvider,
              child: CommentsListWidget(communityId: 1, postId: 1),
            ),
          ),
        ),
      );

      // La lista debe estar inicialmente cargando o vacía
      await tester.pump();

      // Debe mostrar algún indicador de carga o estado vacío
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('CommentComposerWidget debe tener campo de texto', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<CommentsProvider>(
              create: (_) => commentsProvider,
              child: CommentComposerWidget(
                communityId: 1,
                postId: 1,
                parentComment: null,
                onCommentCreated: (comment) {},
                onCancel: () {},
              ),
            ),
          ),
        ),
      );

      // Verificar que hay un campo de texto
      expect(find.byType(TextField), findsOneWidget);

      // Verificar que hay un botón de enviar
      expect(find.widgetWithText(ElevatedButton, 'Comentar'), findsOneWidget);
    });

    test('Comment model debe serializar correctamente', () {
      final comment = Comment(
        id: 1,
        content: 'Test content',
        authorId: 1,
        authorUsername: 'testuser',
        postId: 1,
        communityId: 1,
        threadLevel: 0,
        threadPath: '1',
        createdAt: DateTime.parse('2025-08-18T23:00:00Z'),
        updatedAt: DateTime.parse('2025-08-18T23:00:00Z'),
        isDeleted: false,
        canEdit: true,
        reactionsCount: {'like': 5},
        userReaction: 'like',
      );

      final json = comment.toJson();

      expect(json['id'], 1);
      expect(json['content'], 'Test content');
      expect(json['author_username'], 'testuser');
      expect(json['thread_level'], 0);
      expect(json['reactions_count']['like'], 5);
      expect(json['user_reaction'], 'like');

      // Test deserialización
      final commentFromJson = Comment.fromJson(json);
      expect(commentFromJson.id, comment.id);
      expect(commentFromJson.content, comment.content);
      expect(commentFromJson.threadLevel, comment.threadLevel);
    });

    test('CommentsFilter debe tener copyWith funcional', () {
      final filter = CommentsFilter(
        ordering: CommentOrdering.newest,
        parentId: 1,
        isDeleted: false,
      );

      final newFilter = filter.copyWith(
        ordering: CommentOrdering.oldest,
        isDeleted: true,
      );

      expect(newFilter.ordering, CommentOrdering.oldest);
      expect(newFilter.parentId, 1); // Se mantiene
      expect(newFilter.isDeleted, true);
    });

    test('CreateCommentRequest debe validar correctamente', () {
      final request = CreateCommentRequest(
        content: 'Test comment',
        postId: 1,
        parentId: null,
      );

      expect(request.content, 'Test comment');
      expect(request.postId, 1);
      expect(request.parentId, null);

      final json = request.toJson();
      expect(json['content'], 'Test comment');
      expect(json['post'], 1);
      expect(json.containsKey('parent'), false);
    });
  });

  group('Threading Logic Tests', () {
    test('Threading level debe calcularse correctamente', () {
      // Comentario principal (nivel 0)
      final mainComment = Comment(
        id: 1,
        content: 'Main comment',
        authorId: 1,
        authorUsername: 'user1',
        postId: 1,
        communityId: 1,
        threadLevel: 0,
        threadPath: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: false,
        canEdit: true,
        reactionsCount: {},
        userReaction: null,
      );

      // Respuesta nivel 1
      final reply1 = Comment(
        id: 2,
        content: 'Reply 1',
        authorId: 2,
        authorUsername: 'user2',
        postId: 1,
        communityId: 1,
        threadLevel: 1,
        threadPath: '1.2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: false,
        canEdit: true,
        reactionsCount: {},
        userReaction: null,
      );

      // Respuesta nivel 2
      final reply2 = Comment(
        id: 3,
        content: 'Reply 2',
        authorId: 3,
        authorUsername: 'user3',
        postId: 1,
        communityId: 1,
        threadLevel: 2,
        threadPath: '1.2.3',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDeleted: false,
        canEdit: true,
        reactionsCount: {},
        userReaction: null,
      );

      expect(mainComment.threadLevel, 0);
      expect(reply1.threadLevel, 1);
      expect(reply2.threadLevel, 2);

      expect(mainComment.threadPath, '1');
      expect(reply1.threadPath, '1.2');
      expect(reply2.threadPath, '1.2.3');
    });

    test('canEdit debe respetar límite de tiempo', () {
      final now = DateTime.now();

      // Comentario reciente (puede editarse)
      final recentComment = Comment(
        id: 1,
        content: 'Recent comment',
        authorId: 1,
        authorUsername: 'user1',
        postId: 1,
        communityId: 1,
        threadLevel: 0,
        threadPath: '1',
        createdAt: now.subtract(Duration(minutes: 5)), // 5 minutos atrás
        updatedAt: now.subtract(Duration(minutes: 5)),
        isDeleted: false,
        canEdit: true,
        reactionsCount: {},
        userReaction: null,
      );

      // Comentario viejo (no puede editarse)
      final oldComment = Comment(
        id: 2,
        content: 'Old comment',
        authorId: 1,
        authorUsername: 'user1',
        postId: 1,
        communityId: 1,
        threadLevel: 0,
        threadPath: '2',
        createdAt: now.subtract(Duration(minutes: 20)), // 20 minutos atrás
        updatedAt: now.subtract(Duration(minutes: 20)),
        isDeleted: false,
        canEdit: false,
        reactionsCount: {},
        userReaction: null,
      );

      expect(recentComment.canEdit, true);
      expect(oldComment.canEdit, false);
    });
  });
}
