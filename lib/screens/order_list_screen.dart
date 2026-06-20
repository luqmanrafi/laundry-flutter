import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../utils/order_flow_controller.dart';
import 'order_detail_screen.dart';
import 'customer_order_detail_screen.dart';
import '../widgets/address_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'courier_tracking_screen.dart';
class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  String _activeFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.currentUser != null) {
        context.read<OrderProvider>().loadMyOrders(auth.currentUser!.id);
      } else {
        SharedPreferences.getInstance().then((prefs) {
          final userId = prefs.getString('user_id') ?? '';
          context.read<OrderProvider>().loadMyOrders(userId); 
        });
      }
    });
  }

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
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  'Semua',
                  'Menunggu',
                  'Pickup',
                  'Proses',
                  'Selesai',
                ].map((filter) {
                  return _FilterChip(
                    label: filter,
                    selected: _activeFilter == filter,
                    onTap: () {
                      setState(() {
                        _activeFilter = filter;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<OrderProvider>(
                builder: (context, orderProv, child) {
                  if (orderProv.isLoading && orderProv.myOrders.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF005B71)));
                  }

                  List<Order> allOrders = List.from(orderProv.myOrders);
                  if (orderProv.currentOrder != null && !allOrders.any((o) => o.id == orderProv.currentOrder!.id)) {
                    allOrders.insert(0, orderProv.currentOrder!);
                  }

                  final filteredOrders = allOrders.where((order) {
                    if (_activeFilter == 'Semua') return true;
                    
                    if (_activeFilter == 'Menunggu') {
                      return order.status == OrderStatus.pending;
                    }
                    if (_activeFilter == 'Pickup') {
                      return order.status == OrderStatus.dibawa_kurir_ke_laundry || order.status == OrderStatus.kurir_menuju_lokasi;
                    }
                    if (_activeFilter == 'Proses') {
                      return order.status == OrderStatus.sedang_dicuci ||
                          order.status == OrderStatus.siap_dikirim ||
                          order.status == OrderStatus.proses_pengantaran;
                    }
                    if (_activeFilter == 'Selesai') {
                      return order.status == OrderStatus.selesai ||
                          order.status == OrderStatus.cancelled;
                    }
                    return true;
                  }).toList();

                  if (filteredOrders.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada riwayat pesanan untuk kategori ini.',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: filteredOrders.length + 1, // +1 for spacing at the bottom
                    itemBuilder: (context, index) {
                      if (index == filteredOrders.length) {
                        return const SizedBox(height: 100);
                      }

                      final order = filteredOrders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _OrderCard(
                          id: '#ORD-${order.id}',
                          name: isCourier ? order.customer.name : order.service.name,
                          subtitle: order.pickupAddress,
                          status: order.status.label,
                          time: '${order.pickupDate.day}/${order.pickupDate.month}/${order.pickupDate.year}',
                          isCourier: isCourier,
                          realOrderId: order.id, // we will add this to _OrderCard
                        ),
                      );
                    },
                  );
                },
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
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
  final String? realOrderId;

  const _OrderCard({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.time,
    required this.isCourier,
    this.realOrderId,
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
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => isCourier
                    ? OrderDetailScreen(orderId: realOrderId)
                    : CustomerOrderDetailScreen(orderId: realOrderId),
              ),
            );
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
                AddressText(
                  address: subtitle,
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
