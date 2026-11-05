import 'package:flutter/material.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/system_info.dart';

class SystemInfoSection extends StatelessWidget {
  final SystemInfo systemInfo;
  final VoidCallback onRefreshDiagnostics;

  const SystemInfoSection({
    super.key,
    required this.systemInfo,
    required this.onRefreshDiagnostics,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Sistem & Infrastruktur Backend',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ringkasan platform aplikasi, mesin basis data Supabase, protokol keamanan, dan status latensi sistem.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onRefreshDiagnostics,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Periksa Status'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Status Ping Koneksi Database
          Container(
            padding: const EdgeInsets.all(16),
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
                Icon(
                  systemInfo.isDatabaseConnected
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  size: 24,
                  color: systemInfo.isDatabaseConnected
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        systemInfo.isDatabaseConnected
                            ? 'Koneksi Basis Data Supabase Terhubung Normal'
                            : 'Koneksi Basis Data Mengalami Gangguan',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Latensi Respons: ${systemInfo.databaseLatencyMs} ms • Terakhir Diperiksa: ${AdminDateFormatter.formatDateTime(systemInfo.lastCheckedAt)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11.5,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.primary50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Text(
                    systemInfo.environment.toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tabel Spesifikasi & Integritas Arsitektur
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              _SpecCard(
                title: 'Aplikasi Web & Framework',
                icon: Icons.web_rounded,
                isDark: isDark,
                specs: [
                  ('Nama Aplikasi', systemInfo.appName),
                  ('Versi Produksi', systemInfo.appVersion),
                  ('Framework SDK', systemInfo.flutterSdkVersion),
                  ('Arsitektur', 'Clean Architecture + BLoC State Management'),
                ],
              ),
              _SpecCard(
                title: 'Basis Data & Realtime Engine',
                icon: Icons.storage_rounded,
                isDark: isDark,
                specs: [
                  ('Platform Backend', systemInfo.backendPlatform),
                  ('Database Engine', systemInfo.databaseEngine),
                  ('Penyedia Realtime', systemInfo.realtimeEngine),
                  ('Foreign Key Constraint', 'Proteksi Relasi t_shipments Aktif'),
                ],
              ),
              _SpecCard(
                title: 'Kebijakan Keamanan & Autentikasi',
                icon: Icons.admin_panel_settings_outlined,
                isDark: isDark,
                specs: [
                  ('Standar Hak Akses', systemInfo.securityProtocol),
                  ('Kredensial Frontend', 'Strictly Anon Key Only (No Service-Role)'),
                  ('Penyimpanan Sandi', 'Bcrypt Secure Hashing'),
                  ('Sesi Penyimpanan', 'SharedPreferences + Secure Cookie Expiry'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Catatan Keamanan
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seluruh kunci rahasia (service-role key, secret token) diisolasi pada tingkat backend dan tidak pernah diekspos ke klien frontend website.',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final List<(String label, String value)> specs;

  const _SpecCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.specs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...specs.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.$1,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 10.5,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    item.$2,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

