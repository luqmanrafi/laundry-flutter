import 'package:flutter/material.dart';

import '../models/order.dart';
import '../utils/order_flow_controller.dart';

class OrderStatusStepper extends StatelessWidget {
  final OrderStatus status;
  const OrderStatusStepper({super.key, required this.status});

  static const List<OrderStatus> _steps = [
    OrderStatus.pending,
    OrderStatus.pickup,
    OrderStatus.waitingConfirmation,
    OrderStatus.processing,
    OrderStatus.delivery,
    OrderStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    if (status == OrderStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE4E4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFB1B1)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: Color(0xFFC62828)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Order dibatalkan',
                style: TextStyle(color: Color(0xFFC62828), fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    final currentIndex = _steps.indexOf(status);

    return Column(
      children: List.generate(_steps.length, (index) {
        final step = _steps[index];
        final isDone = index < currentIndex;
        final isActive = index == currentIndex;
        final isLast = index == _steps.length - 1;

        return InkWell(
          onTap: () {
            // Allows manual override of the status by tapping
            OrderFlowController.status.value = step;
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isDone || isActive ? const Color(0xFF005B71) : const Color(0xFFD5DBE3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDone ? Icons.check : Icons.circle,
                      size: isDone ? 14 : 8,
                      color: Colors.white,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 32,
                      color: isDone ? const Color(0xFF005B71) : const Color(0xFFD5DBE3),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    step.label,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isDone || isActive ? const Color(0xFF1C1F24) : const Color(0xFF8B94A1),
                      fontSize: isActive ? 16 : 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
