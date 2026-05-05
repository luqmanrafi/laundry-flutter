import 'service.dart';
import 'user.dart';
import 'invoice.dart';

enum OrderStatus {
  pending,
  pickup,
  waitingConfirmation,
  processing,
  delivery,
  completed,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.pickup:
        return 'Pickup';
      case OrderStatus.waitingConfirmation:
        return 'Menunggu Konfirmasi';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.delivery:
        return 'Delivery';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
    }
  }

  bool get isTerminal =>
      this == OrderStatus.completed || this == OrderStatus.cancelled;
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
}

const List<OrderStatus> kOrderStatusFlow = [
  OrderStatus.pending,
  OrderStatus.pickup,
  OrderStatus.waitingConfirmation,
  OrderStatus.processing,
  OrderStatus.delivery,
  OrderStatus.completed,
];

bool canMoveToNextStatus(OrderStatus current, OrderStatus next) {
  if (current.isTerminal) return false;
  if (next == OrderStatus.cancelled) return true;

  final currentIndex = kOrderStatusFlow.indexOf(current);
  final nextIndex = kOrderStatusFlow.indexOf(next);
  if (currentIndex < 0 || nextIndex < 0) return false;

  return nextIndex == currentIndex + 1;
}
