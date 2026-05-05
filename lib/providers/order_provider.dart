import 'package:flutter/material.dart';
import '../models/order.dart';
import '../models/service.dart';
import '../repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repository = OrderRepository();
  
  List<Service> _services = [];
  List<Order> _myOrders = [];
  bool _isLoading = false;

  List<Service> get services => _services;
  List<Order> get myOrders => _myOrders;
  bool get isLoading => _isLoading;

  Future<void> loadServices() async {
    _setLoading(true);
    _services = await _repository.fetchServices();
    _setLoading(false);
  }

  Future<void> loadMyOrders(String userId) async {
    _setLoading(true);
    _myOrders = await _repository.fetchOrdersForUser(userId);
    _setLoading(false);
  }

  Future<bool> createNewOrder(Order order) async {
    _setLoading(true);
    final savedOrder = await _repository.createOrder(order);
    _myOrders.add(savedOrder);
    _setLoading(false);
    return true;
  }

  Future<bool> updateStatus(String orderId, OrderStatus newStatus) async {
    _setLoading(true);
    final success = await _repository.updateOrderStatus(orderId, newStatus);
    if (success) {
      final index = _myOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final o = _myOrders[index];
        _myOrders[index] = Order(
          id: o.id,
          customer: o.customer,
          service: o.service,
          pickupDate: o.pickupDate,
          pickupAddress: o.pickupAddress,
          status: newStatus,
          courier: o.courier,
          weight: o.weight,
          invoice: o.invoice,
        );
      }
    }
    _setLoading(false);
    return success;
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
