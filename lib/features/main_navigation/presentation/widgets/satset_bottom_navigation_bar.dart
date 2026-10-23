import 'package:flutter/material.dart';

import '../../../../shared/theme/theme.dart';
import '../../domain/entities/navigation_item.dart';

class SatSetBottomNavigationBar extends StatefulWidget {
  /// Tab aktif untuk navigasi Pelanggan
  final NavigationTab? currentTab;

  /// Tab aktif untuk navigasi Kurir
  final CourierNavigationTab? currentCourierTab;

  /// Callback ketika tab pelanggan dipilih
  final ValueChanged<NavigationTab>? onTabSelected;

  /// Callback ketika tab kurir dipilih
  final ValueChanged<CourierNavigationTab>? onCourierTabSelected;

  /// Callback tombol aksi Kirim (+ Kirim) untuk pelanggan
  final VoidCallback? onSendActionTap;

  /// Callback tombol aksi Scan (Pindai Barcode) untuk kurir
  final VoidCallback? onScanActionTap;

  /// Indikator apakah bilah navigasi dalam mode khusus Kurir
  final bool isCourierMode;

  /// Jumlah lencana tugas aktif atau pesanan
  final int? badgeCount;

  /// Jumlah tugas aktif kurir (dari t_shipment_assignments)
  final int? activeTasksCount;

  /// Indikator adanya tugas aktif kurir untuk mengaktifkan titik pulsasi GPS
  final bool hasActiveTask;

  const SatSetBottomNavigationBar({
    super.key,
    this.currentTab,
    this.currentCourierTab,
    this.onTabSelected,
    this.onCourierTabSelected,
    this.onSendActionTap,
    this.onScanActionTap,
    this.isCourierMode = false,
    this.badgeCount,
    this.activeTasksCount,
    this.hasActiveTask = false,
  });

  /// Factory constructor khusus untuk navigasi Kurir (Courier)
  factory SatSetBottomNavigationBar.courier({
    Key? key,
    required CourierNavigationTab currentTab,
    required ValueChanged<CourierNavigationTab> onTabSelected,
    VoidCallback? onScanActionTap,
    int? activeTasksCount,
    bool hasActiveTask = false,
  }) {
    return SatSetBottomNavigationBar(
      key: key,
      isCourierMode: true,
      currentCourierTab: currentTab,
      onCourierTabSelected: onTabSelected,
      onScanActionTap: onScanActionTap,
      activeTasksCount: activeTasksCount,
      hasActiveTask: hasActiveTask,
    );
  }

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
          child: widget.isCourierMode
              ? _buildCourierNavRow(isDark)
              : _buildCustomerNavRow(isDark),
        ),
      ),
    );
  }

  /// Bilah menu navigasi khusus Kurir (Tasks, Scan, Tracking, History, Account)
  Widget _buildCourierNavRow(bool isDark) {
    final currentTab = widget.currentCourierTab ?? CourierNavigationTab.tasks;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Tasks (Halaman Utama Courier)
        _buildCourierNavItem(
          tab: CourierNavigationTab.tasks,
          isSelected: currentTab == CourierNavigationTab.tasks,
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment_rounded,
          isDark: isDark,
          badgeCount: widget.activeTasksCount ?? widget.badgeCount,
        ),

        // 2. Pelacakan GPS Realtime (Tracking)
        _buildCourierNavItem(
          tab: CourierNavigationTab.trackingCourier,
          isSelected: currentTab == CourierNavigationTab.trackingCourier,
          icon: Icons.navigation_outlined,
          activeIcon: Icons.navigation_rounded,
          isDark: isDark,
          hasLiveDot: widget.hasActiveTask,
        ),

        // 3. Scan (Tombol Aksi Pindai Barcode Paket di Tengah - Setelah Pelacakan)
        _buildCenterCourierScanButton(isDark, currentTab),

        // 4. Riwayat Tugas (Task History)
        _buildCourierNavItem(
          tab: CourierNavigationTab.history,
          isSelected: currentTab == CourierNavigationTab.history,
          icon: Icons.history_outlined,
          activeIcon: Icons.history_rounded,
          isDark: isDark,
        ),

        // 5. Akun Profil Kurir & Otorisasi
        _buildCourierNavItem(
          tab: CourierNavigationTab.account,
          isSelected: currentTab == CourierNavigationTab.account,
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildCourierNavItem({
    required CourierNavigationTab tab,
    required bool isSelected,
    required IconData icon,
    required IconData activeIcon,
    required bool isDark,
    bool hasLiveDot = false,
    int? badgeCount,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (widget.onCourierTabSelected != null) {
            widget.onCourierTabSelected!(tab);
          }
        },
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
                      horizontal: 14,
                      vertical: 4,
                    ),
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

                  // Titik Aktif Real-Time GPS (hanya saat ada tugas aktif berjalan)
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

                  // Lencana Penghitung Tugas Aktif
                  if (badgeCount != null && badgeCount > 0)
                    PositionedDirectional(
                      top: -2,
                      end: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
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

  /// Tombol aksi scan barcode di bilah navigasi kurir
  Widget _buildCenterCourierScanButton(
    bool isDark,
    CourierNavigationTab currentTab,
  ) {
    final isSelected = currentTab == CourierNavigationTab.scan;

    return Transform.translate(
      offset: const Offset(0, -6),
      child: GestureDetector(
        onTap: () {
          if (widget.onScanActionTap != null) {
            widget.onScanActionTap!();
          } else if (widget.onCourierTabSelected != null) {
            widget.onCourierTabSelected!(CourierNavigationTab.scan);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
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
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                CourierNavigationTab.scan.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bilah menu navigasi Pelanggan (Home, LiveTrack, Kirim, Orders, Account)
  Widget _buildCustomerNavRow(bool isDark) {
    final currentTab = widget.currentTab ?? NavigationTab.home;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Beranda
        _buildCustomerNavItem(
          tab: NavigationTab.home,
          isSelected: currentTab == NavigationTab.home,
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          isDark: isDark,
        ),

        // 2. Lacak Live
        _buildCustomerNavItem(
          tab: NavigationTab.liveTrack,
          isSelected: currentTab == NavigationTab.liveTrack,
          icon: Icons.explore_outlined,
          activeIcon: Icons.explore_rounded,
          isDark: isDark,
          hasLiveDot: true,
        ),

        // 3. Tombol Aksi Utama (+ Kirim) - Menonjol di Tengah
        _buildCenterSendButton(isDark),

        // 4. Pesanan
        _buildCustomerNavItem(
          tab: NavigationTab.orders,
          isSelected: currentTab == NavigationTab.orders,
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2_rounded,
          isDark: isDark,
          badgeCount: widget.badgeCount,
        ),

        // 5. Akun
        _buildCustomerNavItem(
          tab: NavigationTab.account,
          isSelected: currentTab == NavigationTab.account,
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildCustomerNavItem({
    required NavigationTab tab,
    required bool isSelected,
    required IconData icon,
    required IconData activeIcon,
    required bool isDark,
    bool hasLiveDot = false,
    int? badgeCount,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          if (widget.onTabSelected != null) {
            widget.onTabSelected!(tab);
          }
        },
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
                      horizontal: 14,
                      vertical: 4,
                    ),
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

                  if (badgeCount != null && badgeCount > 0)
                    PositionedDirectional(
                      top: -2,
                      end: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
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
