import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/courier_task.dart';

class CourierTaskFilterTabs extends StatelessWidget {
  final CourierTaskGroup selectedGroup;
  final CourierTaskType? selectedType;
  final int pendingCount;
  final int inProgressCount;
  final int completedCount;
  final ValueChanged<CourierTaskGroup> onGroupChanged;
  final ValueChanged<CourierTaskType?> onTypeChanged;

  const CourierTaskFilterTabs({
    super.key,
    required this.selectedGroup,
    required this.selectedType,
    required this.pendingCount,
    required this.inProgressCount,
    required this.completedCount,
    required this.onGroupChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Group Segmented Control
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceVariantLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              _buildGroupTab(
                context,
                title: 'Perlu Dikerjakan',
                count: pendingCount,
                group: CourierTaskGroup.pending,
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              _buildGroupTab(
                context,
                title: 'Berlangsung',
                count: inProgressCount,
                group: CourierTaskGroup.inProgress,
                isDark: isDark,
              ),
              const SizedBox(width: 4),
              _buildGroupTab(
                context,
                title: 'Selesai',
                count: completedCount,
                group: CourierTaskGroup.completed,
                isDark: isDark,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Type Chips Row (Semua, Pickup, Delivery)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildTypeChip(
                context,
                label: 'Semua Tugas',
                icon: Icons.list_alt_rounded,
                isSelected: selectedType == null,
                onTap: () => onTypeChanged(null),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                context,
                label: 'Pengambilan (Pickup)',
                icon: Icons.archive_outlined,
                isSelected: selectedType == CourierTaskType.pickup,
                onTap: () => onTypeChanged(CourierTaskType.pickup),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildTypeChip(
                context,
                label: 'Pengantaran (Delivery)',
                icon: Icons.local_shipping_outlined,
                isSelected: selectedType == CourierTaskType.delivery,
                onTap: () => onTypeChanged(CourierTaskType.delivery),
                isDark: isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupTab(
    BuildContext context, {
    required String title,
    required int count,
    required CourierTaskGroup group,
    required bool isDark,
  }) {
    final isSelected = selectedGroup == group;

    return Expanded(
      child: InkWell(
        onTap: () => onGroupChanged(group),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.surfaceVariantDark : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.primary)
                      : (isDark ? Colors.white60 : AppColors.textSecondaryLight),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.primary : AppColors.primary100)
                      : (isDark ? AppColors.borderDark : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? (isDark ? Colors.white : AppColors.primary)
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
