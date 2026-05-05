import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../widgets/organic_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
              height: 280,
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
                              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10)],
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: const Color(0xFF2DAAC8),
                              child: Icon(
                                isCourier ? Icons.motorcycle : Icons.person, 
                                color: Colors.white, 
                                size: 40,
                              ),
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
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(50),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isCourier ? 'Kurir Aktif' : 'Pelanggan Setia',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
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
            
            // Courier Stats
            if (isCourier)
              Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(title: 'Rating', value: '4.9', icon: Icons.star, color: const Color(0xFF2DAAC8)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(title: 'Selesai', value: '124', icon: Icons.check_circle, color: const Color(0xFF005B71)),
                      ),
                    ],
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  if (!isCourier) const SizedBox(height: 20),
                  _MenuTile(
                    icon: Icons.person_outline,
                    title: 'Edit Profil',
                    onTap: () {},
                  ),
                  const SizedBox(height: 12),
                  if (isCourier) ...[
                    _MenuTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Pendapatan Saya',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _MenuTile(
                      icon: Icons.history,
                      title: 'Riwayat Pengiriman',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    _MenuTile(
                      icon: Icons.location_on_outlined,
                      title: 'Alamat Tersimpan',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                  ],
                  _MenuTile(
                    icon: Icons.help_outline,
                    title: 'Pusat Bantuan',
                    onTap: () {},
                  ),
                  const SizedBox(height: 32),
                  
                  // Logout Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF0F0),
                      foregroundColor: const Color(0xFFD32F2F),
                      elevation: 0,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2DAAC8),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        onPressed: () {
          final msg = isCourier ? 'Fitur Scanner QR sedang dalam pengembangan' : 'Fitur Buat Order sedang dalam pengembangan';
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
        },
        child: Icon(isCourier ? Icons.qr_code_scanner : Icons.add, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
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
              const SizedBox(width: 40), // Space for FAB
              IconButton(
                icon: Icon(isCourier ? Icons.map_outlined : Icons.notifications_none, color: Colors.grey),
                onPressed: () {
                  if (isCourier) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur Peta (Map) sedang dalam pengembangan')));
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

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1F24))),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w600)),
        ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
      ),
    );
  }
}
