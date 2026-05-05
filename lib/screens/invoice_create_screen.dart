import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../utils/order_flow_controller.dart';
import '../utils/notification_controller.dart';
import '../models/app_notification.dart';

class InvoiceCreateScreen extends StatefulWidget {
  const InvoiceCreateScreen({super.key});

  @override
  State<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends State<InvoiceCreateScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _rateController = TextEditingController(text: '15000');
  final TextEditingController _noteController = TextEditingController();
  
  double _weight = 0.0;
  double _ratePerKg = 15000.0;
  String _selectedService = 'Cuci Kering';
  
  final List<String> _services = [
    'Cuci Ekspres',
    'Cuci Kering',
    'Cuci Setrika',
    'Setrika Saja'
  ];

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_calculateTotal);
    _rateController.addListener(_calculateTotal);
  }
  
  void _calculateTotal() {
    setState(() {
      _weight = double.tryParse(_weightController.text) ?? 0.0;
      _ratePerKg = double.tryParse(_rateController.text) ?? 0.0;
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _rateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = _weight * _ratePerKg;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF004A5E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buat Invoice',
          style: TextStyle(color: Color(0xFF004A5E), fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Customer Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order ID', style: TextStyle(fontSize: 14, color: Colors.black54)),
                      const SizedBox(height: 4),
                      const Text('#INV-220525-001', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1C1F24))),
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0xFFF4F7F5),
                            child: Icon(Icons.person, color: Colors.grey, size: 20),
                          ),
                          SizedBox(width: 12),
                          Text('Fahrudin Tamimi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2DAAC8).withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('PICKUP', style: TextStyle(color: Color(0xFF2DAAC8), fontWeight: FontWeight.w800, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Order Summary Card
          const Text('RINGKASAN PESANAN', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF004A5E), letterSpacing: 1.2)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputField(
                  label: 'Berat Laundry (kg)',
                  child: SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1C1F24)),
                      decoration: InputDecoration(
                        hintText: '0.0',
                        suffixText: ' kg',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        filled: true,
                        fillColor: const Color(0xFFF4F7F5),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ),
                const Divider(color: Color(0xFFE4E6EA), height: 1),
                _buildInputField(
                  label: 'Tarif per kg',
                  child: SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _rateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1C1F24)),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ),
                const Divider(color: Color(0xFFE4E6EA), height: 1),
                _buildInputField(
                  label: 'Layanan',
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedService,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF004A5E)),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1C1F24), fontFamily: 'Montserrat'),
                      alignment: Alignment.centerRight,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedService = newValue;
                          });
                        }
                      },
                      items: _services.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(color: Color(0xFFE4E6EA), height: 1),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Harga', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1C1F24))),
                      Text(
                        _formatCurrency(totalPrice),
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2DAAC8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Notes
          const Text('CATATAN (OPSIONAL)', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF004A5E), letterSpacing: 1.2)),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tambahkan catatan khusus untuk pesanan ini...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004A5E),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            onPressed: _weight > 0 && _ratePerKg > 0 ? () {
              // Save total price
              OrderFlowController.currentTotal.value = totalPrice;
              
              // Finish pickup, advance order status
              OrderFlowController.performRoleAction(UserRole.kurir);
              
              // Add a notification for the customer
              NotificationController.addNotification(AppNotification(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: 'Tagihan Pembayaran Baru',
                message: 'Tagihan untuk pesanan #INV-220525-001 sebesar ${_formatCurrency(totalPrice)} telah diterbitkan. Silakan lakukan pembayaran.',
                timestamp: DateTime.now(),
                type: NotificationType.orderUpdate,
              ));

              Navigator.pushReplacementNamed(context, '/courier_home');
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invoice berhasil dibuat dengan total ${_formatCurrency(totalPrice)}!')),
              );
            } : null, // Disable if no weight or rate inputted
            child: const Text('Simpan & Kirim Invoice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF4E5560))),
          child,
        ],
      ),
    );
  }
}
