import 'package:flutter/material.dart';

import '../models/user.dart';
import '../utils/order_flow_controller.dart';
import '../models/order.dart';
import '../widgets/order_status_stepper.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

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
                    'Detail Order', 
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Order ID', style: TextStyle(fontSize: 16, color: Colors.black54)),
                            SizedBox(height: 4),
                            Text('#INV-220525-001', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1C1F24))),
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
                  Row(
                    children: [
                      const CircleAvatar(radius: 24, backgroundColor: Color(0xFFF4F7F5), child: Icon(Icons.person, color: Colors.grey)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Fahrudin Tamimi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            SizedBox(height: 2),
                            Text('+62 812-3456-7890', style: TextStyle(fontSize: 14, color: Colors.black54)),
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
            _card(
              child: ValueListenableBuilder(
                valueListenable: OrderFlowController.status,
                builder: (context, status, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Timeline Status Order',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF005B71)),
                      ),
                      const SizedBox(height: 20),
                      OrderStatusStepper(status: status),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: ValueListenableBuilder(
            valueListenable: OrderFlowController.status,
            builder: (context, status, _) {
              final label = OrderFlowController.actionLabelForRole(UserRole.kurir);
              final canAct = OrderFlowController.canRoleAct(UserRole.kurir);

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
                        if (status == OrderStatus.pickup) {
                          Navigator.pushReplacementNamed(context, '/invoice_create');
                          return;
                        }
                        OrderFlowController.performRoleAction(UserRole.kurir);
                      }
                    : null,
                child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
