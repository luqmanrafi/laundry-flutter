import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart'; 
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../widgets/organic_header.dart';
import 'order_detail_screen.dart'; 
import 'courier_tracking_screen.dart';
import '../widgets/address_text.dart';
import 'package:intl/intl.dart';

class CourierHomeScreen extends StatefulWidget {
  const CourierHomeScreen({super.key});

  @override
  State<CourierHomeScreen> createState() => _CourierHomeScreenState();
}

class _CourierHomeScreenState extends State<CourierHomeScreen> {
  String _formatCurrency(dynamic value) {
    if (value == null) return "Menunggu Berat";
    if (value is num) {
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      return formatter.format(value);
    }
    return value.toString();
  }

  @override
  void initState() {
    super.initState();
    // OTOMATIS AMBIL DAFTAR PESANAN PELANGGAN SAAT KURIR MASUK HOME
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load data layanan pendukung relasi database terlebih dahulu
      context.read<OrderProvider>().loadServices(); 
      
      SharedPreferences.getInstance().then((prefs) {
        final userId = prefs.getString('user_id') ?? '';
        context.read<OrderProvider>().loadMyOrders(userId); 
      }); 
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. AMBIL DATA SESSION LOG IN Driver/Kurir secara dinamis via try-catch kebal error
    final authProv = Provider.of<AuthProvider>(context);

    final String namaKurirLogin = authProv.currentUser?.name ?? 'Nama Pengguna';
  
    final orderProv = Provider.of<OrderProvider>(context);
    final listOrderanPelanggan = orderProv.myOrders;
    
    int pickupCount = 0;
    int deliveryCount = 0;
    int selesaiCount = 0;

    List<Order> allOrders = List.from(listOrderanPelanggan);
    if (orderProv.currentOrder != null && !allOrders.any((o) => o.id == orderProv.currentOrder!.id)) {
      allOrders.insert(0, orderProv.currentOrder!);
    }

    for (var order in allOrders) {
      if (order.status == OrderStatus.pending || order.status == OrderStatus.dibawa_kurir_ke_laundry || order.status == OrderStatus.sedang_dicuci) {
        pickupCount++;
      } else if (order.status == OrderStatus.siap_dikirim || order.status == OrderStatus.proses_pengantaran) {
        deliveryCount++;
      } else if (order.status == OrderStatus.selesai) {
        selesaiCount++;
      }
    }

    return Scaffold(
      extendBody: true, // For floating nav bar
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          
          // =======================================================================
          // FIXED: SEKARANG CUMA ADA SATU ORGANIC HEADER YANG MURNI UTUR COK!
          // =======================================================================
          SliverToBoxAdapter(
            child: OrganicHeader(
              height: 290,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFF2DAAC8),
                          child: Text(
                            namaKurirLogin.isNotEmpty ? namaKurirLogin.substring(0, 1).toUpperCase() : 'K',
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Tidak ada notifikasi baru.')),
                            );
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Stack(
                              children: [
                                const Icon(Icons.notifications_outlined, color: Colors.white, size: 26),
                                Positioned(
                                  right: 2,
                                  top: 2,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5252),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFF005B71), width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                    children: [
                      _SummaryCard(title: 'Pickup', count: pickupCount.toString(), icon: Icons.outbox_outlined),
                      _SummaryCard(title: 'Delivery', count: deliveryCount.toString(), icon: Icons.local_shipping_outlined),
                      _SummaryCard(title: 'Selesai', count: selesaiCount.toString(), icon: Icons.check_circle_outline),
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.grey, size: 40),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Belum ada pesanan aktif dari pelanggan masuk saat ini',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      orderProv.simulateIncomingMockOrder();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF005B71),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                                    label: const Text('Simulasikan Order Masuk (Demo)', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            )
                          : ListView(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              children: [

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
                                      distance: orderan.jarakMeter != null
                                          ? 'Jarak: ${(orderan.jarakMeter! / 1000).toStringAsFixed(1)} km'
                                          : 'Tarif: ${_formatCurrency(orderan.invoice?.totalPrice ?? (orderan.weight != null ? (orderan.weight! * orderan.service.pricePerKg).round() : null))}',
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
                                      onAccept: orderan.status == OrderStatus.pending
                                          ? () async {
                                              final success = await orderProv.takeOrder(
                                                orderan.id,
                                              );
                                              if (success && mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Pesanan berhasil diambil!')),
                                                );
                                                orderProv.loadMyOrders('');
                                              } else if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Maaf, pesanan ini sudah diambil oleh kurir lain.')),
                                                );
                                                // Refresh daftar agar pesanan yang sudah diambil menghilang dari layar
                                                orderProv.loadMyOrders('');
                                              }
                                            }
                                          : null,
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                  const SizedBox(height: 160), 
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
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
              IconButton(icon: const Icon(Icons.map_outlined, color: Colors.grey), 
                onPressed: () {
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
  final VoidCallback? onAccept;

  const _ActiveOrderCard({
    required this.invoiceId,
    required this.customerName,
    required this.address,
    required this.distance,
    required this.status,
    required this.onDetail,
    this.onAccept,
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
                Expanded(
                  child: AddressText(
                    address: address,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDetail,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2DAAC8), width: 1.5),
                      foregroundColor: const Color(0xFF2DAAC8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Lihat Detail', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                if (onAccept != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DAAC8),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Ambil Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}