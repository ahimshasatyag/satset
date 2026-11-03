import 'package:flutter/material.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_profile.dart';

class AdminProfileSection extends StatefulWidget {
  final AdminProfile profile;
  final bool isSaving;
  final void Function({
    required int adminId,
    required String namaLengkap,
    required String email,
    required String noHp,
    String? alamatLengkap,
  }) onSaveProfile;

  const AdminProfileSection({
    super.key,
    required this.profile,
    required this.isSaving,
    required this.onSaveProfile,
  });

  @override
  State<AdminProfileSection> createState() => _AdminProfileSectionState();
}

class _AdminProfileSectionState extends State<AdminProfileSection> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.namaLengkap);
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController = TextEditingController(text: widget.profile.noHp);
    _addressController =
        TextEditingController(text: widget.profile.alamatLengkap ?? '');
  }

  @override
  void didUpdateWidget(covariant AdminProfileSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != oldWidget.profile) {
      if (_nameController.text != widget.profile.namaLengkap) {
        _nameController.text = widget.profile.namaLengkap;
      }
      if (_emailController.text != widget.profile.email) {
        _emailController.text = widget.profile.email;
      }
      if (_phoneController.text != widget.profile.noHp) {
        _phoneController.text = widget.profile.noHp;
      }
      if (_addressController.text != (widget.profile.alamatLengkap ?? '')) {
        _addressController.text = widget.profile.alamatLengkap ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmSave() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Simpan Perubahan Profil Admin?'),
        content: const Text(
          'Pastikan informasi nama, alamat email, dan nomor telepon sudah benar. Perubahan akan disimpan ke tabel m_employee.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Simpan Perubahan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      widget.onSaveProfile(
        adminId: widget.profile.id,
        namaLengkap: _nameController.text.trim(),
        email: _emailController.text.trim(),
        noHp: _phoneController.text.trim(),
        alamatLengkap: _addressController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Form(
        key: _formKey,
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
                        'Profil Administrator (m_employee)',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelola identitas resmi akun administrator SatSet Delivery dengan hak akses id_users_role = 1.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Text(
                    'Role: ${widget.profile.role.toUpperCase()} (ID: ${widget.profile.idUsersRole})',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Kartu Ringkasan Identitas Pegawai
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _BadgeField(
                    label: 'ID Pegawai',
                    value: '#${widget.profile.id}',
                  ),
                  _BadgeField(
                    label: 'Kode Employee',
                    value: widget.profile.employeeCode,
                  ),
                  _BadgeField(
                    label: 'Tipe Pegawai',
                    value: widget.profile.employeeType,
                  ),
                  _BadgeField(
                    label: 'Status Akun',
                    value: widget.profile.isActive ? 'Aktif' : 'Nonaktif',
                  ),
                  _BadgeField(
                    label: 'Terdaftar Sejak',
                    value: AdminDateFormatter.formatDateTime(
                      widget.profile.createdAt,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Form Input Profil
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 680;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _nameController,
                              style: AppTextStyles.bodyMedium,
                              decoration: const InputDecoration(
                                labelText: 'Nama Lengkap Administrator *',
                                hintText: 'Masukkan nama lengkap resmi...',
                                prefixIcon: Icon(
                                  Icons.badge_outlined,
                                  size: 20,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Nama lengkap tidak boleh kosong.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              style: AppTextStyles.bodyMedium,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Alamat Email Administrator *',
                                hintText: 'nama@satset.id...',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  size: 20,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Email tidak boleh kosong.';
                                }
                                if (!val.contains('@') || !val.contains('.')) {
                                  return 'Format alamat email tidak valid.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _phoneController,
                              style: AppTextStyles.bodyMedium,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Nomor Telepon / WhatsApp *',
                                hintText: '08123456789...',
                                prefixIcon: Icon(
                                  Icons.phone_outlined,
                                  size: 20,
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Nomor telepon tidak boleh kosong.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _addressController,
                              style: AppTextStyles.bodyMedium,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Alamat Operasional (Opsional)',
                                hintText:
                                    'Alamat kantor atau domisili kerja...',
                                prefixIcon: Icon(
                                  Icons.location_on_outlined,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      style: AppTextStyles.bodyMedium,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap Administrator *',
                        hintText: 'Masukkan nama lengkap resmi...',
                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama lengkap tidak boleh kosong.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      style: AppTextStyles.bodyMedium,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Email Administrator *',
                        hintText: 'nama@satset.id...',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Email tidak boleh kosong.';
                        }
                        if (!val.contains('@') || !val.contains('.')) {
                          return 'Format alamat email tidak valid.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      style: AppTextStyles.bodyMedium,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Telepon / WhatsApp *',
                        hintText: '08123456789...',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nomor telepon tidak boleh kosong.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Operasional (Opsional)',
                        hintText: 'Alamat kantor atau domisili kerja...',
                        prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.icon(
                  onPressed: widget.isSaving ? null : _handleConfirmSave,
                  icon: widget.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    widget.isSaving
                        ? 'Menyimpan...'
                        : 'Simpan Perubahan Profil',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeField extends StatelessWidget {
  final String label;
  final String value;

  const _BadgeField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

