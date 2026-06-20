import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../widgets/organic_header.dart';
import 'coming_soon_screen.dart';
import 'edit_profile_screen.dart';
import 'saved_addresses_screen.dart';
import 'help_center_screen.dart';
import 'courier_tracking_screen.dart';
import 'courier_income_screen.dart';
import 'courier_delivery_history_screen.dart';
import '../providers/order_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _profileImagePath;
  String? _phone;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('user_profile_image');
      _phone = prefs.getString('user_phone');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Memastikan saat kembali ke halaman ini datanya di-refresh
    _loadLocalData();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final isCourier = user?.role == UserRole.kurir;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      extendBody: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            OrganicHeader(
              height: 310,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Profil Saya',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings, color: Colors.white),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: const Color(0xFF2DAAC8).withOpacity(0.5), blurRadius: 15, spreadRadius: 2)
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white,
                              backgroundImage: _profileImagePath != null ? FileImage(File(_profileImagePath!)) : null,
                              child: _profileImagePath == null 
                                ? Text(
                                    (user?.name.isNotEmpty == true ? user!.name : 'U').substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Color(0xFF2DAAC8),
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  )
                                : null,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'Nama Pengguna',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? 'email@example.com',
                                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                                if (_phone != null && _phone!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, color: Colors.white70, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        _phone!,
                                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 20, offset: Offset(0, 8))],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _MenuTile(
                          icon: Icons.person_outline,
                          title: 'Edit Profil',
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                            _loadLocalData(); // Refresh pasca kembali
                          },
                        ),
                        const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF4F7F5)),
                        if (isCourier) ...[

                          _MenuTile(
                            icon: Icons.history,
                            title: 'Riwayat Pengiriman',
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const CourierDeliveryHistoryScreen()));
                            },
                          ),
                        ] else ...[
                          _MenuTile(
                            icon: Icons.location_on_outlined,
                            title: 'Alamat Tersimpan',
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedAddressesScreen()));
                            },
                          ),
                        ],
                        const Divider(height: 1, indent: 64, endIndent: 20, color: Color(0xFFF4F7F5)),
                        _MenuTile(
                          icon: Icons.help_outline,
                          title: 'Pusat Bantuan',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterScreen()));
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Logout Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD32F2F),
                      side: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Keluar (Log Out)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    onPressed: () {
                      auth.logout();
                      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
                    },
                  ),
                  const SizedBox(height: 120), // Bottom nav spacing
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: isCourier ? null : FloatingActionButtonLocation.centerDocked,
      floatingActionButton: isCourier ? null : FloatingActionButton(
        backgroundColor: const Color(0xFF2DAAC8),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        onPressed: () {
          Navigator.pushNamed(context, '/order_create');
        },
        child: const Icon(Icons.add, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: isCourier ? null : const CircularNotchedRectangle(),
        notchMargin: 10,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home_outlined, color: Colors.grey),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, isCourier ? '/courier_home' : '/customer_home');
                },
              ),
              IconButton(
                icon: const Icon(Icons.receipt_long, color: Colors.grey),
                onPressed: () => Navigator.pushReplacementNamed(context, '/order_list'),
              ),
              if (!isCourier) const SizedBox(width: 40), // Space for FAB
              IconButton(
                icon: Icon(isCourier ? Icons.map_outlined : Icons.notifications_none, color: Colors.grey),
                onPressed: () {
                  if (isCourier) {
                    final orderProv = context.read<OrderProvider>();
                    final activeOrder = orderProv.currentOrder ?? (orderProv.myOrders.isNotEmpty ? orderProv.myOrders.first : null);
                    if (activeOrder != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CourierTrackingScreen(orderId: activeOrder.id)),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Belum ada pesanan aktif untuk ditracking')),
                      );
                    }
                  } else {
                    Navigator.pushNamed(context, '/notifications');
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.person, color: Color(0xFF005B71)),
                onPressed: () {}, // Already here
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF005B71)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
