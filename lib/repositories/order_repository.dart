import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/service.dart';

class OrderRepository {

  // =======================================================================
  // 1. FETCH SERVICES (SUDAH AMAN & ANTIMUNTAH)
  // =======================================================================
  Future<List<Service>> fetchServices() async {
    if (!dotenv.isInitialized) await dotenv.load();
    final baseUrl = dotenv.env['API_URL'];
    final url = Uri.parse("$baseUrl/services"); 

    try {
      print("📡 Menembak GET Services ke: $url");
      final response = await http.get(url, headers: {
        "Accept": "application/json",
      });
      
      print("🚨 RESPONS GET SERVICES: ${response.statusCode} -> ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> listLayanan = [];

        if (decoded is Map<String, dynamic>) {
          listLayanan = decoded['data'] ?? decoded['services'] ?? decoded['layanan'] ?? [];
        } else if (decoded is List) {
          listLayanan = decoded;
        }

        return listLayanan.map((json) => Service.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("❌ Error fetch services dari backend: $e");
      return [];
    }
  }

  // =======================================================================
  // 2. FETCH LIST ORDERS (REAL BACKEND - ANTI DUMMY!)
  // =======================================================================
  Future<List<Order>> fetchOrdersForUser(String userId) async {
    if (!dotenv.isInitialized) await dotenv.load();
    final baseUrl = dotenv.env['API_URL'];
    
    // SINKRON SAKLEK: GET /api/orders?user_id=UUID
    final url = Uri.parse("$baseUrl/orders?user_id=$userId"); 

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token') ?? '';

      print("📡 Menembak GET List Order ke: $url");

      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer ${savedToken.trim()}", 
        },
      );

      print("🚨 RESPONS LIST ORDER BACKEND [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> listOrderRaw = [];

        // Antisipasi bungkus Map data dari Laravel
        if (decoded is Map<String, dynamic>) {
          listOrderRaw = decoded['data'] ?? decoded['orders'] ?? [];
        } else if (decoded is List) {
          listOrderRaw = decoded;
        }

        return listOrderRaw.map((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("❌ Error Fetch Orders User dari backend: $e");
      return [];
    }
  }

  // =======================================================================
  // 3. UPDATE STATUS PESANAN (DINAMIS MENGIKUTI ALUR STATUS BACKEND)
  // =======================================================================
  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    if (!dotenv.isInitialized) await dotenv.load();
    final baseUrl = dotenv.env['API_URL'];
    
    // Jalur Restful API Update Status
    final url = Uri.parse("$baseUrl/orders/$orderId/status");

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token') ?? '';

      // Ambil string asli enum (misal: 'sedang_dicuci' atau 'siap_dikirim')
      final String statusString = newStatus.name;

      print("📡 Menembak PUT Update Status ke: $url dengan data: $statusString");

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer ${savedToken.trim()}",
        },
        body: jsonEncode({
          "status": statusString, 
        }),
      );

      print(" RESPONS UPDATE STATUS [${response.statusCode}]: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print(" Error Update Status Repo: $e");
      return false;
    }
  }

  // =======================================================================
  // 4. FETCH DETAIL ORDER (SUDAH MATANG RESTFUL API)
  // =======================================================================
  Future<Order?> fetchOrderDetail(String orderId) async {
    if (!dotenv.isInitialized) await dotenv.load();
    final baseUrl = dotenv.env['API_URL'];
    final url = Uri.parse("$baseUrl/orders/$orderId"); 

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token') ?? '';

      print("📡 Menembak GET Detail Order ke: $url");
      final response = await http.get(
        url, 
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer ${savedToken.trim()}",
        },
      );

      print(" RESPONS GET DETAIL ORDER [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        final Map<String, dynamic> orderJson = (decoded is Map && decoded.containsKey('data')) 
            ? decoded['data'] 
            : decoded;

        return Order.fromJson(orderJson);
      }
      return null;
    } catch (e) {
      print("❌ Error fetch detail order dari backend: $e");
      return null;
    }
  }
}