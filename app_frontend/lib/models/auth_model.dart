class AuthUser {
  final int id;
  final String email;
  final String fullName;
  final bool isActive;

  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.isActive = true,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Reader',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}