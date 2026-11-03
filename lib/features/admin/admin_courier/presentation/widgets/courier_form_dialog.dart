import 'package:flutter/material.dart';
import 'package:satset/features/auth/data/utils/validators.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_courier_item.dart';

class CourierFormDialog extends StatefulWidget {
  final AdminCourierItem? existingCourier;
  final void Function({
    required String namaLengkap,
    required String email,
    required String noHp,
    String? password,
    String? employeeCode,
    String? alamatLengkap,
    String? fotoUrl,
    required bool isActive,
  }) onSubmit;

  const CourierFormDialog({
    super.key,
    this.existingCourier,
    required this.onSubmit,
  });

  @override
  State<CourierFormDialog> createState() => _CourierFormDialogState();
}

class _CourierFormDialogState extends State<CourierFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _employeeCodeController;
  late final TextEditingController _addressController;
  late final TextEditingController _photoUrlController;

  late bool _isActive;
  bool _obscurePassword = true;

  bool get _isEditMode => widget.existingCourier != null;

  @override
  void initState() {
    super.initState();
    final c = widget.existingCourier;
    _nameController = TextEditingController(text: c?.namaLengkap ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _phoneController = TextEditingController(text: c?.noHp ?? '');
    _passwordController = TextEditingController();
    _employeeCodeController =
        TextEditingController(text: c?.employeeCode ?? '');
    _addressController =
        TextEditingController(text: c?.alamatLengkap ?? '');
    _photoUrlController = TextEditingController(text: c?.fotoUrl ?? '');
    _isActive = c?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _employeeCodeController.dispose();
    _addressController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    widget.onSubmit(
      namaLengkap: _nameController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      noHp: _phoneController.text.trim(),
      password: _passwordController.text.trim().isEmpty
          ? null
          : _passwordController.text.trim(),
      employeeCode: _employeeCodeController.text.trim().isEmpty
          ? null
          : _employeeCodeController.text.trim(),
      alamatLengkap: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      fotoUrl: _photoUrlController.text.trim().isEmpty
          ? null
          : _photoUrlController.text.trim(),
      isActive: _isActive,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Modal
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isEditMode
                              ? Icons.manage_accounts_rounded
                              : Icons.person_add_alt_1_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEditMode
                                  ? 'Edit Profil Kurir (${widget.existingCourier!.employeeCode})'
                                  : 'Tambah Akun Kurir Baru',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tabel m_employee • Role Kurir ditetapkan tetap (id_users_role = 2)',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Nama Lengkap
                  TextFormField(
                    controller: _nameController,
                    validator: Validators.validateName,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap Kurir *',
                      hintText: 'Contoh: Budi Santoso',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Email & Nomor Telepon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _emailController,
                          validator: Validators.validateEmail,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Kurir *',
                            hintText: 'kurir@satset.id',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          validator: Validators.validatePhone,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Nomor Telepon / HP *',
                            hintText: '081234567890',
                            prefixIcon: const Icon(Icons.phone_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Kode Identitas Employee & Password
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _employeeCodeController,
                          readOnly: _isEditMode,
                          decoration: InputDecoration(
                            labelText: _isEditMode
                                ? 'Identitas Employee (Terkunci)'
                                : 'Kode Pegawai (Opsional, Otomatis)',
                            hintText: 'Contoh: 005',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: (val) {
                            if (!_isEditMode) {
                              return Validators.validatePassword(val ?? '');
                            }
                            if (val != null && val.trim().isNotEmpty) {
                              return Validators.validatePassword(val.trim());
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: _isEditMode
                                ? 'Password Baru (Kosongkan jika tetap)'
                                : 'Password Akun Kurir *',
                            hintText: 'Min. 6 karakter',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 18,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Alamat Lengkap
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Alamat Domisili Kurir (alamat_lengkap)',
                      hintText: 'Masukkan alamat lengkap tempat tinggal kurir...',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // URL Foto Profil
                  TextFormField(
                    controller: _photoUrlController,
                    decoration: InputDecoration(
                      labelText: 'URL Foto Profil (foto_url - Opsional)',
                      hintText: 'https://...',
                      prefixIcon: const Icon(Icons.image_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Status Akun & Informasi Keamanan
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Status Akun Kurir Aktif (is_active)',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        _isActive
                            ? 'Kurir dapat login dan menerima penugasan pengiriman.'
                            : 'Akun dinonaktifkan; kurir tidak dapat menerima tugas baru.',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      value: _isActive,
                      onChanged: (val) {
                        setState(() {
                          _isActive = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Aksi
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _handleSave,
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          _isEditMode ? 'Simpan Perubahan' : 'Buat Akun Kurir',
                        ),
                      ),
                    ],
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

