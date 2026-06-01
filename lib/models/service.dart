// class Service {
//   final String id;
//   final String name;
//   final String description;
//   final int pricePerKg;
//   final String icon;

//   Service({
//     required this.id,
//     required this.name,
//     required this.description,
//     required this.pricePerKg,
//     required this.icon,
//   });

//   // Fungsi sakti untuk convert data dari API Laravel
//   factory Service.fromJson(Map<String, dynamic> json) {
//     return Service(
//       id: json['id'].toString(), // Ambil ID asli backend (dijamin aman mau int/string)
//       name: json['name'] ?? json['layanan'] ?? json['nama'] ?? 'Layanan',
//       description: json['description'] ?? json['deskripsi'] ?? '',
//       pricePerKg: json['pricePerKg'] ?? json['harga_per_kg'] ?? json['hargaPerkg'] ?? 0,
//       icon: json['icon'] ?? 'local_laundry_service',
//     );
//   }
// }

class Service {
  final String id;
  final String name;
  final int pricePerKg;
  final String description;
  final String? icon; // Kita kasih tanda tanya (?) biar opsional dan gak bikin error

  Service({
    required this.id,
    required this.name,
    required this.pricePerKg,
    required this.description,
    this.icon, // Tidak wajib diisi
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'].toString(),
      name: json['namaLayanan'] ?? 'Layanan',
      pricePerKg: json['hargaPerKg'] ?? 0,
      description: json['keterangan'] ?? '',
      icon: null, // Dari backend kosongin aja aman
    );
  }
}