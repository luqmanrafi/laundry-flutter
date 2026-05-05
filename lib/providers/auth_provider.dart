import 'package:flutter/material.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _currentUser = await _repository.login(email, password);
    _setLoading(false);
    return _currentUser != null;
  }

  Future<bool> register(String name, String email, String password, UserRole role) async {
    _setLoading(true);
    _currentUser = await _repository.register(name, email, password, role);
    _setLoading(false);
    return _currentUser != null;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
