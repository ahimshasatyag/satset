import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/notification_item.dart';

class NotificationEmptyState extends StatelessWidget {
  final NotificationFilter activeFilter;
  final VoidCallback onRefresh;

  const NotificationEmptyState({
    super.key,
    required this.activeFilter,
    required this.onRefresh,
  });

  IconData _getEmptyIcon() {
    switch (activeFilter) {
      case NotificationFilter.unread:
        return Icons.mark_email_read_outlined;
      case NotificationFilter.shipment:
        return Icons.local_shipping_outlined;
      case NotificationFilter.payment:
        return Icons.account_balance_wallet_outlined;
      case NotificationFilter.all:
      default:
        return Icons.notifications_off_outlined;
    }
  }

  String _getTitle() {
    switch (activeFilter) {
      case NotificationFilter.unread:
        return 'Semua Notifikasi Telah Dibaca';
      case NotificationFilter.shipment:
        return 'Belum Ada Info Pengiriman';
      case NotificationFilter.payment:
        return 'Belum Ada Info Pembayaran';
      case NotificationFilter.all:
      default:
        return 'Kotak Masuk Masih Bersih';
    }
  }

  String _getMessage() {
    switch (activeFilter) {
      case NotificationFilter.unread:
        return 'Bagus! Anda telah membaca semua pembaruan status dan pengumuman terbaru.';
      case NotificationFilter.shipment:
        return 'Pemberitahuan perubahan status paket dan pergerakan kurir akan muncul di sini.';
      case NotificationFilter.payment:
        return 'Konfirmasi transaksi, tagihan ongkir, dan status pembayaran akan dicatat di sini.';
      case NotificationFilter.all:
      default:
        return 'Pemberitahuan terkait paket, kurir, dan keamanan akun Anda akan tampil di halaman ini.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariantLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getEmptyIcon(),
                size: 38,
                color: Colors.grey.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _getTitle(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _getMessage(),
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Segarkan Notifikasi',
              size: ButtonSize.small,
              variant: ButtonVariant.outlined,
              prefixIcon: const Icon(Icons.refresh_rounded, size: 16),
              onPressed: onRefresh,
            ),
          ],
        ),
      ),
    );
  }
}
