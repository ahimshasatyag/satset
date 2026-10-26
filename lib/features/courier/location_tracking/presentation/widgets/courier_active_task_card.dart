import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/badges/status_badge.dart';
import '../../domain/entities/courier_tracking_task.dart';

/// Kartu tugas aktif yang mengambang di atas peta pelacakan kurir
class CourierActiveTaskCard extends StatelessWidget {
  final CourierTrackingTask task;
  final List<CourierTrackingTask> allActiveTasks;
  final bool isTrackingActive;
  final ValueChanged<bool> onToggleTracking;
  final ValueChanged<CourierTrackingTask>? onSelectTask;

  const CourierActiveTaskCard({
    super.key,
    required this.task,
    required this.allActiveTasks,
    required this.isTrackingActive,
    required this.onToggleTracking,
    this.onSelectTask,
  });

  BadgeStatus _resolveBadgeStatus(String code) {
    switch (code.toUpperCase()) {
      case 'DELIVERED':
        return BadgeStatus.success;
      case 'FAILED_DELIVERY':
      case 'CANCELLED':
      case 'RETURNED':
        return BadgeStatus.error;
      case 'OUT_FOR_DELIVERY':
      case 'PICKED_UP':
      case 'IN_TRANSIT':
        return BadgeStatus.brand;
      default:
        return BadgeStatus.warning;
    }
  }

  void _showTaskSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Pilih Tugas Aktif yang Dilacak',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Divider(height: 1, color: isDark ? Colors.white12 : Colors.black12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: allActiveTasks.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  itemBuilder: (context, index) {
                    final item = allActiveTasks[index];
                    final isSelected = item.taskId == task.taskId;

                    return ListTile(
                      leading: Icon(
                        item.isPickup
                            ? Icons.archive_outlined
                            : Icons.local_shipping_outlined,
                        color: item.isPickup
                            ? AppColors.secondary
                            : AppColors.primary,
                      ),
                      title: Text(
                        item.trackingNumber,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? AppColors.primary : null,
                        ),
                      ),
                      subtitle: Text(
                        '${item.taskTypeLabel} • ${item.targetPersonName} (${item.targetCity})',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.primary)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        onSelectTask?.call(item);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Baris Atas: Badge Tugas, Status & Selector jika >1 tugas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: task.isPickup
                          ? AppColors.secondary.withValues(alpha: 0.12)
                          : AppColors.tertiary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.isPickup ? 'PICKUP' : 'DELIVERY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: task.isPickup
                            ? AppColors.secondary
                            : (isDark ? Colors.lightBlueAccent : AppColors.tertiary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: task.statusName,
                    status: _resolveBadgeStatus(task.statusCode),
                  ),
                ],
              ),
              if (allActiveTasks.length > 1)
                InkWell(
                  onTap: () => _showTaskSelector(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${allActiveTasks.length} Tugas',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 2. Baris Resi & Tombol Salin
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    task.trackingNumber,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: task.trackingNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Nomor resi ${task.trackingNumber} disalin!'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              Text(
                task.serviceTypeName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 3. Pihak Tujuan & Alamat
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                task.isPickup ? Icons.person_pin_circle_outlined : Icons.location_on_outlined,
                size: 16,
                color: task.isPickup ? AppColors.secondary : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${task.isPickup ? "Penjemputan: " : "Tujuan: "}${task.targetPersonName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${task.targetAddress}, ${task.targetCity}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
          const SizedBox(height: 8),

          // 4. Toggle Pelacakan GPS Live
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kirim Lokasi Live',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isTrackingActive
                        ? 'Koordinat diperbarui ke server & pelanggan'
                        : 'Pelacakan dijeda untuk tugas ini',
                    style: TextStyle(
                      fontSize: 10,
                      color: isTrackingActive
                          ? AppColors.success
                          : (isDark ? Colors.white54 : AppColors.textMutedLight),
                    ),
                  ),
                ],
              ),
              Switch(
                value: isTrackingActive,
                onChanged: onToggleTracking,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
