import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/live_track_shipment.dart';

class LiveTrackTopBar extends StatefulWidget {
  final OrderDirection selectedDirection;
  final ValueChanged<OrderDirection> onDirectionChanged;
  final ValueChanged<String> onSearchSubmitted;
  final VoidCallback onRefresh;
  final String? initialQuery;

  const LiveTrackTopBar({
    super.key,
    required this.selectedDirection,
    required this.onDirectionChanged,
    required this.onSearchSubmitted,
    required this.onRefresh,
    this.initialQuery,
  });

  @override
  State<LiveTrackTopBar> createState() => _LiveTrackTopBarState();
}

class _LiveTrackTopBarState extends State<LiveTrackTopBar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
  }

  @override
  void didUpdateWidget(covariant LiveTrackTopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery &&
        widget.initialQuery != _searchController.text) {
      _searchController.text = widget.initialQuery ?? '';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Tab Selector: Kiriman Saya vs Paket Masuk
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.tertiary50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _buildTabItem(
                  direction: OrderDirection.outgoing,
                  icon: Icons.outbox_rounded,
                  label: 'Kiriman Saya',
                  isDark: isDark,
                ),
                _buildTabItem(
                  direction: OrderDirection.incoming,
                  icon: Icons.move_to_inbox_rounded,
                  label: 'Paket Masuk',
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 2. Bar Pencarian Nomor Resi / Barcode
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari nomor resi atau nama penerima...',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                widget.onSearchSubmitted('');
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (val) {
                      setState(() {});
                      widget.onSearchSubmitted(val);
                    },
                    onSubmitted: widget.onSearchSubmitted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  tooltip: 'Perbarui Data Pelacakan',
                  color: AppColors.primary,
                  onPressed: widget.onRefresh,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required OrderDirection direction,
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = widget.selectedDirection == direction;

    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onDirectionChanged(direction),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.primary : AppColors.primary)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
