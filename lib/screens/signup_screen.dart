import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../widgets/organic_header.dart';
import '../widgets/app_logo.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repasswordController = TextEditingController();

  String selectedRole = 'Pelanggan';
  bool showPassword = false;
  bool showRePassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _repasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Ambil input dari controller (Sudah Benar)
    final nama = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmedPassword = _repasswordController.text;

    // VALIDASI (Perhatikan nama variabel di bawah ini)
    if (nama.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi!')),
      );
      return;
    }

    if (password != confirmedPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password tidak cocok!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      
      final role = selectedRole.toLowerCase(); 

      print("Daftar: $nama, $email, Role: $role");

      // Kirim data ke AuthProvider
      final success = await auth.register(
        nama: nama,
        email: email,
        password: password,
        confirmedPassword: confirmedPassword,
        role: role,
      );
      
      if (!mounted) return;

      if (success) {
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pendaftaran Berhasil! Silakan Login.'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacementNamed(context, '/login');
          // Navigator.pushReplacementNamed(context, '/customer_home');

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran Gagal. Email mungkin sudah terdaftar.')),
        );
      }
    } catch (e) {
     
      print("Error saat register: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan sistem.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            OrganicHeader(
              height: 320,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      ),
                    ),
                    const AppLogo(size: 60, color: Colors.white, showText: true),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -20),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'DAFTAR AKUN',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Segmented Control Style
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7F5),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _roleOption(
                                label: 'Pelanggan',
                                isSelected: selectedRole == 'Pelanggan',
                                onTap: () => setState(() => selectedRole = 'Pelanggan'),
                              ),
                            ),
                            Expanded(
                              child: _roleOption(
                                label: 'Kurir',
                                isSelected: selectedRole == 'Kurir',
                                onTap: () => setState(() => selectedRole = 'Kurir'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      _buildTextField(hint: 'Nama Lengkap', icon: Icons.person_outline, controller: _nameController),
                      const SizedBox(height: 16),
                      _buildTextField(hint: 'Email', icon: Icons.email_outlined, controller: _emailController),
                      const SizedBox(height: 16),
                      _buildTextField(
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        controller: _passwordController,
                        isObscure: !showPassword,
                        onSuffixTap: () => setState(() => showPassword = !showPassword),
                        suffixIcon: showPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        hint: 'Ulangi Password',
                        icon: Icons.lock_outline,
                        controller: _repasswordController,
                        isObscure: !showRePassword,
                        onSuffixTap: () => setState(() => showRePassword = !showRePassword),
                        suffixIcon: showRePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2DAAC8)),
                        child: _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Daftar'),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Sudah punya akun? ', style: TextStyle(color: Colors.black54)),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                            child: Text(
                              'Log in',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hint, 
    required IconData icon, 
    TextEditingController? controller,
    bool isObscure = false, 
    IconData? suffixIcon, 
    VoidCallback? onSuffixTap
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon != null ? IconButton(icon: Icon(suffixIcon), onPressed: onSuffixTap) : null,
        filled: true,
        fillColor: const Color(0xFFF4F7F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _roleOption({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF005B71) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }
}
