import 'service.dart';
import 'user.dart';
import 'invoice.dart';

// 1. ENUM STATUS BARU (SUDAH SINKRON SAKLEK SAMA DATABASE LARAVEL BACKEND)
enum OrderStatus {
  pending,
  dibawa_kurir_ke_laundry,
  sedang_dicuci,
  siap_dikirim,
  proses_pengantaran,
  selesai,
  cancelled // Kita tambahkan cancelled buat jaga-jaga fitur pembatalan
}

// Fungsi helper buat convert String backend ke Enum Flutter
OrderStatus parseStatus(String status) {
  switch (status) {
    case 'dibawa_kurir_ke_laundry': return OrderStatus.dibawa_kurir_ke_laundry;
    case 'sedang_dicuci': return OrderStatus.sedang_dicuci;
    case 'siap_dikirim': return OrderStatus.siap_dikirim;
    case 'proses_pengantaran': return OrderStatus.proses_pengantaran;
    case 'selesai': return OrderStatus.selesai;
    case 'cancelled': return OrderStatus.cancelled;
    default: return OrderStatus.pending;
  }
}

// 2. EXTENSION UNTUK LABEL UI (SUDAH DISINKRONKAN!)
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

  // Logika terminal penentu status akhir agar canMoveToNextStatus tidak error
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

  // =======================================================================
  // SENJATA TAMBAHAN: DECODER JSON DARI BACKEND LARAVEL REAL-TIME
  // Map variabel lokal Flutter ke key JSON asli milik backend-mu!
  // =======================================================================
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'].toString(),
      pickupAddress: json['alamatPenjemputan'] ?? json['pickupAddress'] ?? '',
      status: parseStatus(json['status'] ?? 'pending'),
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
      
      // Mengamankan parsing Object Relation demi menghindari crash data null
      customer: User.fromJson(json['customer'] ?? json['user'] ?? {}),
      courier: json['courier'] != null ? User.fromJson(json['courier']) : null,
      service: Service.fromJson(json['layanan'] ?? json['service'] ?? {}),
      
      // Parsing format ISO String DateTime dari database MySQL
      pickupDate: DateTime.parse(json['createdAt'] ?? json['updatedAt'] ?? DateTime.now().toString()),
      invoice: json['invoice'] != null ? Invoice.fromJson(json['invoice']) : null,
    );
  }
}

// 3. SEKUENS ALUR VALIDASI (DISUAIKAN SAKLEK DENGAN ARRAY BACKEND JALUR LOGIS)
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