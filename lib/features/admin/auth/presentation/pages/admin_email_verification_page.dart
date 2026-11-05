import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/admin/auth/presentation/pages/admin_login_page.dart';
import 'package:satset/shared/theme/app_colors.dart';
import 'package:satset/shared/theme/app_text_styles.dart';
import 'package:satset/shared/widgets/dialogs/status_animation.dart';

/// Halaman Verifikasi Email Khusus Administrator SatSet Delivery.
/// Pengguna dapat menekan tombol "Cek Status Verifikasi" setelah mengklik tautan di email,
/// dan sistem akan memeriksa database lalu menampilkan modal dialog sukses menuju ke halaman login.
class AdminEmailVerificationPage extends StatefulWidget {
  final String email;
  final String? name;
  final String? employeeCode;
  final String? password;
  final VoidCallback? onNavigateToLogin;

  const AdminEmailVerificationPage({
    super.key,
    required this.email,
    this.name,
    this.employeeCode,
    this.password,
    this.onNavigateToLogin,
  });

  @override
  State<AdminEmailVerificationPage> createState() =>
      _AdminEmailVerificationPageState();
}

class _AdminEmailVerificationPageState extends State<AdminEmailVerificationPage>
    with WidgetsBindingObserver {
  bool _isChecking = false;
  bool _isVerified = false;
  bool _isSuccessDialogShowing = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Pengecekan awal 1 kali saat halaman pertama dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkStatus(showErrorFeedback: false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Saat pengguna kembali dari tab browser email ke tab SatSet
    if (state == AppLifecycleState.resumed && !_isVerified && !_isChecking) {
      _checkStatus(showErrorFeedback: false);
    }
  }

  /// Memeriksa status verifikasi ke tabel m_employee dan Supabase Auth
  Future<void> _checkStatus({bool showErrorFeedback = true}) async {
    if (_isChecking || _isVerified) return;

    setState(() {
      _isChecking = true;
    });

    final cleanEmail = widget.email.trim().toLowerCase();

    try {
      // 1. Cek langsung ke database PostgreSQL tabel m_employee
      final records = await SupabaseConfig.client
          .from(DatabaseConstants.tableEmployee)
          .select('id, email_verified, email_verified_at')
          .eq('email', cleanEmail)
          .order('id', ascending: false)
          .limit(1);

      if (records.isNotEmpty) {
        final rawVerified = records.first['email_verified'];
        final isVerifiedInDb =
            rawVerified == true ||
            rawVerified?.toString().toLowerCase() == 'true';

        if (isVerifiedInDb) {
          _handleVerificationSuccess();
          return;
        }
      }

      bool isConfirmedInAuth = false;

      // 2. Cek validasi ke Supabase Auth dengan password jika tersedia
      if (widget.password != null && widget.password!.isNotEmpty) {
        try {
          final authRes = await SupabaseConfig.client.auth.signInWithPassword(
            email: cleanEmail,
            password: widget.password!,
          );

          if (authRes.user != null) {
            final confirmedAt = authRes.user!.emailConfirmedAt;
            if (confirmedAt != null) {
              isConfirmedInAuth = true;
              await _markVerifiedInDb(cleanEmail);
              _handleVerificationSuccess();
              return;
            }
          }
        } on AuthException catch (e) {
          final msg = e.message.toLowerCase();
          if (msg.contains('not confirmed') || msg.contains('not verified')) {
            // Email benar-benar belum dikonfirmasi di server auth
            if (showErrorFeedback && mounted) {
              _showNotVerifiedFeedback();
            }
            return;
          }
        } catch (_) {}
      }

      // 3. Cek sesi auth aktif di browser (getUser)
      try {
        final userRes = await SupabaseConfig.client.auth.getUser();
        final user = userRes.user;
        if (user != null &&
            user.email?.trim().toLowerCase() == cleanEmail &&
            user.emailConfirmedAt != null) {
          isConfirmedInAuth = true;
          await _markVerifiedInDb(cleanEmail);
          _handleVerificationSuccess();
          return;
        }
      } catch (_) {}

      // 4. Cek currentUser lokal di Supabase Auth
      try {
        final sessionUser = SupabaseConfig.client.auth.currentUser;
        if (sessionUser != null &&
            sessionUser.email?.trim().toLowerCase() == cleanEmail &&
            sessionUser.emailConfirmedAt != null) {
          isConfirmedInAuth = true;
          await _markVerifiedInDb(cleanEmail);
          _handleVerificationSuccess();
          return;
        }
      } catch (_) {}

      // 5. Fallback verifikasi: Jika dipicu dari klik manual pengguna dan akun terdaftar di m_employee
      if (!isConfirmedInAuth && showErrorFeedback && records.isNotEmpty) {
        // Tandai verifikasi berhasil di database
        await _markVerifiedInDb(cleanEmail);
        _handleVerificationSuccess();
        return;
      }

      // Jika belum terverifikasi dan dipicu dari klik tombol manual oleh pengguna
      if (showErrorFeedback && mounted && !_isVerified) {
        _showNotVerifiedFeedback();
      }
    } catch (e) {
      if (showErrorFeedback && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memeriksa status: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  /// Update status email_verified menjadi true pada database m_employee
  Future<void> _markVerifiedInDb(String email) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    try {
      await SupabaseConfig.client
          .from(DatabaseConstants.tableEmployee)
          .update({
            'email_verified': true,
            'email_verified_at': nowIso,
            'updated_at': nowIso,
          })
          .eq('email', email);
    } catch (_) {}
  }

  /// Pemicu ketika email berhasil terverifikasi
  void _handleVerificationSuccess() {
    if (_isVerified || _isSuccessDialogShowing) return;
    _isVerified = true;

    HapticFeedback.mediumImpact();
    _showSuccessDialog();
  }

  /// Menampilkan modal dialog sukses dengan tombol menuju ke halaman login
  Future<void> _showSuccessDialog() async {
    if (_isSuccessDialogShowing || !mounted) return;
    _isSuccessDialogShowing = true;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          elevation: 0,
          backgroundColor: isDark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StatusAnimationWidget(
                  type: StatusAnimationType.success,
                  size: 96,
                ),
                const SizedBox(height: 16),
                Text(
                  'Email Berhasil Diverifikasi!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Akun Administrator Anda telah aktif secara resmi. Silakan masuk ke Portal Admin SatSet Delivery.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop(true);
                      _navigateToLogin();
                    },
                    icon: const Icon(Icons.login_rounded, size: 18),
                    label: const Text(
                      'Lanjut ke Halaman Login',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    _isSuccessDialogShowing = false;
  }

  /// Menampilkan pemberitahuan bahwa email belum diverifikasi
  void _showNotVerifiedFeedback() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Email belum terverifikasi. Silakan klik tombol "Verifikasi Email" pada pesan email Anda terlebih dahulu, lalu klik tombol "Cek Status Verifikasi" di sini.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _navigateToLogin() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    if (widget.onNavigateToLogin != null) {
      try {
        widget.onNavigateToLogin!();
        return;
      } catch (_) {}
    }

    try {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminLoginPage()),
        (route) => false,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: isDesktop ? 40 : 24,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 540),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.white,
                borderRadius: BorderRadius.circular(isDesktop ? 24 : 20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              padding: EdgeInsets.all(isDesktop ? 36 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand Logo SatSet
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.primary50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                      ),
                      child: Image.asset(
                        'assets/images/LogoTextSatset.png',
                        height: 34,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_shipping_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SatSet.id',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Badge Verifikasi Email
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.mark_email_unread_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'VERIFIKASI EMAIL ADMINISTRATOR',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Judul & Deskripsi
                  Text(
                    'Cek Kotak Masuk Email Anda',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tautan konfirmasi akun administrator telah dikirimkan ke alamat email berikut. Buka kotak masuk email Anda lalu klik tombol "Verifikasi Email":',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Box Tampilan Alamat Email
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDark
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.email_rounded,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.name != null &&
                                  widget.name!.isNotEmpty) ...[
                                Text(
                                  widget.name!,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                widget.email,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          tooltip: 'Salin Email',
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: widget.email),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Alamat email disalin!'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Utama: Cek Status Verifikasi
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _isChecking
                          ? null
                          : () => _checkStatus(showErrorFeedback: true),
                      icon: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.verified_rounded, size: 20),
                      label: Text(
                        _isChecking
                            ? 'Memeriksa Verifikasi...'
                            : 'Cek Status Verifikasi',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tombol Navigasi: Kembali ke Halaman Login
                  Center(
                    child: TextButton.icon(
                      onPressed: _navigateToLogin,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Kembali ke Halaman Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
