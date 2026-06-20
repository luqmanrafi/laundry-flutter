import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../models/invoice.dart';
import '../models/user.dart';
import '../models/service.dart';
import '../repositories/order_repository.dart';
import '../utils/order_flow_controller.dart'; 

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repository = OrderRepository();
  
  List<Service> _services = [];
  List<Order> _myOrders = [];
  List<Order> _activeOrders = []; // Cache lokal untuk pesanan aktif
  Order? _currentOrder; 
  bool _isLoading = false;

  List<Service> get services => _services;
  List<Order> get myOrders => _myOrders;
  List<Order> get activeOrders => _activeOrders;
  Order? get currentOrder => _currentOrder; // Getter untuk detail order
  bool get isLoading => _isLoading;

  Future<void> loadServices() async {
    _setLoading(true);
    _services = await _repository.fetchServices();
    _setLoading(false);
  }

  Future<void> loadMyOrders(String userId) async {
    _setLoading(true);
    try {
      _myOrders = await _repository.fetchOrdersForUser(userId);
      // Suntikkan pesanan aktif dari memori lokal (workaround untuk remote backend)
      for (var active in _activeOrders) {
        if (!_myOrders.any((o) => o.id == active.id)) {
          _myOrders.add(active);
        }
      }
    } catch (e) {
      print("🚨 Log Master: Route GET list orders gagal / belum siap (Status 404 ignored): $e");
      _myOrders = List.from(_activeOrders);
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Order>> loadCourierHistory() async {
    _setLoading(true);
    try {
      final history = await _repository.fetchCourierHistory();
      _myOrders = history;
      // Suntikkan pesanan aktif dari memori lokal (workaround untuk remote backend)
      for (var active in _activeOrders) {
        if (!_myOrders.any((o) => o.id == active.id)) {
          _myOrders.add(active);
        }
      }
      return _myOrders;
    } catch (e) {
      print("Error loadCourierHistory: $e");
      _myOrders = List.from(_activeOrders);
      return _myOrders;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadOrderDetail(String orderId) async {
    _setLoading(true);
    try {
      final result = await _repository.fetchOrderDetail(orderId);
      if (result != null) {
        final existingIdx = _myOrders.indexWhere((o) => o.id == orderId);
        if (existingIdx != -1) {
          final existing = _myOrders[existingIdx];
          _currentOrder = Order(
            id: result.id,
            customer: User(
              id: result.customer.id,
              name: existing.customer.name != 'Pelanggan Anonim' ? existing.customer.name : result.customer.name,
              email: result.customer.email,
              phone: result.customer.phone,
              role: result.customer.role,
            ),
            courier: result.courier,
            service: result.service,
            pickupDate: result.pickupDate,
            pickupAddress: result.pickupAddress,
            weight: result.weight,
            status: result.status,
            paymentStatus: result.paymentStatus,
            invoice: result.invoice,
            latitude: result.latitude,
            longitude: result.longitude,
            ongkir: result.ongkir > 0 ? result.ongkir : existing.ongkir,
            courierLatitude: result.courierLatitude,
            courierLongitude: result.courierLongitude,
            jarakMeter: existing.jarakMeter ?? result.jarakMeter,
          );
        } else {
          _currentOrder = result;
        }
       
        OrderFlowController.status.value = result.status;
      }
    } catch (e) {
      print(" Error di Provider pas load detail order: $e");
    } finally {
      _setLoading(false);
    }
  }
  
  Future<bool> createNewOrder({
    required String serviceId,
    required String serviceName,
    required String notes,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    _setLoading(true);
    
    if (!dotenv.isInitialized) {
      await dotenv.load();
    }

    final baseUrl = dotenv.env['API_URL'];
    final url = Uri.parse("$baseUrl/orders");

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token') ?? '';
      final savedUserId = prefs.getString('user_id') ?? '';

      final cleanServiceId = serviceId.replaceAll(RegExp(r'[^0-9]'), '');
      final int finalServiceId = int.tryParse(cleanServiceId) ?? 1; 

      print("=================== INFO PAYLOAD FLUTTER ===================");
      print(" URL API          : $url");
      print(" USER ID (UUID)   : $savedUserId");
      print(" ID SERVICE (AUTO): $finalServiceId ");
      print(" KOORDINAT LAT    : $latitude");
      print(" KOORDINAT LONG   : $longitude");
      print(" Status           : Mengirim via AUTOMATIC PURE INT JSON...");
      print("============================================================");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer ${savedToken.trim()}", 
        },
        body: jsonEncode({
          "userId": savedUserId,
          "user_id": savedUserId,
          
          "serviceId": finalServiceId,
          "service_id": finalServiceId,
          
          "layanan": {
            "id": finalServiceId,
            "name": serviceName,
            "nama": serviceName,
          },

          "deskripsi": notes.isEmpty ? 'null' : notes,
          "description": notes.isEmpty ? 'null' : notes,
          "pickupAddress": address,
          "address": address,
          
          "lokasiPenjemputan": {
            "type": "Point",
            "coordinates": [longitude, latitude] 
          },
          "lokasi": {
            "type": "Point",
            "coordinates": [longitude, latitude]
          },
          
          "latitude": latitude,
          "longitude": longitude
        }),
      );

      print("STATUS RESPONS LARAVEL: ${response.statusCode}");
      print("BODY RESPONS LARAVEL  : ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Jika data API response me-return object order baru, simpan ke currentOrder
        try {
          final decoded = jsonDecode(response.body);
          final rawData = (decoded is Map && decoded.containsKey('data')) ? decoded['data'] : null;
          if (rawData != null && rawData is Map<String, dynamic>) {
            _currentOrder = Order.fromJson(rawData);
          }
        } catch (_) {}

        await loadMyOrders(savedUserId);
        return true;
      }
      return false;
    } catch (e) {
      print("CRASH ERROR KONEKSI DI PROVIDER: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateStatus(String orderId, OrderStatus newStatus, {double? weight, double? price, double? finalTotalPrice, String? notes}) async {
    _setLoading(true);
    final success = await _repository.updateOrderStatus(orderId, newStatus, weight: weight, price: price, finalTotalPrice: finalTotalPrice, notes: notes);
    if (success) {
      if (weight != null && price != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('mock_weight_$orderId', weight);
        await prefs.setDouble('mock_price_$orderId', price);
        await prefs.setInt('mock_total_$orderId', finalTotalPrice != null ? finalTotalPrice.round() : (weight * price).round());
      }
      
      // Update data di dalam list local biar UI gak perlu fetch ulang total
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
          weight: weight ?? o.weight,
          invoice: finalTotalPrice != null ? Invoice(id: 'mock', orderId: orderId, weight: weight!, pricePerKg: price!.round(), totalPrice: finalTotalPrice.round(), createdAt: DateTime.now()) : o.invoice,
        );
      }
      
      // Jika order yang sedang dibuka di screen detail adalah order ini, update juga datanya
      if (_currentOrder != null && _currentOrder!.id == orderId) {
        _currentOrder = Order(
          id: _currentOrder!.id,
          customer: _currentOrder!.customer,
          service: _currentOrder!.service,
          pickupDate: _currentOrder!.pickupDate,
          pickupAddress: _currentOrder!.pickupAddress,
          status: newStatus,
          courier: _currentOrder!.courier,
          weight: weight ?? _currentOrder!.weight,
          invoice: finalTotalPrice != null ? Invoice(id: 'mock', orderId: orderId, weight: weight!, pricePerKg: price!.round(), totalPrice: finalTotalPrice.round(), createdAt: DateTime.now()) : _currentOrder!.invoice,
        );
        OrderFlowController.status.value = newStatus;
        
        // Simpan ke daftar pesanan aktif lokal
        _activeOrders.removeWhere((o) => o.id == orderId);
        if (newStatus != OrderStatus.selesai && newStatus != OrderStatus.cancelled) {
          _activeOrders.add(_currentOrder!);
        }
      }
    }
    _setLoading(false);
    return success;
  }

  Future<void> refreshCurrentOrder() async {
    if (_currentOrder != null) {
      await loadOrderDetail(_currentOrder!.id);
    }
  }

  Future<String?> payOrder(String orderId, double amount) async {
    _setLoading(true);
    try {
      final paymentUrl = await _repository.payOrder(orderId, amount);
      if (paymentUrl != null) {
        // Optimistically update the UI to assume they are about to pay, 
        // though realistically the backend midtrans webhook will confirm payment.
        // For testing purposes we keep the mock local update if they want instant feedback
      }
      return paymentUrl;
    } catch (e) {
      print("Gagal generate payment midtrans: $e");
      return null;
    } finally {
      _setLoading(false);
    }
  }
  Future<bool> takeOrder(String orderId) async {
    _setLoading(true);
    bool success = false;
    try {
      success = await _repository.takeOrder(orderId);
    } catch (e) {
      print("⚠️ Backend take order error: $e");
    }
    
    if (success) {
      // Perbarui status secara lokal menjadi kurir_menuju_lokasi
      if (_currentOrder != null && _currentOrder!.id == orderId) {
        _currentOrder = Order(
          id: _currentOrder!.id,
          customer: _currentOrder!.customer,
          service: _currentOrder!.service,
          pickupDate: _currentOrder!.pickupDate,
          pickupAddress: _currentOrder!.pickupAddress,
          status: OrderStatus.kurir_menuju_lokasi,
          courier: _currentOrder!.courier,
          weight: _currentOrder!.weight,
          invoice: _currentOrder!.invoice,
          latitude: _currentOrder!.latitude,
          longitude: _currentOrder!.longitude,
          jarakMeter: _currentOrder!.jarakMeter,
        );
        OrderFlowController.status.value = OrderStatus.kurir_menuju_lokasi;
        
        // Tambahkan ke cache lokal order aktif
        _activeOrders.removeWhere((o) => o.id == orderId);
        _activeOrders.add(_currentOrder!);
      }

      final index = _myOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final o = _myOrders[index];
        _myOrders[index] = Order(
          id: o.id,
          customer: o.customer,
          service: o.service,
          pickupDate: o.pickupDate,
          pickupAddress: o.pickupAddress,
          status: OrderStatus.kurir_menuju_lokasi,
          courier: o.courier,
          weight: o.weight,
          invoice: o.invoice,
          latitude: o.latitude,
          longitude: o.longitude,
          jarakMeter: o.jarakMeter,
        );
        
        // Pastikan juga tersimpan di cache memori lokal meskipun diambil dari homescreen
        _activeOrders.removeWhere((x) => x.id == orderId);
        _activeOrders.add(_myOrders[index]);
      }
      notifyListeners();
    }
    _setLoading(false);
    return success;
  }


  void simulateIncomingMockOrder() {
    final mockOrder = Order(
      id: '99',
      customer: User(id: 'customer-1', name: 'John Doe', email: 'john@example.com', role: UserRole.pelanggan),
      service: _services.isNotEmpty ? _services.first : Service(id: '1', name: 'Cuci Reguler', pricePerKg: 5000, description: 'Estimasi 2 hari'),
      pickupDate: DateTime.now(),
      pickupAddress: 'Jl. Ahmad Yani No. 10, Lamongan',
      status: OrderStatus.pending,
      latitude: -7.1186128,
      longitude: 112.4110956,
    );
    
    // Cegah duplikasi jika dipanggil berkali-kali
    if (!_myOrders.any((o) => o.id == '99')) {
      _myOrders.insert(0, mockOrder);
      notifyListeners();
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}