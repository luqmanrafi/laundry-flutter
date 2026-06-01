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

  // =======================================================================
  // ALUR AKSI KURIR (DISESUAIKAN SAKLEK DENGAN ENUM BARU BACKEND)
  // =======================================================================
  static bool _performCourierAction() {
    switch (status.value) {
      case OrderStatus.pending:
        return _move(OrderStatus.dibawa_kurir_ke_laundry);
      case OrderStatus.dibawa_kurir_ke_laundry:
        return _move(OrderStatus.sedang_dicuci);
      case OrderStatus.siap_dikirim:
        return _move(OrderStatus.proses_pengantaran);
      case OrderStatus.proses_pengantaran:
        return _move(OrderStatus.selesai);
      default:
        return false;
    }
  }

  // =======================================================================
  // ALUR AKSI PELANGGAN (Konfirmasi setelah laundry siap dikirim)
  // =======================================================================
  static bool _performCustomerAction() {
    switch (status.value) {
      case OrderStatus.sedang_dicuci:
        return _move(OrderStatus.siap_dikirim);
      default:
        return false;
    }
  }

  // =======================================================================
  // LABEL TOMBOL DINAMIS UI UNTUK KURIR & PELANGGAN
  // =======================================================================
  static String actionLabelForRole(UserRole role) {
    final current = status.value;
    switch (role) {
      case UserRole.kurir:
        switch (current) {
          case OrderStatus.pending:
            return 'Ambil Order (Pickup)';
          case OrderStatus.dibawa_kurir_ke_laundry:
            return 'Taruh di Toko & Input Berat';
          case OrderStatus.sedang_dicuci:
            return 'Menunggu Proses Cuci Selesai';
          case OrderStatus.siap_dikirim:
            return 'Antar Pakaian Ke Pelanggan';
          case OrderStatus.proses_pengantaran:
            return 'Selesaikan Pesanan';
          case OrderStatus.selesai:
            return 'Order Selesai';
          case OrderStatus.cancelled:
            return 'Order Dibatalkan';
        }
      case UserRole.pelanggan:
        switch (current) {
          case OrderStatus.pending:
          case OrderStatus.dibawa_kurir_ke_laundry:
            return 'Menunggu Invoice Kurir';
          case OrderStatus.sedang_dicuci:
            return 'Bayar & Konfirmasi Pesanan';
          case OrderStatus.siap_dikirim:
            return 'Pesanan Siap Dikirim';
          case OrderStatus.proses_pengantaran:
            return 'Kurir Sedang Di Jalan';
          case OrderStatus.selesai:
            return 'Order Selesai';
          case OrderStatus.cancelled:
            return 'Order Dibatalkan';
        }
    }
  }

  // =======================================================================
  // VALIDASI APAKAH TOMBOL BISA DIKLIK ATAU DISABLE
  // =======================================================================
  static bool canRoleAct(UserRole role) {
    final current = status.value;
    if (current.isTerminal) return false;
    switch (role) {
      case UserRole.kurir:
        return current == OrderStatus.pending ||
            current == OrderStatus.dibawa_kurir_ke_laundry ||
            current == OrderStatus.siap_dikirim ||
            current == OrderStatus.proses_pengantaran;
      case UserRole.pelanggan:
        return current == OrderStatus.sedang_dicuci;
    }
  }
}