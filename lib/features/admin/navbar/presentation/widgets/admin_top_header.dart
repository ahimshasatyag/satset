import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/shared/theme/theme.dart';

class AdminTopHeader extends StatelessWidget {
  final User? currentUser;
  final VoidCallback onRefresh;
  final bool isRefreshing;
  final VoidCallback? onOpenDrawer;
  final bool showDrawerButton;
  final VoidCallback? onLogout;
  final String sectionTitle;
  final String pageTitle;

  const AdminTopHeader({
    super.key,
    this.currentUser,
    required this.onRefresh,
    this.isRefreshing = false,
    this.onOpenDrawer,
    this.showDrawerButton = false,
    this.onLogout,
    this.sectionTitle = 'Portal Utama',
    this.pageTitle = 'Dashboard Operasional',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final adminName = currentUser?.name.isNotEmpty == true
        ? currentUser!.name
        : 'Administrator SatSet';
    final adminEmail = currentUser?.email.isNotEmpty == true
        ? currentUser!.email
        : 'admin@satset.id';

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Tombol hamburger jika di layar mobile/tablet kecil
          if (showDrawerButton) ...[
            IconButton(
              onPressed: onOpenDrawer,
              icon: const Icon(Icons.menu_rounded),
              tooltip: 'Buka Menu',
            ),
            const SizedBox(width: 8),
          ],

          // Title & Breadcrumb
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      sectionTitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 16),
                    Flexible(
                      child: Text(
                        pageTitle,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Realtime Live Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Realtime Sync',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Tombol Refresh Manual
          IconButton(
            onPressed: isRefreshing ? null : onRefresh,
            icon: isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Data',
          ),

          // Tombol Toggle Tema Terang/Gelap
          IconButton(
            onPressed: () {
              context.read<ThemeCubit>().toggleTheme();
            },
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: isDark ? 'Mode Terang' : 'Mode Gelap',
          ),
          const SizedBox(width: 8),

          // Profil Admin
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adminName,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      adminEmail,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onLogout != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
              tooltip: 'Keluar Sesi Administrator',
            ),
          ],
        ],
      ),
    );
  }
}

