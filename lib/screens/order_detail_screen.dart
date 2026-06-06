import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../providers/order_provider.dart';
import '../utils/order_flow_controller.dart';
import '../widgets/order_status_stepper.dart';
import '../providers/auth_provider.dart';

class OrderDetailScreen extends StatefulWidget {
  final String? orderId; // Menampung kiriman ID Order dari halaman list/riwayat
  final Order? orderData;
  const OrderDetailScreen({super.key, this.orderId, this.orderData,});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
 @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProv = context.read<OrderProvider>();

      if (widget.orderId == null) {
        print(" Basket: Navigasi datang dari Home Screen. Mencari orderan aktif...");
        
        if (orderProv.currentOrder != null) {
          print(" Sukses Mengamankan Data Aktif Langsung dari Provider: ID #ORD-${orderProv.currentOrder!.id}");
          OrderFlowController.status.value = orderProv.currentOrder!.status;
          if (mounted) setState(() {});
        } 
       
        else if (orderProv.myOrders.isNotEmpty) {
          final orderAktifUser = orderProv.myOrders.first; 
          try {
            (orderProv as dynamic).currentOrder = orderAktifUser;
            OrderFlowController.status.value = orderAktifUser.status;
          } catch (e) {
            print("Gagal set data via dynamic setter: $e");
          }
          if (mounted) setState(() {});
          print(" Sukses Mengamankan Order ID Dinamis dari Riwayat: ${orderAktifUser.id}");
        } 

        else {
          print(" Riwayat & Memori kosong, terpaksa fallback ke ID Demo 10");
          orderProv.loadOrderDetail('10');
        }
      } 
      
      else {
        print(" Menembak API Detail Order Berdasarkan ID: ${widget.orderId}");
        orderProv.loadOrderDetail(widget.orderId!);
      }
    });
  }

  Future<void> _handleCourierAction(Order order) async {
    final orderProv = context.read<OrderProvider>();
    
    OrderStatus? nextStatus;
    switch (order.status) {
      case OrderStatus.pending:
        nextStatus = OrderStatus.dibawa_kurir_ke_laundry;
        break;
      case OrderStatus.siap_dikirim:
        nextStatus = OrderStatus.proses_pengantaran;
        break;
      case OrderStatus.proses_pengantaran:
        nextStatus = OrderStatus.selesai;
        break;
      default:
        nextStatus = null;
    }

    if (nextStatus != null) {
      final success = await orderProv.updateStatus(order.id, nextStatus);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status berhasil diperbarui ke: ${nextStatus.label}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = Provider.of<OrderProvider>(context);
    final order = orderProv.currentOrder;

    // Loading State jika data dari API Laravel belum kelar
    if (orderProv.isLoading && order == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF005B71))),
      );
    }

    // Jika data tidak ditemukan setelah loading selesai
    if (order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7F5),
        appBar: AppBar(title: const Text('Detail Order')),
        body: const Center(child: Text('Data pesanan gagal dimuat dari backend.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // HEADER BAR
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Detail Order', 
                    textAlign: TextAlign.center, 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF005B71)),
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
            const SizedBox(height: 24),

            // CARD ID & DATA PELANGGAN
            _card(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Order ID', style: TextStyle(fontSize: 16, color: Colors.black54)),
                            const SizedBox(height: 4),
                          
                            Text('#ORD-${order.id}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1C1F24))),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2DAAC8).withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          order.status.label.toUpperCase(), 
                          style: const TextStyle(color: Color(0xFF2DAAC8), fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE4E6EA)),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      const CircleAvatar(radius: 24, backgroundColor: Color(0xFFF4F7F5), child: Icon(Icons.person, color: Colors.grey)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.customer.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(order.customer.email, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.call, color: Color(0xFF005B71)),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF005B71).withAlpha(20),
                          padding: const EdgeInsets.all(12),
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // CARD TIMELINE TIMESTEPPER STATUS
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Timeline Status Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF005B71)),
                  ),
                  const SizedBox(height: 20),
                  OrderStatusStepper(status: order.status), 
                ],
              ),
            ),
            const SizedBox(height: 16),

            
            // CARD RINCIAN PEMBAYARAN 
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rincian Pembayaran',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF005B71)),
                  ),
                  const SizedBox(height: 16),
                  
                  //  DETAIL LAYANAN YANG DIPILIH
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Paket: ${order.service.name}', style: const TextStyle(color: Colors.black87, fontSize: 15)),
                      Text('Rp ${order.service.pricePerKg}/kg', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ONGKOS KIRIM REAL DARI KALKULASI BACKEND (Misal Rp 196.713)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Ongkos Kirim (Jarak Spasial)', style: TextStyle(color: Colors.black54, fontSize: 14)),
                      Text('Rp 196.713', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                    ],
                  ),
                  
                  // JIKA BERAT SUDAH DI-INPUT KURIR DI OUTLET (INVOICE GENERATED)
                  if (order.weight != null && order.invoice != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Berat Pakaian (${order.weight} kg)', style: const TextStyle(color: Colors.black54, fontSize: 14)),
                        Text('Rp ${order.invoice!.totalPrice - 196713}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Color(0xFFE4E6EA), thickness: 1),
                  ),

                  // TOTAL AKHIR ATAU STATUS MENUNGGU TIMBANGAN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Bayar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1C1F24)),
                      ),
                      Text(
                        order.weight == null 
                            ? 'Menunggu Berat' 
                            : 'Rp ${order.invoice?.totalPrice ?? "0"}',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.w900, 
                          color: order.weight == null ? Colors.orange.shade700 : const Color(0xFF005B71)
                        ),
                      ),
                    ],
                  ),
                  
                  if (order.weight == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '*Nota final akan diperbarui otomatis oleh sistem setelah kurir menimbang pakaian di outlet laundry.',
                      style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Builder(
            builder: (context) {
              final authProv = Provider.of<AuthProvider>(context, listen: false);
            
              UserRole roleLogin = UserRole.pelanggan;
              try {
                final dynamic dynamicAuth = authProv;
                
                // Ambil string role dari provider kawanmu
                final String? roleStr = dynamicAuth.role?.toString() ?? 
                                       dynamicAuth.userRole?.toString();
                
                // Jika terdeteksi kata 'kurir' atau 'courier', ubah role ke kurir
                if (roleStr != null && (roleStr.toLowerCase().contains('kurir') || roleStr.toLowerCase().contains('courier'))) {
                  roleLogin = UserRole.kurir;
                }
              } catch (_) {
                roleLogin = UserRole.pelanggan; // Amankan ke pelanggan kalau eror
              }

              final canAct = OrderFlowController.canRoleAct(roleLogin);
              final label = OrderFlowController.actionLabelForRole(roleLogin);

              if (roleLogin == UserRole.pelanggan) {
                return Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF005B71).withAlpha(20),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  alignment: Alignment.center, 
                  child: Text(
                    label, 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF005B71)), 
                  ),
                );
              }

              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DAAC8),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 6,
                ),
                onPressed: canAct
                    ? () {
                        if (order!.status == OrderStatus.dibawa_kurir_ke_laundry) {
                          Navigator.pushReplacementNamed(context, '/invoice_create');
                          return;
                        }
                        _handleCourierAction(order);
                      }
                    : null,
                child: orderProv.isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }
}