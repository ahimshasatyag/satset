import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:satset/features/auth/data/utils/validators.dart';
import 'package:satset/features/customer/shipments/data/models/shipment_model.dart';
import 'package:satset/features/customer/shipments/domain/entities/shipment.dart';
import 'package:satset/features/customer/shipments/presentation/widgets/location_picker_map_dialog.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

import '../../domain/entities/customer_address.dart';
import '../../domain/repositories/address_repository.dart';

/// Form dialog (bottom sheet) untuk menambah atau mengubah data alamat customer.
/// Mendukung input:
/// - Dropdown Master Label (`id_label` dari tabel `m_label`)
/// - Nama Lengkap Penerima (`nama_lengkap`)
/// - Nomor Telepon / WhatsApp (`no_telp`)
/// - Email Penerima (`email`)
/// - Pemilih Lokasi Peta GPS Interaktif (`latitude`, `longitude`)
/// - Cascading Dropdown Wilayah Berjenjang (Provinsi, Kab/Kota, Kecamatan, Kelurahan)
/// - Alamat Lengkap & Kode Pos
/// - Switch Alamat Utama (`is_utama`)
class AddressFormDialog extends StatefulWidget {
  final CustomerAddress? initialAddress;
  final AddressRepository repository;
  final String? defaultName;
  final String? defaultPhone;
  final String? defaultEmail;

  const AddressFormDialog({
    super.key,
    this.initialAddress,
    required this.repository,
    this.defaultName,
    this.defaultPhone,
    this.defaultEmail,
  });

