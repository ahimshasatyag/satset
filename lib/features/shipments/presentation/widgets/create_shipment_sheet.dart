import 'dart:math';
import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';
import '../../data/datasources/shipment_local_datasource.dart';
import '../../data/datasources/shipment_remote_datasource.dart';
import '../../data/repositories/shipment_repository_impl.dart';
import '../../domain/entities/shipment.dart';
import 'package:satset/features/customer/order/presentation/pages/payment_page.dart';
import '../pages/create_shipment_page.dart';
import 'create_shipment_skeleton.dart';

class CreateShipmentSheet extends StatefulWidget {
  final Function(Map<String, dynamic> data)? onOrderCreated;
  final dynamic repository;

  const CreateShipmentSheet({
    super.key,
    this.onOrderCreated,
    this.repository,
  });

  /// Navigasi langsung ke halaman penuh pembuatan pengiriman [CreateShipmentPage]
  static Future<T?> show<T>(
    BuildContext context, {
    Function(Map<String, dynamic> data)? onOrderCreated,
    dynamic repository,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (_) => CreateShipmentPage(
          onOrderCreated: onOrderCreated,
          repository: repository,
        ),
      ),
    );
  }

  @override
  State<CreateShipmentSheet> createState() => _CreateShipmentSheetState();
}

class _CreateShipmentSheetState extends State<CreateShipmentSheet> {
  late final dynamic _repository;

  int _currentStep = 0; // 0: Alamat, 1: Paket & Layanan, 2: Pembayaran & Ringkasan
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Master data
  List<Province> _provinces = [];
  List<OrderServiceType> _serviceTypes = [];

  // Cascading Region: Pengirim
  Province? _senderProvince;
  List<Regency> _senderRegencies = [];
  Regency? _senderRegency;
  List<District> _senderDistricts = [];
  District? _senderDistrict;
  List<Village> _senderVillages = [];
  Village? _senderVillage;

  // Cascading Region: Penerima
  Province? _receiverProvince;
  List<Regency> _receiverRegencies = [];
  Regency? _receiverRegency;
  List<District> _receiverDistricts = [];
  District? _receiverDistrict;
  List<Village> _receiverVillages = [];
  Village? _receiverVillage;

  // Text Controllers: Pengirim
  final TextEditingController _senderNameController = TextEditingController();
  final TextEditingController _senderPhoneController = TextEditingController();
  final TextEditingController _senderAddressController = TextEditingController();
  final TextEditingController _senderPostalController = TextEditingController();

  // Text Controllers: Penerima
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController = TextEditingController();
  final TextEditingController _receiverAddressController = TextEditingController();
  final TextEditingController _receiverPostalController = TextEditingController();

  // Text Controllers: Paket
  final TextEditingController _itemDescController = TextEditingController();
  final TextEditingController _weightController = TextEditingController(text: '1000');
  final TextEditingController _lengthController = TextEditingController(text: '20');
  final TextEditingController _widthController = TextEditingController(text: '15');
  final TextEditingController _heightController = TextEditingController(text: '10');
  final TextEditingController _itemCountController = TextEditingController(text: '1');
  final TextEditingController _goodsValueController = TextEditingController(text: '0');

