import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart'; 
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../widgets/organic_header.dart';
import 'order_detail_screen.dart'; 

class CourierHomeScreen extends StatefulWidget {
  const CourierHomeScreen({super.key});

  @override
  State<CourierHomeScreen> createState() => _CourierHomeScreenState();
}

class _CourierHomeScreenState extends State<CourierHomeScreen> {
  @override
  void initState() {
    super.initState();
    // OTOMATIS AMBIL DAFTAR PESANAN PELANGGAN SAAT KURIR MASUK HOME
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load data layanan pendukung relasi database terlebih dahulu
      context.read<OrderProvider>().loadServices(); 
      
      // Menembak seluruh data pesanan riil dari MySQL tanpa filter user_id kosongan
      context.read<OrderProvider>().loadMyOrders(''); 
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. AMBIL DATA SESSION LOG IN Driver/Kurir secara dinamis via try-catch kebal error
    final authProv = Provider.of<AuthProvider>(context);

    final String namaKurirLogin = authProv.currentUser?.name ?? 'Nama Pengguna';
  
    final orderProv = Provider.of<OrderProvider>(context);
    final listOrderanPelanggan = orderProv.myOrders;

    return Scaffold(
      extendBody: true, // For floating nav bar
      body: CustomScrollView(
        slivers: [
          
          // =======================================================================
          // FIXED: SEKARANG CUMA ADA SATU ORGANIC HEADER YANG MURNI UTUR COK!
          // =======================================================================
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
                      namaKurirLogin, // <--- Dinamis seutuhnya mengikuti data akun kurir login
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
          
          // AREA DAFTAR KINERJA RINGKASAN & DATA PELANGGAN
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
                    'Daftar Order Pelanggan', 
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF005B71),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // LOGIKA KONDISIONAL PEMBACAAN DATA RE-TIME
                  orderProv.isLoading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(color: Color(0xFF005B71)),
                          ),
                        )
                      : (listOrderanPelanggan.isEmpty && orderProv.currentOrder == null)
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                              child: const Center(
                                child: Text(
                                  'Belum ada pesanan aktif dari pelanggan masuk saat ini',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                                ),
                              ),
                            )
                          : ListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              children: [
                                // Skenario Pengaman: Jika data yang baru dibuat pelanggan masih ada di memori aktif
                                if (orderProv.currentOrder != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _ActiveOrderCard(
                                      invoiceId: '#ORD-${orderProv.currentOrder!.id}',
                                      customerName: orderProv.currentOrder!.customer?.name ?? 'Pelanggan Baru',
                                      address: orderProv.currentOrder!.pickupAddress.isEmpty ? 'Alamat Lokasi' : orderProv.currentOrder!.pickupAddress,
                                      distance: 'Tarif: Rp ${orderProv.currentOrder!.invoice?.totalPrice ?? "196.700"}',
                                      status: orderProv.currentOrder!.status.label,
                                      onDetail: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => OrderDetailScreen(orderId: orderProv.currentOrder!.id),
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                ...listOrderanPelanggan.map((orderan) {
                                
                                  final String idValidSakti = (orderan.id == null || orderan.id.toString() == 'null') 
                                      ? '1' 
                                      : orderan.id.toString();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _ActiveOrderCard(
                                      invoiceId: '#ORD-$idValidSakti',
                                      customerName: orderan.customer?.name ?? 'Pelanggan Asli',
                                      address: orderan.pickupAddress.isEmpty ? 'Alamat Penjemputan' : orderan.pickupAddress,
                                      distance: 'Tarif: Rp ${orderan.invoice?.totalPrice ?? "Menyesuaikan"}',
                                      status: orderan.status.label,
                                      onDetail: () {
                                      
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => OrderDetailScreen(
                                              orderId: idValidSakti,
                                              orderData: orderan, 
                                            ),

                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                  const SizedBox(height: 100), 
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
              IconButton(icon: const Icon(Icons.home, color: Color(0xFF005B71)), onPressed: () {}),
              IconButton(icon: const Icon(Icons.receipt_long, color: Colors.grey), 
                onPressed: () => Navigator.pushReplacementNamed(context, '/order_list')),
              const SizedBox(width: 40), 
              IconButton(icon: const Icon(Icons.map_outlined, color: Colors.grey), 
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur Peta (Map) sedang dalam pengembangan')),
                  );
                },
              ),
              IconButton(icon: const Icon(Icons.person_outline, color: Colors.grey), 
                onPressed: () => Navigator.pushReplacementNamed(context, '/profile')),
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
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1F24)),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1C1F24)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF005B71).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Color(0xFF005B71), fontWeight: FontWeight.w800, fontSize: 12),
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(address, style: const TextStyle(color: Colors.black54))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.payments_outlined, color: Colors.grey, size: 20), 
                const SizedBox(width: 8),
                Text(distance, style: const TextStyle(color: Color(0xFF005B71), fontWeight: FontWeight.w700)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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