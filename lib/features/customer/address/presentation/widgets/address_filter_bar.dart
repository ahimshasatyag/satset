import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../bloc/address_event.dart';

class AddressFilterBar extends StatelessWidget {
  final AddressFilterCategory activeFilter;
  final int totalCount;
  final int primaryCount;
  final int otherCount;
  final ValueChanged<AddressFilterCategory> onFilterSelected;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController searchController;

  const AddressFilterBar({
    super.key,
    required this.activeFilter,
    required this.totalCount,
    required this.primaryCount,
    required this.otherCount,
    required this.onFilterSelected,
    required this.onSearchChanged,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Search TextField
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Cari label, jalan, kota, kecamatan...',
              hintStyle: TextStyle(
                color: isDark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                size: 20,
              ),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),

        // Filter Chips Horizontal List
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              _buildChip(
                context,
                label: 'Semua ($totalCount)',
                category: AddressFilterCategory.all,
                isSelected: activeFilter == AddressFilterCategory.all,
              ),
              const SizedBox(width: 8),
              _buildChip(
                context,
                label: 'Alamat Utama ($primaryCount)',
                category: AddressFilterCategory.primary,
                isSelected: activeFilter == AddressFilterCategory.primary,
                icon: Icons.home_rounded,
              ),
              const SizedBox(width: 8),
              _buildChip(
                context,
                label: 'Alamat Lain ($otherCount)',
                category: AddressFilterCategory.others,
                isSelected: activeFilter == AddressFilterCategory.others,
                icon: Icons.location_on_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required AddressFilterCategory category,
    required bool isSelected,
    IconData? icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => onFilterSelected(category),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.white12 : AppColors.surfaceVariantLight),
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
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.textSecondaryLight),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white.withValues(alpha: 0.8) : AppColors.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
