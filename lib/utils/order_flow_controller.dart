import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/user.dart';

class OrderFlowController {
  OrderFlowController._();

  static final ValueNotifier<OrderStatus> status =
      ValueNotifier<OrderStatus>(OrderStatus.pending);
      
  static final ValueNotifier<double> currentTotal = 
      ValueNotifier<double>(0.0);

  static void reset() {
    status.value = OrderStatus.pending;
    currentTotal.value = 0.0;
  }

  static bool _move(OrderStatus next) {
    if (!canMoveToNextStatus(status.value, next)) return false;
    status.value = next;
    return true;
  }

  static bool cancelOrder() {
    if (status.value.isTerminal) return false;
    status.value = OrderStatus.cancelled;
    return true;
  }

  static bool performRoleAction(UserRole role) {
    switch (role) {
      case UserRole.kurir:
        return _performCourierAction();
      case UserRole.pelanggan:
        return _performCustomerAction();
    }
  }

  static bool _performCourierAction() {
    switch (status.value) {
      case OrderStatus.pending:
        return _move(OrderStatus.pickup);
      case OrderStatus.pickup:
        return _move(OrderStatus.waitingConfirmation);
      case OrderStatus.processing:
        return _move(OrderStatus.delivery);
      case OrderStatus.delivery:
        return _move(OrderStatus.completed);
      default:
        return false;
    }
  }

  static bool _performCustomerAction() {
    switch (status.value) {
      case OrderStatus.waitingConfirmation:
        return _move(OrderStatus.processing);
      default:
        return false;
    }
  }



  static String actionLabelForRole(UserRole role) {
    final current = status.value;
    switch (role) {
      case UserRole.kurir:
        switch (current) {
          case OrderStatus.pending:
            return 'Ambil Order';
          case OrderStatus.pickup:
            return 'Kirim Invoice';
          case OrderStatus.processing:
            return 'Update ke Delivery';
          case OrderStatus.delivery:
            return 'Selesaikan Order';
          case OrderStatus.waitingConfirmation:
            return 'Menunggu Konfirmasi User';
          case OrderStatus.completed:
            return 'Order Selesai';
          case OrderStatus.cancelled:
            return 'Order Dibatalkan';
        }
      case UserRole.pelanggan:
        switch (current) {
          case OrderStatus.waitingConfirmation:
            return 'Bayar & Konfirmasi Pesanan';
          case OrderStatus.pending:
          case OrderStatus.pickup:
            return 'Menunggu Invoice';
          case OrderStatus.processing:
            return 'Sedang Diproses';
          case OrderStatus.delivery:
            return 'Sedang Diantar';
          case OrderStatus.completed:
            return 'Order Selesai';
          case OrderStatus.cancelled:
            return 'Order Dibatalkan';
        }
    }
  }

  static bool canRoleAct(UserRole role) {
    final current = status.value;
    if (current.isTerminal) return false;
    switch (role) {
      case UserRole.kurir:
        return current == OrderStatus.pending ||
            current == OrderStatus.pickup ||
            current == OrderStatus.processing ||
            current == OrderStatus.delivery;
      case UserRole.pelanggan:
        return current == OrderStatus.waitingConfirmation;
    }
  }
}
