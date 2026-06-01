import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  User? _currentUser;
  String? _token; 
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuth => _token != null; 

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      // Sekarang result menangkap Map JSON utuh dari repositori kita yang baru
      final responseData = await _repository.login(email, password);
      
      if (responseData != null) {
        final prefs = await SharedPreferences.getInstance();

        // DETEKTIF TOKEN: Ambil token asli buatan backend Laravel kamu!
        _token = responseData['token'] ?? 
                 responseData['access_token'] ?? 
                 responseData['token_jwt'] ?? 
                 responseData['data']?['token'] ?? 
                 'BERHASIL_LOGIN_NGROK'; // Fallback jika backend emang ga ngasih token
        
        print("MANTAP! TOKEN ASLI DARI LARAVEL SUKSES KETANGKAP: $_token");

        // Bongkar data user-nya dari map
        final userMap = responseData['user'] ?? responseData['data']?['user'] ?? responseData;
        _currentUser = User(
          id: (userMap['id'] ?? '0').toString(),
          name: userMap['name'] ?? userMap['nama'] ?? 'User Laundry',
          email: userMap['email'] ?? email,
          role: userMap['role'] == 'kurir' ? UserRole.kurir : UserRole.pelanggan,
        );

        // Simpan token asli buatan Laravel beserta profil ke memori internal HP
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_id', _currentUser!.id);
        await prefs.setString('user_name', _currentUser!.name);
        await prefs.setString('user_email', _currentUser!.email);
        await prefs.setString('user_role', _currentUser!.role == UserRole.kurir ? 'kurir' : 'pelanggan');
        
        notifyListeners(); 
      }
    } catch (e) {
      print("Error login provider: $e");
    } finally {
      _setLoading(false);
    }
    return _currentUser != null;
  }

  Future<bool> register({
    required String nama,
    required String email,
    required String password,
    required String confirmedPassword,
    required String role,
  }) async {
    _setLoading(true);

    if (!dotenv.isInitialized) {
      await dotenv.load(); 
    }

    final url = "${dotenv.env['API_URL']}/auth/register";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nama": nama,
          "email": email,
          "password": password,
          "confirmedPassword": confirmedPassword,
          "role": role,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('auth_token')) return false;

    _token = prefs.getString('auth_token');
    
    final savedId = prefs.getString('user_id') ?? '0';
    final savedName = prefs.getString('user_name') ?? 'User';
    final savedEmail = prefs.getString('user_email') ?? '';
    final savedRole = prefs.getString('user_role') ?? 'pelanggan';
    
    _currentUser = User(
      id: savedId, 
      name: savedName, 
      email: savedEmail, 
      role: savedRole == 'kurir' ? UserRole.kurir : UserRole.pelanggan
    );
    
    notifyListeners();
    return true;
  }
  
  void logout() async {
    _currentUser = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}