import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_notification.dart';
import '../utils/notification_controller.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Notifikasi',
          style: TextStyle(color: Color(0xFF004A5E), fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              NotificationController.markAllAsRead();
            },
            child: const Text('Tandai Dibaca', style: TextStyle(color: Color(0xFF2DAAC8), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<AppNotification>>(
        valueListenable: NotificationController.notifications,
        builder: (context, notifications, child) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationCard(notification: notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1C1F24)),
          ),
          SizedBox(height: 8),
          Text(
            'Semua pemberitahuan pesanan\\nakan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  IconData _getIcon() {
    switch (notification.type) {
      case NotificationType.promo:
        return Icons.local_offer_rounded;
      case NotificationType.orderUpdate:
        return Icons.shopping_bag_rounded;
      case NotificationType.systemInfo:
        return Icons.info_outline_rounded;
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case NotificationType.promo:
        return const Color(0xFF2DAAC8);
      case NotificationType.orderUpdate:
        return const Color(0xFF005B71);
      case NotificationType.systemInfo:
        return Colors.blue;
    }
  }

  String _formatTime() {
    final now = DateTime.now();
    final diff = now.difference(notification.timestamp);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mnt yang lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam yang lalu';
    } else {
      return DateFormat('dd MMM, HH:mm').format(notification.timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isUnread = !notification.isRead;

    return GestureDetector(
      onTap: () {
        NotificationController.markAsRead(notification.id);
        // Bisa tambahkan navigasi spesifik di sini berdasarkan tipe notifikasi
        if (notification.type == NotificationType.orderUpdate) {
          Navigator.pushNamed(context, '/detail_pesanan');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? Colors.white : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isUnread 
              ? const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4))]
              : null,
          border: isUnread 
              ? Border.all(color: const Color(0xFF005B71).withAlpha(30), width: 1.5)
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getIconColor().withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIcon(), color: _getIconColor(), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                            color: isUnread ? const Color(0xFF1C1F24) : Colors.black54,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6, left: 8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2DAAC8),
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUnread ? Colors.black87 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatTime(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
