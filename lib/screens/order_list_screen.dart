import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../utils/order_flow_controller.dart';

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isCourier = auth.currentUser?.role == UserRole.kurir;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      extendBody: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: const [
                  Expanded(
                    child: Text(
                      'Riwayat Order',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF005B71),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  _FilterChip(label: 'Semua', selected: false),
                  _FilterChip(label: 'Menunggu', selected: false),
                  _FilterChip(label: 'Pickup', selected: true),
                  _FilterChip(label: 'Proses', selected: false),
                  _FilterChip(label: 'Selesai', selected: false),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  ValueListenableBuilder(
                    valueListenable: OrderFlowController.status,
                    builder: (context, statusEnum, child) {
                      return _OrderCard(
                        id: '#INV-220525-001',
                        name: isCourier ? 'Tomi' : 'Cuci Kering',
                        subtitle: 'Jl. Ngawi Timur No. 10, Kenari',
                        status: statusEnum.label,
                        time: '10:00 - 12:00',
                        isCourier: isCourier,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _OrderCard(
                    id: '#INV-220525-002',
                    name: isCourier ? 'Abbad' : 'Setrika Saja',
                    subtitle: 'Perumahan Indah, Blok A2',
                    status: 'Proses',
                    time: 'Selesai 24 Mei',
                    isCourier: isCourier,
                  ),
                  const SizedBox(height: 100), // Space for bottom nav
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
                  Navigator.pushReplacementNamed(
                    context, 
                    isCourier ? '/courier_home' : '/customer_home'
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.receipt_long, color: Color(0xFF005B71)),
                onPressed: () {}, // Already here
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
                icon: const Icon(Icons.person_outline, color: Colors.grey),
                onPressed: () => Navigator.pushReplacementNamed(context, '/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _FilterChip({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2DAAC8) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: selected ? null : Border.all(color: const Color(0xFFD8DDE3)),
        boxShadow: selected ? const [BoxShadow(color: Color(0x332DAAC8), blurRadius: 6, offset: Offset(0, 3))] : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : const Color(0xFF7B7D81),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String id;
  final String name;
  final String subtitle;
  final String status;
  final String time;
  final bool isCourier;

  const _OrderCard({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.time,
    required this.isCourier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Fix UX: whole card is clickable
            Navigator.pushNamed(context, isCourier ? '/order_detail' : '/detail_pesanan');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      id,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'Pickup' ? const Color(0xFF2DAAC8).withAlpha(30) : const Color(0xFF005B71).withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: status == 'Pickup' ? const Color(0xFF2DAAC8) : const Color(0xFF005B71),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C1F24),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE4E6EA)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(time, style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Text(
                      'Lihat Detail >',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2DAAC8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
