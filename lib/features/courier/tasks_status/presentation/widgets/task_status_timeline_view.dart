import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';
import '../../domain/entities/task_status_step.dart';

class TaskStatusTimelineView extends StatelessWidget {
  final List<TaskStatusStep> timeline;

  const TaskStatusTimelineView({
    super.key,
    required this.timeline,
  });

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = _monthName(dt.month);
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute WIB';
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kronologi Status Pengiriman',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${timeline.length} Tahapan',
                style: AppTextStyles.labelSmall.copyWith(
                  color: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (timeline.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada riwayat pelacakan status tercatat.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textMuted,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: timeline.length,
              itemBuilder: (context, index) {
                // Tampilkan kronologi dari yang terbaru (atas) ke yang lama (bawah)
                final reversedIndex = timeline.length - 1 - index;
                final step = timeline[reversedIndex];
                final isLatest = index == 0;
                final isLast = index == timeline.length - 1;

                return _buildTimelineItem(
                  step: step,
                  isLatest: isLatest,
                  isLast: isLast,
                  isDark: isDark,
                  textSecondary: textSecondary,
                  textMuted: textMuted,
                  borderColor: borderColor,
                  surfaceVariant: surfaceVariant,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required TaskStatusStep step,
    required bool isLatest,
    required bool isLast,
    required bool isDark,
    required Color textSecondary,
    required Color textMuted,
    required Color borderColor,
    required Color surfaceVariant,
  }) {
    final isFailed = step.statusCode.toUpperCase() == 'FAILED_DELIVERY';
    final isDelivered = step.statusCode.toUpperCase() == 'DELIVERED';

    Color dotColor = textMuted;
    if (isLatest) {
      if (isFailed) {
        dotColor = AppColors.error;
      } else if (isDelivered) {
        dotColor = AppColors.success;
      } else {
        dotColor = AppColors.primary;
      }
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kolom Indikator & Garis Vertikal
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: isLatest ? 14 : 10,
                  height: isLatest ? 14 : 10,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: isLatest
                        ? Border.all(
                            color: dotColor.withValues(alpha: 0.3),
                            width: 3,
                          )
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: borderColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Konten Tahapan
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          step.statusName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: isLatest ? FontWeight.w700 : FontWeight.w600,
                            color: isLatest
                                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                : textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        _formatDateTime(step.createdAt),
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                  if (step.locationName != null && step.locationName!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          step.locationName!,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: textMuted,
                          ),
                        ),
                        if (step.hasLocation) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: surfaceVariant,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              'GPS',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (step.notes != null && step.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.notes!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isFailed
                            ? AppColors.error
                            : textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
