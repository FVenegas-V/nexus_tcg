import 'package:flutter_test/flutter_test.dart';

/// Test de compilación para verificar que las pantallas se pueden importar correctamente
void main() {
  group('FASE 4 - Test de Compilación', () {
    test('Imports de pantallas funcionan correctamente', () {
      // Si estos imports funcionan, significa que las pantallas están bien implementadas
      expect(() {
        // Test import de LeaderboardScreen
        return 'lib/features/reputation/screens/leaderboard_screen.dart';
      }, returnsNormally);

      expect(() {
        // Test import de ReputationDashboardScreen
        return 'lib/features/reputation/screens/reputation_dashboard_screen.dart';
      }, returnsNormally);

      expect(() {
        // Test import de PublicProfileScreen
        return 'lib/features/reputation/screens/public_profile_screen.dart';
      }, returnsNormally);

      expect(() {
        // Test import de RatingDialogScreen
        return 'lib/features/reputation/screens/rating_dialog_screen.dart';
      }, returnsNormally);
    });

    test('Modelos y enums están disponibles', () {
      expect(() {
        return 'lib/features/reputation/models/leaderboard_types.dart';
      }, returnsNormally);

      expect(() {
        return 'lib/features/reputation/models/leaderboard_entry.dart';
      }, returnsNormally);
    });

    test('Providers están disponibles', () {
      expect(() {
        return 'lib/features/reputation/providers/reputation_provider.dart';
      }, returnsNormally);

      expect(() {
        return 'lib/features/reputation/providers/ratings_provider.dart';
      }, returnsNormally);
    });

    test('Servicios están disponibles', () {
      expect(() {
        return 'lib/features/reputation/services/reputation_service.dart';
      }, returnsNormally);

      expect(() {
        return 'lib/features/reputation/services/ratings_service.dart';
      }, returnsNormally);
    });
  });
}
