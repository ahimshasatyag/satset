import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';
import '../../data/utils/validators.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Halaman atur kata sandi baru dan konfirmasi kata sandi SatSet
class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String code;

  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hasMinLength = false;
  bool _hasMixedCase = false;
  bool _hasDigits = false;
  bool _hasSpecialChars = false;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_validatePasswordRules);
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_validatePasswordRules);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePasswordRules() {
    final password = _newPasswordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasMixedCase = password.contains(RegExp(r'[a-z]')) && password.contains(RegExp(r'[A-Z]'));
      _hasDigits = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChars = password.contains(RegExp(r'[!@#\$&*~_.,\-]'));
    });
  }

  int get _strengthScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasMixedCase) score++;
    if (_hasDigits) score++;
    if (_hasSpecialChars) score++;
    return score;
  }

  Color _getStrengthColor() {
    switch (_strengthScore) {
      case 0:
      case 1:
        return AppColors.error;
      case 2:
      case 3:
        return AppColors.warning;
      case 4:
      default:
        return AppColors.success;
    }
  }

  String _getStrengthLabel() {
    if (_newPasswordController.text.isEmpty) return '';
    switch (_strengthScore) {
      case 0:
      case 1:
        return 'Sangat Lemah';
      case 2:
        return 'Cukup';
      case 3:
        return 'Kuat';
      case 4:
      default:
        return 'Sangat Kuat 🔥';
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        CustomDialog.showWarning(
          context: context,
          title: 'Kata Sandi Tidak Cocok',
          message: 'Konfirmasi kata sandi harus persis sama dengan kata sandi baru.',
        );
        return;
      }

      context.read<AuthBloc>().add(
            AuthResetPasswordSubmitted(
              email: widget.email,
              code: widget.code,
              newPassword: _newPasswordController.text,
            ),
          );
    }
  }

  /// Menampilkan modal bottom sheet konfirmasi dari widgets.dart sebelum kembali ke login
  void _handleBackToLogin() {
    CustomBottomSheet.showWarning(
      context: context,
      title: 'Tinggalkan Halaman?',
      message: 'Apakah Anda yakin ingin meninggalkan reset password untuk login?',
      confirmText: 'Ya, Kembali',
      cancelText: 'Batal',
      onConfirm: () {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackToLogin();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Stack(
        children: [
          // Background motif dari Background.png
          Positioned.fill(
            child: Image.asset(
              'assets/images/Background.png',
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),

          // Lapisan overlay halus untuk mode gelap
          if (isDark)
            Positioned.fill(
              child: Container(
                color: AppColors.backgroundDark.withValues(alpha: 0.85),
              ),
            ),

          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthResetPasswordSuccess) {
                CustomDialog.showSuccess(
                  context: context,
                  title: 'Kata Sandi Diperbarui! 🎉',
                  message:
                      'Kata sandi akun SatSet Anda berhasil diubah. Silakan masuk kembali menggunakan kata sandi baru.',
                  confirmText: 'Masuk Sekarang',
                  onConfirm: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  },
                );
              } else if (state is AuthFailure) {
                CustomDialog.showError(
                  context: context,
                  title: 'Gagal Menyimpan',
                  message: state.errorMessage,
                  confirmText: 'Coba Lagi',
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              return SafeArea(
                child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: CustomCard(
                      variant: CardVariant.elevated,
                      padding: const EdgeInsets.all(24),
                      borderRadius: BorderRadius.circular(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon Badge Ilustrasi Gembok
                            Center(
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.lock_reset_rounded,
                                  size: 38,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Judul & Deskripsi
                            Center(
                              child: Text(
                                'Buat Kata Sandi Baru',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.headlineSmall.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                'Kata sandi baru harus kuat dan tidak boleh sama dengan kata sandi sebelumnya.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Input Password Baru
                            CustomTextField(
                              label: 'Kata Sandi Baru',
                              hintText: 'Minimal 8 karakter unik',
                              controller: _newPasswordController,
                              isPassword: true,
                              isRequired: true,
                              enabled: !isLoading,
                              prefixIcon: const Icon(Icons.lock_outline_rounded),
                              validator: Validators.validatePassword,
                            ),
                            const SizedBox(height: 12),

                            // Indikator Meter Kekuatan Kata Sandi
                            if (_newPasswordController.text.isNotEmpty) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _strengthScore / 4,
                                        backgroundColor: isDark
                                            ? AppColors.borderDark
                                            : AppColors.borderLight,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _getStrengthColor(),
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _getStrengthLabel(),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: _getStrengthColor(),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Checklist Ketentuan Kata Sandi
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Kriteria Keamanan Sandi:',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildRuleItem('Minimal 8 karakter', _hasMinLength, isDark),
                                  const SizedBox(height: 4),
                                  _buildRuleItem('Kombinasi huruf besar & kecil (A-z)', _hasMixedCase, isDark),
                                  const SizedBox(height: 4),
                                  _buildRuleItem('Mengandung angka (0-9)', _hasDigits, isDark),
                                  const SizedBox(height: 4),
                                  _buildRuleItem('Mengandung simbol/karakter khusus (!@#\$)', _hasSpecialChars, isDark),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Input Konfirmasi Kata Sandi
                            CustomTextField(
                              label: 'Konfirmasi Kata Sandi Baru',
                              hintText: 'Ulangi kata sandi baru',
                              controller: _confirmPasswordController,
                              isPassword: true,
                              isRequired: true,
                              enabled: !isLoading,
                              textInputAction: TextInputAction.done,
                              prefixIcon: const Icon(Icons.lock_reset_rounded),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Konfirmasi kata sandi wajib diisi';
                                }
                                if (value != _newPasswordController.text) {
                                  return 'Konfirmasi kata sandi tidak cocok';
                                }
                                return null;
                              },
                              onSubmitted: (_) => _handleSubmit(),
                            ),
                            const SizedBox(height: 28),

                            // Tombol Submit Kata Sandi Baru
                            CustomButton.gradient(
                              text: isLoading ? 'Menyimpan Sandi...' : 'Simpan Kata Sandi Baru',
                              isLoading: isLoading,
                              onPressed: isLoading ? null : _handleSubmit,
                              size: ButtonSize.large,
                              prefixIcon: const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Tombol Batal
                            Center(
                              child: CustomButton.ghost(
                                text: 'Kembali ke Halaman Masuk',
                                onPressed: _handleBackToLogin,
                                size: ButtonSize.small,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
        },
          ),
        ],
      ),
    ),
  );
  }

  /// Item checklist aturan kata sandi dengan indikator centang dinamis
  Widget _buildRuleItem(String text, bool isSatisfied, bool isDark) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSatisfied
                ? AppColors.success
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Icon(
            isSatisfied ? Icons.check : Icons.circle,
            size: isSatisfied ? 12 : 6,
            color: isSatisfied
                ? AppColors.white
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSatisfied
                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
