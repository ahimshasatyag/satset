import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../splash/presentation/pages/splash_page.dart';

class ThemePreviewPage extends StatefulWidget {
  final bool? isDarkMode;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onResetToSplash;

  const ThemePreviewPage({
    super.key,
    this.isDarkMode,
    this.onToggleTheme,
    this.onResetToSplash,
  });

  @override
  State<ThemePreviewPage> createState() => _ThemePreviewPageState();
}

class _ThemePreviewPageState extends State<ThemePreviewPage> {
  bool _isLoadingButton = false;

  bool get _isDark {
    if (widget.isDarkMode != null) return widget.isDarkMode!;
    return Theme.of(context).brightness == Brightness.dark;
  }

  void _handleToggleTheme() {
    if (widget.onToggleTheme != null) {
      widget.onToggleTheme!();
    } else {
      context.read<ThemeCubit>().toggleTheme();
    }
  }

  void _triggerLoading() {
    setState(() => _isLoadingButton = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoadingButton = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        showBackButton: false,
        titleWidget: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'SATSET',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Widget Showcase'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Halaman Login',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
          ),
          IconButton(
            tooltip: 'Mulai Ulang dari Splash',
            icon: const Icon(Icons.replay_rounded),
            onPressed: () {
              if (widget.onResetToSplash != null) {
                widget.onResetToSplash!();
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const SplashPage()),
                  (route) => false,
                );
              }
            },
          ),
          IconButton(
            tooltip: _isDark ? 'Mode Terang' : 'Mode Gelap',
            icon: Icon(_isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: _handleToggleTheme,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo Brand Container
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isDark
                      ? AppColors.surfaceDark
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: Image.asset(
                  'assets/images/LogoTextSatset.png',
                  height: 65,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 1. Status Badges
            Text('1. Status Badges', style: AppTextStyles.titleMedium),
            const SizedBox(height: 10),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge.satset(label: 'Sat-Set Instant'),
                StatusBadge.success(label: 'Terkirim'),
                StatusBadge.warning(label: 'Sedang Diantar'),
                StatusBadge.error(label: 'Gagal'),
                StatusBadge(label: 'Menunggu Kurir', status: BadgeStatus.info),
              ],
            ),
            const SizedBox(height: 24),

            // 2. Custom Card Hero Banner
            Text('2. Custom Card (Banner & Outlined)',
                style: AppTextStyles.titleMedium),
            const SizedBox(height: 10),
            CustomCard.banner(
              onTap: () {},
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Promo Sat-Set Kilat ⚡',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kirim barang instan dengan diskon ongkir hingga 50%.',
                          style: TextStyle(
                            color: AppColors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Custom Text Fields
            Text('3. Custom Text Field', style: AppTextStyles.titleMedium),
            const SizedBox(height: 10),
            const CustomTextField(
              label: 'Nomor Resi / Pelacakan',
              hintText: 'Contoh: SATSET-882910',
              isRequired: true,
              prefixIcon: Icon(Icons.search),
            ),
            const SizedBox(height: 14),
            const CustomTextField(
              label: 'PIN / Kata Sandi Pengguna',
              hintText: 'Masukkan 6 digit PIN',
              isPassword: true,
              isRequired: true,
              prefixIcon: Icon(Icons.lock_outline),
            ),
            const SizedBox(height: 24),

            // 4. Custom Buttons
            Text('4. Custom Button (Varian Brand)',
                style: AppTextStyles.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                CustomButton(
                  text: 'Primary Red',
                  onPressed: () {},
                  isFullWidth: false,
                  prefixIcon: const Icon(Icons.flash_on,
                      color: AppColors.white, size: 18),
                ),
                CustomButton.secondary(
                  text: 'Speed Orange',
                  onPressed: () {},
                  isFullWidth: false,
                  prefixIcon: const Icon(Icons.local_shipping,
                      color: AppColors.white, size: 18),
                ),
                CustomButton.gradient(
                  text: _isLoadingButton ? 'Memproses...' : 'Gradient Animasi',
                  isLoading: _isLoadingButton,
                  isFullWidth: false,
                  onPressed: _triggerLoading,
                ),
                CustomButton.outlined(
                  text: 'Outlined Button',
                  onPressed: () {},
                  isFullWidth: false,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 5. Dialogs & Bottom Sheet Triggers (Dengan Animasi Lottie)
            Text('5. Modal & Dialog Animasi Lottie',
                style: AppTextStyles.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Menggunakan file animasi Lottie di assets/icon (Check Mark, Sign for error, & Warning Status)',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                CustomButton(
                  text: 'Dialog Sukses',
                  isFullWidth: false,
                  prefixIcon: const Icon(Icons.check_circle, color: AppColors.white, size: 16),
                  onPressed: () {
                    CustomDialog.showSuccess(
                      context: context,
                      title: 'Pesanan Berhasil!',
                      message: 'Paket Sat-Set Anda telah terdaftar dan kurir siap meluncur.',
                      confirmText: 'Mantap',
                    );
                  },
                ),
                CustomButton.secondary(
                  text: 'Dialog Warning',
                  isFullWidth: false,
                  prefixIcon: const Icon(Icons.warning_amber, color: AppColors.white, size: 16),
                  onPressed: () {
                    CustomDialog.showWarning(
                      context: context,
                      title: 'Periksa Alamat Tujuan',
                      message: 'Alamat belum dilengkapi nomor rumah/patokan. Tetap lanjutkan?',
                      confirmText: 'Lanjutkan',
                      cancelText: 'Ubah Alamat',
                    );
                  },
                ),
                CustomButton.outlined(
                  text: 'Dialog Error',
                  isFullWidth: false,
                  prefixIcon: const Icon(Icons.cancel, color: AppColors.primary, size: 16),
                  onPressed: () {
                    CustomDialog.showError(
                      context: context,
                      title: 'Gagal Memproses',
                      message: 'Koneksi jaringan terputus atau server sedang sibuk.',
                      confirmText: 'Coba Lagi',
                      cancelText: 'Tutup',
                    );
                  },
                ),
                CustomButton.outlined(
                  text: 'Bottom Sheet Status',
                  isFullWidth: false,
                  prefixIcon: const Icon(Icons.vertical_align_top, color: AppColors.primary, size: 16),
                  onPressed: () {
                    CustomBottomSheet.showSuccess(
                      context: context,
                      title: 'Pengiriman Tuntas!',
                      message: 'Penerima telah menerima paket dengan selamat.',
                      confirmText: 'Tutup',
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 6. Loading & Skeleton Shimmer
            Text('6. Shimmer & Loading State', style: AppTextStyles.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                const CustomShimmer.circle(size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomShimmer(
                        width: double.infinity,
                        height: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      CustomShimmer(
                        width: 180,
                        height: 12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Kirim Baru'),
      ),
    );
  }
}
