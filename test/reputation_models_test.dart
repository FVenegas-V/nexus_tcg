import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_tcg/features/reputation/models/leaderboard_types.dart';

/// Tests básicos para verificar modelos y enums de FASE 4
void main() {
  group('FASE 4 - Tests de Modelos', () {
    test('LeaderboardPeriod enum funciona correctamente', () {
      // Test valores de enum
      expect(LeaderboardPeriod.weekly.displayName, equals('Semanal'));
      expect(LeaderboardPeriod.monthly.displayName, equals('Mensual'));
      expect(LeaderboardPeriod.quarterly.displayName, equals('Trimestral'));
      expect(LeaderboardPeriod.yearly.displayName, equals('Anual'));
      expect(LeaderboardPeriod.allTime.displayName, equals('Histórico'));

      // Test valores API
      expect(LeaderboardPeriod.weekly.apiValue, equals('week'));
      expect(LeaderboardPeriod.monthly.apiValue, equals('month'));
      expect(LeaderboardPeriod.quarterly.apiValue, equals('quarter'));
      expect(LeaderboardPeriod.yearly.apiValue, equals('year'));
      expect(LeaderboardPeriod.allTime.apiValue, equals('all'));

      // Test método fromString
      expect(
        LeaderboardPeriod.fromString('week'),
        equals(LeaderboardPeriod.weekly),
      );
      expect(
        LeaderboardPeriod.fromString('month'),
        equals(LeaderboardPeriod.monthly),
      );
      expect(
        LeaderboardPeriod.fromString('quarter'),
        equals(LeaderboardPeriod.quarterly),
      );
      expect(
        LeaderboardPeriod.fromString('year'),
        equals(LeaderboardPeriod.yearly),
      );
      expect(
        LeaderboardPeriod.fromString('all'),
        equals(LeaderboardPeriod.allTime),
      );

      // Test valor por defecto
      expect(
        LeaderboardPeriod.fromString('invalid'),
        equals(LeaderboardPeriod.monthly),
      );
    });

    test('LeaderboardCategory enum funciona correctamente', () {
      // Test valores de enum
      expect(LeaderboardCategory.overall.displayName, equals('General'));
      expect(LeaderboardCategory.trading.displayName, equals('Intercambios'));
      expect(LeaderboardCategory.community.displayName, equals('Comunidad'));
      expect(LeaderboardCategory.helpfulness.displayName, equals('Utilidad'));

      // Test valores API
      expect(LeaderboardCategory.overall.apiValue, equals('overall'));
      expect(LeaderboardCategory.trading.apiValue, equals('trading'));
      expect(LeaderboardCategory.community.apiValue, equals('community'));
      expect(LeaderboardCategory.helpfulness.apiValue, equals('helpfulness'));

      // Test método fromString
      expect(
        LeaderboardCategory.fromString('overall'),
        equals(LeaderboardCategory.overall),
      );
      expect(
        LeaderboardCategory.fromString('trading'),
        equals(LeaderboardCategory.trading),
      );
      expect(
        LeaderboardCategory.fromString('community'),
        equals(LeaderboardCategory.community),
      );
      expect(
        LeaderboardCategory.fromString('helpfulness'),
        equals(LeaderboardCategory.helpfulness),
      );

      // Test valor por defecto
      expect(
        LeaderboardCategory.fromString('invalid'),
        equals(LeaderboardCategory.overall),
      );
    });

    test('LeaderboardPeriod días configurados correctamente', () {
      expect(LeaderboardPeriod.weekly.days, equals(7));
      expect(LeaderboardPeriod.monthly.days, equals(30));
      expect(LeaderboardPeriod.quarterly.days, equals(90));
      expect(LeaderboardPeriod.yearly.days, equals(365));
      expect(LeaderboardPeriod.allTime.days, equals(0));
    });

    test('Enums tienen todos los valores esperados', () {
      // Verificar que LeaderboardPeriod tiene exactamente 5 valores
      expect(LeaderboardPeriod.values.length, equals(5));
      expect(LeaderboardPeriod.values, contains(LeaderboardPeriod.weekly));
      expect(LeaderboardPeriod.values, contains(LeaderboardPeriod.monthly));
      expect(LeaderboardPeriod.values, contains(LeaderboardPeriod.quarterly));
      expect(LeaderboardPeriod.values, contains(LeaderboardPeriod.yearly));
      expect(LeaderboardPeriod.values, contains(LeaderboardPeriod.allTime));

      // Verificar que LeaderboardCategory tiene exactamente 4 valores
      expect(LeaderboardCategory.values.length, equals(4));
      expect(LeaderboardCategory.values, contains(LeaderboardCategory.overall));
      expect(LeaderboardCategory.values, contains(LeaderboardCategory.trading));
      expect(
        LeaderboardCategory.values,
        contains(LeaderboardCategory.community),
      );
      expect(
        LeaderboardCategory.values,
        contains(LeaderboardCategory.helpfulness),
      );
    });
  });
}
