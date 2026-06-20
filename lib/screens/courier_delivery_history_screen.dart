import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../models/order.dart';

class CourierDeliveryHistoryScreen extends StatefulWidget {
  const CourierDeliveryHistoryScreen({super.key});

  @override
  State<CourierDeliveryHistoryScreen> createState() => _CourierDeliveryHistoryScreenState();
}

class _CourierDeliveryHistoryScreenState extends State<CourierDeliveryHistoryScreen> {
  bool _isLoading = true;
  List<Order> _deliveredOrders = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    final orderProv = Provider.of<OrderProvider>(context, listen: false);
    
    // Gunakan fungsi loadCourierHistory yang baru dibuat
    final historyList = await orderProv.loadCourierHistory();
    
    // Filter pesanan yang sudah selesai (Tugas Pengiriman Sukses)
    final finishedOrders = historyList.where((o) => o.status == OrderStatus.selesai).toList();
    
    // Urutkan dari yang terbaru
    finishedOrders.sort((a, b) => b.pickupDate.compareTo(a.pickupDate));

    if (mounted) {
      setState(() {
        _deliveredOrders = finishedOrders;
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd MMMM yyyy, HH:mm', 'id_ID');
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: const Text('Riwayat Pengiriman', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF005B71),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2DAAC8)))
          : RefreshIndicator(
              onRefresh: _loadHistoryData,
              color: const Color(0xFF2DAAC8),
              child: _deliveredOrders.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _deliveredOrders.length,
                      itemBuilder: (context, index) {
                        return _buildDeliveryCard(_deliveredOrders[index]);
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2DAAC8).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline, size: 80, color: Color(0xFF2DAAC8)),
            ),
            const SizedBox(height: 24),
            Text(
              'Belum ada Riwayat',
              style: TextStyle(fontSize: 22, color: Colors.grey[800], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Anda belum menyelesaikan pengiriman apapun. Selesaikan pesanan untuk melihat riwayat tugas Anda di sini.',
                style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, size: 18, color: Color(0xFF005B71)),
                    const SizedBox(width: 8),
                    Text(
                      '#ORD-${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF005B71), fontSize: 15),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.check_circle, size: 14, color: Color(0xFF4CAF50)),
                      SizedBox(width: 4),
                      Text('Selesai', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
          ),
          
          // Card Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2DAAC8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_pin_circle_outlined, color: Color(0xFF2DAAC8), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customer.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.pickupAddress,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_laundry_service, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.service.name,
                          style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(order.pickupDate),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
