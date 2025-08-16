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
      gameTypeId: 1,
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
      gameTypeId: 2,
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
      gameTypeId: 3,
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
      gameTypeId: 4,
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
      gameTypeId: 5,
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
      gameTypeId: 6,
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
      gameTypeId: 1,
      memberCount: 1834,
      isSubscribed: false,
      createdAt: DateTime(2023, 7, 29),
      tags: ['Draft', 'Limited', 'Señales', 'Pick Order'],
      difficultyLevel: 'Avanzado',
    ),
    Community(
      id: 8,
      name: 'Pokémon VGC Competitivo',
      description:
          'Video Game Championship de Pokémon. Análisis de equipos, predicciones meta y preparación para Worlds.',
      gameType: 'Pokémon TCG',
      gameTypeId: 2,
      memberCount: 2167,
      isSubscribed: true,
      createdAt: DateTime(2023, 12, 5),
      tags: ['VGC', 'Competitivo', 'Equipos', 'Worlds'],
      difficultyLevel: 'Avanzado',
    ),
    Community(
      id: 9,
      name: 'TCG Casual Chileno',
      description:
          'Para jugadores casuales de todos los TCGs. Ambiente relajado, intercambios amistosos y diversión garantizada.',
      gameType: 'Varios',
      gameTypeId: 7,
      memberCount: 567,
      isSubscribed: false,
      createdAt: DateTime(2024, 2, 14),
      tags: ['Casual', 'Chile', 'Intercambios', 'Diversión'],
      difficultyLevel: 'Principiante',
    ),
    Community(
      id: 10,
      name: 'Flesh and Blood Rising',
      description:
          'El TCG que está revolucionando el mercado. Mecánicas innovadoras, arte excepcional y jugabilidad única.',
      gameType: 'Flesh and Blood',
      gameTypeId: 8,
      memberCount: 1289,
      isSubscribed: true,
      createdAt: DateTime(2024, 4, 7),
      tags: ['FAB', 'Innovador', 'Arte', 'Único'],
      difficultyLevel: 'Intermedio',
    ),
  ];

  /// Obtiene comunidades filtradas por tipo de juego
  static List<Community> getCommunitiesByGameType(String gameType) {
    return allCommunities
        .where(
          (community) =>
              community.gameTypeName.toLowerCase() == gameType.toLowerCase(),
        )
        .toList();
  }

  /// Obtiene comunidades con tags específicos
  static List<Community> getCommunitiesByTag(String tag) {
    return allCommunities
        .where(
          (community) => community.tagNames.any(
            (communityTag) => communityTag.toLowerCase() == tag.toLowerCase(),
          ),
        )
        .toList();
  }

  /// Obtiene tipos de juego únicos disponibles
  static List<String> get availableGameTypes {
    return allCommunities
        .map((community) => community.gameTypeName)
        .toSet()
        .toList()
      ..sort();
  }

  /// Obtiene todos los tags únicos
  static List<String> get availableTags {
    final allTags = <String>[];
    for (final community in allCommunities) {
      allTags.addAll(community.tagNames);
    }
    return allTags.toSet().toList()..sort();
  }

  /// Obtiene comunidades por nivel de dificultad
  static List<Community> getCommunitiesByDifficulty(String difficulty) {
    return allCommunities
        .where(
          (community) =>
              community.difficultyLevel.toLowerCase() ==
              difficulty.toLowerCase(),
        )
        .toList();
  }

  /// Obtiene comunidades a las que el usuario está suscrito
  static List<Community> get subscribedCommunities {
    return allCommunities.where((community) => community.isSubscribed).toList();
  }

  /// Obtiene los niveles de dificultad disponibles
  static List<String> get availableDifficultyLevels {
    return allCommunities
        .map((community) => community.difficultyLevel)
        .toSet()
        .toList()
      ..sort();
  }

  /// Simula la búsqueda de comunidades por nombre o descripción
  static List<Community> searchCommunities(String query) {
    if (query.isEmpty) return allCommunities;

    final searchTerm = query.toLowerCase();
    return allCommunities.where((community) {
      return community.name.toLowerCase().contains(searchTerm) ||
          community.description.toLowerCase().contains(searchTerm) ||
          community.gameTypeName.toLowerCase().contains(searchTerm) ||
          community.tagNames.any(
            (tag) => tag.toLowerCase().contains(searchTerm),
          );
    }).toList();
  }
}
