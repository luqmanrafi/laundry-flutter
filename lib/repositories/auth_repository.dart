import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user.dart';

class AuthRepository {
  
  Future<Map<String, dynamic>?> login(String email, String password) async {
    if (!dotenv.isInitialized) {
      await dotenv.load();
    }

    final baseUrl = dotenv.env['API_URL'];
    final url = Uri.parse("$baseUrl/auth/login");

    try {
      print("Menembak API Login ke: $url");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      print("Jawaban Mentah Backend: ${response.statusCode} -> ${response.body}");

      if (response.statusCode == 200) {
       
        return jsonDecode(response.body);
      }
      
      return null;
    } catch (e) {
      print("Error Jaringan di AuthRepository: $e");
      return null;
    }
  }

  // 2. REGISTER REAL-TIME
  Future<User?> register(String name, String email, String password, UserRole role) async {
    if (!dotenv.isInitialized) {
      await dotenv.load();
    }

    final baseUrl = dotenv.env['API_URL'];
    final url = Uri.parse("$baseUrl/auth/register");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "nama": name,
          "email": email,
          "password": password,
          "role": role == UserRole.kurir ? 'kurir' : 'pelanggan',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        Map<String, dynamic> userMap = responseData['user'] ?? responseData;

        return User(
          id: (userMap['id'] ?? '0').toString(),
          name: userMap['name'] ?? userMap['nama'] ?? name,
          email: userMap['email'] ?? email,
          role: role,
        );
      }
      return null;
    } catch (e) {
      print("Error Register Repo: $e");
      return null;
    }
  }
}