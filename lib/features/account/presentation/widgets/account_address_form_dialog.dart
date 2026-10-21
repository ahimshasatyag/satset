import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../shipments/domain/entities/shipment.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/repositories/account_repository.dart';
import '../../../auth/data/utils/validators.dart';

class AccountAddressFormDialog extends StatefulWidget {
  final AccountRepository repository;
  final UserAddress? initialAddress;
  final String defaultReceiverName;
  final String defaultPhone;

  const AccountAddressFormDialog({
    super.key,
    required this.repository,
    this.initialAddress,
    required this.defaultReceiverName,
    required this.defaultPhone,
  });

  static Future<UserAddress?> show(
    BuildContext context, {
    required AccountRepository repository,
    UserAddress? initialAddress,
    required String defaultReceiverName,
    required String defaultPhone,
  }) {
    return showDialog<UserAddress>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AccountAddressFormDialog(
        repository: repository,
        initialAddress: initialAddress,
        defaultReceiverName: defaultReceiverName,
        defaultPhone: defaultPhone,
      ),
    );
  }

  @override
  State<AccountAddressFormDialog> createState() =>
      _AccountAddressFormDialogState();
}

class _AccountAddressFormDialogState extends State<AccountAddressFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _labelController;
  late final TextEditingController _receiverNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _fullAddressController;
  late final TextEditingController _postalCodeController;

  bool _isPrimary = false;

  // Data master wilayah berjenjang
  List<Province> _provinces = [];
  List<Regency> _regencies = [];
  List<District> _districts = [];
  List<Village> _villages = [];

  Province? _selectedProvince;
  Regency? _selectedRegency;
  District? _selectedDistrict;
  Village? _selectedVillage;

  bool _isLoadingProvinces = true;
  bool _isLoadingRegencies = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingVillages = false;

  final List<String> _quickLabels = ['Rumah', 'Kantor', 'Gudang', 'Toko'];

  @override
  void initState() {
    super.initState();
    final init = widget.initialAddress;
    _labelController = TextEditingController(text: init?.label ?? 'Rumah');
    _receiverNameController = TextEditingController(
      text: init?.receiverName.isNotEmpty == true
          ? init!.receiverName
          : widget.defaultReceiverName,
    );
    _phoneController = TextEditingController(
      text: init?.phone.isNotEmpty == true ? init!.phone : widget.defaultPhone,
    );
    _fullAddressController =
        TextEditingController(text: init?.fullAddress ?? '');
    _postalCodeController =
        TextEditingController(text: init?.postalCode ?? '');
    _isPrimary = init?.isPrimary ?? false;

    _loadInitialRegionData();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _receiverNameController.dispose();
    _phoneController.dispose();
    _fullAddressController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialRegionData() async {
    try {
      final provinces = await widget.repository.getProvinces();
      if (!mounted) return;
      setState(() {
        _provinces = provinces;
        _isLoadingProvinces = false;
      });

      final init = widget.initialAddress;
      if (init != null && init.provinceCode != null) {
        final prov = provinces.where((p) => p.code == init.provinceCode).firstOrNull;
        if (prov != null) {
          _selectedProvince = prov;
          await _onProvinceChanged(prov, isInitial: true);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingProvinces = false);
      }
    }
  }

  Future<void> _onProvinceChanged(Province? prov, {bool isInitial = false}) async {
    if (prov == null) return;
    setState(() {
      _selectedProvince = prov;
      if (!isInitial) {
        _selectedRegency = null;
        _selectedDistrict = null;
        _selectedVillage = null;
        _regencies = [];
        _districts = [];
        _villages = [];
        _postalCodeController.clear();
      }
      _isLoadingRegencies = true;
    });

    try {
      final regencies = await widget.repository.getRegencies(prov.code);
      if (!mounted) return;
      setState(() {
        _regencies = regencies;
        _isLoadingRegencies = false;
      });

      final init = widget.initialAddress;
      if (isInitial && init != null && init.regencyCode != null) {
        final reg = regencies.where((r) => r.code == init.regencyCode).firstOrNull;
        if (reg != null) {
          _selectedRegency = reg;
          await _onRegencyChanged(reg, isInitial: true);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingRegencies = false);
    }
  }

  Future<void> _onRegencyChanged(Regency? reg, {bool isInitial = false}) async {
    if (reg == null) return;
    setState(() {
      _selectedRegency = reg;
      if (!isInitial) {
        _selectedDistrict = null;
        _selectedVillage = null;
        _districts = [];
        _villages = [];
        _postalCodeController.clear();
      }
      _isLoadingDistricts = true;
    });

    try {
      final districts = await widget.repository.getDistricts(reg.code);
      if (!mounted) return;
      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;
      });

      final init = widget.initialAddress;
      if (isInitial && init != null && init.districtCode != null) {
        final dist = districts.where((d) => d.code == init.districtCode).firstOrNull;
        if (dist != null) {
          _selectedDistrict = dist;
          await _onDistrictChanged(dist, isInitial: true);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingDistricts = false);
    }
  }

  Future<void> _onDistrictChanged(District? dist, {bool isInitial = false}) async {
    if (dist == null) return;
    setState(() {
      _selectedDistrict = dist;
      if (!isInitial) {
        _selectedVillage = null;
        _villages = [];
        _postalCodeController.clear();
      }
      _isLoadingVillages = true;
    });

    try {
      final villages = await widget.repository.getVillages(dist.code);
      if (!mounted) return;
      setState(() {
        _villages = villages;
        _isLoadingVillages = false;
      });

      final init = widget.initialAddress;
      if (isInitial && init != null && init.villageCode != null) {
        final vil = villages.where((v) => v.code == init.villageCode).firstOrNull;
        if (vil != null) {
          _selectedVillage = vil;
          if (vil.postalCode != null && _postalCodeController.text.isEmpty) {
            _postalCodeController.text = vil.postalCode!;
          }
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingVillages = false);
    }
  }

  void _onVillageChanged(Village? vil) {
    if (vil == null) return;
    setState(() {
      _selectedVillage = vil;
      if (vil.postalCode != null && vil.postalCode!.isNotEmpty) {
        _postalCodeController.text = vil.postalCode!;
      }
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final id = widget.initialAddress?.id ??
          'addr-${DateTime.now().millisecondsSinceEpoch}';

      final address = UserAddress(
        id: id,
        label: _labelController.text.trim().isNotEmpty
            ? _labelController.text.trim()
            : 'Alamat',
        receiverName: _receiverNameController.text.trim(),
        phone: _phoneController.text.trim(),
        provinceCode: _selectedProvince?.code ?? widget.initialAddress?.provinceCode,
        provinceName: _selectedProvince?.name ?? widget.initialAddress?.provinceName,
        regencyCode: _selectedRegency?.code ?? widget.initialAddress?.regencyCode,
        regencyName: _selectedRegency?.name ?? widget.initialAddress?.regencyName,
        districtCode: _selectedDistrict?.code ?? widget.initialAddress?.districtCode,
        districtName: _selectedDistrict?.name ?? widget.initialAddress?.districtName,
        villageCode: _selectedVillage?.code ?? widget.initialAddress?.villageCode,
        villageName: _selectedVillage?.name ?? widget.initialAddress?.villageName,
        postalCode: _postalCodeController.text.trim(),
        fullAddress: _fullAddressController.text.trim(),
        latitude: widget.initialAddress?.latitude,
        longitude: widget.initialAddress?.longitude,
        isPrimary: _isPrimary,
      );

      Navigator.of(context).pop(address);
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
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
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
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.initialAddress == null
                                ? 'Tambah Alamat Baru'
                                : 'Ubah Alamat Pengiriman',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Gunakan data wilayah berjenjang resmi SatSet.',
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
                const SizedBox(height: 16),

                // Form Konten Scrollable
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label Alamat & Quick Chips
                        Text(
                          'Label Alamat',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          children: _quickLabels.map((l) {
                            final isSelected = _labelController.text == l;
                            return ChoiceChip(
                              label: Text(l, style: const TextStyle(fontSize: 11)),
                              selected: isSelected,
                              selectedColor:
                                  AppColors.primary.withValues(alpha: 0.18),
                              onSelected: (_) {
                                setState(() {
                                  _labelController.text = l;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          hintText: 'Contoh: Rumah, Kantor SCBD, dll',
                          controller: _labelController,
                          isRequired: true,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Label alamat wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        // Nama Penerima & No HP
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                label: 'Nama Penerima',
                                hintText: 'Nama lengkap',
                                controller: _receiverNameController,
                                isRequired: true,
                                validator: Validators.validateName,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                label: 'Nomor HP',
                                hintText: '08123456789',
                                controller: _phoneController,
                                isRequired: true,
                                keyboardType: TextInputType.phone,
                                validator: Validators.validatePhone,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Wilayah Berjenjang
                        Text(
                          'Wilayah Pengiriman (Berjenjang)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 1. Provinsi
                        _buildDropdown<Province>(
                          label: 'Provinsi',
                          hint: 'Pilih Provinsi',
                          value: _selectedProvince,
                          items: _provinces,
                          isLoading: _isLoadingProvinces,
                          itemLabel: (p) => p.name,
                          onChanged: _onProvinceChanged,
                        ),
                        const SizedBox(height: 10),

                        // 2. Kabupaten / Kota
                        _buildDropdown<Regency>(
                          label: 'Kabupaten / Kota',
                          hint: _selectedProvince == null
                              ? 'Pilih provinsi terlebih dahulu'
                              : 'Pilih Kabupaten / Kota',
                          value: _selectedRegency,
                          items: _regencies,
                          isLoading: _isLoadingRegencies,
                          itemLabel: (r) => '${r.type} ${r.name}',
                          onChanged: _onRegencyChanged,
                        ),
                        const SizedBox(height: 10),

                        // 3. Kecamatan
                        _buildDropdown<District>(
                          label: 'Kecamatan',
                          hint: _selectedRegency == null
                              ? 'Pilih kab/kota terlebih dahulu'
                              : 'Pilih Kecamatan',
                          value: _selectedDistrict,
                          items: _districts,
                          isLoading: _isLoadingDistricts,
                          itemLabel: (d) => d.name,
                          onChanged: _onDistrictChanged,
                        ),
                        const SizedBox(height: 10),

                        // 4. Kelurahan & Kode Pos
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildDropdown<Village>(
                                label: 'Kelurahan',
                                hint: _selectedDistrict == null
                                    ? 'Pilih kecamatan'
                                    : 'Pilih Kelurahan',
                                value: _selectedVillage,
                                items: _villages,
                                isLoading: _isLoadingVillages,
                                itemLabel: (v) => v.name,
                                onChanged: _onVillageChanged,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: CustomTextField(
                                label: 'Kode Pos',
                                hintText: '10110',
                                controller: _postalCodeController,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Alamat Lengkap
                        CustomTextField(
                          label: 'Alamat Lengkap & Patokan',
                          hintText:
                              'Jl. Sudirman No. 12, RT 01/RW 02, Dekat Menara SatSet',
                          controller: _fullAddressController,
                          isRequired: true,
                          maxLines: 2,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Alamat lengkap wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Checkbox Jadikan Alamat Utama
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Jadikan sebagai alamat utama',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Alamat utama akan otomatis terpilih saat membuat order pengiriman.',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          value: _isPrimary,
                          activeColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _isPrimary = val ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tombol Simpan & Batal
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 10),
                    CustomButton(
                      text: widget.initialAddress == null
                          ? 'Simpan Alamat'
                          : 'Perbarui Alamat',
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

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<T> items,
    required bool isLoading,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariantLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 44,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    isExpanded: true,
                    value: value,
                    hint: Text(
                      hint,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                    items: items.map((item) {
                      return DropdownMenuItem<T>(
                        value: item,
                        child: Text(
                          itemLabel(item),
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: items.isEmpty ? null : onChanged,
                  ),
                ),
        ),
      ],
    );
  }
}
