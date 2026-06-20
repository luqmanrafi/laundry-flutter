import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../utils/order_flow_controller.dart';
import '../widgets/order_status_stepper.dart';
import '../widgets/payment_gateway_simulation.dart';
import '../widgets/address_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'courier_tracking_screen.dart';

class CustomerOrderDetailScreen extends StatefulWidget {
  final String? orderId;
  const CustomerOrderDetailScreen({super.key, this.orderId});

  @override
  State<CustomerOrderDetailScreen> createState() => _CustomerOrderDetailScreenState();
}

class _CustomerOrderDetailScreenState extends State<CustomerOrderDetailScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProv = context.read<OrderProvider>();
      if (widget.orderId != null) {
        orderProv.loadOrderDetail(widget.orderId!);
      } else if (orderProv.currentOrder != null) {
        orderProv.refreshCurrentOrder();
        OrderFlowController.status.value = orderProv.currentOrder!.status;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh order details automatically when returning to app (e.g., after Midtrans payment)
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    final orderProv = context.read<OrderProvider>();
    if (widget.orderId != null) {
      await orderProv.loadOrderDetail(widget.orderId!);
    } else {
      await orderProv.refreshCurrentOrder();
    }
  }

  // Melakukan polling refresh 3 kali setelah kembali dari Midtrans
  Future<void> _pollRefreshData() async {
    for (int i = 0; i < 3; i++) {
      if (!mounted) return;
      await _refreshData();
      final orderProv = context.read<OrderProvider>();
      final currentOrder = widget.orderId != null ? orderProv.currentOrder : orderProv.currentOrder;
      if (currentOrder != null && currentOrder.paymentStatus == 'paid') {
        break; // Sudah lunas, berhenti polling
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  /// Cek apakah invoice sudah diterbitkan berdasarkan STATUS (bukan weight)
  bool _isInvoiceReady(Order order) {
    return order.status == OrderStatus.dibawa_kurir_ke_laundry ||
           order.status == OrderStatus.sedang_dicuci ||
           order.status == OrderStatus.siap_dikirim ||
           order.status == OrderStatus.proses_pengantaran ||
           order.status == OrderStatus.selesai;
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = Provider.of<OrderProvider>(context);
    final order = orderProv.currentOrder;

    if (orderProv.isLoading && order == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF005B71))),
      );
    }

    if (order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7F5),
        appBar: AppBar(title: const Text('Detail Pesanan')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Gagal memuat detail pesanan dari server.', textAlign: TextAlign.center),
          ),
        ),
      );
    }

    // Status-based invoice check — BUKAN weight-based semata
    final bool isStatusEligible = _isInvoiceReady(order);

    // Ambil data invoice
    final double beratLaundry = order.weight ?? order.invoice?.weight ?? 0.0;
    final int tarifPerKg = order.invoice?.pricePerKg ?? order.service.pricePerKg;
    final double biayaLaundry = beratLaundry * tarifPerKg;
    final double totalBiaya = isStatusEligible
        ? (order.invoice?.totalPrice.toDouble() ?? biayaLaundry)
        : 0.0;
    final double ongkosKirim = order.ongkir ?? 0.0;
    
    // Total Akhir dari invoice/backend (totalBiaya) sudah termasuk ongkir.
    // Jika belum ada invoice (totalBiaya == 0), gunakan estimasi (biayaLaundry + ongkosKirim).
    final double displayTotal = (totalBiaya > 0) ? totalBiaya : (biayaLaundry > 0 ? biayaLaundry + ongkosKirim : 0.0);
    
    // Invoice BENAR-BENAR siap jika status memenuhi DAN total tagihan > 0
    final bool invoiceReady = isStatusEligible && displayTotal > 0;

    final String textHarga = invoiceReady 
        ? _formatCurrency(displayTotal)
        : 'Menunggu Invoice';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: const Color(0xFF005B71),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // HEADER
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

              // CARD UTAMA: INFO LAYANAN & ID
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
                                    namaPaketPilihan = dynamicService.namaLayanan?.toString() ??
                                                       dynamicService.nama?.toString() ??
                                                       dynamicService.name?.toString() ??
                                                       'Cuci Biasa';
                                  } catch (_) {
                                    namaPaketPilihan = 'Cuci Biasa';
                                  }
                                  return Text(
                                    namaPaketPilihan,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1F24)),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _statusColor(order.status).withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            order.status.label.toUpperCase(),
                            style: TextStyle(color: _statusColor(order.status), fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE4E6EA)),
                    const SizedBox(height: 16),
                    const Text('Nama Pelanggan', style: TextStyle(fontSize: 14, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        final authProv = Provider.of<AuthProvider>(context, listen: false);
                        final String customerName = ((order.customer.name == 'Pelanggan Asli' || order.customer.name == 'Pelanggan Anonim') && authProv.currentUser?.name != null)
                            ? authProv.currentUser!.name
                            : order.customer.name;
                        return Text(
                          customerName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1C1F24)),
                        );
                      }
                    ),
                    const SizedBox(height: 12),
                    const Text('Order ID Database', style: TextStyle(fontSize: 14, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text(
                      '#ORD-${order.id}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1C1F24)),
                    ),
                    const SizedBox(height: 12),
                    const Text('Alamat Penjemputan', style: TextStyle(fontSize: 14, color: Colors.black54)),
                    const SizedBox(height: 4),
                    AddressText(
                      address: order.pickupAddress,
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
                    OrderStatusStepper(status: order.status),
                    
                    if (order.status == OrderStatus.pending || 
                        order.status == OrderStatus.dibawa_kurir_ke_laundry || 
                        order.status == OrderStatus.proses_pengantaran) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CourierTrackingScreen(orderId: order.id)),
                          );
                        },
                        icon: const Icon(Icons.motorcycle_rounded),
                        label: const Text('Lacak Posisi Kurir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2DAAC8),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ══════════════════════════════════════════════
              // CARD INVOICE — Muncul ketika status >= sedang_dicuci
              // ══════════════════════════════════════════════
              if (invoiceReady) ...[
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2DAAC8).withAlpha(25),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF2DAAC8), size: 24),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Invoice Laundry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF005B71))),
                                SizedBox(height: 2),
                                Text('Tagihan dari kurir', style: TextStyle(fontSize: 13, color: Colors.black54)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: (order.paymentStatus == 'paid' || order.status == OrderStatus.selesai)
                                  ? Colors.green.shade50 
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              (order.paymentStatus == 'paid' || order.status == OrderStatus.selesai) ? 'Lunas' : 'Belum Bayar',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: (order.paymentStatus == 'paid' || order.status == OrderStatus.selesai)
                                    ? Colors.green.shade700 
                                    : Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFFE4E6EA), height: 1),
                      const SizedBox(height: 16),

                      // Detail Layanan
                      _invoiceRow('Layanan', order.service.name),
                      const SizedBox(height: 10),
                      _invoiceRow('Tarif per kg', _formatCurrency(tarifPerKg.toDouble())),
                      const SizedBox(height: 10),
                      _invoiceRow(
                        'Berat Pakaian',
                        beratLaundry > 0 ? '${beratLaundry.toStringAsFixed(1)} kg' : 'Sedang diproses',
                      ),
                      if (biayaLaundry > 0) ...[
                        const SizedBox(height: 10),
                        _invoiceRow('Biaya Laundry', _formatCurrency(biayaLaundry)),
                      ],
                      if (ongkosKirim > 0) ...[
                        const SizedBox(height: 10),
                        _invoiceRow('Ongkos Kirim', _formatCurrency(ongkosKirim)),
                      ],

                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFE4E6EA), height: 1),
                      const SizedBox(height: 16),

                      // Total Tagihan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Tagihan',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1C1F24)),
                          ),
                          Text(
                            displayTotal > 0 ? _formatCurrency(displayTotal) : 'Rp -',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2DAAC8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // CARD MENUNGGU INVOICE — belum sampai tahap sedang_dicuci
                _card(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.hourglass_top_rounded, color: Colors.orange.shade600, size: 32),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Menunggu Invoice dari Kurir',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1C1F24)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Invoice akan tersedia setelah kurir menimbang dan menginput berat pakaian di rumah Anda.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),

      // BOTTOM NAVIGATION BAR
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
                    invoiceReady ? 'Total Tagihan' : 'Estimasi Harga',
                    style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    textHarga,
                    style: TextStyle(
                      fontSize: 20,
                      color: invoiceReady ? const Color(0xFF005B71) : Colors.orange.shade700,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // TOMBOL PEMBAYARAN
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF005B71),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 4,
                ),
                // Tombol aktif jika status dibawa_kurir_ke_laundry atau sedang_dicuci (invoice sudah terbit), dan paymentStatus bukan 'paid'
                onPressed: ((order.status == OrderStatus.dibawa_kurir_ke_laundry || order.status == OrderStatus.sedang_dicuci) && invoiceReady && order.paymentStatus != 'paid')
                    ? () async {
                        final orderProv = context.read<OrderProvider>();
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Memproses pembayaran...'), duration: Duration(seconds: 1)),
                        );

                        final paymentUrl = await orderProv.payOrder(order.id, displayTotal);

                        if (paymentUrl != null) {
                          final uri = Uri.parse(paymentUrl);
                          try {
                            // Tunggu sampai pengguna menutup inAppBrowserView
                            await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                            
                            // Setelah kembali, polling data untuk memastikan status terupdate
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Memeriksa status pembayaran...'),
                                  backgroundColor: Color(0xFF005B71),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              await _pollRefreshData();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gagal membuka halaman pembayaran'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Gagal membuat link pembayaran'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      }
                    : null,
                child: Text(
                  _buttonLabel(order, invoiceReady),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),

              // TOMBOL BATALKAN PESANAN (hanya saat pending)
              if (order.status == OrderStatus.pending) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: orderProv.isLoading ? null : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Batalkan Pesanan'),
                        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Tidak'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Ya, Batalkan'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      final success = await orderProv.updateStatus(order.id, OrderStatus.cancelled);
                      if (success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pesanan berhasil dibatalkan.')),
                        );
                        Navigator.pop(context);
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Gagal membatalkan pesanan.')),
                        );
                      }
                    }
                  },
                  child: orderProv.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2),
                        )
                      : const Text('Batalkan Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════

  String _buttonLabel(Order order, bool invoiceReady) {
    if (order.status == OrderStatus.selesai) {
      return 'Pesanan Selesai';
    }
    if (order.status == OrderStatus.cancelled) {
      return 'Pesanan Dibatalkan';
    }
    if (order.status == OrderStatus.siap_dikirim || order.status == OrderStatus.proses_pengantaran) {
      return 'Sudah Dibayar (Proses Pengiriman)';
    }

    if (order.status == OrderStatus.dibawa_kurir_ke_laundry || order.status == OrderStatus.sedang_dicuci) {
      if (!invoiceReady) return 'Menunggu Invoice Kurir';
      if (order.paymentStatus == 'paid') {
        return order.status == OrderStatus.sedang_dicuci ? 'Lunas (Proses Cuci)' : 'Lunas (Menunggu Proses Cuci)';
      }
      return 'Bayar Sekarang';
    }

    return 'Menunggu Invoice Kurir';
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.sedang_dicuci:
        return const Color(0xFF2DAAC8);
      case OrderStatus.siap_dikirim:
      case OrderStatus.selesai:
        return Colors.green.shade600;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return const Color(0xFF2DAAC8);
    }
  }

  Widget _invoiceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1C1F24))),
      ],
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