  // Pilihan Layanan & Pembayaran
  OrderServiceType? _selectedService;
  String _paymentMethod = 'TRANSFER'; // 'TRANSFER' or 'COD'
  String _paymentChannel = 'BCA_VA'; // 'BCA_VA', 'MANDIRI_VA', 'BRI_VA', 'QRIS', 'COD'

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ??
        ShipmentRepositoryImpl(
          remoteDataSource: ShipmentRemoteDataSourceImpl(),
          localDataSource: ShipmentLocalDataSourceImpl(),
        );
    _loadInitialData();
  }

  @override
  void dispose() {
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _senderAddressController.dispose();
    _senderPostalController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _receiverAddressController.dispose();
    _receiverPostalController.dispose();
    _itemDescController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _itemCountController.dispose();
    _goodsValueController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Future<List<Province>> provFuture =
          _repository.getProvinces() as Future<List<Province>>;
      final Future<List<OrderServiceType>> typesFuture =
          _repository.getServiceTypes() as Future<List<OrderServiceType>>;
      final Future<Map<String, dynamic>?> profileFuture =
          _repository.getCurrentUserProfile() as Future<Map<String, dynamic>?>;

      final results = await Future.wait<dynamic>([
        provFuture,
        typesFuture,
        profileFuture,
      ]);

      _provinces = results[0] as List<Province>;
      _serviceTypes = results[1] as List<OrderServiceType>;
      final userProfile = results[2] as Map<String, dynamic>?;

      if (_serviceTypes.isNotEmpty) {
        _selectedService = _serviceTypes.first;
      }

      // Prefill Pengirim dari profil pengguna
      if (userProfile != null) {
        _senderNameController.text =
            userProfile['nama_lengkap']?.toString() ?? userProfile['name']?.toString() ?? '';
        _senderPhoneController.text =
            userProfile['no_hp']?.toString() ?? userProfile['phone']?.toString() ?? '';
        _senderAddressController.text =
            userProfile['alamat_lengkap']?.toString() ?? userProfile['address']?.toString() ?? '';
      }

      // Default pilih provinsi pertama jika ada
      if (_provinces.isNotEmpty) {
        _senderProvince = _provinces.first;
        _receiverProvince = _provinces.first;
        await Future.wait([
          _onSenderProvinceSelected(_senderProvince!),
          _onReceiverProvinceSelected(_receiverProvince!),
        ]);
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat master data: $e';
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onSenderProvinceSelected(Province prov) async {
    setState(() {
      _senderProvince = prov;
      _senderRegencies = [];
      _senderRegency = null;
      _senderDistricts = [];
      _senderDistrict = null;
      _senderVillages = [];
      _senderVillage = null;
    });
    try {
      final regs = await _repository.getRegencies(prov.code);
      if (mounted) {
        setState(() {
          _senderRegencies = regs;
          if (regs.isNotEmpty) {
            _onSenderRegencySelected(regs.first);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _onSenderRegencySelected(Regency reg) async {
    setState(() {
      _senderRegency = reg;
      _senderDistricts = [];
      _senderDistrict = null;
      _senderVillages = [];
      _senderVillage = null;
    });
    try {
      final dists = await _repository.getDistricts(reg.code);
      if (mounted) {
        setState(() {
          _senderDistricts = dists;
          if (dists.isNotEmpty) {
            _onSenderDistrictSelected(dists.first);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _onSenderDistrictSelected(District dist) async {
    setState(() {
      _senderDistrict = dist;
      _senderVillages = [];
      _senderVillage = null;
    });
    try {
      final vills = await _repository.getVillages(dist.code);
      if (mounted) {
        setState(() {
          _senderVillages = vills;
          if (vills.isNotEmpty) {
            _onSenderVillageSelected(vills.first);
          }
        });
      }
    } catch (_) {}
  }

  void _onSenderVillageSelected(Village vill) {
    setState(() {
      _senderVillage = vill;
      if (vill.postalCode != null && vill.postalCode!.isNotEmpty) {
        _senderPostalController.text = vill.postalCode!;
      }
    });
  }

  Future<void> _onReceiverProvinceSelected(Province prov) async {
    setState(() {
      _receiverProvince = prov;
      _receiverRegencies = [];
      _receiverRegency = null;
      _receiverDistricts = [];
      _receiverDistrict = null;
      _receiverVillages = [];
      _receiverVillage = null;
    });
    try {
      final regs = await _repository.getRegencies(prov.code);
      if (mounted) {
        setState(() {
          _receiverRegencies = regs;
          if (regs.isNotEmpty) {
            _onReceiverRegencySelected(regs.first);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _onReceiverRegencySelected(Regency reg) async {
    setState(() {
      _receiverRegency = reg;
      _receiverDistricts = [];
      _receiverDistrict = null;
      _receiverVillages = [];
      _receiverVillage = null;
    });
    try {
      final dists = await _repository.getDistricts(reg.code);
      if (mounted) {
        setState(() {
          _receiverDistricts = dists;
          if (dists.isNotEmpty) {
            _onReceiverDistrictSelected(dists.first);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _onReceiverDistrictSelected(District dist) async {
    setState(() {
      _receiverDistrict = dist;
      _receiverVillages = [];
      _receiverVillage = null;
    });
    try {
      final vills = await _repository.getVillages(dist.code);
      if (mounted) {
        setState(() {
          _receiverVillages = vills;
          if (vills.isNotEmpty) {
            _onReceiverVillageSelected(vills.first);
          }
        });
      }
    } catch (_) {}
  }

  void _onReceiverVillageSelected(Village vill) {
    setState(() {
      _receiverVillage = vill;
      if (vill.postalCode != null && vill.postalCode!.isNotEmpty) {
        _receiverPostalController.text = vill.postalCode!;
      }
    });
  }

  // Perhitungan Biaya Realistis
  Map<String, double> _calculateCost() {
    final weightGram = int.tryParse(_weightController.text) ?? 1000;
    final lengthCm = int.tryParse(_lengthController.text) ?? 10;
    final widthCm = int.tryParse(_widthController.text) ?? 10;
    final heightCm = int.tryParse(_heightController.text) ?? 10;
    final goodsVal = double.tryParse(_goodsValueController.text) ?? 0.0;

    final actualWeightKg = weightGram / 1000.0;
    final volumetricWeightKg = (lengthCm * widthCm * heightCm) / 6000.0;
    final chargeableWeightKg = max(actualWeightKg, volumetricWeightKg);
    final billedKg = max(1, chargeableWeightKg.ceil());

    double baseRate = _selectedService?.basePrice ?? 15000;
    final shippingFee = baseRate * billedKg;
    final insuranceFee = goodsVal > 0 ? (goodsVal * 0.002).clamp(2000.0, 100000.0) : 0.0;
    const additionalFee = 1000.0;
    const discount = 0.0;
    final total = shippingFee + insuranceFee + additionalFee - discount;

    return {
      'shippingFee': shippingFee,
      'insuranceFee': insuranceFee,
      'additionalFee': additionalFee,
      'discount': discount,
      'total': total,
      'chargeableKg': chargeableWeightKg,
      'volumetricKg': volumetricWeightKg,
    };
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validasi Step 1: Alamat
      if (_senderNameController.text.trim().isEmpty ||
          _senderPhoneController.text.trim().isEmpty ||
          _senderAddressController.text.trim().isEmpty) {
        _showErrorToast('Lengkapi nama, telepon, dan alamat pengirim.');
        return;
      }
      if (_receiverNameController.text.trim().isEmpty ||
          _receiverPhoneController.text.trim().isEmpty ||
          _receiverAddressController.text.trim().isEmpty) {
        _showErrorToast('Lengkapi nama, telepon, dan alamat penerima.');
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      // Validasi Step 2: Paket
      if (_itemDescController.text.trim().isEmpty) {
        _showErrorToast('Harap masukkan deskripsi / nama barang.');
        return;
      }
      if (_selectedService == null) {
        _showErrorToast('Pilih salah satu layanan pengiriman.');
        return;
      }
      setState(() => _currentStep = 2);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final cost = _calculateCost();

    final orderPayload = {
      'pengirim_nama': _senderNameController.text.trim(),
      'pengirim_no_hp': _senderPhoneController.text.trim(),
      'pengirim_alamat': _senderAddressController.text.trim(),
      'pengirim_kota': _senderRegency?.name ?? 'Jakarta Selatan',
      'pengirim_kode_pos': _senderPostalController.text.trim(),
      'penerima_nama': _receiverNameController.text.trim(),
      'penerima_no_hp': _receiverPhoneController.text.trim(),
      'penerima_alamat': _receiverAddressController.text.trim(),
      'penerima_kota': _receiverRegency?.name ?? 'Jakarta Barat',
      'penerima_kode_pos': _receiverPostalController.text.trim(),
      'catatan_pengiriman': _itemDescController.text.trim(),
      'itemName': _itemDescController.text.trim(),
      'total_berat_gram': int.tryParse(_weightController.text) ?? 1000,
      'panjang_cm': int.tryParse(_lengthController.text) ?? 20,
      'lebar_cm': int.tryParse(_widthController.text) ?? 15,
      'tinggi_cm': int.tryParse(_heightController.text) ?? 10,
      'total_barang': int.tryParse(_itemCountController.text) ?? 1,
      'nilai_barang': double.tryParse(_goodsValueController.text) ?? 0.0,
      'service_type_id': _selectedService?.id ?? 1,
      'serviceType': _selectedService?.name ?? 'Reguler',
      'metode_pembayaran': _paymentMethod,
      'payment_channel': _paymentMethod == 'COD' ? 'COD' : _paymentChannel,
      'total_biaya': cost['total']!,
    };

    try {
      final createdOrder = await _repository.createShipmentOrder(orderPayload);

      if (mounted) {
        // Callback jika ada listener di luar
        widget.onOrderCreated?.call(orderPayload);

        // Langsung arahkan ke Halaman Pembayaran menggantikan halaman formulir
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentPage(order: createdOrder),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Gagal membuat pesanan: $e';
        });
        _showErrorToast('Gagal memproses pesanan: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const CreateShipmentSkeleton();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step Indicator Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
          ),
          child: _buildStepIndicator(isDark),
        ),

        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Form Content Scrollable
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: _buildCurrentStepContent(isDark, theme),
          ),
        ),

        // Bottom Action Buttons
        Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: _buildBottomNavigationButtons(isDark),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(bool isDark) {
    final steps = ['1. Alamat', '2. Paket', '3. Pembayaran'];
    return Row(
      children: List.generate(steps.length, (index) {
        final isCompleted = _currentStep > index;
        final isCurrent = _currentStep == index;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrent
                        ? AppColors.primary
                        : (isCompleted
                            ? AppColors.success
                            : (isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF1F5F9))),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    steps[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent || isCompleted
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isCurrent || isCompleted
                          ? Colors.white
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
                ),
              ),
              if (index < steps.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStepContent(bool isDark, ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildStep1Address(isDark, theme);
      case 1:
        return _buildStep2Package(isDark, theme);
      case 2:
      default:
        return _buildStep3PaymentSummary(isDark, theme);
    }
  }

  Widget _buildStep1Address(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SENDER SECTION CARD
        _buildFormCard(
          title: 'Alamat Pengirim (Asal)',
          subtitle: 'Lokasi dan rincian kontak penjemputan paket',
          icon: Icons.outbox_rounded,
          isDark: isDark,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Asal',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Nama Lengkap Pengirim',
                hintText: 'Nama pengirim paket',
                controller: _senderNameController,
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Nomor Telepon / WhatsApp',
                hintText: '0812xxxxxxxx',
                controller: _senderPhoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              ),
              const SizedBox(height: 12),
              _buildRegionDropdown<Province>(
                label: 'Provinsi Pengirim',
                value: _senderProvince,
                items: _provinces,
                itemLabel: (p) => p.name,
                onChanged: (p) {
                  if (p != null) _onSenderProvinceSelected(p);
                },
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildRegionDropdown<Regency>(
                label: 'Kabupaten / Kota',
                value: _senderRegency,
                items: _senderRegencies,
                itemLabel: (r) => r.name,
                onChanged: (r) {
                  if (r != null) _onSenderRegencySelected(r);
                },
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildRegionDropdown<District>(
                      label: 'Kecamatan',
                      value: _senderDistrict,
                      items: _senderDistricts,
                      itemLabel: (d) => d.name,
                      onChanged: (d) {
                        if (d != null) _onSenderDistrictSelected(d);
                      },
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: _buildRegionDropdown<Village>(
                      label: 'Kelurahan',
                      value: _senderVillage,
                      items: _senderVillages,
                      itemLabel: (v) => v.name,
                      onChanged: (v) {
                        if (v != null) _onSenderVillageSelected(v);
                      },
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      label: 'Alamat Lengkap Pengirim',
                      hintText: 'Nama jalan, nomor rumah, RT/RW, patokan',
                      controller: _senderAddressController,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Kode Pos',
                      hintText: '12xxx',
                      controller: _senderPostalController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // RECIPIENT SECTION CARD
        _buildFormCard(
          title: 'Alamat Penerima (Tujuan)',
          subtitle: 'Lokasi dan rincian kontak tujuan pengantaran',
          icon: Icons.move_to_inbox_rounded,
          isDark: isDark,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Tujuan',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Nama Lengkap Penerima',
                hintText: 'Nama penerima paket',
                controller: _receiverNameController,
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Nomor Telepon / WhatsApp',
                hintText: '0812xxxxxxxx',
                controller: _receiverPhoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              ),
              const SizedBox(height: 12),
              _buildRegionDropdown<Province>(
                label: 'Provinsi Penerima',
                value: _receiverProvince,
                items: _provinces,
                itemLabel: (p) => p.name,
                onChanged: (p) {
                  if (p != null) _onReceiverProvinceSelected(p);
                },
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildRegionDropdown<Regency>(
                label: 'Kabupaten / Kota',
                value: _receiverRegency,
                items: _receiverRegencies,
                itemLabel: (r) => r.name,
                onChanged: (r) {
                  if (r != null) _onReceiverRegencySelected(r);
                },
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildRegionDropdown<District>(
                      label: 'Kecamatan',
                      value: _receiverDistrict,
                      items: _receiverDistricts,
                      itemLabel: (d) => d.name,
                      onChanged: (d) {
                        if (d != null) _onReceiverDistrictSelected(d);
                      },
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: _buildRegionDropdown<Village>(
                      label: 'Kelurahan',
                      value: _receiverVillage,
                      items: _receiverVillages,
                      itemLabel: (v) => v.name,
                      onChanged: (v) {
                        if (v != null) _onReceiverVillageSelected(v);
                      },
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      label: 'Alamat Lengkap Penerima',
                      hintText: 'Nama jalan, gedung, nomor rumah, RT/RW',
                      controller: _receiverAddressController,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Kode Pos',
                      hintText: '14xxx',
                      controller: _receiverPostalController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Package(bool isDark, ThemeData theme) {
    final cost = _calculateCost();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // INFORMASI BARANG & PAKET CARD
        _buildFormCard(
          title: 'Informasi Barang & Paket',
          subtitle: 'Rincian deskripsi, berat, dan dimensi fisik paket',
          icon: Icons.inventory_2_outlined,
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Deskripsi / Nama Barang',
                hintText: 'Contoh: Pakaian, Dokumen, Makanan Kering, Aksesoris',
                controller: _itemDescController,
                prefixIcon: const Icon(Icons.description_outlined, size: 20),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Berat Total (Gram)',
                      hintText: '1000',
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.scale_rounded, size: 20),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      label: 'Jumlah Paket (Pcs)',
                      hintText: '1',
                      controller: _itemCountController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.layers_outlined, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Dimensi Paket (Panjang x Lebar x Tinggi)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'P (cm)',
                      hintText: '20',
                      controller: _lengthController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomTextField(
                      label: 'L (cm)',
                      hintText: '15',
                      controller: _widthController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomTextField(
                      label: 'T (cm)',
                      hintText: '10',
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Berat Volumetrik: ${cost['volumetricKg']!.toStringAsFixed(2)} kg (dibulatkan: ${cost['chargeableKg']!.ceil()} kg)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                label: 'Nilai Barang / Proteksi Asuransi (Rp)',
                hintText: '0 (Opsional)',
                controller: _goodsValueController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.shield_outlined, size: 20),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),

        // PILIHAN LAYANAN CARD
        _buildFormCard(
          title: 'Pilihan Jenis Layanan',
          subtitle: 'Pilih layanan pengiriman sesuai durasi dan tarif',
          icon: Icons.local_shipping_outlined,
          isDark: isDark,
          child: Column(
            children: _serviceTypes.map((service) {
              final isSelected = _selectedService?.id == service.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedService = service),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : (isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? AppColors.primary : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.primary : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Estimasi Tiba: ${service.estimationLabel}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rp ${(service.basePrice).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}/kg',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3PaymentSummary(bool isDark, ThemeData theme) {
    final cost = _calculateCost();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // METODE PEMBAYARAN CARD
        _buildFormCard(
          title: 'Metode Pembayaran',
          subtitle: 'Pilih transfer gateway atau bayar di tempat (COD)',
          icon: Icons.payment_rounded,
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentMethodCard(
                      label: 'Transfer Gateway',
                      icon: Icons.account_balance_wallet_outlined,
                      method: 'TRANSFER',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPaymentMethodCard(
                      label: 'Cash on Delivery',
                      icon: Icons.payments_outlined,
                      method: 'COD',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              if (_paymentMethod == 'TRANSFER') ...[
                const SizedBox(height: 16),
                const Text(
                  'Pilih Saluran Pembayaran Transfer:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChannelChip('BCA Virtual Account', 'BCA_VA'),
                    _buildChannelChip('Mandiri VA', 'MANDIRI_VA'),
                    _buildChannelChip('BRI VA', 'BRI_VA'),
                    _buildChannelChip('QRIS Instan', 'QRIS'),
                  ],
                ),
              ],
            ],
          ),
        ),

        // RINGKASAN RINCIAN BIAYA CARD
        _buildFormCard(
          title: 'Ringkasan Rincian Biaya Pengiriman',
          subtitle: 'Rincian ongkos kirim dan total yang harus dibayar',
          icon: Icons.receipt_long_rounded,
          isDark: isDark,
          child: Column(
            children: [
              _buildSummaryLine('Asal', _senderRegency?.name ?? 'Jakarta Selatan', isDark),
              _buildSummaryLine('Tujuan', _receiverRegency?.name ?? 'Bandung', isDark),
              _buildSummaryLine('Layanan', _selectedService?.name ?? 'Reguler', isDark),
              _buildSummaryLine(
                'Berat Ditagih',
                '${cost['chargeableKg']!.ceil()} kg (${_weightController.text} gr)',
                isDark,
              ),
              const Divider(height: 20),
              _buildSummaryLine(
                'Biaya Pengiriman',
                'Rp ${cost['shippingFee']!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                isDark,
              ),
              if (cost['insuranceFee']! > 0)
                _buildSummaryLine(
                  'Asuransi Barang',
                  'Rp ${cost['insuranceFee']!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                  isDark,
                ),
              _buildSummaryLine(
                'Biaya Layanan Tambahan',
                'Rp ${cost['additionalFee']!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                isDark,
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Rp ${cost['total']!.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryLine(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String label,
    required IconData icon,
    required String method,
    required bool isDark,
  }) {
    final isSelected = _paymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelChip(String label, String channelCode) {
    final isSelected = _paymentChannel == channelCode;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      onSelected: (val) {
        if (val) setState(() => _paymentChannel = channelCode);
      },
    );
  }

  Widget _buildBottomNavigationButtons(bool isDark) {
    return Row(
      children: [
        if (_currentStep > 0) ...[
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : _prevStep,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Kembali'),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : (_currentStep == 2 ? _submitOrder : _nextStep),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _currentStep == 2 ? 'Buat Pesanan & Bayar' : 'Lanjut',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _currentStep == 2
                            ? Icons.check_circle_outline_rounded
                            : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required Widget child,
    required bool isDark,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRegionDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              value: items.contains(value) ? value : null,
              hint: Text(
                'Pilih $label',
                style: const TextStyle(fontSize: 12),
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
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
