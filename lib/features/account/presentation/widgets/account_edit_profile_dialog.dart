import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/data/utils/validators.dart';

class AccountEditProfileDialog extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final String currentEmail;

  const AccountEditProfileDialog({
    super.key,
    required this.currentName,
    required this.currentPhone,
    required this.currentEmail,
  });

  static Future<Map<String, String>?> show(
    BuildContext context, {
    required String currentName,
    required String currentPhone,
    required String currentEmail,
  }) {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AccountEditProfileDialog(
        currentName: currentName,
        currentPhone: currentPhone,
        currentEmail: currentEmail,
      ),
    );
  }

  @override
  State<AccountEditProfileDialog> createState() =>
      _AccountEditProfileDialogState();
}

class _AccountEditProfileDialogState extends State<AccountEditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _phoneController = TextEditingController(text: widget.currentPhone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
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
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
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
                            'Ubah Profil Akun',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Perbarui informasi nama dan nomor telepon Anda.',
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
                  ],
                ),
                const SizedBox(height: 20),

                // Nama Lengkap
                CustomTextField(
                  label: 'Nama Lengkap',
                  hintText: 'Masukkan nama lengkap',
                  controller: _nameController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.person_rounded, size: 20),
                  validator: Validators.validateName,
                ),
                const SizedBox(height: 14),

                // Nomor Telepon
                CustomTextField(
                  label: 'Nomor Telepon',
                  hintText: 'Contoh: 081234567890',
                  controller: _phoneController,
                  isRequired: true,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_rounded, size: 20),
                  validator: Validators.validatePhone,
                ),
                const SizedBox(height: 14),

                // Email (Read-Only)
                CustomTextField(
                  label: 'Email Terdaftar',
                  hintText: widget.currentEmail,
                  readOnly: true,
                  enabled: false,
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  helperText:
                      'Email terhubung dengan akun Supabase Auth dan tidak dapat diubah.',
                ),
                const SizedBox(height: 24),

                // Tombol Aksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 10),
                    CustomButton(
                      text: 'Simpan Perubahan',
                      size: ButtonSize.medium,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
