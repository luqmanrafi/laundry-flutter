import '../models/order.dart';
import '../models/service.dart';
import '../utils/dummy_data.dart';

class OrderRepository {
  // TODO(Backend): Replace with real API GET request (e.g. http.get('/services'))
  Future<List<Service>> fetchServices() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return dummyServices;
  }

  // TODO(Backend): Replace with real API POST request (e.g. http.post('/orders'))
  Future<Order> createOrder(Order order) async {
    await Future.delayed(const Duration(seconds: 1));
    return order; // Backend should assign the real ID
  }

  // TODO(Backend): Replace with real API GET request (e.g. http.get('/orders?user_id=...'))
  Future<List<Order>> fetchOrdersForUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return dummyOrders.where((o) => o.customer.id == userId || (o.courier != null && o.courier!.id == userId)).toList();
  }

  // TODO(Backend): Replace with real API PUT request (e.g. http.put('/orders/$orderId/status'))
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await Future.delayed(const Duration(seconds: 1));
    return true; // Simulate success
  }
}
