class UserRating {
  final int id;
  final User rater;
  final User ratedUser;
  final int rating;
  final String? comment;
  final String interactionType;
  final String? interactionReference;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  const UserRating({
    required this.id,
    required this.rater,
    required this.ratedUser,
    required this.rating,
    this.comment,
    required this.interactionType,
    this.interactionReference,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory UserRating.fromJson(Map<String, dynamic> json) {
    return UserRating(
      id: json['id'],
      rater: User.fromJson(json['rater']),
      ratedUser: User.fromJson(json['rated_user']),
      rating: json['rating'],
      comment: json['comment'],
      interactionType: json['interaction_type'],
      interactionReference: json['interaction_reference'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rater': rater.toJson(),
      'rated_user': ratedUser.toJson(),
      'rating': rating,
      'comment': comment,
      'interaction_type': interactionType,
      'interaction_reference': interactionReference,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  @override
  String toString() {
    return 'UserRating(id: $id, rating: $rating, rater: ${rater.username}, ratedUser: ${ratedUser.username})';
  }
}

class User {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final UserProfile? profile;

  const User({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.profile,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      email: json['email'],
      profile: json['profile'] != null
          ? UserProfile.fromJson(json['profile'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'profile': profile?.toJson(),
    };
  }

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }
}

class UserProfile {
  final int? id;
  final String? bio;
  final String? location;
  final String? profilePicture;
  final double reputationScore;
  final int reputationCount;
  final bool showEmail;
  final bool showCommunities;
  final DateTime? dateJoined;

  const UserProfile({
    this.id,
    this.bio,
    this.location,
    this.profilePicture,
    this.reputationScore = 0.0,
    this.reputationCount = 0,
    this.showEmail = false,
    this.showCommunities = true,
    this.dateJoined,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      bio: json['bio'],
      location: json['location'],
      profilePicture: json['profile_picture'],
      reputationScore: (json['reputation_score'] ?? 0.0).toDouble(),
      reputationCount: json['reputation_count'] ?? 0,
      showEmail: json['show_email'] ?? false,
      showCommunities: json['show_communities'] ?? true,
      dateJoined: json['date_joined'] != null
          ? DateTime.parse(json['date_joined'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bio': bio,
      'location': location,
      'profile_picture': profilePicture,
      'reputation_score': reputationScore,
      'reputation_count': reputationCount,
      'show_email': showEmail,
      'show_communities': showCommunities,
      'date_joined': dateJoined?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    int? id,
    String? bio,
    String? location,
    String? profilePicture,
    double? reputationScore,
    int? reputationCount,
    bool? showEmail,
    bool? showCommunities,
    DateTime? dateJoined,
  }) {
    return UserProfile(
      id: id ?? this.id,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      profilePicture: profilePicture ?? this.profilePicture,
      reputationScore: reputationScore ?? this.reputationScore,
      reputationCount: reputationCount ?? this.reputationCount,
      showEmail: showEmail ?? this.showEmail,
      showCommunities: showCommunities ?? this.showCommunities,
      dateJoined: dateJoined ?? this.dateJoined,
    );
  }

  /// Convierte el score de reputación a estrellas (1-5)
  int get starsRating {
    return (reputationScore.clamp(1.0, 5.0)).round();
  }

  /// Texto descriptivo del nivel de reputación
  String get reputationLevel {
    if (reputationScore >= 4.5) return 'Excelente';
    if (reputationScore >= 4.0) return 'Muy Bueno';
    if (reputationScore >= 3.5) return 'Bueno';
    if (reputationScore >= 3.0) return 'Regular';
    if (reputationScore >= 2.0) return 'Mejorable';
    return 'Nuevo';
  }
}
