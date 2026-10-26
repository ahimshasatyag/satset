import 'package:flutter/material.dart';
import 'package:satset/features/notifications/domain/repositories/notification_repository.dart';
import 'package:satset/features/notifications/presentation/pages/notifications_page.dart';

/// Halaman Notifikasi khusus untuk peran Kurir (Courier)
/// Menampilkan pemberitahuan penugasan kiriman baru, tugas mendesak,
/// pembaruan rute operasional, dan status pengiriman.
class CourierNotificationsPage extends StatelessWidget {
  final String? courierId;
  final NotificationRepository? repository;

  const CourierNotificationsPage({
    super.key,
    this.courierId,
    this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationsPage(
      isCourier: true,
      courierId: courierId,
      repository: repository,
    );
  }
}
