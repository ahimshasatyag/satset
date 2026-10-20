import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import '../../domain/entities/navigation_item.dart';

class SatSetBottomNavigationBar extends StatefulWidget {
  final NavigationTab currentTab;
  final ValueChanged<NavigationTab> onTabSelected;
  final VoidCallback onSendActionTap;
  final int? badgeCount;

  const SatSetBottomNavigationBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    required this.onSendActionTap,
    this.badgeCount,
  });

  @override
  State<SatSetBottomNavigationBar> createState() =>
      _SatSetBottomNavigationBarState();
}

class _SatSetBottomNavigationBarState extends State<SatSetBottomNavigationBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Beranda
              _buildNavItem(
                tab: NavigationTab.home,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                isDark: isDark,
              ),

              // 2. Lacak Live
              _buildNavItem(
                tab: NavigationTab.liveTrack,
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore_rounded,
                isDark: isDark,
                hasLiveDot: true,
              ),

              // 3. Tombol Aksi Utama (+ Kirim) - Menonjol di Tengah
              _buildCenterSendButton(isDark),

              // 4. Pesanan
              _buildNavItem(
                tab: NavigationTab.orders,
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2_rounded,
                isDark: isDark,
                badgeCount: widget.badgeCount,
              ),

              // 5. Akun
              _buildNavItem(
                tab: NavigationTab.account,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required NavigationTab tab,
    required IconData icon,
    required IconData activeIcon,
    required bool isDark,
    bool hasLiveDot = false,
    int? badgeCount,
  }) {
    final isSelected = widget.currentTab == tab;

    return Expanded(
      child: InkWell(
        onTap: () => widget.onTabSelected(tab),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isSelected ? activeIcon : icon,
                      size: 24,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                  ),

                  // Titik Aktif Real-Time (untuk Lacak Live)
                  if (hasLiveDot)
                    PositionedDirectional(
                      top: 2,
                      end: 8,
                      child: ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surfaceLight,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Lencana Penghitung Pesanan Aktif
                  if (badgeCount != null && badgeCount > 0)
                    PositionedDirectional(
                      top: -2,
                      end: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceLight,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                tab.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterSendButton(bool isDark) {
    return Transform.translate(
      offset: const Offset(0, -8),
      child: GestureDetector(
        onTap: widget.onSendActionTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2.5),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(7),
                  child: Image.asset(
                    'assets/images/LogoSatset.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                '+ Kirim',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
