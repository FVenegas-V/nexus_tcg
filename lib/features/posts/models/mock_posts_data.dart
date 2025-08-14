import 'post.dart';

/// Servicio para generar datos mock de posts
/// Proporciona datos realistas para desarrollo y testing del feed
class MockPostsData {
  /// Lista completa de posts mock para desarrollo
  static List<Post> get allPosts => [
    Post(
      id: 1,
      content:
          '¡Acabo de armar mi nuevo mazo Grixis Control! Después de mucha investigación y testing, creo que tengo la combinación perfecta para el meta actual. ¿Qué opinan de esta build? 🔥',
      imageUrls: [],
      author: const PostAuthor(
        id: 101,
        username: 'mtg_strategist',
        avatarUrl: null,
        isVerified: true,
      ),
      community: const PostCommunity(
        id: 1,
        name: 'Magic: The Gathering Competitivo',
        gameType: 'Magic: The Gathering',
      ),
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      likesCount: 42,
      commentsCount: 8,
      isLiked: false,
      isBookmarked: false,
    ),

    Post(
      id: 2,
      content:
          'Encontré esta carta holográfica de Charizard en perfecto estado en una tienda local. ¡No puedo creer la suerte que tuve! Definitivamente va directo a mi colección principal.',
      imageUrls: [],
      author: const PostAuthor(
        id: 102,
        username: 'pokemon_collector',
        avatarUrl: null,
        isVerified: false,
      ),
      community: const PostCommunity(
        id: 2,
        name: 'Pokémon TCG Collectors',
        gameType: 'Pokémon TCG',
      ),
      createdAt: DateTime.now().subtract(const Duration(hours: 4)),
      likesCount: 87,
      commentsCount: 15,
      isLiked: true,
      isBookmarked: true,
    ),

    Post(
      id: 3,
      content:
          'Tutorial: Cómo sideboard correctamente en Modern. Muchos jugadores subestiman la importancia del sideboard, pero puede ser la diferencia entre ganar y perder un match. Aquí mis consejos:',
      imageUrls: [],
      author: const PostAuthor(
        id: 103,
        username: 'modern_master',
        avatarUrl: null,
        isVerified: true,
      ),
      community: const PostCommunity(
        id: 1,
        name: 'Magic: The Gathering Competitivo',
        gameType: 'Magic: The Gathering',
      ),
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      likesCount: 156,
      commentsCount: 32,
      isLiked: false,
      isBookmarked: false,
    ),

    Post(
      id: 4,
      content:
          'Blue-Eyes White Dragon vs Red-Eyes Black Dragon: ¿cuál prefieren y por qué? Estoy armando un mazo nostálgico y no puedo decidirme. Ambas tienen sus ventajas...',
      imageUrls: [],
      author: const PostAuthor(
        id: 104,
        username: 'yugioh_duelist',
        avatarUrl: null,
        isVerified: false,
      ),
      community: const PostCommunity(
        id: 3,
        name: 'Yu-Gi-Oh! Duelistas',
        gameType: 'Yu-Gi-Oh!',
      ),
      createdAt: DateTime.now().subtract(const Duration(hours: 8)),
      likesCount: 73,
      commentsCount: 26,
      isLiked: true,
      isBookmarked: false,
    ),

    Post(
      id: 5,
      content:
          'Reseña del nuevo set de Pokémon: algunos hits increíbles, pero siento que las pull rates están un poco bajas. ¿Alguien más ha tenido la misma experiencia?',
      imageUrls: [],
      author: const PostAuthor(
        id: 105,
        username: 'pack_opener',
        avatarUrl: null,
        isVerified: false,
      ),
      community: const PostCommunity(
        id: 2,
        name: 'Pokémon TCG Collectors',
        gameType: 'Pokémon TCG',
      ),
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      likesCount: 34,
      commentsCount: 12,
      isLiked: false,
      isBookmarked: true,
    ),

    Post(
      id: 6,
      content:
          '¡Conseguí mi primera victoria en un torneo local! El mazo Burn funcionó perfectamente. Gracias a todos los que me dieron consejos la semana pasada 🏆',
      imageUrls: [],
      author: const PostAuthor(
        id: 106,
        username: 'new_competitive',
        avatarUrl: null,
        isVerified: false,
      ),
      community: const PostCommunity(
        id: 1,
        name: 'Magic: The Gathering Competitivo',
        gameType: 'Magic: The Gathering',
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      likesCount: 124,
      commentsCount: 41,
      isLiked: true,
      isBookmarked: false,
    ),

    Post(
      id: 7,
      content:
          'Predicciones para el próximo banlist de Yu-Gi-Oh!: creo que definitivamente van a limitar algunas cartas del meta actual. ¿Qué piensan ustedes?',
      imageUrls: [],
      author: const PostAuthor(
        id: 107,
        username: 'meta_analyst',
        avatarUrl: null,
        isVerified: true,
      ),
      community: const PostCommunity(
        id: 3,
        name: 'Yu-Gi-Oh! Duelistas',
        gameType: 'Yu-Gi-Oh!',
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      likesCount: 89,
      commentsCount: 67,
      isLiked: false,
      isBookmarked: true,
    ),

    Post(
      id: 8,
      content:
          'Intercambio: busco cartas de agua para mi mazo. Tengo varias cartas de fuego raras para ofrecer. ¡Manden DM si les interesa!',
      imageUrls: [],
      author: const PostAuthor(
        id: 108,
        username: 'trader_pro',
        avatarUrl: null,
        isVerified: false,
      ),
      community: const PostCommunity(
        id: 2,
        name: 'Pokémon TCG Collectors',
        gameType: 'Pokémon TCG',
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
      likesCount: 23,
      commentsCount: 7,
      isLiked: false,
      isBookmarked: false,
    ),

    Post(
      id: 9,
      content:
          'Análisis del meta post-banlist: los mazos de combo siguen siendo viables, pero ahora hay más diversidad. Es genial ver diferentes estrategias compitiendo al mismo nivel.',
      imageUrls: [],
      author: const PostAuthor(
        id: 109,
        username: 'format_expert',
        avatarUrl: null,
        isVerified: true,
      ),
      community: const PostCommunity(
        id: 3,
        name: 'Yu-Gi-Oh! Duelistas',
        gameType: 'Yu-Gi-Oh!',
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      likesCount: 198,
      commentsCount: 84,
      isLiked: true,
      isBookmarked: true,
    ),

    Post(
      id: 10,
      content:
          'Momento wholesome: enseñé a jugar Magic a mi hermanito de 10 años y hoy me ganó por primera vez. ¡Estoy súper orgulloso! 🥺',
      imageUrls: [],
      author: const PostAuthor(
        id: 110,
        username: 'big_sibling',
        avatarUrl: null,
        isVerified: false,
      ),
      community: const PostCommunity(
        id: 1,
        name: 'Magic: The Gathering Competitivo',
        gameType: 'Magic: The Gathering',
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 6)),
      likesCount: 456,
      commentsCount: 93,
      isLiked: true,
      isBookmarked: false,
    ),

    Post(
      id: 11,
      content:
          'PSA: Cuidado con las cartas falsas que están circulando. Aquí tienen una guía rápida para identificarlas y evitar estafas.',
      imageUrls: [],
      author: const PostAuthor(
        id: 111,
        username: 'authenticity_checker',
        avatarUrl: null,
        isVerified: true,
      ),
      community: const PostCommunity(
        id: 2,
        name: 'Pokémon TCG Collectors',
        gameType: 'Pokémon TCG',
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      likesCount: 267,
      commentsCount: 52,
      isLiked: false,
      isBookmarked: true,
    ),

    Post(
      id: 12,
      content:
          'Deck tech: Mi build de Eldlich post-sideboard. Funcionó increíble en el regional del fin de semana. Comparto la lista completa y el reasoning detrás de cada carta.',
      imageUrls: [],
      author: const PostAuthor(
        id: 112,
        username: 'golden_lord',
        avatarUrl: null,
        isVerified: false,
      ),
      community: const PostCommunity(
        id: 3,
        name: 'Yu-Gi-Oh! Duelistas',
        gameType: 'Yu-Gi-Oh!',
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 3, hours: 12)),
      likesCount: 145,
      commentsCount: 38,
      isLiked: false,
      isBookmarked: false,
    ),
  ];

  /// Simula cargar más posts (para paginación infinita)
  static List<Post> getMorePosts(int currentCount) {
    // Simula generar posts adicionales con IDs incrementales
    final newPosts = <Post>[];

    for (int i = 0; i < 10; i++) {
      final newId = currentCount + i + 1;
      newPosts.add(
        Post(
          id: newId,
          content:
              'Post generado dinámicamente #$newId. Este es contenido de prueba para validar la paginación infinita. ¡Funciona genial!',
          imageUrls: [],
          author: PostAuthor(
            id: 200 + i,
            username: 'user_${200 + i}',
            avatarUrl: null,
            isVerified: i % 3 == 0, // Algunos usuarios verificados
          ),
          community: PostCommunity(
            id: (i % 3) + 1, // Rotar entre las 3 comunidades principales
            name: _getCommunityName((i % 3) + 1),
            gameType: _getGameType((i % 3) + 1),
          ),
          createdAt: DateTime.now().subtract(Duration(days: 4 + i)),
          likesCount: (i + 1) * 12,
          commentsCount: (i + 1) * 3,
          isLiked: i % 4 == 0,
          isBookmarked: i % 5 == 0,
        ),
      );
    }

    return newPosts;
  }

  static String _getCommunityName(int id) {
    switch (id) {
      case 1:
        return 'Magic: The Gathering Competitivo';
      case 2:
        return 'Pokémon TCG Collectors';
      case 3:
        return 'Yu-Gi-Oh! Duelistas';
      default:
        return 'Comunidad General';
    }
  }

  static String _getGameType(int id) {
    switch (id) {
      case 1:
        return 'Magic: The Gathering';
      case 2:
        return 'Pokémon TCG';
      case 3:
        return 'Yu-Gi-Oh!';
      default:
        return 'General';
    }
  }
}
