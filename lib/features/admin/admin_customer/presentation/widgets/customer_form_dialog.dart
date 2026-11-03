import 'package:flutter/material.dart';
import 'package:satset/features/admin/delivery/presentation/widgets/admin_searchable_dropdown.dart';
import 'package:satset/features/auth/data/utils/validators.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_customer_item.dart';
import '../../domain/repositories/admin_customer_repository.dart';

class CustomerFormDialog extends StatefulWidget {
  final AdminCustomerItem customer;
  final AdminCustomerRepository repository;
  final void Function({
    required String namaLengkap,
    required String email,
    required String noHp,
    String? alamatLengkap,
    String? idProvinsi,
    String? idKabkot,
    String? idKecamatan,
    String? idKelurahan,
    double? latitude,
    double? longitude,
    required bool emailVerified,
  }) onSubmit;

  const CustomerFormDialog({
    super.key,
    required this.customer,
    required this.repository,
    required this.onSubmit,
  });

  @override
  State<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _kodePosController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;

  String _selectedProvinsi = '';
  String _selectedKabkot = '';
  String _selectedKecamatan = '';
  String _selectedKelurahan = '';
  late bool _emailVerified;

  List<AdminWilayahOption> _provinsiList = [];
  List<AdminWilayahOption> _kabkotList = [];
  List<AdminWilayahOption> _kecamatanList = [];
  List<AdminWilayahOption> _kelurahanList = [];
  bool _isLoadingWilayah = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameController = TextEditingController(text: c.namaLengkap);
    _emailController = TextEditingController(text: c.email);
    _phoneController = TextEditingController(text: c.noHp);
    _addressController = TextEditingController(text: c.alamatLengkap ?? '');
    _kodePosController = TextEditingController(text: c.kodePos ?? '');
    _latitudeController = TextEditingController(
      text: c.latitude != null ? c.latitude!.toString() : '',
    );
    _longitudeController = TextEditingController(
      text: c.longitude != null ? c.longitude!.toString() : '',
    );

    _selectedProvinsi = c.idProvinsi ?? '';
    _selectedKabkot = c.idKabkot ?? '';
    _selectedKecamatan = c.idKecamatan ?? '';
    _selectedKelurahan = c.idKelurahan ?? '';
    _emailVerified = c.emailVerified;

