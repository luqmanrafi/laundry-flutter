import 'package:flutter/material.dart';
import '../widgets/organic_header.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../utils/dummy_data.dart'; // Using dummy data for now
import '../utils/order_flow_controller.dart';

class CourierHomeScreen extends StatelessWidget {
  const CourierHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We would use AuthProvider in real implementation
    final courier = dummyUsers.firstWhere((u) => u.role == UserRole.kurir);

    return Scaffold(
      extendBody: true, // For floating nav bar
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: OrganicHeader(
              height: 250,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Color(0xFF2DAAC8),
                          child: Icon(Icons.motorcycle, color: Colors.white, size: 30),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ADE80).withAlpha(40),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF4ADE80), width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.circle, color: Color(0xFF4ADE80), size: 10),
                              SizedBox(width: 6),
                              Text('Online', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome back',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      courier.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Ringkasan Hari Ini',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF005B71),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _SummaryCard(title: 'Pickup', count: '5', icon: Icons.outbox_outlined),
                        _SummaryCard(title: 'Delivery', count: '3', icon: Icons.local_shipping_outlined),
                        _SummaryCard(title: 'Selesai', count: '10', icon: Icons.check_circle_outline),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Order Aktif',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF005B71),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder(
                      valueListenable: OrderFlowController.status,
                      builder: (context, statusEnum, child) {
                        return _ActiveOrderCard(
                          invoiceId: '#INV-220525-001',
                          customerName: 'TOMI',
                          address: 'Jl. Ngawi Timur No. 10, Kenari',
                          distance: '6.9 km dari lokasi Anda',
                          status: statusEnum.label,
                          onDetail: () => Navigator.pushNamed(context, '/order_detail'),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _ActiveOrderCard(
                      invoiceId: '#INV-220525-002',
                      customerName: 'SITI',
                      address: 'Perumahan Indah, Blok A2',
                      distance: '2.1 km dari lokasi Anda',
                      status: 'Delivery',
                      onDetail: () => Navigator.pushNamed(context, '/order_detail'),
                    ),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2DAAC8),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur Scanner QR sedang dalam pengembangan')),
          );
        },
        child: const Icon(Icons.qr_code_scanner, size: 28),
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
                icon: const Icon(Icons.home, color: Color(0xFF005B71)), 
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.receipt_long, color: Colors.grey), 
                onPressed: () => Navigator.pushReplacementNamed(context, '/order_list'),
              ),
              const SizedBox(width: 40), // Space for FAB
              IconButton(
                icon: const Icon(Icons.map_outlined, color: Colors.grey), 
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur Peta (Map) sedang dalam pengembangan')),
                  );
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

class _SummaryCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.secondary, size: 28),
              const SizedBox(height: 8),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1C1F24),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  final String invoiceId;
  final String customerName;
  final String address;
  final String distance;
  final String status;
  final VoidCallback onDetail;

  const _ActiveOrderCard({
    required this.invoiceId,
    required this.customerName,
    required this.address,
    required this.distance,
    required this.status,
    required this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  invoiceId,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C1F24),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'Pickup' 
                        ? const Color(0xFF2DAAC8).withAlpha(30)
                        : const Color(0xFF005B71).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: status == 'Pickup' ? const Color(0xFF2DAAC8) : const Color(0xFF005B71),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFFF4F7F5),
                  child: Icon(Icons.person, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Text(
                  customerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.directions_bike_outlined, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  distance,
                  style: const TextStyle(
                    color: Color(0xFF005B71),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onDetail,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2DAAC8), width: 1.5),
                  foregroundColor: const Color(0xFF2DAAC8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Lihat Detail', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
