enum UserRole { pelanggan, kurir } // <--- ADMIN RESMI DIBUANG DARI KASTA ENUM!

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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['nama'] ?? 'Anonymous',
      email: json['email'] ?? '',
      // Jika dari backend tiba-tiba ngirim string 'admin' (buat jaga-jaga), kita default-kan ke pelanggan saja biar gak crash
      role: json['role']?.toString().toLowerCase() == 'kurir' ? UserRole.kurir : UserRole.pelanggan,
      avatarUrl: json['avatarUrl'] ?? json['avatar_url'],
    );
  }
}