  static Future<CustomerAddress?> show(
    BuildContext context, {
    CustomerAddress? initialAddress,
    required AddressRepository repository,
    String? defaultName,
    String? defaultPhone,
    String? defaultEmail,
  }) {
    return showModalBottomSheet<CustomerAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddressFormDialog(
        initialAddress: initialAddress,
        repository: repository,
        defaultName: defaultName,
        defaultPhone: defaultPhone,
        defaultEmail: defaultEmail,
      ),
    );
  }

  @override
  State<AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<AddressFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _postalCodeController;

  // Master Labels (m_label)
  List<AddressLabel> _labels = [];
  AddressLabel? _selectedLabel;
  bool _isLoadingLabels = false;

  // Koordinat Peta (latitude & longitude)
  double? _latitude;
  double? _longitude;

  // Variabel dropdown wilayah berjenjang
  Province? _selectedProvince;
  Regency? _selectedRegency;
  District? _selectedDistrict;
  Village? _selectedVillage;

  List<Province> _provinces = [];
  List<Regency> _regencies = [];
  List<District> _districts = [];
  List<Village> _villages = [];

  bool _isLoadingProvinces = false;
  bool _isLoadingRegencies = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingVillages = false;

  bool _isPrimary = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final addr = widget.initialAddress;

    _titleController = TextEditingController(text: addr?.title ?? 'Rumah');
    _nameController = TextEditingController(
      text: addr?.receiverName ?? widget.defaultName ?? '',
    );
    _phoneController = TextEditingController(
      text: addr?.phoneNumber ?? widget.defaultPhone ?? '',
    );
    _emailController = TextEditingController(
      text: addr?.email ?? widget.defaultEmail ?? '',
    );
    _addressController = TextEditingController(text: addr?.fullAddress ?? '');
    _postalCodeController = TextEditingController(text: addr?.postalCode ?? '');

    _latitude = addr?.latitude;
    _longitude = addr?.longitude;
    _isPrimary = addr?.isPrimary ?? false;

    _initData();
  }

  Future<void> _initData() async {
    await Future.wait([_fetchLabels(), _initRegionData()]);
  }

  /// Mengambil master label dari tabel m_label
  Future<void> _fetchLabels() async {
    setState(() => _isLoadingLabels = true);
    try {
      final rows = await widget.repository.getLabels();
      if (mounted) {
        setState(() {
          _labels = rows;
          _resolveInitialLabel();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _labels = [];
          _resolveInitialLabel();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLabels = false);
      }
    }
  }

  void _resolveInitialLabel() {
    final addr = widget.initialAddress;
    if (addr?.labelId != null) {
      _selectedLabel = _labels.where((l) => l.id == addr!.labelId).firstOrNull;
    }
    if (_selectedLabel == null && addr?.title != null) {
      final t = addr!.title.toLowerCase();
      _selectedLabel = _labels
          .where((l) => l.name.toLowerCase() == t)
          .firstOrNull;
    }
    _selectedLabel ??=
        _labels.where((l) => l.name.toLowerCase() == 'rumah').firstOrNull ??
        (_labels.isNotEmpty ? _labels.first : null);

    if (_selectedLabel != null && _titleController.text.trim().isEmpty) {
      _titleController.text = _selectedLabel!.name;
    }
  }

  /// Inisialisasi awal master wilayah dan pemilihan otomatis saat mode edit
  Future<void> _initRegionData() async {
    final addr = widget.initialAddress;
    await _fetchProvinces();

    if (addr != null && mounted) {
      final prov = _provinces
          .where(
            (p) =>
                (addr.provinceCode != null && p.code == addr.provinceCode) ||
                (addr.provinceName != null &&
                    p.name.toLowerCase() == addr.provinceName!.toLowerCase()),
          )
          .firstOrNull;

      if (prov != null) {
        setState(() => _selectedProvince = prov);

        setState(() => _isLoadingRegencies = true);
        try {
          final regList = await widget.repository.getRegencies(prov.code);
          if (mounted) {
            setState(() {
              _regencies = regList;
              _isLoadingRegencies = false;
            });

            final reg = regList
                .where(
                  (r) =>
                      (addr.regencyCode != null &&
                          r.code == addr.regencyCode) ||
                      (addr.regencyName != null &&
                          r.name.toLowerCase() ==
                              addr.regencyName!.toLowerCase()),
                )
                .firstOrNull;

            if (reg != null) {
              setState(() => _selectedRegency = reg);

              setState(() => _isLoadingDistricts = true);
              try {
                final distList = await widget.repository.getDistricts(reg.code);
                if (mounted) {
                  setState(() {
                    _districts = distList;
                    _isLoadingDistricts = false;
                  });

                  final dist = distList
                      .where(
                        (d) =>
                            (addr.districtCode != null &&
                                d.code == addr.districtCode) ||
                            (addr.districtName != null &&
                                d.name.toLowerCase() ==
                                    addr.districtName!.toLowerCase()),
                      )
                      .firstOrNull;

                  if (dist != null) {
                    setState(() => _selectedDistrict = dist);

                    setState(() => _isLoadingVillages = true);
                    try {
                      final vilList = await widget.repository.getVillages(
                        dist.code,
                      );
                      if (mounted) {
                        setState(() {
                          _villages = vilList;
                          _isLoadingVillages = false;
                        });

                        final vil = vilList
                            .where(
                              (v) =>
                                  (addr.villageCode != null &&
                                      v.code == addr.villageCode) ||
                                  (addr.villageName != null &&
                                      v.name.toLowerCase() ==
                                          addr.villageName!.toLowerCase()),
                            )
                            .firstOrNull;

                        if (vil != null) {
                          setState(() {
                            _selectedVillage = vil;
                            if (_postalCodeController.text.trim().isEmpty &&
                                vil.postalCode != null &&
                                vil.postalCode!.isNotEmpty) {
                              _postalCodeController.text = vil.postalCode!;
                            }
                          });
                        }
                      }
                    } catch (_) {
                      if (mounted) setState(() => _isLoadingVillages = false);
                    }
                  }
                }
              } catch (_) {
                if (mounted) setState(() => _isLoadingDistricts = false);
              }
            }
          }
        } catch (_) {
          if (mounted) setState(() => _isLoadingRegencies = false);
        }
      }
    }
  }

  /// Mengambil daftar provinsi dari Supabase / repository
  Future<void> _fetchProvinces() async {
    setState(() => _isLoadingProvinces = true);
    try {
      final rows = await widget.repository.getProvinces();
      if (mounted) {
        setState(() => _provinces = rows);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _provinces = const [
            ProvinceModel(code: '31', name: 'DKI JAKARTA'),
            ProvinceModel(code: '32', name: 'JAWA BARAT'),
            ProvinceModel(code: '33', name: 'JAWA TENGAH'),
            ProvinceModel(code: '34', name: 'DI YOGYAKARTA'),
            ProvinceModel(code: '35', name: 'JAWA TIMUR'),
            ProvinceModel(code: '36', name: 'BANTEN'),
          ];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingProvinces = false);
      }
    }
  }

  Future<void> _fetchRegencies(String provinceCode) async {
    setState(() {
      _isLoadingRegencies = true;
      _regencies = [];
      _selectedRegency = null;
      _districts = [];
      _selectedDistrict = null;
      _villages = [];
      _selectedVillage = null;
    });

    try {
      final rows = await widget.repository.getRegencies(provinceCode);
      if (mounted) {
        setState(() => _regencies = rows);
      }
    } catch (_) {
      if (mounted) setState(() => _regencies = []);
    } finally {
      if (mounted) setState(() => _isLoadingRegencies = false);
    }
  }

  Future<void> _fetchDistricts(String regencyCode) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _selectedDistrict = null;
      _villages = [];
      _selectedVillage = null;
    });

    try {
      final rows = await widget.repository.getDistricts(regencyCode);
      if (mounted) {
        setState(() => _districts = rows);
      }
    } catch (_) {
      if (mounted) setState(() => _districts = []);
    } finally {
      if (mounted) setState(() => _isLoadingDistricts = false);
    }
  }

  Future<void> _fetchVillages(String districtCode) async {
    setState(() {
      _isLoadingVillages = true;
      _villages = [];
      _selectedVillage = null;
    });

    try {
      final rows = await widget.repository.getVillages(districtCode);
      if (mounted) {
        setState(() => _villages = rows);
      }
    } catch (_) {
      if (mounted) setState(() => _villages = []);
    } finally {
      if (mounted) setState(() => _isLoadingVillages = false);
    }
  }

  /// Membuka peta interaktif LocationPickerMapDialog untuk memilih titik GPS presisi
  Future<void> _pickLocationOnMap() async {
    final initialLoc =
        (_latitude != null && _longitude != null && _latitude != 0.0)
        ? LatLng(_latitude!, _longitude!)
        : null;

    final result = await LocationPickerMapDialog.show(
      context,
      title: 'Tentukan Titik Alamat',
      initialLocation: initialLoc,
      initialCityName: _selectedRegency?.name ?? _selectedProvince?.name,
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  Widget _buildRegionDropdown<T>({
    required String label,
    String? hintText,
    String? disabledHint,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
    required bool isDark,
    bool enabled = true,
    bool isLoading = false,
  }) {
    final effectiveHint = !enabled && disabledHint != null
        ? disabledHint
        : (hintText ?? 'Pilih $label');
    final isActuallyEnabled = enabled && !isLoading && items.isNotEmpty;

    return SearchableDropdown<T>(
      label: label,
      value: items.contains(value) ? value : null,
      items: items,
      itemLabel: itemLabel,
      onChanged: onChanged,
      isDark: isDark,
      enabled: isActuallyEnabled,
      isLoading: isLoading,
      hintText: effectiveHint,
      emptyHintText: 'Tidak ada data $label',
      searchHint: 'Cari $label...',
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProvince == null ||
        _selectedRegency == null ||
        _selectedDistrict == null ||
        _selectedVillage == null) {
      CustomDialog.showWarning(
        context: context,
        title: 'Wilayah Belum Lengkap',
        message: 'Silakan lengkapi pilihan Provinsi, Kabupaten/Kota, Kecamatan, dan Kelurahan terlebih dahulu.',
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final existing = widget.initialAddress;
    final labelTitle = _selectedLabel?.name ?? _titleController.text.trim();

    final result = CustomerAddress(
      id: existing?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
      rawId: existing?.rawId,
      userId: existing?.userId,
      title: labelTitle.isNotEmpty ? labelTitle : 'Alamat',
      receiverName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      fullAddress: _addressController.text.trim(),
      provinceCode: _selectedProvince?.code,
      provinceName: _selectedProvince?.name,
      regencyCode: _selectedRegency?.code,
      regencyName: _selectedRegency?.name,
      districtCode: _selectedDistrict?.code,
      districtName: _selectedDistrict?.name,
      villageCode: _selectedVillage?.code,
      villageName: _selectedVillage?.name,
      postalCode: _postalCodeController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
      labelId: _selectedLabel?.id,
      labelName: _selectedLabel?.name,
      isPrimary: _isPrimary,
      sourceType: existing?.sourceType ?? AddressSourceType.mAddress,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(result);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.initialAddress != null;
    final hasCoord =
        _latitude != null && _longitude != null && _latitude != 0.0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Ubah Alamat' : 'Tambah Alamat Baru',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isEditing
                            ? 'Perbarui detail data alamat Anda'
                            : 'Simpan alamat pengiriman baru untuk SatSet',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
            const SizedBox(height: 16),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Dropdown Label (id_label dari m_label)
                    SearchableDropdown<AddressLabel>(
                      label: 'Label Alamat',
                      hintText: 'Pilih Label Alamat',
                      value: _selectedLabel,
                      items: _labels,
                      itemLabel: (l) => l.name,
                      isLoading: _isLoadingLabels,
                      isDark: isDark,
                      enabled: !_isSubmitting,
                      onChanged: (val) {
                        setState(() {
                          _selectedLabel = val;
                          if (val != null) {
                            _titleController.text = val.name;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. Input Nama Lengkap (nama_lengkap)
                    CustomTextField(
                      label: 'Nama Lengkap Penerima',
                      hintText: 'Contoh: Budi Pratama',
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      isRequired: true,
                      enabled: !_isSubmitting,
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                      validator: Validators.validateName,
                    ),
                    const SizedBox(height: 16),

                    // 3. Input Nomor Telepon (no_telp)
                    CustomTextField(
                      label: 'Nomor Telepon / WhatsApp',
                      hintText: 'Contoh: 081234567890',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      isRequired: true,
                      enabled: !_isSubmitting,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: 16),

                    // 4. Input Email (email)
                    CustomTextField(
                      label: 'Alamat Email',
                      hintText: 'Contoh: nama@domain.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !_isSubmitting,
                      prefixIcon: const Icon(Icons.email_outlined),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return null;
                        return Validators.validateEmail(val.trim());
                      },
                    ),
                    const SizedBox(height: 16),

                    // 5. Pemilih Titik Koordinat Peta (latitude & longitude)
                    Text(
                      'Titik Lokasi Peta (GPS)',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: hasCoord
                            ? AppColors.primary.withValues(
                                alpha: isDark ? 0.15 : 0.06,
                              )
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: hasCoord
                              ? AppColors.primary.withValues(alpha: 0.5)
                              : (isDark ? Colors.white12 : Colors.black12),
                          width: hasCoord ? 1.5 : 1.0,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _isSubmitting ? null : _pickLocationOnMap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: hasCoord
                                        ? AppColors.primary
                                        : (isDark
                                              ? Colors.white12
                                              : Colors.black.withValues(
                                                  alpha: 0.06,
                                                )),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.map_rounded,
                                    size: 20,
                                    color: hasCoord
                                        ? Colors.white
                                        : (isDark
                                              ? Colors.white70
                                              : Colors.black54),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          const Text(
                                            'Pilih Titik di Peta',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (hasCoord)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.success
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'TERPASANG',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.success,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        hasCoord
                                            ? 'Lat: ${_latitude!.toStringAsFixed(6)}, Lng: ${_longitude!.toStringAsFixed(6)}'
                                            : 'Buka peta interaktif untuk menentukan titik koordinat presisi',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: hasCoord
                                              ? 'monospace'
                                              : null,
                                          color: isDark
                                              ? Colors.white60
                                              : Colors.black54,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (hasCoord)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                    ),
                                    tooltip: 'Hapus Titik',
                                    onPressed: () {
                                      setState(() {
                                        _latitude = null;
                                        _longitude = null;
                                      });
                                    },
                                  )
                                else
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6. Dropdown Wilayah Berjenjang
                    // 6.1 Dropdown Provinsi
                    _buildRegionDropdown<Province>(
                      label: 'Provinsi',
                      hintText: 'Pilih Provinsi',
                      value: _selectedProvince,
                      items: _provinces,
                      itemLabel: (p) => p.name,
                      isLoading: _isLoadingProvinces,
                      isDark: isDark,
                      enabled: !_isSubmitting,
                      onChanged: (p) {
                        if (p != _selectedProvince) {
                          setState(() {
                            _selectedProvince = p;
                          });
                          if (p != null) {
                            _fetchRegencies(p.code);
                          } else {
                            setState(() {
                              _regencies = [];
                              _selectedRegency = null;
                              _districts = [];
                              _selectedDistrict = null;
                              _villages = [];
                              _selectedVillage = null;
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 6.2 Dropdown Kabupaten / Kota
                    _buildRegionDropdown<Regency>(
                      label: 'Kabupaten / Kota',
                      hintText: 'Pilih Kabupaten/Kota',
                      disabledHint: 'Pilih provinsi terlebih dahulu',
                      value: _selectedRegency,
                      items: _regencies,
                      itemLabel: (r) => r.name,
                      enabled: !_isSubmitting && _selectedProvince != null,
                      isLoading: _isLoadingRegencies,
                      isDark: isDark,
                      onChanged: (r) {
                        if (r != _selectedRegency) {
                          setState(() {
                            _selectedRegency = r;
                          });
                          if (r != null) {
                            _fetchDistricts(r.code);
                          } else {
                            setState(() {
                              _districts = [];
                              _selectedDistrict = null;
                              _villages = [];
                              _selectedVillage = null;
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 6.3 Dropdown Kecamatan
                    _buildRegionDropdown<District>(
                      label: 'Kecamatan',
                      hintText: 'Pilih Kecamatan',
                      disabledHint: 'Pilih kabupaten/kota terlebih dahulu',
                      value: _selectedDistrict,
                      items: _districts,
                      itemLabel: (d) => d.name,
                      enabled: !_isSubmitting && _selectedRegency != null,
                      isLoading: _isLoadingDistricts,
                      isDark: isDark,
                      onChanged: (d) {
                        if (d != _selectedDistrict) {
                          setState(() {
                            _selectedDistrict = d;
                          });
                          if (d != null) {
                            _fetchVillages(d.code);
                          } else {
                            setState(() {
                              _villages = [];
                              _selectedVillage = null;
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // 6.4 Dropdown Kelurahan
                    _buildRegionDropdown<Village>(
                      label: 'Kelurahan',
                      hintText: 'Pilih Kelurahan',
                      disabledHint: 'Pilih kecamatan terlebih dahulu',
                      value: _selectedVillage,
                      items: _villages,
                      itemLabel: (v) => v.name,
                      enabled: !_isSubmitting && _selectedDistrict != null,
                      isLoading: _isLoadingVillages,
                      isDark: isDark,
                      onChanged: (v) {
                        setState(() {
                          _selectedVillage = v;
                          if (v?.postalCode != null &&
                              v!.postalCode!.isNotEmpty) {
                            _postalCodeController.text = v.postalCode!;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // 7. Input Alamat Lengkap
                    CustomTextField(
                      label: 'Alamat Lengkap',
                      hintText:
                          'Contoh: Jl. Sudirman No. 45, RT 01/RW 02, Menteng',
                      controller: _addressController,
                      keyboardType: TextInputType.streetAddress,
                      textInputAction: TextInputAction.next,
                      maxLines: 2,
                      isRequired: true,
                      enabled: !_isSubmitting,
                      prefixIcon: const Icon(Icons.home_outlined),
                      validator: Validators.validateAddress,
                    ),
                    const SizedBox(height: 16),

                    // 8. Kode Pos
                    CustomTextField(
                      label: 'Kode Pos',
                      hintText: 'Contoh: 10110',
                      controller: _postalCodeController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      enabled: !_isSubmitting,
                      prefixIcon: const Icon(Icons.local_post_office_outlined),
                    ),
                    const SizedBox(height: 16),

                    // 9. Switch Alamat Utama
                    if (isEditing) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 20,
                              color: _isPrimary
                                  ? AppColors.secondary
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Jadikan sebagai Alamat Utama',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Switch(
                              value: _isPrimary,
                              activeThumbColor: AppColors.primary,
                              onChanged: _isSubmitting
                                  ? null
                                  : (val) => setState(() => _isPrimary = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Button Simpan
            CustomButton(
              text: isEditing ? 'Simpan Perubahan' : 'Tambah Alamat',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _submit,
              prefixIcon: Icon(
                isEditing
                    ? Icons.check_circle_outline_rounded
                    : Icons.add_location_alt_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
