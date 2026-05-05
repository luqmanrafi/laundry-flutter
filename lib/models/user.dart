enum UserRole { pelanggan, kurir }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
  });
}
