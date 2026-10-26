import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import '../../domain/entities/notification_item.dart';

class NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final ValueChanged<NotificationItem>? onTap;
  final ValueChanged<String>? onMarkAsRead;
  final ValueChanged<String>? onDelete;

  const NotificationCard({
    super.key,
    required this.item,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
  });

  IconData _getIcon() {
    switch (item.type) {
      case NotificationType.shipment:
        return Icons.local_shipping_rounded;
      case NotificationType.payment:
        return Icons.account_balance_wallet_rounded;
      case NotificationType.account:
        return Icons.shield_rounded;
      case NotificationType.promo:
        return Icons.discount_rounded;
      case NotificationType.system:
        return Icons.info_outline_rounded;
      case NotificationType.taskAssignment:
        return Icons.assignment_rounded;
      case NotificationType.urgentTask:
        return Icons.warning_amber_rounded;
    }
  }

  Color _getColor() {
    switch (item.type) {
      case NotificationType.shipment:
        return AppColors.primary;
      case NotificationType.payment:
        return AppColors.secondary;
      case NotificationType.account:
        return AppColors.tertiary;
      case NotificationType.promo:
        return AppColors.warning;
      case NotificationType.system:
        return AppColors.info;
      case NotificationType.taskAssignment:
        return AppColors.primary;
      case NotificationType.urgentTask:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = _getColor();

    return Dismissible(
      key: Key('notif-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        onDelete?.call(item.id);
      },
      child: InkWell(
        onTap: () => onTap?.call(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: !item.isRead
                ? (isDark
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.primary50.withValues(alpha: 0.6))
                : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: !item.isRead
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
              width: !item.isRead ? 1.2 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ikon Kategori Notifikasi
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getIcon(), color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),

                  // Judul & Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: !item.isRead
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!item.isRead) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              item.type.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: iconColor,
                              ),
                            ),
                            const Text(' • ',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey)),
                            Text(
                              item.formattedTime,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Pesan Notifikasi
              Padding(
                padding: const EdgeInsets.only(left: 50),
                child: Text(
                  item.message,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),

              // Action buttons & quick links
              Padding(
                padding: const EdgeInsets.only(left: 50, top: 8),
                child: Row(
                  children: [
                    if (item.isAssignment || item.isUrgent)
                      InkWell(
                        onTap: () => onTap?.call(item),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (item.isUrgent
                                    ? AppColors.error
                                    : AppColors.primary)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.isUrgent
                                    ? Icons.bolt_rounded
                                    : Icons.assignment_turned_in_rounded,
                                size: 12,
                                color: item.isUrgent
                                    ? AppColors.error
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.isUrgent
                                    ? 'Lihat Tugas Mendesak'
                                    : 'Buka Tugas',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: item.isUrgent
                                      ? AppColors.error
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (item.isShipment && item.shipmentId != null)
                      InkWell(
                        onTap: () => onTap?.call(item),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.near_me_rounded,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Lacak Paket',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (item.isPayment && item.paymentId != null)
                      InkWell(
                        onTap: () => onTap?.call(item),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 12,
                                color: AppColors.secondary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Detail Pembayaran',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (!item.isRead && onMarkAsRead != null)
                      IconButton(
                        icon: const Icon(
                          Icons.done_all_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                        tooltip: 'Tandai sudah dibaca',
                        onPressed: () => onMarkAsRead!(item.id),
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                        tooltip: 'Hapus notifikasi',
                        onPressed: () => onDelete!(item.id),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
