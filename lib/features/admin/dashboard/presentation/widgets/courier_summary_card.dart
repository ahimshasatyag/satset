import 'package:flutter/material.dart';
import 'package:satset/shared/theme/app_colors.dart';
import 'package:satset/shared/theme/app_text_styles.dart';
import '../../domain/entities/admin_courier_summary.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';

class CourierSummaryCard extends StatelessWidget {
  final List<AdminCourierSummary> couriers;

  const CourierSummaryCard({super.key, required this.couriers});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status & Penugasan Kurir SatSet',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const Icon(Icons.two_wheeler_rounded, color: AppColors.secondary, size: 22),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Aktivitas tugas dari t_shipment_assignments & t_shipment_locations',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),

          if (couriers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada data kurir terdaftar.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: couriers.length.clamp(0, 5),
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final c = couriers[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar Kurir
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: c.hasActiveDuty
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.two_wheeler_rounded,
                          size: 18,
                          color: c.hasActiveDuty ? AppColors.success : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Nama & Kode
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.namaLengkap,
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${c.employeeCode} • ${c.noHp}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                fontSize: 11,
                              ),
                            ),
                            if (c.lastLocationUpdate != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Update: ${AdminDateFormatter.formatTimeAgo(c.lastLocationUpdate)}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.info,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Badge Penugasan Aktif
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: c.hasActiveDuty
                                  ? AppColors.success.withValues(alpha: isDark ? 0.2 : 0.12)
                                  : (isDark ? AppColors.surfaceDark : AppColors.white),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: c.hasActiveDuty
                                    ? AppColors.success.withValues(alpha: 0.3)
                                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                              ),
                            ),
                            child: Text(
                              c.hasActiveDuty ? 'Sedang Bertugas' : 'Standby',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: c.hasActiveDuty
                                    ? AppColors.success
                                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${c.activeAssignmentsCount} aktif • ${c.completedAssignmentsCount} selesai',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
