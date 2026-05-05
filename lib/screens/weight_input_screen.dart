import 'package:flutter/material.dart';

import '../models/user.dart';
import '../models/order.dart';
import '../utils/order_flow_controller.dart';

class WeightInputScreen extends StatelessWidget {
  const WeightInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Input Berat Laundry'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD2D8E0)),
            ),
            padding: const EdgeInsets.all(14),
            child: ValueListenableBuilder(
              valueListenable: OrderFlowController.status,
              builder: (context, status, child) => Text('Status saat ini: ${status.label}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A66AF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              OrderFlowController.performRoleAction(UserRole.kurir);
              Navigator.pushReplacementNamed(context, '/detail_pesanan');
            },
            child: const Text('Kirim Invoice ->', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
