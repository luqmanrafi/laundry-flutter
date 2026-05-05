import '../models/user.dart';
import '../utils/dummy_data.dart';

class AuthRepository {
  // TODO(Backend): Replace with real API call (e.g. http.post('/login'))
  Future<User?> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    try {
      return dummyUsers.firstWhere((u) => u.email == email);
    } catch (e) {
      // Return null if user not found (in real app, return specific error messages)
      return null;
    }
  }

  // TODO(Backend): Replace with real API call (e.g. http.post('/register'))
  Future<User?> register(String name, String email, String password, UserRole role) async {
    await Future.delayed(const Duration(seconds: 1));
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      role: role,
    );
    // Dummy mode: just return the new user to simulate auto-login after register.
    return newUser;
  }
}
