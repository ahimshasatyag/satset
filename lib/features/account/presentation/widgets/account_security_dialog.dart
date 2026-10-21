import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/data/utils/validators.dart';

class AccountSecurityDialog extends StatefulWidget {
  final String email;
  final bool isEmailVerified;
  final VoidCallback onResendVerification;
  final ValueChanged<String> onChangePassword;

  const AccountSecurityDialog({
    super.key,
    required this.email,
    required this.isEmailVerified,
    required this.onResendVerification,
    required this.onChangePassword,
  });

  static Future<void> show(
    BuildContext context, {
    required String email,
    required bool isEmailVerified,
    required VoidCallback onResendVerification,
    required ValueChanged<String> onChangePassword,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AccountSecurityDialog(
        email: email,
        isEmailVerified: isEmailVerified,
        onResendVerification: onResendVerification,
        onChangePassword: onChangePassword,
      ),
    );
  }

  @override
  State<AccountSecurityDialog> createState() => _AccountSecurityDialogState();
}

class _AccountSecurityDialogState extends State<AccountSecurityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPasswordSection = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitPassword() {
    if (_formKey.currentState?.validate() ?? false) {
      final pwd = _newPasswordController.text;
      Navigator.of(context).pop();
      widget.onChangePassword(pwd);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shield_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Keamanan Akun',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Kelola kredensial dan verifikasi Supabase Auth Anda.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Informasi Email & Status Verifikasi
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.email,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            widget.isEmailVerified
                                ? Icons.verified_rounded
                                : Icons.warning_amber_rounded,
                            size: 14,
                            color: widget.isEmailVerified
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.isEmailVerified
                                ? 'Status: Terverifikasi oleh Supabase Auth'
                                : 'Status: Belum Terverifikasi',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: widget.isEmailVerified
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      if (!widget.isEmailVerified) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 12),
                          label: const Text(
                            'Kirim Ulang Tautan Verifikasi',
                            style: TextStyle(fontSize: 11),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onResendVerification();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Ubah Kata Sandi
                if (!_showPasswordSection)
                  CustomButton(
                    text: 'Ubah Kata Sandi Akun',
                    variant: ButtonVariant.outlined,
                    isFullWidth: true,
                    prefixIcon: const Icon(Icons.lock_reset_rounded, size: 18),
                    onPressed: () {
                      setState(() {
                        _showPasswordSection = true;
                      });
                    },
                  )
                else
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perbarui Kata Sandi',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          label: 'Kata Sandi Baru',
                          hintText: 'Minimal 8 karakter',
                          isPassword: true,
                          controller: _newPasswordController,
                          isRequired: true,
                          validator: Validators.validatePassword,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Konfirmasi Kata Sandi Baru',
                          hintText: 'Ulangi kata sandi baru',
                          isPassword: true,
                          controller: _confirmPasswordController,
                          isRequired: true,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Konfirmasi kata sandi wajib diisi';
                            }
                            if (val != _newPasswordController.text) {
                              return 'Kata sandi konfirmasi tidak cocok';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _showPasswordSection = false;
                                  _newPasswordController.clear();
                                  _confirmPasswordController.clear();
                                });
                              },
                              child: const Text('Batal'),
                            ),
                            const SizedBox(width: 8),
                            CustomButton(
                              text: 'Simpan Sandi Baru',
                              size: ButtonSize.medium,
                              onPressed: _submitPassword,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
