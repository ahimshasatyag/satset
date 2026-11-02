import 'package:flutter/material.dart';
import 'package:satset/shared/theme/app_colors.dart';
import 'package:satset/shared/theme/app_text_styles.dart';
import '../../domain/entities/admin_dashboard_stats.dart';

class StatisticsCards extends StatelessWidget {
  final AdminDashboardStats stats;

  const StatisticsCards({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsif: 4 kolom pada layar lebar, 2 kolom pada tablet, 1 kolom pada ponsel sempit
        final width = constraints.maxWidth;
        final int crossAxisCount = width > 1100 ? 4 : (width > 600 ? 2 : 1);
        final double itemWidth = (width - ((crossAxisCount - 1) * 16)) / crossAxisCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                title: 'Total Pengiriman',
                value: stats.totalShipments.toString(),
                subText: 'Semua riwayat pengiriman',
                icon: Icons.local_shipping_rounded,
                accentColor: AppColors.primary,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                title: 'Menunggu Konfirmasi',
                value: stats.pendingShipments.toString(),
                subText: 'Status PENDING',
                icon: Icons.pending_actions_rounded,
                accentColor: AppColors.warning,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                title: 'Dalam Proses / Transit',
                value: stats.inProcessShipments.toString(),
                subText: 'Sedang berjalan di rute',
                icon: Icons.airport_shuttle_rounded,
                accentColor: AppColors.info,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                title: 'Berhasil Diterima',
                value: stats.deliveredShipments.toString(),
                subText: 'Paket sukses sampai tujuan',
                icon: Icons.check_circle_rounded,
                accentColor: AppColors.success,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                title: 'Gagal / Dibatalkan',
                value: '${stats.failedShipments} / ${stats.cancelledShipments}',
                subText: 'Gagal kirim & dibatalkan',
                icon: Icons.cancel_rounded,
                accentColor: AppColors.error,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                title: 'Total Pelanggan',
                value: stats.totalCustomers.toString(),
                subText: 'Akun pelanggan terdaftar',
                icon: Icons.people_alt_rounded,
                accentColor: AppColors.secondary,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                title: 'Pegawai SatSet',
                value: stats.totalEmployees.toString(),
                subText: '${stats.totalAdmins} Admin • ${stats.totalCouriers} Kurir',
                icon: Icons.badge_rounded,
                accentColor: AppColors.primary,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _MetricCard(
                title: 'Kurir Bertugas',
                value: stats.couriersWithAssignmentCount.toString(),
                subText: 'Dari ${stats.totalCouriers} kurir terdaftar',
                icon: Icons.two_wheeler_rounded,
                accentColor: AppColors.success,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subText;
  final IconData icon;
  final Color accentColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subText,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subText,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

