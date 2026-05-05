import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';

class NotificationController {
  NotificationController._();

  static final ValueNotifier<List<AppNotification>> notifications = ValueNotifier<List<AppNotification>>([
    AppNotification(
      id: 'welcome',
      title: 'Selamat datang di WashWeswos!',
      message: 'Layanan laundry premium terbaik untuk pakaian kesayangan Anda. Nikmati promo perdana 20% khusus hari ini!',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.promo,
    ),
    AppNotification(
      id: 'system',
      title: 'Pembaruan Sistem',
      message: 'Sekarang Anda bisa melakukan tracking pesanan secara real-time!',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      type: NotificationType.systemInfo,
      isRead: true,
    ),
  ]);

  static void addNotification(AppNotification notification) {
    // Insert at the top of the list
    notifications.value = [notification, ...notifications.value];
  }

  static void markAsRead(String id) {
    notifications.value = notifications.value.map((n) {
      if (n.id == id && !n.isRead) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
  }

  static void markAllAsRead() {
    notifications.value = notifications.value.map((n) => n.copyWith(isRead: true)).toList();
  }
  
  static int get unreadCount => notifications.value.where((n) => !n.isRead).length;
}
