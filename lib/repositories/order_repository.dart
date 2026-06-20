import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../models/order.dart';
import '../models/service.dart';

class OrderRepository {

  Future<List<Service>> fetchServices() async {
    if (!dotenv.isInitialized) await dotenv.load();
    final baseUrl = dotenv.env['API_URL'];
    final url = Uri.parse("$baseUrl/services"); 

    try {
      print("📡 Menembak GET Services ke: $url");
      final response = await http.get(url, headers: {
        "Accept": "application/json",
        "ngrok-skip-browser-warning": "69420",
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
      print(" Error fetch services dari backend: $e");
      return [];
    }
  }

  Future<List<Order>> fetchOrdersForUser(String userId) async {
    if (!dotenv.isInitialized) await dotenv.load();
    final baseUrl = dotenv.env['API_URL'];
    
    double lat = -7.1286128;
    double lng = 112.4210956;
    
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 2),
        );
        if (position.latitude >= -11.0 && position.latitude <= 6.0 &&
            position.longitude >= 95.0 && position.longitude <= 141.0) {
          lat = position.latitude;
          lng = position.longitude;
        }
      }
    } catch (e) {
      print("⚠️ Gagal mengambil koordinat riil GPS perangkat: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? '';

    print("🔑 DEBUG ROLE DARI PREFS: '$role'");

    // Kurir memanggil /pickup, Pelanggan memanggil /history
    final Uri url = role == 'kurir' 
        ? Uri.parse("$baseUrl/pickup?latitude=$lat&longitude=$lng")
        : Uri.parse("$baseUrl/history"); 

    try {
      final savedToken = prefs.getString('auth_token') ?? '';

      print("📡 Menembak Express API ke URL: $url");

      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer ${savedToken.trim()}", // Token jwt kurir/pelanggan
          "ngrok-skip-browser-warning": "69420",
        },
      );

      print(" RESPONS LIST ORDER EXPRESS [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> listOrderRaw = [];

        // Bongkar bungkusan array dari controller Express-mu
        if (decoded is Map<String, dynamic>) {
          listOrderRaw = decoded['data'] ?? decoded['orders'] ?? decoded['pickup'] ?? [];
        } else if (decoded is List) {
          listOrderRaw = decoded;
        }

        return listOrderRaw.map((json) {
          final order = Order.fromJson(json);
          if (order.jarakMeter == null && order.latitude != null && order.longitude != null) {
            order.jarakMeter = Geolocator.distanceBetween(lat, lng, order.latitude!, order.longitude!);
          }
          return order;
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Order>> fetchCourierHistory() async {
    if (!dotenv.isInitialized) await dotenv.load();
    final baseUrl = dotenv.env['API_URL'];
    final url = Uri.parse("$baseUrl/courier/history"); 

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token') ?? '';

      print("📡 Menembak GET History (Courier) ke: $url");
      final response = await http.get(
        url,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer ${savedToken.trim()}",
          "ngrok-skip-browser-warning": "69420",
        },
      );

      print(" RESPONS GET COURIER HISTORY [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> listOrderRaw = [];
        if (decoded is Map<String, dynamic>) {
          listOrderRaw = decoded['data'] ?? decoded['orders'] ?? [];
        } else if (decoded is List) {
          listOrderRaw = decoded;
        }

        return listOrderRaw.map((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print("Error Fetch Courier History: $e");
      return [];
    }
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus, {double? weight, double? price, double? finalTotalPrice, String? notes}) async {
    if (!dotenv.isInitialized) await dotenv.load();
    final baseUrl = dotenv.env['API_URL'];
    
    Uri url = Uri.parse("$baseUrl/orders/$orderId/status");

    // Jika kurir memasukkan berat, arahkan ke endpoint input-berat
    if (newStatus == OrderStatus.dibawa_kurir_ke_laundry && weight != null) {
      url = Uri.parse("$baseUrl/orders/$orderId/input-berat");
    } else if (newStatus == OrderStatus.proses_pengantaran) {
      // Jika kurir mau mengantar pesanan, arahkan ke endpoint antar untuk nge-claim ordernya kembali
      url = Uri.parse("$baseUrl/orders/$orderId/antar");
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token') ?? '';

      final String statusString = newStatus.name;

      print(" Menembak PUT Update Status ke: $url dengan data: status=$statusString, weight=$weight, price=$price, finalTotalPrice=$finalTotalPrice, notes=$notes");

      final double? computedTotal = finalTotalPrice ?? ((weight != null && price != null) ? (weight * price) : null);

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer ${savedToken.trim()}",
        },
        body: jsonEncode({
          "status": statusString, 
          if (weight != null) "berat": weight,
          if (weight != null) "weight": weight,
          if (price != null) ...{
            "harga": price,
            "price": price,
            "harga_per_kg": price,
          },
          if (computedTotal != null) ...{
            "total": computedTotal,
            "total_price": computedTotal,
            "totalPrice": computedTotal.round(),
            "total_biaya": computedTotal.round(),
            "totalBiaya": computedTotal.round(),
            "total_bayar": computedTotal.round(),
            "totalBayar": computedTotal.round(),
          },
          if (notes != null && notes.isNotEmpty) ...{
            "catatan": notes,
            "notes": notes,
            "deskripsi": notes,
            "description": notes,
          }
        }),
      );

      print(" RESPONS UPDATE STATUS [${response.statusCode}]: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print(" Error Update Status Repo: $e");
      return false;
    }
  }

  Future<bool> takeOrder(String orderId) async {
    if (!dotenv.isInitialized) await dotenv.load();
    final baseUrl = dotenv.env['API_URL'];
    final url = Uri.parse("$baseUrl/orders/$orderId/take");

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token') ?? '';

      print("📡 Menembak PUT Take Order ke: $url");
      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer ${savedToken.trim()}",
        },
      );

      print(" RESPONS TAKE ORDER [${response.statusCode}]: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print(" Error Take Order Repo: $e");
      return false;
    }
  }

  Future<Order?> fetchOrderDetail(String orderId) async {
    // Bypass untuk Mock Order 99
    if (orderId == '99') {
      return null; // Akan langsung jatuh ke fallback cache di Provider/UI
    }

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
          "ngrok-skip-browser-warning": "69420",
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
      print(" Error Fetch Detail Order: $e");
      return null;
    }
  }

  Future<String?> payOrder(String orderId, double amount) async {
    if (!dotenv.isInitialized) await dotenv.load();
    final baseUrl = dotenv.env['API_URL'];
    final url = Uri.parse("$baseUrl/orders/$orderId/pay"); 

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token') ?? '';

      print("📡 Menembak POST Pay Order ke: $url dengan amount $amount");
      final response = await http.post(
        url, 
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer ${savedToken.trim()}",
          "ngrok-skip-browser-warning": "69420",
        },
        body: jsonEncode({
          "amount": amount.round(),
          "gross_amount": amount.round(),
          "total_biaya": amount.round(),
          "total": amount.round(),
        }),
      );

      print(" RESPONS PAY ORDER [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          final data = decoded['data'];
          if (data is Map<String, dynamic> && data.containsKey('payment_url')) {
            return data['payment_url'] as String;
          }
        }
      }
      return null;
    } catch (e) {
      print(" Error Pay Order Repo: $e");
      return null;
    }
  }
}