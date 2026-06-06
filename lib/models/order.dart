import 'service.dart';
import 'user.dart';
import 'invoice.dart';

// 1. ENUM STATUS (SINKRON SAKLEK SAMA DATABASE EXPRESS NODE.JS)
enum OrderStatus {
  pending,
  dibawa_kurir_ke_laundry,
  sedang_dicuci,
  siap_dikirim,
  proses_pengantaran,
  selesai,
  cancelled 
}

// Fungsi helper buat convert String backend ke Enum Flutter
OrderStatus parseStatus(String status) {
  final raw = status.toLowerCase().trim();
  switch (raw) {
    case 'menunggu_kurir': 
      return OrderStatus.pending;
    case 'dibawa_kurir_ke_laundry': 
      return OrderStatus.dibawa_kurir_ke_laundry;
    case 'sedang_dicuci': 
      return OrderStatus.sedang_dicuci;
    case 'siap_dikirim': 
      return OrderStatus.siap_dikirim;
    case 'proses_pengantaran': 
      return OrderStatus.proses_pengantaran;
    case 'selesai': 
      return OrderStatus.selesai;
    case 'cancelled': 
      return OrderStatus.cancelled;
    default: 
      return OrderStatus.pending;
  }
}

// 2. EXTENSION UNTUK LABEL UI
extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Menunggu Kurir';
      case OrderStatus.dibawa_kurir_ke_laundry:
        return 'Membawa ke Laundry';
      case OrderStatus.sedang_dicuci:
        return 'Sedang Dicuci';
      case OrderStatus.siap_dikirim:
        return 'Siap Dikirim';
      case OrderStatus.proses_pengantaran:
        return 'Proses Pengantaran';
      case OrderStatus.selesai:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  bool get isTerminal =>
      this == OrderStatus.selesai || this == OrderStatus.cancelled;
}

class Order {
  final String id;
  final User customer; 
  final User? courier;
  final Service service; 
  final DateTime pickupDate;
  final String pickupAddress;
  final double? weight;
  final OrderStatus status;
  final Invoice? invoice;

  Order({
    required this.id,
    required this.customer,
    this.courier,
    required this.service,
    required this.pickupDate,
    required this.pickupAddress,
    this.weight,
    required this.status,
    this.invoice,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // A. Parsing data status riil dari string database Express ('menunggu_kurir')
    final String rawStatus = json['status']?.toString() ?? 'pending';
    final OrderStatus statusParsed = parseStatus(rawStatus);

    // B. Ambil Ongkir Asli dari Backend Node.js
    final int ongkirReal = int.tryParse(json['ongkir']?.toString() ?? '0') ?? 0;

    // C. Parsing Alamat & Koordinat Sakti (Anti Teks String "null" dari Express)
    String alamatSakti = 'Alamat Penjemputan';
    if (json['lokasiPenjemputan'] != null && json['lokasiPenjemputan']['coordinates'] != null) {
      final coords = json['lokasiPenjemputan']['coordinates'] as List;
      alamatSakti = "Koordinat: ${coords[1]}, ${coords[0]}"; 
    }

    final String deskripsiRaw = json['deskripsi']?.toString() ?? '';
    final String alamatFinal = (deskripsiRaw.isNotEmpty && deskripsiRaw != 'null')
        ? deskripsiRaw
        : alamatSakti;

    // D. Parsing relasi objek Model Service 
    final serviceJson = json['layanan'] ?? {};
    final parsedService = Service(
      id: serviceJson['id']?.toString() ?? json['serviceId']?.toString() ?? '1',
      name: serviceJson['namaLayanan']?.toString() ?? 'Paket Laundry',
      pricePerKg: int.tryParse(serviceJson['hargaPerKg']?.toString() ?? '') ?? 
                  int.tryParse(json['hargaPerkg']?.toString() ?? '') ?? 7000,
      description: serviceJson['keterangan']?.toString() ?? '',
      icon: null,
    );

    // E. Parsing relasi objek Model Customer Pelanggan
    final customerJson = json['user'];
    final parsedCustomer = customerJson != null 
        ? User.fromJson(customerJson)
        : User(
            id: json['userId']?.toString() ?? 'customer-id',
            name: 'Pelanggan Asli', 
            email: 'pelanggan@laundry.com',
            role: UserRole.pelanggan,
          );

    return Order(
      id: json['id']?.toString() ?? '1',
      customer: parsedCustomer,
      courier: json['kurir'] != null ? User.fromJson(json['kurir']) : null,
      service: parsedService,
      pickupDate: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString()) 
          : DateTime.now(),
      pickupAddress: alamatFinal, 
      weight: double.tryParse(json['berat']?.toString() ?? ''),
      status: statusParsed,

     invoice: json['invoice'] != null 
          ? Invoice.fromJson(json['invoice']) 
          : Invoice(
              id: 'inv', 
             
              totalPrice: ongkirReal, 
              orderId: json['id']?.toString() ?? '1', 
              weight: double.tryParse(json['berat']?.toString() ?? '0.0') ?? 0.0, 
              pricePerKg: parsedService.pricePerKg, 
              createdAt: json['createdAt'] != null 
                  ? DateTime.parse(json['createdAt'].toString()) 
                  : DateTime.now(), 
            ),
     
    );
  }
}

const List<OrderStatus> kOrderStatusFlow = [
  OrderStatus.pending,
  OrderStatus.dibawa_kurir_ke_laundry,
  OrderStatus.sedang_dicuci,
  OrderStatus.siap_dikirim,
  OrderStatus.proses_pengantaran,
  OrderStatus.selesai,
];

bool canMoveToNextStatus(OrderStatus current, OrderStatus next) {
  if (current.isTerminal) return false;
  if (next == OrderStatus.cancelled) return true;

  final currentIndex = kOrderStatusFlow.indexOf(current);
  final nextIndex = kOrderStatusFlow.indexOf(next);
  if (currentIndex < 0 || nextIndex < 0) return false;

  return nextIndex == currentIndex + 1;
}