import 'service.dart';
import 'user.dart';
import 'invoice.dart';

// 1. ENUM STATUS (SINKRON SAKLEK SAMA DATABASE EXPRESS NODE.JS)
enum OrderStatus {
  pending,
  kurir_menuju_lokasi,
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
    case 'kurir_menuju_lokasi':
      return OrderStatus.kurir_menuju_lokasi;
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
      case OrderStatus.kurir_menuju_lokasi:
        return 'Menjemput Pesanan';
      case OrderStatus.dibawa_kurir_ke_laundry:
        return 'Dibawa ke Laundry';
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
  final String paymentStatus;
  final Invoice? invoice;
  final double? latitude;
  final double? longitude;
  final double ongkir;
  final double? courierLatitude;
  final double? courierLongitude;
  double? jarakMeter;

  Order({
    required this.id,
    required this.customer,
    this.courier,
    required this.service,
    required this.pickupDate,
    required this.pickupAddress,
    this.weight,
    required this.status,
    this.paymentStatus = 'unpaid',
    this.invoice,
    this.latitude,
    this.longitude,
    this.ongkir = 0.0,
    this.courierLatitude,
    this.courierLongitude,
    this.jarakMeter,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // A. Parsing data status riil dari string database Express ('menunggu_kurir')
    final String rawStatus = json['status']?.toString() ?? json['order_status']?.toString() ?? 'pending';
    final OrderStatus statusParsed = parseStatus(rawStatus);
    
    final String paymentStatusParsed = json['paymentStatus']?.toString() ?? json['payment_status']?.toString() ?? 'unpaid';

    // B. Ambil Ongkir Asli dari Backend Node.js
    final double ongkirReal = double.tryParse(json['ongkir']?.toString() ?? json['order_ongkir']?.toString() ?? '0.0') ?? 0.0;

    // C. Parsing Alamat & Koordinat Sakti (Anti Teks String "null" dari Express)
    String alamatSakti = 'Alamat Penjemputan';
    double? parsedLat;
    double? parsedLng;
    final dynamic lokasiObj = json['lokasiPenjemputan'] ?? json['order_lokasiPenjemputan'];
    if (lokasiObj != null && lokasiObj['coordinates'] != null) {
      final coords = lokasiObj['coordinates'] as List;
      alamatSakti = "Koordinat: ${coords[1]}, ${coords[0]}"; 
      parsedLat = double.tryParse(coords[1].toString());
      parsedLng = double.tryParse(coords[0].toString());
    }

    final String deskripsiRaw = json['deskripsi']?.toString() ?? json['order_deskripsi']?.toString() ?? '';
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
    final customerJson = json['user'] ?? json['User'] ?? json['pelanggan'] ?? json['Pelanggan'] ?? json['customer'] ?? json['Customer'];
    final parsedCustomer = customerJson != null 
        ? User.fromJson(customerJson)
        : User(
            id: json['userId']?.toString() ?? json['user_id']?.toString() ?? 'customer-id',
            name: json['userName']?.toString() ?? 
                  json['user_name']?.toString() ?? 
                  json['user_nama']?.toString() ?? 
                  json['namaPelanggan']?.toString() ?? 
                  json['nama_pelanggan']?.toString() ?? 
                  json['pelanggan_nama']?.toString() ?? 
                  json['customerName']?.toString() ?? 
                  json['customer_name']?.toString() ?? 
                  json['name']?.toString() ?? 
                  json['nama']?.toString() ?? 
                  'Pelanggan Anonim', 
            email: json['userEmail']?.toString() ?? 
                   json['user_email']?.toString() ?? 
                   json['customerEmail']?.toString() ?? 
                   json['customer_email']?.toString() ?? 
                   json['email']?.toString() ?? 
                   'pelanggan@laundry.com',
            role: UserRole.pelanggan,
          );

    // F. Parsing Koordinat Kurir (Real-Time Tracking support)
    double? parsedCourierLat;
    double? parsedCourierLng;
    final kurirData = json['kurir'] ?? json['courier'];
    if (kurirData != null && kurirData is Map) {
      parsedCourierLat = double.tryParse(kurirData['latitude']?.toString() ?? '');
      parsedCourierLng = double.tryParse(kurirData['longitude']?.toString() ?? '');
    }
    // Fallback jika dikirim langsung di object order
    parsedCourierLat ??= double.tryParse(json['courierLatitude']?.toString() ?? json['kurirLatitude']?.toString() ?? '');
    parsedCourierLng ??= double.tryParse(json['courierLongitude']?.toString() ?? json['kurirLongitude']?.toString() ?? '');

    return Order(
      id: json['id']?.toString() ?? json['order_id']?.toString() ?? '1',
      customer: parsedCustomer,
      courier: kurirData != null ? User.fromJson(kurirData as Map<String, dynamic>) : null,
      service: parsedService,
      pickupDate: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString()) 
          : DateTime.now(),
      pickupAddress: alamatFinal, 
      weight: double.tryParse(json['berat']?.toString() ?? json['order_berat']?.toString() ?? ''),
      status: statusParsed,
      paymentStatus: paymentStatusParsed,
      latitude: parsedLat,
      longitude: parsedLng,

     invoice: json['invoice'] != null 
          ? Invoice.fromJson(json['invoice']) 
          : Invoice(
              id: 'inv', 
              totalPrice: (double.tryParse(json['totalBiaya']?.toString() ?? '') ?? 
                          double.tryParse(json['total_biaya']?.toString() ?? '') ?? 
                          double.tryParse(json['hargaTotal']?.toString() ?? '') ?? 
                          0.0).toInt(), // JANGAN MENGGUNAKAN ONGKIR SEBAGAI TOTAL BIAYA LAUNDRY
              orderId: json['id']?.toString() ?? '1', 
              weight: double.tryParse(json['berat']?.toString() ?? '0.0') ?? 0.0, 
              pricePerKg: parsedService.pricePerKg, 
              createdAt: json['createdAt'] != null 
                  ? DateTime.parse(json['createdAt'].toString()) 
                  : DateTime.now(), 
            ),
      ongkir: ongkirReal.toDouble(),
      courierLatitude: parsedCourierLat,
      courierLongitude: parsedCourierLng,
      jarakMeter: double.tryParse(json['jarak_meter']?.toString() ?? ''),
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