    _loadInitialWilayahHierarchy();
  }

  Future<void> _loadInitialWilayahHierarchy() async {
    if (!mounted) return;
    setState(() => _isLoadingWilayah = true);

    try {
      final provs = await widget.repository.getProvinsiList();
      List<AdminWilayahOption> kabs = [];
      List<AdminWilayahOption> kecs = [];
      List<AdminWilayahOption> kels = [];

      if (_selectedProvinsi.isNotEmpty) {
        kabs = await widget.repository.getKabkotList(_selectedProvinsi);
      }
      if (_selectedKabkot.isNotEmpty) {
        kecs = await widget.repository.getKecamatanList(_selectedKabkot);
      }
      if (_selectedKelurahan.isNotEmpty || _selectedKecamatan.isNotEmpty) {
        kels = await widget.repository.getKelurahanList(_selectedKecamatan);
      }

      if (mounted) {
        setState(() {
          _provinsiList = provs;
          _kabkotList = kabs;
          _kecamatanList = kecs;
          _kelurahanList = kels;
          _isLoadingWilayah = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingWilayah = false);
      }
    }
  }

  Future<void> _onProvinsiChanged(String kodeProv) async {
    setState(() {
      _selectedProvinsi = kodeProv;
      _selectedKabkot = '';
      _selectedKecamatan = '';
      _selectedKelurahan = '';
      _kabkotList = [];
      _kecamatanList = [];
      _kelurahanList = [];
      _kodePosController.clear();
    });

    if (kodeProv.isNotEmpty) {
      final kabs = await widget.repository.getKabkotList(kodeProv);
      if (mounted) {
        setState(() => _kabkotList = kabs);
      }
    }
  }

  Future<void> _onKabkotChanged(String kodeKab) async {
    setState(() {
      _selectedKabkot = kodeKab;
      _selectedKecamatan = '';
      _selectedKelurahan = '';
      _kecamatanList = [];
      _kelurahanList = [];
      _kodePosController.clear();
    });

    if (kodeKab.isNotEmpty) {
      final kecs = await widget.repository.getKecamatanList(kodeKab);
      if (mounted) {
        setState(() => _kecamatanList = kecs);
      }
    }
  }

  Future<void> _onKecamatanChanged(String kodeKec) async {
    setState(() {
      _selectedKecamatan = kodeKec;
      _selectedKelurahan = '';
      _kelurahanList = [];
      _kodePosController.clear();
    });

    if (kodeKec.isNotEmpty) {
      final kels = await widget.repository.getKelurahanList(kodeKec);
      if (mounted) {
        setState(() => _kelurahanList = kels);
      }
    }
  }

  void _onKelurahanChanged(String kodeKel) {
    String? foundKodePos;
    for (final k in _kelurahanList) {
      if (k.kode == kodeKel) {
        foundKodePos = k.kodePos;
        break;
      }
    }
    setState(() {
      _selectedKelurahan = kodeKel;
      if (foundKodePos != null && foundKodePos.isNotEmpty) {
        _kodePosController.text = foundKodePos;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _kodePosController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Pembaruan Profil Customer'),
        content: Text(
          'Apakah Anda yakin ingin menyimpan perubahan informasi profil dan wilayah untuk customer "${_nameController.text.trim()}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, Simpan'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    widget.onSubmit(
      namaLengkap: _nameController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      noHp: _phoneController.text.trim(),
      alamatLengkap: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      idProvinsi: _selectedProvinsi.isEmpty ? null : _selectedProvinsi,
      idKabkot: _selectedKabkot.isEmpty ? null : _selectedKabkot,
      idKecamatan: _selectedKecamatan.isEmpty ? null : _selectedKecamatan,
      idKelurahan: _selectedKelurahan.isEmpty ? null : _selectedKelurahan,
      latitude: double.tryParse(_latitudeController.text.trim()),
      longitude: double.tryParse(_longitudeController.text.trim()),
      emailVerified: _emailVerified,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660),
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
                        child: const Icon(
                          Icons.person_pin_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Profil & Alamat Customer (ID #${widget.customer.id})',
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Tabel m_users • Password customer dikelola terpisah via Supabase Auth',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoadingWilayah)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
                      labelText: 'Nama Lengkap Customer *',
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
                            labelText: 'Email Customer *',
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

                  // Alamat Lengkap (alamat_lengkap)
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Alamat Lengkap Utama (alamat_lengkap)',
                      hintText: 'Masukkan nama jalan, nomor rumah, RT/RW...',
                      prefixIcon: const Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Pilihan Wilayah Bertingkat (Provinsi & Kabupaten/Kota)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AdminSearchableDropdown<String>(
                          value: _selectedProvinsi,
                          width: double.infinity,
                          labelText: 'Provinsi (m_provinsi)',
                          hintText: 'Pilih Provinsi',
                          searchHintText: 'Cari provinsi...',
                          options: [
                            const AdminDropdownOption(
                              value: '',
                              label: '-- Pilih Provinsi --',
                            ),
                            ..._provinsiList.map((p) {
                              return AdminDropdownOption<String>(
                                value: p.kode,
                                label: p.nama,
                              );
                            }),
                          ],
                          onChanged: _onProvinsiChanged,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AdminSearchableDropdown<String>(
                          value: _selectedKabkot,
                          width: double.infinity,
                          labelText: 'Kabupaten / Kota (m_kabkot)',
                          hintText: 'Pilih Kabupaten/Kota',
                          searchHintText: 'Cari kabupaten/kota...',
                          options: [
                            const AdminDropdownOption(
                              value: '',
                              label: '-- Pilih Kabupaten/Kota --',
                            ),
                            ..._kabkotList.map((k) {
                              return AdminDropdownOption<String>(
                                value: k.kode,
                                label: k.nama,
                              );
                            }),
                          ],
                          onChanged: _onKabkotChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Pilihan Wilayah Bertingkat (Kecamatan & Kelurahan + Kode Pos)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AdminSearchableDropdown<String>(
                          value: _selectedKecamatan,
                          width: double.infinity,
                          labelText: 'Kecamatan (m_kecamatan)',
                          hintText: 'Pilih Kecamatan',
                          searchHintText: 'Cari kecamatan...',
                          options: [
                            const AdminDropdownOption(
                              value: '',
                              label: '-- Pilih Kecamatan --',
                            ),
                            ..._kecamatanList.map((kc) {
                              return AdminDropdownOption<String>(
                                value: kc.kode,
                                label: kc.nama,
                              );
                            }),
                          ],
                          onChanged: _onKecamatanChanged,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AdminSearchableDropdown<String>(
                          value: _selectedKelurahan,
                          width: double.infinity,
                          labelText: 'Kelurahan / Desa (m_kelurahan)',
                          hintText: 'Pilih Kelurahan',
                          searchHintText: 'Cari kelurahan...',
                          options: [
                            const AdminDropdownOption(
                              value: '',
                              label: '-- Pilih Kelurahan --',
                            ),
                            ..._kelurahanList.map((kl) {
                              return AdminDropdownOption<String>(
                                value: kl.kode,
                                label: kl.kodePos != null &&
                                        kl.kodePos!.isNotEmpty
                                    ? '${kl.nama} (${kl.kodePos})'
                                    : kl.nama,
                              );
                            }),
                          ],
                          onChanged: _onKelurahanChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Kode Pos, Latitude, Longitude
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _kodePosController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Kode Pos Kelurahan',
                            hintText: 'Otomatis dari m_kelurahan',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _latitudeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Latitude',
                            hintText: '-6.9932',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _longitudeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Longitude',
                            hintText: '110.4203',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Status Verifikasi Email (email_verified)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
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
                        'Status Verifikasi Email (email_verified)',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        _emailVerified
                            ? 'Email customer telah terverifikasi pada sistem.'
                            : 'Email customer belum terverifikasi.',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      value: _emailVerified,
                      onChanged: (val) {
                        setState(() => _emailVerified = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

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
                        label: const Text('Simpan Perubahan'),
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

