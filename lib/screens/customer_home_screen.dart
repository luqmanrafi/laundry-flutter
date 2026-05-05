import 'package:flutter/material.dart';
import '../utils/dummy_data.dart';
import '../utils/order_flow_controller.dart';
import '../models/order.dart';
import '../models/service.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activeUser = dummyUsers.first;

    return Scaffold(
      extendBody: true,
      body: CustomScrollView(
        slivers: [
          // Dynamic Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF005B71),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF004A5E), Color(0xFF005B71)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24, width: 2),
                                  ),
                                  child: const CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Color(0xFF2DAAC8),
                                    child: Icon(Icons.person, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Halo,', style: TextStyle(color: Colors.white70, fontSize: 14)),
                                    Text(
                                      activeUser.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 18),
                                  SizedBox(width: 6),
                                  Text('120 Poin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Search bar or quick action
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4))],
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.search, color: Colors.grey),
                              SizedBox(width: 12),
                              Text('Cari layanan laundry...', style: TextStyle(color: Colors.grey, fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Active Order Tracking (Only shows if an order is active)
                    ValueListenableBuilder<OrderStatus>(
                      valueListenable: OrderFlowController.status,
                      builder: (context, status, child) {
                        if (status != OrderStatus.pending && status != OrderStatus.completed && status != OrderStatus.cancelled) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                            child: _ActiveOrderCard(status: status),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Services Grid (Horizontal Row)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Text('Layanan Kami', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1C1F24))),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: dummyServices.map((service) => _ServiceItem(service: service)).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Promo Banner
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Text('Promo Spesial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1C1F24))),
                    ),
                    SizedBox(
                      height: 160,
                      child: PageView(
                        controller: PageController(viewportFraction: 0.88),
                        padEnds: false,
                        children: const [
                          Padding(padding: EdgeInsets.only(left: 24), child: _PromoBanner(imagePath: 'assets/images/promo1.png')),
                          Padding(padding: EdgeInsets.only(left: 16), child: _PromoBanner(imagePath: 'assets/images/promo2.png')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
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
        elevation: 6,
        onPressed: () {
          Navigator.pushNamed(context, '/order_create');
        },
        child: const Icon(Icons.add, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10,
        color: Colors.white,
        elevation: 20,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(icon: const Icon(Icons.home, color: Color(0xFF005B71)), onPressed: () {}),
              IconButton(icon: const Icon(Icons.receipt_long, color: Colors.grey), onPressed: () => Navigator.pushReplacementNamed(context, '/order_list')),
              const SizedBox(width: 40),
              IconButton(icon: const Icon(Icons.notifications_none, color: Colors.grey), onPressed: () => Navigator.pushNamed(context, '/notifications')),
              IconButton(icon: const Icon(Icons.person_outline, color: Colors.grey), onPressed: () => Navigator.pushReplacementNamed(context, '/profile')),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  final OrderStatus status;
  
  const _ActiveOrderCard({required this.status});

  String _getStatusText() {
    switch (status) {
      case OrderStatus.pickup: return 'Kurir menuju lokasi Anda';
      case OrderStatus.waitingConfirmation: return 'Menunggu Pembayaran';
      case OrderStatus.processing: return 'Cucian sedang diproses';
      case OrderStatus.delivery: return 'Kurir mengantar cucian';
      default: return 'Pesanan aktif';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF005B71).withAlpha(30), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2DAAC8).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.motorcycle, color: Color(0xFF2DAAC8)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pesanan Berjalan', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(_getStatusText(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF005B71))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.grey),
            onPressed: () => Navigator.pushNamed(context, '/detail_pesanan'),
          )
        ],
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final Service service;

  const _ServiceItem({required this.service});

  IconData _iconForService(String icon) {
    switch (icon) {
      case 'bolt': return Icons.water_drop_outlined;
      case 'iron': return Icons.iron;
      case 'local_laundry_service': default: return Icons.local_laundry_service_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
              boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            child: Icon(_iconForService(service.icon), color: const Color(0xFF005B71), size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            service.name.split(' ').join('\n'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  final String imagePath;
  const _PromoBanner({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
        ),
      ),
    );
  }
}
