import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';

class CourierIncomeScreen extends StatefulWidget {
  const CourierIncomeScreen({super.key});

  @override
  State<CourierIncomeScreen> createState() => _CourierIncomeScreenState();
}

class _CourierIncomeScreenState extends State<CourierIncomeScreen> {
  bool _isLoading = true;
  double _totalIncome = 0;
  List<Order> _completedOrders = [];

  @override
  void initState() {
    super.initState();
    _loadIncomeData();
  }

  Future<void> _loadIncomeData() async {
    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    final authProv = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProv.currentUser?.id ?? '';
    
    // Pastikan myOrders terbaru dimuat (isi userId agar fetch /history, bukan /pickup)
    await orderProv.loadMyOrders(userId);
    
    // Filter pesanan yang sudah selesai
    final finishedOrders = orderProv.myOrders.where((o) => o.status == OrderStatus.selesai).toList();
    
    // Hitung total ongkir (pendapatan kurir)
    double total = 0;
    for (var order in finishedOrders) {
      if (order.ongkir > 0) {
        total += order.ongkir;
      } else {
        // Fallback jika ongkir 0 dari API tapi pesanan sudah selesai
        total += order.service.pricePerKg > 0 ? 5000 : 0; // Contoh fallback ongkir statis jika data hilang
      }
    }

    // Urutkan dari yang terbaru
    finishedOrders.sort((a, b) => b.pickupDate.compareTo(a.pickupDate));

    if (mounted) {
      setState(() {
        _completedOrders = finishedOrders;
        _totalIncome = total;
        _isLoading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Pendapatan Saya', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF005B71),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2DAAC8)))
          : RefreshIndicator(
              onRefresh: _loadIncomeData,
              color: const Color(0xFF2DAAC8),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildIncomeHeader(),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.history, color: Color(0xFF005B71), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Riwayat Pendapatan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _completedOrders.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum ada pendapatan.',
                                  style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Selesaikan pesanan untuk mendapatkan penghasilan!',
                                  style: TextStyle(color: Colors.grey[500]),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final order = _completedOrders[index];
                              final income = order.ongkir > 0 ? order.ongkir : 5000.0;
                              return _buildIncomeCard(order, income);
                            },
                            childCount: _completedOrders.length,
                          ),
                        ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 30)),
                ],
              ),
            ),
    );
  }

  Widget _buildIncomeHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2DAAC8), Color(0xFF005B71)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2DAAC8).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Total Saldo Pendapatan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _formatCurrency(_totalIncome),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Dari ${_completedOrders.length} Pesanan Selesai',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeCard(Order order, double income) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_downward, color: Color(0xFF4CAF50), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesanan #ORD-${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(order.pickupDate),
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '+ ${_formatCurrency(income)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }
}
