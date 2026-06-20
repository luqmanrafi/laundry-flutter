import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../models/user.dart';
import '../providers/order_provider.dart';
import '../utils/order_flow_controller.dart';
import '../widgets/order_status_stepper.dart';
import '../providers/auth_provider.dart';
import '../widgets/address_text.dart';

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

  Future<void> _openWhatsApp(String phone) async {
    String formattedPhone = phone;
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '62${formattedPhone.substring(1)}';
    }

    final Uri waUrl = Uri.parse('https://wa.me/$formattedPhone');
    if (await canLaunchUrl(waUrl)) {
      await launchUrl(waUrl);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    }
  }

  Future<void> _handleCourierAction(Order order) async {
    final orderProv = context.read<OrderProvider>();
    
    if (order.status == OrderStatus.pending) {
      final success = await orderProv.takeOrder(order.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil diambil!')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maaf, pesanan ini sudah diambil oleh kurir lain.')),
        );
        orderProv.loadMyOrders('');
        Navigator.pop(context); // Kembali ke list utama
      }
      return;
    }

    OrderStatus? nextStatus;
    switch (order.status) {
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
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Order ID', style: TextStyle(fontSize: 14, color: Colors.black54)),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text('#ORD\u2011${order.id}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1C1F24))),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2DAAC8).withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            order.status.label.toUpperCase(), 
                            style: const TextStyle(color: Color(0xFF2DAAC8), fontWeight: FontWeight.w800, fontSize: 11),
                            textAlign: TextAlign.right,
                          ),
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
                        child: Builder(
                          builder: (context) {
                            final authProv = Provider.of<AuthProvider>(context, listen: false);
                            final bool isPelanggan = authProv.currentUser?.role == UserRole.pelanggan;
                            final String customerName = ((order.customer.name == 'Pelanggan Asli' || order.customer.name == 'Pelanggan Anonim') && authProv.currentUser?.name != null && isPelanggan)
                                ? authProv.currentUser!.name
                                : order.customer.name;
                            final String customerEmail = (order.customer.email == 'pelanggan@laundry.com' && authProv.currentUser?.email != null && isPelanggan)
                                ? authProv.currentUser!.email
                                : order.customer.email;
                            
                            // Gunakan no HP pelanggan. Jika kosong, buat no dummy berdasarkan panjang nama agar unik
                            final String displayPhone = order.customer.phone ?? '0812999${order.customer.name.length}000';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customerName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.phone, size: 14, color: Color(0xFF005B71)),
                                    const SizedBox(width: 4),
                                    Text(displayPhone, style: const TextStyle(fontSize: 14, color: Color(0xFF005B71), fontWeight: FontWeight.bold)),
                                  ],
                                )
                              ],
                            );
                          }
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final String targetPhone = order.customer.phone ?? '0812999${order.customer.name.length}000';
                          return IconButton(
                            icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFF25D366).withAlpha(20),
                              padding: const EdgeInsets.all(12),
                            ),
                            onPressed: () => _openWhatsApp(targetPhone),
                          );
                        }
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: Color(0xFFE4E6EA)),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined, color: Color(0xFF005B71), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Alamat Penjemputan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                            const SizedBox(height: 4),
                            AddressText(
                              address: order.pickupAddress,
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (order.jarakMeter != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Color(0xFFE4E6EA)),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.social_distance_outlined, color: Color(0xFF005B71), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Jarak ke Pelanggan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text(
                                '${(order.jarakMeter! / 1000).toStringAsFixed(1)} km',
                                style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rincian Pembayaran',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF005B71)),
                      ),
                      Builder(
                        builder: (context) {
                          final authProv = Provider.of<AuthProvider>(context, listen: false);
                          final roleLogin = authProv.currentUser?.role ?? UserRole.pelanggan;
                          if (roleLogin == UserRole.kurir && order.status == OrderStatus.sedang_dicuci && order.paymentStatus != 'paid') {
                            return InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '/invoice_create');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2DAAC8).withAlpha(20),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit, size: 14, color: Color(0xFF2DAAC8)),
                                    SizedBox(width: 4),
                                    Text('Edit', style: TextStyle(color: Color(0xFF2DAAC8), fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        }
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  //  DETAIL LAYANAN YANG DIPILIH
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Paket: ${order.service.name}', style: const TextStyle(color: Colors.black87, fontSize: 15)),
                      Text('${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(order.service.pricePerKg)}/kg', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  
                  // JIKA BERAT SUDAH DI-INPUT KURIR (INVOICE GENERATED)
                  if (order.weight != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Berat Pakaian', style: TextStyle(color: Colors.black54, fontSize: 14)),
                        Text('${order.weight} kg', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Biaya Laundry', style: TextStyle(color: Colors.black54, fontSize: 14)),
                        Text(
                          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format((order.weight ?? 0) * order.service.pricePerKg),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('PPN (11%)', style: TextStyle(color: Colors.black54, fontSize: 14)),
                        Text(
                          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(((order.weight ?? 0) * order.service.pricePerKg) * 0.11),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ongkos Kirim', style: TextStyle(color: Colors.black54, fontSize: 14)),
                        Text(
                          NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(order.ongkir),
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
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
                            : NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(order.invoice?.totalPrice ?? (((order.weight! * order.service.pricePerKg) * 1.11) + order.ongkir).round()),
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
                      '*Nota final akan diperbarui otomatis oleh sistem setelah kurir menimbang pakaian di rumah Pelanggan.',
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
              final UserRole roleLogin = authProv.currentUser?.role ?? UserRole.pelanggan;

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
                        if (order!.status == OrderStatus.kurir_menuju_lokasi) {
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