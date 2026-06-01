class Invoice {
  final String id;
  final String orderId;
  final double weight;
  final int pricePerKg;
  final int totalPrice;
  final DateTime createdAt;

  Invoice({
    required this.id,
    required this.orderId,
    required this.weight,
    required this.pricePerKg,
    required this.totalPrice,
    required this.createdAt,
  });

  // =======================================================================
  // KUNCI SAKTI: TAMBAHKAN DECODER UNTUK NOTA INVOICE DARI BACKEND
  // =======================================================================
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? json['order_id']?.toString() ?? '',
      weight: double.tryParse(json['weight']?.toString() ?? '0.0') ?? 0.0,
      pricePerKg: json['pricePerKg'] ?? json['price_per_kg'] ?? json['hargaPerKg'] ?? 0,
      totalPrice: json['totalPrice'] ?? json['total_price'] ?? json['totalBayar'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at'] ?? DateTime.now().toString()),
    );
  }
}