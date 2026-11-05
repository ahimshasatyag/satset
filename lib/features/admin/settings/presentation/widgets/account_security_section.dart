import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_profile.dart';

class AccountSecuritySection extends StatefulWidget {
  final AdminProfile profile;
  final bool isSaving;
  final void Function({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) onChangePassword;
  final VoidCallback onLogout;

  const AccountSecuritySection({
    super.key,
    required this.profile,
    required this.isSaving,
    required this.onChangePassword,
    required this.onLogout,
  });

  @override
  State<AccountSecuritySection> createState() => _AccountSecuritySectionState();
}

class _AccountSecuritySectionState extends State<AccountSecuritySection> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Konfirmasi Ubah Kata Sandi',
            style: TextStyle(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin memperbarui kata sandi akun administrator ini melalui Supabase Auth? '
            'Setelah berhasil, gunakan kata sandi baru untuk sesi login berikutnya.',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Ubah Kata Sandi'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      widget.onChangePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textStyle = AppTextStyles.bodyMedium.copyWith(
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
    final iconColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

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
          Text(
            'Keamanan Akun & Pengelolaan Sesi Login',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola kata sandi akun secara aman melalui Supabase Auth serta pantau status sesi login administrator.',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 20),

          // Informasi Sesi Login Aktif
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lock_clock_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sesi Login Administrator Aktif',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'AKTIF & TERAUTENTIKASI',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 24,
                  runSpacing: 10,
                  children: [
                    _SessionField(
                      label: 'Email Terdaftar',
                      value: widget.profile.email,
                      isDark: isDark,
                    ),
                    _SessionField(
                      label: 'Tingkat Otoritas',
                      value:
                          'Administrator (Role ID: ${widget.profile.idUsersRole})',
                      isDark: isDark,
                    ),
                    _SessionField(
                      label: 'Mekanisme Autentikasi',
                      value: 'Supabase JWT Auth & HTTP Secure Cookies',
                      isDark: isDark,
                    ),
                    _SessionField(
                      label: 'Proteksi Sandi',
                      value:
                          'Bcrypt Hash Encoding (Tidak Pernah Disimpan Plain Text)',
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Form Ubah Kata Sandi
          Text(
            'Ubah Kata Sandi Akun (Supabase Auth Security)',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kata sandi baru minimal harus terdiri dari 6 karakter kombinasi yang aman.',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),

          Form(
            key: _formKey,
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 320,
                  child: TextFormField(
                    controller: _currentPasswordController,
                    obscureText: _obscureCurrent,
                    style: textStyle,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi Saat Ini *',
                      hintText: '••••••••',
                      prefixIcon: Icon(
                        Icons.key_outlined,
                        size: 20,
                        color: iconColor,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrent
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: iconColor,
                        ),
                        onPressed: () =>
                            setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Kata sandi saat ini harus diisi.';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    style: textStyle,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi Baru *',
                      hintText: 'Minimal 6 karakter...',
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: iconColor,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: iconColor,
                        ),
                        onPressed: () =>
                            setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Kata sandi baru tidak boleh kosong.';
                      }
                      if (val.length < 6) {
                        return 'Kata sandi minimal 6 karakter.';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    style: textStyle,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Kata Sandi Baru *',
                      hintText: 'Ulangi kata sandi baru...',
                      prefixIcon: Icon(
                        Icons.lock_reset_rounded,
                        size: 20,
                        color: iconColor,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: iconColor,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
                      ),
                    ),
                    validator: (val) {
                      if (val != _newPasswordController.text) {
                        return 'Konfirmasi kata sandi tidak cocok.';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed:
                    widget.isSaving ? null : _handleConfirmChangePassword,
                icon: widget.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.security_update_good_rounded, size: 18),
                label: Text(
                  widget.isSaving
                      ? 'Memperbarui...'
                      : 'Perbarui Kata Sandi',
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          const SizedBox(height: 20),

          // Bagian Keluar / Logout Sesi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keluar dari Sesi Administrator',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hapus token autentikasi lokal, bersihkan cookies, dan akhiri sesi login saat ini.',
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
              OutlinedButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout_rounded, size: 17),
                label: const Text('Keluar (Logout)'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionField extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _SessionField({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 11,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}

