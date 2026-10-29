import 'package:flutter/material.dart';
import 'package:satset/features/auth/data/utils/validators.dart';
import 'package:satset/features/customer/shipments/data/models/shipment_model.dart';
import 'package:satset/features/customer/shipments/domain/entities/shipment.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';
import '../../domain/entities/customer_address.dart';
import '../../domain/repositories/address_repository.dart';

/// Form dialog (bottom sheet) untuk menambah atau mengubah data alamat customer.
/// Mengadopsi implementasi dropdown wilayah berjenjang (Provinsi, Kab/Kota, Kecamatan, Kelurahan)
/// yang persis dan konsisten dengan [RegisterPage].
class AddressFormDialog extends StatefulWidget {
  final CustomerAddress? initialAddress;
  final AddressRepository repository;
  final String? defaultName;
  final String? defaultPhone;

  const AddressFormDialog({
    super.key,
    this.initialAddress,
    required this.repository,
    this.defaultName,
    this.defaultPhone,
  });

  static Future<CustomerAddress?> show(
    BuildContext context, {
    CustomerAddress? initialAddress,
    required AddressRepository repository,
    String? defaultName,
    String? defaultPhone,
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
  late final TextEditingController _addressController;
  late final TextEditingController _postalCodeController;

  // Variabel dropdown wilayah berjenjang (selaras dengan RegisterPage)
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

  bool _isSubmitting = false;

  static const List<String> _quickLabels = ['Rumah', 'Kantor', 'Apartemen', 'Toko'];

  @override
  void initState() {
    super.initState();
    final addr = widget.initialAddress;

    _titleController = TextEditingController(
      text: addr?.title ?? 'Rumah',
    );
    _nameController = TextEditingController(
      text: addr?.receiverName ?? widget.defaultName ?? '',
    );
    _phoneController = TextEditingController(
      text: addr?.phoneNumber ?? widget.defaultPhone ?? '',
    );
    _addressController = TextEditingController(
      text: addr?.fullAddress ?? '',
    );
    _postalCodeController = TextEditingController(
      text: addr?.postalCode ?? '',
    );

    _initRegionData();
  }

  /// Inisialisasi awal master wilayah dan pemilihan otomatis saat mode edit
  Future<void> _initRegionData() async {
    final addr = widget.initialAddress;
    await _fetchProvinces();

    if (addr != null && mounted) {
      final prov = _provinces.where((p) =>
        (addr.provinceCode != null && p.code == addr.provinceCode) ||
        (addr.provinceName != null && p.name.toLowerCase() == addr.provinceName!.toLowerCase())
      ).firstOrNull;

      if (prov != null) {
        setState(() => _selectedProvince = prov);

        // Muat kabupaten untuk provinsi terpilih tanpa mereset data edit
        setState(() => _isLoadingRegencies = true);
        try {
          final regList = await widget.repository.getRegencies(prov.code);
          if (mounted) {
            setState(() {
              _regencies = regList;
              _isLoadingRegencies = false;
            });

            final reg = regList.where((r) =>
              (addr.regencyCode != null && r.code == addr.regencyCode) ||
              (addr.regencyName != null && r.name.toLowerCase() == addr.regencyName!.toLowerCase())
            ).firstOrNull;

            if (reg != null) {
              setState(() => _selectedRegency = reg);

              // Muat kecamatan untuk kabupaten terpilih
              setState(() => _isLoadingDistricts = true);
              try {
                final distList = await widget.repository.getDistricts(reg.code);
                if (mounted) {
                  setState(() {
                    _districts = distList;
                    _isLoadingDistricts = false;
                  });

                  final dist = distList.where((d) =>
                    (addr.districtCode != null && d.code == addr.districtCode) ||
                    (addr.districtName != null && d.name.toLowerCase() == addr.districtName!.toLowerCase())
                  ).firstOrNull;

                  if (dist != null) {
                    setState(() => _selectedDistrict = dist);

                    // Muat kelurahan untuk kecamatan terpilih
                    setState(() => _isLoadingVillages = true);
                    try {
                      final vilList = await widget.repository.getVillages(dist.code);
                      if (mounted) {
                        setState(() {
                          _villages = vilList;
                          _isLoadingVillages = false;
                        });

                        final vil = vilList.where((v) =>
                          (addr.villageCode != null && v.code == addr.villageCode) ||
                          (addr.villageName != null && v.name.toLowerCase() == addr.villageName!.toLowerCase())
                        ).firstOrNull;

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
    setState(() {
      _isLoadingProvinces = true;
    });
    try {
      final rows = await widget.repository.getProvinces();
      if (mounted) {
        setState(() {
          _provinces = rows;
        });
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
        setState(() {
          _isLoadingProvinces = false;
        });
      }
    }
  }

  /// Mengambil daftar kabupaten/kota berdasarkan kode provinsi
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
        setState(() {
          _regencies = rows;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRegencies = false;
        });
      }
    }
  }

  /// Mengambil daftar kecamatan berdasarkan kode kabupaten/kota
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
        setState(() {
          _districts = rows;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDistricts = false;
        });
      }
    }
  }

  /// Mengambil daftar kelurahan berdasarkan kode kecamatan
  Future<void> _fetchVillages(String districtCode) async {
    setState(() {
      _isLoadingVillages = true;
      _villages = [];
      _selectedVillage = null;
    });

    try {
      final rows = await widget.repository.getVillages(districtCode);
      if (mounted) {
        setState(() {
          _villages = rows;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVillages = false;
        });
      }
    }
  }

  /// Helper untuk membangun SearchableDropdown wilayah persis seperti pada RegisterPage
  Widget _buildRegionDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
    String? hintText,
    String? disabledHint,
    bool enabled = true,
    bool isLoading = false,
    bool isDark = false,
  }) {
    String effectiveHint;
    if (isLoading) {
      effectiveHint = 'Memuat $label...';
    } else if (!enabled) {
      effectiveHint =
          disabledHint ?? 'Pilih wilayah sebelumnya terlebih dahulu';
    } else if (items.isEmpty) {
      effectiveHint = 'Tidak ada data $label';
    } else {
      effectiveHint = hintText ?? 'Pilih $label';
    }

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

    final result = CustomerAddress(
      id: existing?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
      rawId: existing?.rawId,
      userId: existing?.userId,
      title: _titleController.text.trim(),
      receiverName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
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
      latitude: existing?.latitude,
      longitude: existing?.longitude,
      isPrimary: existing?.isPrimary ?? false,
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
    _addressController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.initialAddress != null;

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
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                    // Label / Nama Tempat
                    CustomTextField(
                      label: 'Label Alamat',
                      hintText: 'Contoh: Rumah, Kantor, Toko',
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      isRequired: true,
                      enabled: !_isSubmitting,
                      prefixIcon: const Icon(Icons.bookmark_outline_rounded),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Label alamat wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Quick Chips untuk Label
                    SizedBox(
                      height: 34,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _quickLabels.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final label = _quickLabels[index];
                          final isSelected =
                              _titleController.text.trim().toLowerCase() ==
                                  label.toLowerCase();
                          return ActionChip(
                            label: Text(label),
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight),
                            ),
                            backgroundColor: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceLight),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? Colors.white12 : Colors.black12),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 0,
                            ),
                            onPressed: () {
                              setState(() {
                                _titleController.text = label;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Nama Penerima
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

                    // Nomor Telepon / WA
                    CustomTextField(
                      label: 'Nomor WhatsApp / HP',
                      hintText: '081234567890',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      isRequired: true,
                      enabled: !_isSubmitting,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: 16),

                    // Dropdown Wilayah Berjenjang (Persis sesuai RegisterPage)
                    // 1. Dropdown Provinsi
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

                    // 2. Dropdown Kabupaten / Kota
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

                    // 3. Dropdown Kecamatan
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

                    // 4. Dropdown Kelurahan
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
                          if (v?.postalCode != null && v!.postalCode!.isNotEmpty) {
                            _postalCodeController.text = v.postalCode!;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Input Alamat Lengkap
                    CustomTextField(
                      label: 'Alamat Lengkap',
                      hintText: 'Contoh: Jl. Sudirman No. 45, RT 01/RW 02, Menteng',
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

                    // Kode Pos
                    CustomTextField(
                      label: 'Kode Pos',
                      hintText: 'Contoh: 10110',
                      controller: _postalCodeController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      enabled: !_isSubmitting,
                      prefixIcon: const Icon(Icons.local_post_office_outlined),
                    ),
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
                isEditing ? Icons.check_circle_outline_rounded : Icons.add_location_alt_outlined,
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
