import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:nexus_tcg/core/theme/app_theme.dart';
import 'package:nexus_tcg/features/reputation/providers/reputation_provider.dart';
import 'package:nexus_tcg/features/reputation/providers/ratings_provider.dart';
import 'package:nexus_tcg/features/reputation/screens/leaderboard_screen.dart';
import 'package:nexus_tcg/features/reputation/screens/reputation_dashboard_screen.dart';
import 'package:nexus_tcg/features/reputation/screens/public_profile_screen.dart';
import 'package:nexus_tcg/features/reputation/screens/rating_dialog_screen.dart';

/// Tests de integración para el sistema de reputación FASE 4
/// Verifica el funcionamiento completo del sistema con rutas y navegación
void main() {
  group('FASE 4 - Tests de Integración', () {
    late GoRouter router;

    setUp(() {
      // Configurar router para tests
      router = GoRouter(
        initialLocation: '/leaderboard',
        routes: [
          GoRoute(
            path: '/leaderboard',
            builder: (context, state) => const LeaderboardScreen(),
          ),
          GoRoute(
            path: '/reputation/dashboard',
            builder: (context, state) => const ReputationDashboardScreen(),
          ),
          GoRoute(
            path: '/reputation/user/:userId',
            builder: (context, state) {
              final userId = int.parse(state.pathParameters['userId'] ?? '1');
              final username =
                  state.uri.queryParameters['username'] ?? 'TestUser';
              return PublicProfileScreen(userId: userId, username: username);
            },
          ),
          GoRoute(
            path: '/reputation/rate/:userId',
            builder: (context, state) {
              final userId = int.parse(state.pathParameters['userId'] ?? '1');
              final username =
                  state.uri.queryParameters['username'] ?? 'TestUser';
              return RatingDialogScreen(
                targetUserId: userId,
                targetUserName: username,
              );
            },
          ),
        ],
      );
    });

    Widget createTestApp({String? initialLocation}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ReputationProvider()),
          ChangeNotifierProvider(create: (_) => RatingsProvider()),
        ],
        child: MaterialApp.router(
          title: 'Test App',
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      );
    }

    testWidgets('Navegación a LeaderboardScreen funciona', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verificar que estamos en LeaderboardScreen
      expect(find.text('Leaderboard'), findsOneWidget);
      expect(find.text('Filtros'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('Navegación a ReputationDashboardScreen funciona', (
      WidgetTester tester,
    ) async {
      router.go('/reputation/dashboard');
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verificar que estamos en ReputationDashboardScreen
      expect(find.text('Mi Reputación'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('Navegación a PublicProfileScreen con parámetros funciona', (
      WidgetTester tester,
    ) async {
      router.go('/reputation/user/123?username=TestUser');
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verificar que estamos en PublicProfileScreen
      expect(find.textContaining('TestUser'), findsWidgets);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Navegación a RatingDialogScreen con parámetros funciona', (
      WidgetTester tester,
    ) async {
      router.go('/reputation/rate/456?username=TargetUser');
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verificar que estamos en RatingDialogScreen
      expect(find.text('Valorar Usuario'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    group('Test de Widgets Específicos', () {
      testWidgets('LeaderboardScreen muestra elementos correctos', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ReputationProvider()),
              ChangeNotifierProvider(create: (_) => RatingsProvider()),
            ],
            child: const MaterialApp(home: LeaderboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Verificar elementos UI principales
        expect(find.text('Leaderboard'), findsOneWidget);
        expect(find.text('Filtros'), findsOneWidget);
        expect(find.text('Período'), findsOneWidget);
        expect(find.text('Ranking'), findsOneWidget);
        expect(find.text('Estadísticas'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });

      testWidgets('ReputationDashboardScreen muestra estructura correcta', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ReputationProvider()),
              ChangeNotifierProvider(create: (_) => RatingsProvider()),
            ],
            child: const MaterialApp(home: ReputationDashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Verificar estructura del dashboard
        expect(find.text('Mi Reputación'), findsOneWidget);
        expect(find.text('Resumen'), findsOneWidget);
        expect(find.text('Estadísticas'), findsOneWidget);
        expect(find.text('Análisis'), findsOneWidget);
      });

      testWidgets('PublicProfileScreen acepta parámetros correctamente', (
        WidgetTester tester,
      ) async {
        const testUserId = 789;
        const testUsername = 'ProfileUser';

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ReputationProvider()),
              ChangeNotifierProvider(create: (_) => RatingsProvider()),
            ],
            child: const MaterialApp(
              home: PublicProfileScreen(
                userId: testUserId,
                username: testUsername,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verificar que los parámetros se usan correctamente
        expect(find.textContaining(testUsername), findsWidgets);
      });

      testWidgets('RatingDialogScreen muestra formulario de rating', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ReputationProvider()),
              ChangeNotifierProvider(create: (_) => RatingsProvider()),
            ],
            child: const MaterialApp(
              home: RatingDialogScreen(
                targetUserId: 999,
                targetUserName: 'RatingTarget',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verificar elementos del formulario de rating
        expect(find.text('Valorar Usuario'), findsOneWidget);
        expect(find.text('Rating'), findsOneWidget);
        expect(find.text('Comentarios'), findsOneWidget);
        expect(find.byType(Form), findsOneWidget);
      });
    });

    group('Test de Interacciones', () {
      testWidgets('Cambio de tabs en LeaderboardScreen funciona', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ReputationProvider()),
              ChangeNotifierProvider(create: (_) => RatingsProvider()),
            ],
            child: const MaterialApp(home: LeaderboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap en tab "Estadísticas"
        await tester.tap(find.text('Estadísticas'));
        await tester.pumpAndSettle();

        // Verificar que cambió el contenido
        expect(find.text('Estadísticas'), findsOneWidget);
      });

      testWidgets('FloatingActionButton en LeaderboardScreen es clickeable', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ReputationProvider()),
              ChangeNotifierProvider(create: (_) => RatingsProvider()),
            ],
            child: const MaterialApp(home: LeaderboardScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Tap en FloatingActionButton
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Verificar que no hubo errores (el tap funciona)
        expect(find.byType(LeaderboardScreen), findsOneWidget);
      });
    });

    group('Test de Estados', () {
      testWidgets('Pantallas muestran loading states inicialmente', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ReputationProvider()),
              ChangeNotifierProvider(create: (_) => RatingsProvider()),
            ],
            child: const MaterialApp(home: LeaderboardScreen()),
          ),
        );

        // Antes de pumpAndSettle, debería mostrar loading
        expect(find.byType(CircularProgressIndicator), findsWidgets);

        await tester.pumpAndSettle();
      });
    });
  });
}
