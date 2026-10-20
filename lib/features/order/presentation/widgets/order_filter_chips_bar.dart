import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import '../../domain/entities/order_shipment.dart';

class OrderFilterChipsBar extends StatelessWidget {
  final OrderFilterStatus selectedStatus;
  final ValueChanged<OrderFilterStatus> onStatusSelected;

  const OrderFilterChipsBar({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filters = [
      {'status': OrderFilterStatus.all, 'label': 'Semua', 'icon': Icons.tune_rounded},
      {
        'status': OrderFilterStatus.waitingPickup,
        'label': 'Menunggu Penjemputan',
        'icon': Icons.schedule_rounded,
      },
      {
        'status': OrderFilterStatus.inDelivery,
        'label': 'Sedang Diantar Kurir',
        'icon': Icons.delivery_dining_rounded,
      },
      {
        'status': OrderFilterStatus.completed,
        'label': 'Pesanan Selesai',
        'icon': Icons.task_alt_rounded,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((item) {
          final status = item['status'] as OrderFilterStatus;
          final label = item['label'] as String;
          final icon = item['icon'] as IconData;
          final isSelected = selectedStatus == status;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              showCheckmark: false,
              avatar: Icon(
                icon,
                size: 15,
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: isDark
                  ? const Color(0xFF1B2A3D)
                  : const Color(0xFFF1F5F9),
              side: BorderSide(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (_) => onStatusSelected(status),
            ),
          );
        }).toList(),
      ),
    );
  }
}
