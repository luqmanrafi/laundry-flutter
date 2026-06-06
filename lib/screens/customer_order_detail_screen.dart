import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../utils/order_flow_controller.dart';
import '../widgets/order_status_stepper.dart';
import '../widgets/payment_gateway_simulation.dart';

class CustomerOrderDetailScreen extends StatefulWidget {
  final String? orderId; // Menampung jika ada lemparan ID dari halaman riwayat
  const CustomerOrderDetailScreen({super.key, this.orderId});

  @override
  State<CustomerOrderDetailScreen> createState() => _CustomerOrderDetailScreenState();
}

class _CustomerOrderDetailScreenState extends State<CustomerOrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    // OTOMATIS ATUR STATUS STEPPER BERDASARKAN DATA REAL-TIME DI PROVIDER
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProv = context.read<OrderProvider>();
      
      // Jika datang membawa orderId (dari list riwayat), tarik data barunya dulu
      if (widget.orderId != null) {
        print(" Pelanggan menembak API Detail Order ID: ${widget.orderId}");
        orderProv.loadOrderDetail(widget.orderId!);
      } else if (orderProv.currentOrder != null) {
        print(" Pelanggan membaca data aktif memori: #ORD-${orderProv.currentOrder!.id}");
        OrderFlowController.status.value = orderProv.currentOrder!.status;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = Provider.of<OrderProvider>(context);
    final order = orderProv.currentOrder; // Menyedot objek Order riil dari database

    // 1. STATE LOADING: Jika data belum siap dan memori kosong
    if (orderProv.isLoading && order == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF005B71))),
      );
    }

    // 2. STATE ERROR: Jika data kosong total (misal API Laravel crash)
    if (order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7F5),
        appBar: AppBar(title: const Text('Detail Pesanan')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Gagal memuat detail pesanan riil dari server Laravel.', textAlign: TextAlign.center),
          ),
        ),
      );
    }

    // Formatter nominal rupiah polosan tanpa regex ribet
    final double totalBiaya = order.invoice?.totalPrice.toDouble() ?? 0.0;
    final String textHarga = totalBiaya > 0 
        ? 'Rp ${totalBiaya.toInt().toString()}' 
        : 'Menunggu Berat';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            // HEADER TOMBOL KEMBALI
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
                    'Detail Pesanan', 
                    textAlign: TextAlign.center, 
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF005B71)),
                  ),
                ),
                const SizedBox(width: 44),
              ],
            ),
            const SizedBox(height: 24),

            // CARD UTAMA: INFO LAYANAN & ID DATABASE ASLI
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(

                       child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Layanan Paket', style: TextStyle(fontSize: 16, color: Colors.black54)),
                            const SizedBox(height: 4),
                            Builder(
                              builder: (context) {
                                String namaPaketPilihan = 'Cuci Biasa';
                                try {
                                  final dynamic dynamicService = order.service;
                                  // Tembak semua kemungkinan field dari Laravel temanmu
                                  namaPaketPilihan = dynamicService.namaLayanan?.toString() ?? 
                                                     dynamicService.nama?.toString() ?? 
                                                     dynamicService.name?.toString() ?? 
                                                     'Cuci Biasa';
                                } catch (_) {
                                  namaPaketPilihan = 'Cuci Biasa';
                                }

                                return Text(
                                  namaPaketPilihan, 
                                  style: const TextStyle(
                                    fontSize: 24, 
                                    fontWeight: FontWeight.w900, 
                                    color: Color(0xFF1C1F24)
                                  ),
                                );
                              },
                            ),
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
                          order.status.label.toUpperCase(), // <--- DINAMIS STATUS ENUM!
                          style: const TextStyle(color: Color(0xFF2DAAC8), fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE4E6EA)),
                  const SizedBox(height: 16),
                  const Text('Order ID Database', style: TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    '#ORD-${order.id}', // <--- DINAMIS ID AUTO-INCREMENT MYSQL!
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1C1F24)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Alamat Penjemputan', style: TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 4),
                  Text(
                    order.pickupAddress, // <--- DINAMIS ALAMAT RIIL USER!
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // CARD PROGRESS STEPPER
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Progress Pesanan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF005B71)),
                  ),
                  const SizedBox(height: 20),
                  OrderStatusStepper(status: order.status), // <--- STEPPER JALAN SESUAI DATA LAUNDRY
                ],
              ),
            ),
          ],
        ),
      ),

      // BOTTOM NAVIGATION BAR: RINCIAN NOTA & AKSI PEMBAYARAN GATEWAY SIMULASI
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -4))],
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.weight == null ? 'Estimasi Harga' : 'Total Tagihan', 
                    style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    textHarga, // <--- HARGA DARI INVOICE/ONGKIR BACKEND COK!
                    style: const TextStyle(fontSize: 20, color: Color(0xFF005B71), fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // BUTTON TRANSAKSI/PEMBAYARAN UNTUK CUSTOMER
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF005B71),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 4,
                ),
                // Tombol aktif jika status pesanan sedang dicuci/nunggu payment, jika selesai tinggal matikan (null)
                onPressed: (order.status == OrderStatus.siap_dikirim || order.status == OrderStatus.proses_pengantaran)
                    ? () async {
                        final success = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => PaymentGatewaySimulation(amount: totalBiaya),
                        );
                        
                        if (success == true && mounted) {
                          // Update status ke backend via provider
                          context.read<OrderProvider>().updateStatus(order.id, OrderStatus.selesai);
                        }
                      }
                    : null, // Auto disable button jika belum waktunya bayar / sudah selesai
                child: Text(
                  order.status == OrderStatus.selesai 
                      ? 'Pesanan Selesai' 
                      : order.weight == null 
                          ? 'Menunggu Proses Timbangan' 
                          : 'Bayar Sekarang', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ],
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