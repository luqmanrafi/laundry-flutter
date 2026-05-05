
class Invoice {
  final String id;
  final String orderId;
  final double weight;
  final double pricePerKg;
  final double totalPrice;
  final DateTime createdAt;

  Invoice({
    required this.id,
    required this.orderId,
    required this.weight,
    required this.pricePerKg,
    required this.totalPrice,
    required this.createdAt,
  });
}
