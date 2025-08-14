/// Modelo de datos para un usuario de la aplicación
/// Representa la información del usuario autenticado
class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final DateTime dateJoined;
  final bool isEmailVerified;
  final String? avatar; // Para futura implementación de avatares

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.dateJoined,
    required this.isEmailVerified,
    this.avatar,
  });

  /// Nombre completo del usuario
  String get fullName {
    final first = firstName.trim();
    final last = lastName.trim();
    if (first.isEmpty && last.isEmpty) return username;
    if (first.isEmpty) return last;
    if (last.isEmpty) return first;
    return '$first $last';
  }

  /// Iniciales para el avatar placeholder
  String get initials {
    final first = firstName.trim();
    final last = lastName.trim();

    if (first.isEmpty && last.isEmpty) {
      return username.isNotEmpty ? username.substring(0, 1).toUpperCase() : 'U';
    }

    final firstInitial = first.isNotEmpty ? first.substring(0, 1) : '';
    final lastInitial = last.isNotEmpty ? last.substring(0, 1) : '';

    return '$firstInitial$lastInitial'.toUpperCase();
  }

  /// Constructor desde JSON (respuesta de la API)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      dateJoined: DateTime.parse(json['date_joined']),
      isEmailVerified: json['is_email_verified'] ?? false,
      avatar: json['avatar'],
    );
  }

  /// Convertir a JSON para envío a API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'date_joined': dateJoined.toIso8601String(),
      'is_email_verified': isEmailVerified,
      'avatar': avatar,
    };
  }

  /// Constructor para crear una copia con campos modificados
  User copyWith({
    int? id,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    DateTime? dateJoined,
    bool? isEmailVerified,
    String? avatar,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateJoined: dateJoined ?? this.dateJoined,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      avatar: avatar ?? this.avatar,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, username: $username, email: $email, fullName: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
