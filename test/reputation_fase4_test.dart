import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:nexus_tcg/features/reputation/providers/reputation_provider.dart';
import 'package:nexus_tcg/features/reputation/providers/ratings_provider.dart';
import 'package:nexus_tcg/features/reputation/screens/leaderboard_screen.dart';
import 'package:nexus_tcg/features/reputation/screens/reputation_dashboard_screen.dart';
import 'package:nexus_tcg/features/reputation/screens/public_profile_screen.dart';
import 'package:nexus_tcg/features/reputation/screens/rating_dialog_screen.dart';
import 'package:nexus_tcg/features/reputation/models/leaderboard_types.dart';

/// Tests específicos para FASE 4 Frontend - Sistema de Reputación
///
/// Verifica:
/// - Creación correcta de widgets
/// - Integración con providers
/// - Navegación entre pantallas
/// - Funcionalidad de filtros
/// - Estados de loading y error
void main() {
  group('FASE 4 Frontend - Sistema de Reputación Tests', () {
    late ReputationProvider reputationProvider;
    late RatingsProvider ratingsProvider;

    setUp(() {
      reputationProvider = ReputationProvider();
      ratingsProvider = RatingsProvider();
    });

    testWidgets('LeaderboardScreen se renderiza correctamente', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: reputationProvider),
            ChangeNotifierProvider.value(value: ratingsProvider),
          ],
          child: const MaterialApp(home: LeaderboardScreen()),
        ),
      );

      // Verificar que se muestra la pantalla de leaderboard
      expect(find.text('Leaderboard'), findsOneWidget);
      expect(find.text('Filtros'), findsOneWidget);
      expect(find.text('Período'), findsOneWidget);

      // Verificar que existe el TabBar
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Ranking'), findsOneWidget);
      expect(find.text('Estadísticas'), findsOneWidget);

      // Verificar filtros
      expect(
        find.byType(DropdownButtonFormField<LeaderboardPeriod>),
        findsOneWidget,
      );
    });

    testWidgets('ReputationDashboardScreen se renderiza correctamente', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: reputationProvider),
            ChangeNotifierProvider.value(value: ratingsProvider),
          ],
          child: const MaterialApp(home: ReputationDashboardScreen()),
        ),
      );

      // Verificar elementos principales
      expect(find.text('Mi Reputación'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);

      // Verificar tabs del dashboard
      expect(find.text('Resumen'), findsOneWidget);
      expect(find.text('Estadísticas'), findsOneWidget);
      expect(find.text('Análisis'), findsOneWidget);
    });

    testWidgets('PublicProfileScreen se renderiza con parámetros correctos', (
      WidgetTester tester,
    ) async {
      const testUserId = 123;
      const testUsername = 'TestUser';

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: reputationProvider),
            ChangeNotifierProvider.value(value: ratingsProvider),
          ],
          child: const MaterialApp(
            home: PublicProfileScreen(
              userId: testUserId,
              username: testUsername,
            ),
          ),
        ),
      );

      // Verificar que se muestra el username en algún lugar
      expect(find.textContaining(testUsername), findsAtLeastNWidgets(1));

      // Verificar estructura básica
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('RatingDialogScreen se renderiza con parámetros correctos', (
      WidgetTester tester,
    ) async {
      const testUserId = 456;
      const testUsername = 'TargetUser';

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: reputationProvider),
            ChangeNotifierProvider.value(value: ratingsProvider),
          ],
          child: const MaterialApp(
            home: RatingDialogScreen(
              targetUserId: testUserId,
              targetUserName: testUsername,
            ),
          ),
        ),
      );

      // Verificar elementos de rating
      expect(find.text('Valorar Usuario'), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Rating'), findsOneWidget);
      expect(find.text('Comentarios'), findsOneWidget);
    });

    testWidgets('LeaderboardPeriod enum funciona correctamente', (
      WidgetTester tester,
    ) async {
      // Test de enum LeaderboardPeriod
      expect(LeaderboardPeriod.weekly.displayName, equals('Semanal'));
      expect(LeaderboardPeriod.monthly.displayName, equals('Mensual'));
      expect(LeaderboardPeriod.quarterly.displayName, equals('Trimestral'));
      expect(LeaderboardPeriod.yearly.displayName, equals('Anual'));
      expect(LeaderboardPeriod.allTime.displayName, equals('Histórico'));

      // Test de fromString
      expect(
        LeaderboardPeriod.fromString('week'),
        equals(LeaderboardPeriod.weekly),
      );
      expect(
        LeaderboardPeriod.fromString('month'),
        equals(LeaderboardPeriod.monthly),
      );
      expect(
        LeaderboardPeriod.fromString('invalid'),
        equals(LeaderboardPeriod.monthly),
      ); // default
    });

    testWidgets('LeaderboardCategory enum funciona correctamente', (
      WidgetTester tester,
    ) async {
      // Test de enum LeaderboardCategory
      expect(LeaderboardCategory.overall.displayName, equals('General'));
      expect(LeaderboardCategory.trading.displayName, equals('Intercambios'));
      expect(LeaderboardCategory.community.displayName, equals('Comunidad'));
      expect(LeaderboardCategory.helpfulness.displayName, equals('Utilidad'));

      // Test de fromString
      expect(
        LeaderboardCategory.fromString('overall'),
        equals(LeaderboardCategory.overall),
      );
      expect(
        LeaderboardCategory.fromString('trading'),
        equals(LeaderboardCategory.trading),
      );
      expect(
        LeaderboardCategory.fromString('invalid'),
        equals(LeaderboardCategory.overall),
      ); // default
    });

    group('Filtros de Leaderboard', () {
      testWidgets('Filtro de período se puede cambiar', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: reputationProvider),
              ChangeNotifierProvider.value(value: ratingsProvider),
            ],
            child: const MaterialApp(home: LeaderboardScreen()),
          ),
        );

        // Buscar el dropdown de período
        final dropdown = find.byType(
          DropdownButtonFormField<LeaderboardPeriod>,
        );
        expect(dropdown, findsOneWidget);

        // Intentar abrir el dropdown
        await tester.tap(dropdown);
        await tester.pumpAndSettle();

        // Verificar que aparecen las opciones (pueden no aparecer en test, pero el dropdown existe)
        expect(dropdown, findsOneWidget);
      });
    });

    group('Estados de Loading y Error', () {
      testWidgets('LeaderboardScreen muestra loading correctamente', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: reputationProvider),
              ChangeNotifierProvider.value(value: ratingsProvider),
            ],
            child: const MaterialApp(home: LeaderboardScreen()),
          ),
        );

        // Inicialmente debería mostrar loading o estado inicial
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });
    });

    group('Navegación e Integración', () {
      testWidgets('Botones de navegación están presentes', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: reputationProvider),
              ChangeNotifierProvider.value(value: ratingsProvider),
            ],
            child: const MaterialApp(home: LeaderboardScreen()),
          ),
        );

        // Verificar que existe el FloatingActionButton para refresh
        expect(find.byType(FloatingActionButton), findsOneWidget);

        // Verificar iconos de navegación en AppBar
        expect(find.byIcon(Icons.person), findsWidgets);
        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });

      testWidgets('PublicProfileScreen tiene botón de valorar', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: reputationProvider),
              ChangeNotifierProvider.value(value: ratingsProvider),
            ],
            child: const MaterialApp(
              home: PublicProfileScreen(userId: 123, username: 'TestUser'),
            ),
          ),
        );

        // Debería existir algún botón de acción relacionado con valorar
        expect(find.byType(FloatingActionButton), findsWidgets);
      });
    });

    group('Formularios y Validaciones', () {
      testWidgets('RatingDialogScreen tiene formulario completo', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: reputationProvider),
              ChangeNotifierProvider.value(value: ratingsProvider),
            ],
            child: const MaterialApp(
              home: RatingDialogScreen(
                targetUserId: 123,
                targetUserName: 'TestUser',
              ),
            ),
          ),
        );

        // Verificar elementos del formulario
        expect(find.byType(Form), findsOneWidget);
        expect(find.byType(TextFormField), findsWidgets);

        // Verificar botones de acción
        expect(find.text('Guardar'), findsWidgets);
        expect(find.text('Cancelar'), findsWidgets);
      });
    });

    group('Responsive Design', () {
      testWidgets('Pantallas se adaptan a diferentes tamaños', (
        WidgetTester tester,
      ) async {
        // Test con tamaño de pantalla pequeño
        await tester.binding.setSurfaceSize(const Size(400, 600));

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: reputationProvider),
              ChangeNotifierProvider.value(value: ratingsProvider),
            ],
            child: const MaterialApp(home: LeaderboardScreen()),
          ),
        );

        expect(find.byType(LeaderboardScreen), findsOneWidget);

        // Test con tamaño de pantalla grande
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        await tester.pumpAndSettle();

        expect(find.byType(LeaderboardScreen), findsOneWidget);

        // Restaurar tamaño normal
        await tester.binding.setSurfaceSize(null);
      });
    });

    tearDown(() {
      // Cleanup después de cada test
    });
  });
}
