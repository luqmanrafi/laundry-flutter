import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order.dart';
import '../models/service.dart';
import '../repositories/order_repository.dart';
import '../utils/order_flow_controller.dart'; // Impor flow controller untuk auto-sync status global

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repository = OrderRepository();
  
  List<Service> _services = [];
  List<Order> _myOrders = [];
  Order? _currentOrder; // 1. Variabel baru penampung detail order yang sedang aktif dilihat
  bool _isLoading = false;

  List<Service> get services => _services;
  List<Order> get myOrders => _myOrders;
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
    } catch (e) {
      print("🚨 Log Master: Route GET list orders gagal / belum siap (Status 404 ignored): $e");
      _myOrders = [];
    } finally {
      _setLoading(false);
    }
  }

  // =======================================================================
  // 2. FUNGSI BARU: AMBIL DETAIL ORDER REAL-TIME DARI BACKEND LARAVEL
  // =======================================================================
  Future<void> loadOrderDetail(String orderId) async {
    _setLoading(true);
    try {
      final result = await _repository.fetchOrderDetail(orderId);
      if (result != null) {
        _currentOrder = result;
        
        // Otomatis sinkronkan status state global agar stepper UI ikut melompat maju!
        OrderFlowController.status.value = result.status;
      }
    } catch (e) {
      print("❌ Error di Provider pas load detail order: $e");
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
      print("🚀 URL API          : $url");
      print("👤 USER ID (UUID)   : $savedUserId");
      print("🧺 ID SERVICE (AUTO): $finalServiceId ");
      print("📍 KOORDINAT LAT    : $latitude");
      print("📍 KOORDINAT LONG   : $longitude");
      print("📡 Status           : Mengirim via AUTOMATIC PURE INT JSON...");
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

      print("🚨 STATUS RESPONS LARAVEL: ${response.statusCode}");
      print("📦 BODY RESPONS LARAVEL  : ${response.body}");

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
      print("❌ CRASH ERROR KONEKSI DI PROVIDER: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateStatus(String orderId, OrderStatus newStatus) async {
    _setLoading(true);
    final success = await _repository.updateOrderStatus(orderId, newStatus);
    if (success) {
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
          weight: o.weight,
          invoice: o.invoice,
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
          weight: _currentOrder!.weight,
          invoice: _currentOrder!.invoice,
        );
        OrderFlowController.status.value = newStatus;
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