import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/order.dart';
import '../utils/order_flow_controller.dart';
import '../widgets/order_status_stepper.dart';
import '../widgets/payment_gateway_simulation.dart';

class CustomerOrderDetailScreen extends StatelessWidget {
  const CustomerOrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
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
                          children: const [
                            Text('Layanan', style: TextStyle(fontSize: 16, color: Colors.black54)),
                            SizedBox(height: 4),
                            Text('Cuci Kering', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1F24))),
                          ],
                        ),
                      ),
                      ValueListenableBuilder(
                        valueListenable: OrderFlowController.status,
                        builder: (context, status, child) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2DAAC8).withAlpha(30),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.label.toUpperCase(),
                            style: const TextStyle(color: Color(0xFF2DAAC8), fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE4E6EA)),
                  const SizedBox(height: 16),
                  const Text('Order ID', style: TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 4),
                  const Text('#INV-220525-001', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1C1F24))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _card(
              child: ValueListenableBuilder(
                valueListenable: OrderFlowController.status,
                builder: (context, status, child) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress Pesanan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF005B71)),
                    ),
                    const SizedBox(height: 20),
                    OrderStatusStepper(status: status),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
              ValueListenableBuilder(
                valueListenable: OrderFlowController.status,
                builder: (context, status, child) {
                  return ValueListenableBuilder(
                    valueListenable: OrderFlowController.currentTotal,
                    builder: (context, total, child) {
                      final hasInvoice = status.index >= OrderStatus.waitingConfirmation.index;
                      final priceLabel = hasInvoice ? 'Total Tagihan' : 'Estimasi Harga';
                      
                      // Using NumberFormat would be better, but we'll manually format for simplicity here if needed, 
                      // or just use intl if it's imported. Wait, I should just use intl or a simple replace.
                      // Actually, let's just do a simple String.
                      final formatter = total > 0 
                          ? 'Rp ${total.toInt().toString().replaceAll(RegExp(r"\\B(?=(\\d{3})+(?!\\d))"), ".")}' 
                          : 'Rp 20.000 / Kg';

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(priceLabel, style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600)),
                              Text(formatter, style: const TextStyle(fontSize: 20, color: Color(0xFF005B71), fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Builder(
                            builder: (context) {
                              final canAct = OrderFlowController.canRoleAct(UserRole.pelanggan);
                              final label = OrderFlowController.actionLabelForRole(UserRole.pelanggan);

                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  backgroundColor: const Color(0xFF005B71),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                  elevation: 4,
                                ),
                                onPressed: canAct
                                    ? () async {
                                        // If it's a payment action, show the gateway first
                                        if (status.index == OrderStatus.waitingConfirmation.index) {
                                          final success = await showModalBottomSheet<bool>(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => PaymentGatewaySimulation(amount: total),
                                          );
                                          
                                          if (success == true) {
                                            OrderFlowController.performRoleAction(UserRole.pelanggan);
                                          }
                                        } else {
                                          // Other actions
                                          OrderFlowController.performRoleAction(UserRole.pelanggan);
                                        }
                                      }
                                    : null,
                                child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                              );
                            }
                          ),
                        ],
                      );
                    }
                  );
                },
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
