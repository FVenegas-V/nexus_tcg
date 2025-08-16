/// Modelo para CommunityMembership basado en el serializer del backend
class CommunityMembership {
  final int id;
  final int userId;
  final String username;
  final int communityId;
  final String communityName;
  final String role;
  final String status;
  final DateTime joinedAt;
  final DateTime? lastActivity;

  const CommunityMembership({
    required this.id,
    required this.userId,
    required this.username,
    required this.communityId,
    required this.communityName,
    required this.role,
    required this.status,
    required this.joinedAt,
    this.lastActivity,
  });

  /// Crear CommunityMembership desde JSON (backend response)
  factory CommunityMembership.fromJson(Map<String, dynamic> json) {
    return CommunityMembership(
      id: json['id'] as int,
      userId: json['user_id'] ?? json['user'] as int,
      username: json['username'] ?? json['user_username'] as String,
      communityId: json['community_id'] ?? json['community'] as int,
      communityName: json['community_name'] ?? '',
      role: json['role'] as String,
      status: json['status'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'] as String)
          : null,
    );
  }

  /// Convertir CommunityMembership a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'username': username,
      'community_id': communityId,
      'community_name': communityName,
      'role': role,
      'status': status,
      'joined_at': joinedAt.toIso8601String(),
      'last_activity': lastActivity?.toIso8601String(),
    };
  }

  /// Verificar si es admin/moderador
  bool get isStaff => role == 'admin' || role == 'moderator';

  /// Verificar si es miembro activo
  bool get isActive => status == 'active';

  @override
  String toString() {
    return 'CommunityMembership(id: $id, user: $username, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommunityMembership && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
