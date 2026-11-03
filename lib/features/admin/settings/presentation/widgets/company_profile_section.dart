import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/company_profile.dart';

class CompanyProfileSection extends StatefulWidget {
  final CompanyProfile companyProfile;
  final bool isSaving;
  final ValueChanged<CompanyProfile> onSaveCompany;

  const CompanyProfileSection({
    super.key,
    required this.companyProfile,
    required this.isSaving,
    required this.onSaveCompany,
  });

  @override
  State<CompanyProfileSection> createState() => _CompanyProfileSectionState();
}

class _CompanyProfileSectionState extends State<CompanyProfileSection> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;
  late final TextEditingController _hoursController;
  late final TextEditingController _mottoController;
  late final TextEditingController _legalController;

  @override
  void initState() {
    super.initState();
    final p = widget.companyProfile;
    _nameController = TextEditingController(text: p.companyName);
    _addressController = TextEditingController(text: p.operationalAddress);
    _phoneController = TextEditingController(text: p.contactPhone);
    _emailController = TextEditingController(text: p.contactEmail);
    _websiteController = TextEditingController(text: p.websiteUrl);
    _hoursController = TextEditingController(text: p.operationalHours);
    _mottoController = TextEditingController(text: p.motto);
    _legalController = TextEditingController(text: p.legalEntityNumber);
  }

  @override
  void didUpdateWidget(covariant CompanyProfileSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.companyProfile != oldWidget.companyProfile) {
      final p = widget.companyProfile;
      if (_nameController.text != p.companyName) {
        _nameController.text = p.companyName;
      }
      if (_addressController.text != p.operationalAddress) {
        _addressController.text = p.operationalAddress;
      }
      if (_phoneController.text != p.contactPhone) {
        _phoneController.text = p.contactPhone;
      }
      if (_emailController.text != p.contactEmail) {
        _emailController.text = p.contactEmail;
      }
      if (_websiteController.text != p.websiteUrl) {
        _websiteController.text = p.websiteUrl;
      }
      if (_hoursController.text != p.operationalHours) {
        _hoursController.text = p.operationalHours;
      }
      if (_mottoController.text != p.motto) {
        _mottoController.text = p.motto;
      }
      if (_legalController.text != p.legalEntityNumber) {
        _legalController.text = p.legalEntityNumber;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _hoursController.dispose();
    _mottoController.dispose();
    _legalController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirmSave() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Simpan Informasi Perusahaan?'),
        content: const Text(
          'Informasi profil perusahaan, kontak operasional, dan identitas resmi SatSet Delivery akan diperbarui.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Simpan Informasi'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updated = widget.companyProfile.copyWith(
        companyName: _nameController.text.trim(),
        operationalAddress: _addressController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        contactEmail: _emailController.text.trim(),
        websiteUrl: _websiteController.text.trim(),
        operationalHours: _hoursController.text.trim(),
        motto: _mottoController.text.trim(),
        legalEntityNumber: _legalController.text.trim(),
      );
      widget.onSaveCompany(updated);
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
            Text(
              'Informasi & Profil Perusahaan (SatSet Delivery)',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kelola nama resmi perusahaan, alamat kantor operasional, kontak layanan pelanggan, dan identitas korporat.',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: 16),

            // Catatan Skema Database Backend
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Kebutuhan Pengembangan Database (Backend Notice)',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.companyProfile.backendNote,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form Fields
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 320,
                  child: TextFormField(
                    controller: _nameController,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                      labelText: 'Nama Perusahaan / Badan Usaha *',
                      hintText: 'PT SatSet Delivery Indonesia...',
                      prefixIcon: Icon(Icons.business_outlined, size: 20),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nama perusahaan tidak boleh kosong.';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextFormField(
                    controller: _legalController,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Izin / Akta Legalitas *',
                      hintText: 'AHU-0012948.AH.01.01...',
                      prefixIcon: Icon(Icons.gavel_outlined, size: 20),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nomor legalitas tidak boleh kosong.';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextFormField(
                    controller: _emailController,
                    style: AppTextStyles.bodyMedium,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Resmi Customer Service *',
                      hintText: 'support@satset.id...',
                      prefixIcon: Icon(Icons.email_outlined, size: 20),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Email kontak tidak boleh kosong.';
                      }
                      if (!val.contains('@') || !val.contains('.')) {
                        return 'Format email tidak valid.';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextFormField(
                    controller: _phoneController,
                    style: AppTextStyles.bodyMedium,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor Telepon CS / Call Center *',
                      hintText: '+62 21 5550 8899...',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nomor kontak tidak boleh kosong.';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextFormField(
                    controller: _websiteController,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                      labelText: 'Website Resmi SatSet',
                      hintText: 'https://satset.id...',
                      prefixIcon: Icon(Icons.language_rounded, size: 20),
                    ),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextFormField(
                    controller: _hoursController,
                    style: AppTextStyles.bodyMedium,
                    decoration: const InputDecoration(
                      labelText: 'Jam Operasional Pengiriman',
                      hintText: 'Senin - Minggu: 24 Jam...',
                      prefixIcon: Icon(Icons.access_time_rounded, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _mottoController,
              style: AppTextStyles.bodyMedium,
              decoration: const InputDecoration(
                labelText: 'Motto / Slogan Resmi Brand',
                hintText: 'Sat-Set Sampai, Hati Pun Santai...',
                prefixIcon: Icon(Icons.campaign_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _addressController,
              style: AppTextStyles.bodyMedium,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Alamat Kantor Pusat & Pusat Logistik *',
                hintText:
                    'Alamat lengkap gedung kantor operasional SatSet Delivery...',
                prefixIcon: Icon(Icons.location_city_outlined, size: 20),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Alamat operasional tidak boleh kosong.';
                }
                return null;
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
                        : 'Simpan Profil Perusahaan',
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

