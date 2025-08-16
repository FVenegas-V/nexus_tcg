import '../models/community_tag.dart';
import '../../games/models/game_type.dart';

/// Modelo de datos para una comunidad TCG
/// Incluye toda la información necesaria para mostrar comunidades en la UI
/// Actualizado para soportar las APIs de la Fase 2
class Community {
  final int id;
  final String name;
  final String description;

  // Fase 2: gameType ahora puede ser un objeto GameType o un string
  final dynamic gameType; // Puede ser GameType object o String
  final int gameTypeId; // ID del GameType para referencias

  final int memberCount;
  final String? imageUrl;
  final bool isSubscribed;
  final DateTime createdAt;

  // Fase 2: tags ahora son objetos CommunityTag dinámicos
  final List<dynamic> tags; // Puede ser List<String> o List<CommunityTag>

  final String difficultyLevel;
  final bool isPublic;
  final String? ownerUsername;

  const Community({
    required this.id,
    required this.name,
    required this.description,
    required this.gameType,
    required this.gameTypeId,
    required this.memberCount,
    this.imageUrl,
    required this.isSubscribed,
    required this.createdAt,
    required this.tags,
    required this.difficultyLevel,
    this.isPublic = true,
    this.ownerUsername,
  });

  /// Obtiene el nombre del game type como string
  String get gameTypeName {
    if (gameType is GameType) {
      return (gameType as GameType).name;
    } else if (gameType is String) {
      return gameType as String;
    }
    return 'Desconocido';
  }

  /// Obtiene los tags como lista de strings para compatibilidad
  List<String> get tagNames {
    return tags.map((tag) {
      if (tag is CommunityTag) {
        return tag.name;
      } else if (tag is String) {
        return tag;
      }
      return tag.toString();
    }).toList();
  }

  /// Obtiene los tags como objetos CommunityTag
  List<CommunityTag> get tagObjects {
    return tags.map((tag) {
      if (tag is CommunityTag) {
        return tag;
      } else if (tag is String) {
        return CommunityTag.fromString(tag);
      } else if (tag is Map<String, dynamic>) {
        return CommunityTag.fromJson(tag);
      }
      return CommunityTag.fromString(tag.toString());
    }).toList();
  }

  /// Constructor para crear una copia con campos modificados
  Community copyWith({
    int? id,
    String? name,
    String? description,
    dynamic gameType,
    int? gameTypeId,
    int? memberCount,
    String? imageUrl,
    bool? isSubscribed,
    DateTime? createdAt,
    List<dynamic>? tags,
    String? difficultyLevel,
    bool? isPublic,
    String? ownerUsername,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      gameType: gameType ?? this.gameType,
      gameTypeId: gameTypeId ?? this.gameTypeId,
      memberCount: memberCount ?? this.memberCount,
      imageUrl: imageUrl ?? this.imageUrl,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      isPublic: isPublic ?? this.isPublic,
      ownerUsername: ownerUsername ?? this.ownerUsername,
    );
  }

  /// Convierte el modelo a Map para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'game_type': gameType is GameType ? (gameType as GameType).id : gameType,
      'game_type_id': gameTypeId,
      'member_count': memberCount,
      'image_url': imageUrl,
      'is_subscribed': isSubscribed,
      'created_at': createdAt.toIso8601String(),
      'tags': tags.map((tag) {
        if (tag is CommunityTag) return tag.name;
        return tag.toString();
      }).toList(),
      'difficulty_level': difficultyLevel,
      'is_public': isPublic,
      'owner_username': ownerUsername,
    };
  }

  /// Crea un modelo desde Map JSON
  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      gameType: json['game_type'], // Puede ser string o object
      gameTypeId: json['game_type_id'] ?? json['game_type'] as int? ?? 0,
      memberCount: json['member_count'] as int,
      imageUrl: json['image_url'] as String?,
      isSubscribed: json['is_subscribed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      tags: json['tags'] as List? ?? [], // Mantener como dynamic
      difficultyLevel: json['difficulty_level'] as String? ?? 'medium',
      isPublic: json['is_public'] as bool? ?? true,
      ownerUsername: json['owner_username'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Community && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Community(id: $id, name: $name, gameType: $gameType, members: $memberCount)';
  }
}
