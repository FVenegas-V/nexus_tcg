import 'community.dart';

/// Servicio para generar datos mock de comunidades
/// Proporciona datos realistas para desarrollo y testing
class MockCommunitiesData {
  /// Lista completa de comunidades mock para desarrollo
  static List<Community> get allCommunities => [
    Community(
      id: 1,
      name: 'Magic: The Gathering Competitivo',
      description:
          'Comunidad para jugadores competitivos de MTG. Discutimos estrategias de meta, análisis de mazos y preparación para torneos.',
      gameType: 'Magic: The Gathering',
      memberCount: 2847,
      imageUrl: null,
      isSubscribed: true,
      createdAt: DateTime(2023, 8, 15),
      tags: ['Competitivo', 'Torneos', 'Standard', 'Modern'],
      difficultyLevel: 'Avanzado',
    ),
    Community(
      id: 2,
      name: 'Pokémon TCG Collectors',
      description:
          'Para coleccionistas y jugadores de Pokémon TCG. Compartimos cartas raras, intercambios y noticias del meta actual.',
      gameType: 'Pokémon TCG',
      memberCount: 4521,
      imageUrl: null,
      isSubscribed: false,
      createdAt: DateTime(2023, 6, 10),
      tags: ['Coleccionismo', 'Intercambios', 'Cartas Raras', 'Meta'],
      difficultyLevel: 'Intermedio',
    ),
    Community(
      id: 3,
      name: 'Yu-Gi-Oh! Duelistas Chile',
      description:
          'Comunidad chilena de duelistas. Organizamos torneos locales, discutimos nuevas cartas y estrategias meta.',
      gameType: 'Yu-Gi-Oh!',
      memberCount: 1653,
      isSubscribed: true,
      createdAt: DateTime(2023, 9, 22),
      tags: ['Chile', 'Torneos Locales', 'Meta', 'Nuevas Cartas'],
      difficultyLevel: 'Intermedio',
    ),
    Community(
      id: 4,
      name: 'Digimon Card Game Principiantes',
      description:
          'Perfecto para comenzar en Digimon TCG. Explicamos reglas básicas, mazos starter y primeras estrategias.',
      gameType: 'Digimon TCG',
      memberCount: 892,
      isSubscribed: false,
      createdAt: DateTime(2024, 1, 8),
      tags: ['Principiantes', 'Reglas Básicas', 'Mazos Starter'],
      difficultyLevel: 'Principiante',
    ),
    Community(
      id: 5,
      name: 'Dragon Ball Super Card Game',
      description:
          'Comunidad dedicada a DBS TCG. Análisis de cartas, combos devastadores y preparación para campeonatos.',
      gameType: 'Dragon Ball Super',
      memberCount: 1247,
      isSubscribed: false,
      createdAt: DateTime(2023, 11, 3),
      tags: ['DBS', 'Combos', 'Campeonatos', 'Análisis'],
      difficultyLevel: 'Avanzado',
    ),
    Community(
      id: 6,
      name: 'One Piece Card Game Latino',
      description:
          'Comunidad latina del nuevo TCG de One Piece. Estrategias de piratas, discusión de cartas y eventos especiales.',
      gameType: 'One Piece TCG',
      memberCount: 3156,
      isSubscribed: true,
      createdAt: DateTime(2024, 3, 17),
      tags: ['One Piece', 'Latino', 'Piratas', 'Eventos'],
      difficultyLevel: 'Intermedio',
    ),
    Community(
      id: 7,
      name: 'MTG Draft Masters',
      description:
          'Especialistas en Draft de Magic. Señales de colores, pick orders y estrategias para dominar en Limited.',
      gameType: 'Magic: The Gathering',
      memberCount: 1834,
      isSubscribed: false,
      createdAt: DateTime(2023, 7, 29),
      tags: ['Draft', 'Limited', 'Señales', 'Pick Order'],
      difficultyLevel: 'Avanzado',
    ),
    Community(
      id: 8,
      name: 'Lorcana Collectors España',
      description:
          'Coleccionistas y jugadores de Disney Lorcana en España. Intercambios, cartas promocionales y eventos Disney.',
      gameType: 'Disney Lorcana',
      memberCount: 967,
      isSubscribed: false,
      createdAt: DateTime(2024, 2, 14),
      tags: ['Lorcana', 'Disney', 'España', 'Coleccionismo'],
      difficultyLevel: 'Principiante',
    ),
    Community(
      id: 9,
      name: 'Flesh and Blood Competitive',
      description:
          'Elite de jugadores de Flesh and Blood. Meta competitivo, análisis profundo de héroes y preparación para Pro Tour.',
      gameType: 'Flesh and Blood',
      memberCount: 743,
      isSubscribed: false,
      createdAt: DateTime(2023, 12, 11),
      tags: ['FaB', 'Competitivo', 'Pro Tour', 'Héroes'],
      difficultyLevel: 'Avanzado',
    ),
    Community(
      id: 10,
      name: 'Cardfight Vanguard Casual',
      description:
          'Para disfrutar Cardfight Vanguard de manera relajada. Mazos temáticos, lore de clanes y partidas amistosas.',
      gameType: 'Cardfight!! Vanguard',
      memberCount: 1289,
      isSubscribed: true,
      createdAt: DateTime(2023, 10, 7),
      tags: ['Vanguard', 'Casual', 'Clanes', 'Lore'],
      difficultyLevel: 'Intermedio',
    ),
  ];

  /// Obtiene comunidades filtradas por tipo de juego
  static List<Community> getByGameType(String gameType) {
    return allCommunities
        .where((community) => community.gameType == gameType)
        .toList();
  }

  /// Obtiene comunidades a las que el usuario está suscrito
  static List<Community> getSubscribed() {
    return allCommunities.where((community) => community.isSubscribed).toList();
  }

  /// Busca comunidades por nombre o descripción
  static List<Community> search(String query) {
    if (query.isEmpty) return allCommunities;

    final lowercaseQuery = query.toLowerCase();
    return allCommunities.where((community) {
      return community.name.toLowerCase().contains(lowercaseQuery) ||
          community.description.toLowerCase().contains(lowercaseQuery) ||
          community.gameType.toLowerCase().contains(lowercaseQuery) ||
          community.tags.any(
            (tag) => tag.toLowerCase().contains(lowercaseQuery),
          );
    }).toList();
  }

  /// Obtiene una comunidad por ID
  static Community? getById(int id) {
    try {
      return allCommunities.firstWhere((community) => community.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Simula cambio de estado de suscripción
  static Community toggleSubscription(Community community) {
    return community.copyWith(isSubscribed: !community.isSubscribed);
  }

  /// Obtiene tipos de juego únicos disponibles
  static List<String> get availableGameTypes {
    return allCommunities
        .map((community) => community.gameType)
        .toSet()
        .toList()
      ..sort();
  }

  /// Obtiene niveles de dificultad disponibles
  static List<String> get availableDifficultyLevels {
    return allCommunities
        .map((community) => community.difficultyLevel)
        .toSet()
        .toList();
  }
}
