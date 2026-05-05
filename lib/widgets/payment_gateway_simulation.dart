import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../utils/notification_controller.dart';

enum PaymentState { selecting, processing, success }

class PaymentGatewaySimulation extends StatefulWidget {
  final double amount;
  
  const PaymentGatewaySimulation({super.key, required this.amount});

  @override
  State<PaymentGatewaySimulation> createState() => _PaymentGatewaySimulationState();
}

class _PaymentGatewaySimulationState extends State<PaymentGatewaySimulation> {
  PaymentState _state = PaymentState.selecting;

  void _processPayment(String method) async {
    setState(() {
      _state = PaymentState.processing;
    });
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;
    setState(() {
      _state = PaymentState.success;
    });
    
    // Simulate reading success screen before closing
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Add notification
    NotificationController.addNotification(AppNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Pembayaran Berhasil',
      message: 'Pembayaran sebesar ${_formatCurrency(widget.amount)} menggunakan $method telah kami terima. Cucian Anda sedang diproses!',
      timestamp: DateTime.now(),
      type: NotificationType.orderUpdate,
    ));

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  String _formatCurrency(double amount) {
    return 'Rp ${amount.toInt().toString().replaceAll(RegExp(r"\\B(?=(\\d{3})+(?!\\d))"), ".")}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Dynamic content based on state
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case PaymentState.selecting:
        return Column(
          key: const ValueKey('selecting'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pembayaran',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                Text(
                  _formatCurrency(widget.amount),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF005B71)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Pilih Metode Pembayaran',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _buildPaymentMethod('GoPay', Icons.account_balance_wallet, Colors.blue),
            const SizedBox(height: 12),
            _buildPaymentMethod('OVO', Icons.account_balance_wallet_outlined, Colors.purple),
            const SizedBox(height: 12),
            _buildPaymentMethod('BCA Virtual Account', Icons.account_balance, Colors.blue.shade800),
            const SizedBox(height: 12),
            _buildPaymentMethod('Mandiri Virtual Account', Icons.account_balance, Colors.orange.shade700),
          ],
        );
      
      case PaymentState.processing:
        return Container(
          key: const ValueKey('processing'),
          height: 250,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: Color(0xFF005B71)),
              SizedBox(height: 24),
              Text(
                'Memproses Pembayaran...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF005B71)),
              ),
              SizedBox(height: 8),
              Text(
                'Mohon jangan tutup halaman ini',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        );
        
      case PaymentState.success:
        return Container(
          key: const ValueKey('success'),
          height: 250,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pembayaran Berhasil!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.green),
              ),
              const SizedBox(height: 8),
              Text(
                _formatCurrency(widget.amount),
                style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildPaymentMethod(String title, IconData icon, Color iconColor) {
    return InkWell(
      onTap: () => _processPayment(title),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
