import 'dart:math';

import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/features/customer/order/presentation/pages/payment_page.dart';

import '../../data/datasources/shipment_local_datasource.dart';
import '../../data/datasources/shipment_remote_datasource.dart';
import '../../data/repositories/shipment_repository_impl.dart';
import '../../domain/entities/shipment.dart';
import '../pages/create_shipment_page.dart';

import 'package:satset/shared/utils/utils.dart';

import 'package:latlong2/latlong.dart';

import 'components/shipment_address_step.dart';
import 'components/shipment_package_step.dart';
import 'components/shipment_payment_step.dart';
import 'location_picker_map_dialog.dart';

class CreateShipmentSheet extends StatefulWidget {
  final Function(Map<String, dynamic> data)? onOrderCreated;
  final dynamic repository;

  const CreateShipmentSheet({super.key, this.onOrderCreated, this.repository});

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

  int _currentStep =
      0; // 0: Alamat, 1: Paket & Layanan, 2: Pembayaran & Ringkasan
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

  // Status loading bertingkat (cascading)
  bool _isLoadingSenderRegencies = false;
  bool _isLoadingSenderDistricts = false;
  bool _isLoadingSenderVillages = false;
  bool _isLoadingReceiverRegencies = false;
  bool _isLoadingReceiverDistricts = false;
  bool _isLoadingReceiverVillages = false;

  // Data Profil Pengguna (m_users) & Switch Alamat Utama
  Map<String, dynamic>? _userProfile;
  bool _useMainAddress = false;
  bool _isLoadingMainAddress = false;

  // Text Controllers: Pengirim
  final TextEditingController _senderNameController = TextEditingController();
  final TextEditingController _senderPhoneController = TextEditingController();
  final TextEditingController _senderAddressController =
      TextEditingController();
  final TextEditingController _senderPostalController = TextEditingController();

  // Text Controllers: Penerima
  final TextEditingController _receiverNameController = TextEditingController();
  final TextEditingController _receiverPhoneController =
      TextEditingController();
  final TextEditingController _receiverAddressController =
      TextEditingController();
  final TextEditingController _receiverPostalController =
      TextEditingController();

  // Koordinat GPS Titik Lokasi Peta (t_shipments)
  double? _senderLatitude;
  double? _senderLongitude;
  double? _receiverLatitude;
  double? _receiverLongitude;

  // Text Controllers: Paket
  final TextEditingController _itemDescController = TextEditingController();
  final TextEditingController _weightController = TextEditingController(
    text: '1000',
  );
  final TextEditingController _lengthController = TextEditingController(
    text: '20',
  );
  final TextEditingController _widthController = TextEditingController(
    text: '15',
  );
  final TextEditingController _heightController = TextEditingController(
    text: '10',
  );
  final TextEditingController _itemCountController = TextEditingController(
    text: '1',
  );
  final TextEditingController _goodsValueController = TextEditingController(
    text: '15.000',
  );

  // Proteksi Asuransi & Pilihan Layanan & Pembayaran
  bool _useInsurance = false;
  OrderServiceType? _selectedService;
  String _paymentMethod = 'TRANSFER'; // 'TRANSFER' or 'COD'
  String _paymentChannel = 'BCA';
  List<BankAccount> _banks = [];
  BankAccount? _selectedBank;

  // Perhitungan otomatis nilai/harga asli barang dari berat aktual & volumetrik (P x L x T)
  double _calculateAutoGoodsValue() {
    final weightGram = int.tryParse(_weightController.text) ?? 1000;
    final lengthCm = int.tryParse(_lengthController.text) ?? 20;
    final widthCm = int.tryParse(_widthController.text) ?? 15;
    final heightCm = int.tryParse(_heightController.text) ?? 10;

    final actualWeightKg = weightGram / 1000.0;
    final volumetricWeightKg = (lengthCm * widthCm * heightCm) / 6000.0;
    final chargeableWeightKg = max(actualWeightKg, volumetricWeightKg);
    final billedKg = max(1.0, chargeableWeightKg.ceilToDouble());

    final baseRate = _selectedService?.basePrice ?? 15000.0;
    return billedKg * baseRate;
  }

  void _syncAutoGoodsValueIfNeeded() {
    final autoVal = _calculateAutoGoodsValue();
    _goodsValueController.text = CurrencyFormatter.formatNominal(autoVal);
  }

  @override
  void initState() {
    super.initState();
    _syncAutoGoodsValueIfNeeded();
    _repository =
        widget.repository ??
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
      final Future<List<BankAccount>> banksFuture =
          _repository.getBanks() as Future<List<BankAccount>>;

      final results = await Future.wait<dynamic>([
        provFuture,
        typesFuture,
        profileFuture,
        banksFuture,
      ]);

      _provinces = results[0] as List<Province>;
      _serviceTypes = results[1] as List<OrderServiceType>;
      _userProfile = results[2] as Map<String, dynamic>?;
      _banks = results[3] as List<BankAccount>;

      if (_banks.isNotEmpty) {
        _selectedBank = _banks.first;
        _paymentChannel = _selectedBank!.bankName;
      }

      if (_serviceTypes.isNotEmpty) {
        _selectedService = _serviceTypes.first;
        _syncAutoGoodsValueIfNeeded();
      }

      // Prefill Nama & No Telepon Pengirim dari profil m_users jika ada
      if (_userProfile != null) {
        if (_senderNameController.text.isEmpty) {
          _senderNameController.text =
              _userProfile!['nama_lengkap']?.toString() ??
              _userProfile!['name']?.toString() ??
              '';
        }
        if (_senderPhoneController.text.isEmpty) {
          _senderPhoneController.text =
              _userProfile!['no_hp']?.toString() ??
              _userProfile!['phone']?.toString() ??
              '';
        }
      }

      // Pastikan dropdown wilayah tidak otomatis terpilih (tetap null sampai dipilih pengguna / diaktifkan Alamat Utama)
      _senderProvince = null;
      _receiverProvince = null;
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
      _isLoadingSenderRegencies = true;
    });
    if (_useMainAddress) {
      _saveSenderAddressToUsersDatabase();
    }
    try {
      final regs = await _repository.getRegencies(prov.code);
      if (mounted) {
        setState(() {
          _senderRegencies = regs;
          _isLoadingSenderRegencies = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSenderRegencies = false);
      }
    }
  }

  Future<void> _onSenderRegencySelected(Regency reg) async {
    setState(() {
      _senderRegency = reg;
      _senderDistricts = [];
      _senderDistrict = null;
      _senderVillages = [];
      _senderVillage = null;
      _isLoadingSenderDistricts = true;
    });
    if (_useMainAddress) {
      _saveSenderAddressToUsersDatabase();
    }
    try {
      final dists = await _repository.getDistricts(reg.code);
      if (mounted) {
        setState(() {
          _senderDistricts = dists;
          _isLoadingSenderDistricts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSenderDistricts = false);
      }
    }
  }

  Future<void> _onSenderDistrictSelected(District dist) async {
    setState(() {
      _senderDistrict = dist;
      _senderVillages = [];
      _senderVillage = null;
      _isLoadingSenderVillages = true;
    });
    if (_useMainAddress) {
      _saveSenderAddressToUsersDatabase();
    }
    try {
      final vills = await _repository.getVillages(dist.code);
      if (mounted) {
        setState(() {
          _senderVillages = vills;
          _isLoadingSenderVillages = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSenderVillages = false);
      }
    }
  }

  void _onSenderVillageSelected(Village vill) {
    setState(() {
      _senderVillage = vill;
      if (vill.postalCode != null && vill.postalCode!.isNotEmpty) {
        _senderPostalController.text = vill.postalCode!;
      }
    });
    if (_useMainAddress) {
      _saveSenderAddressToUsersDatabase();
    }
  }

  /// Menyimpan alamat pengirim ke database tabel m_users jika switch aktif
  Future<void> _saveSenderAddressToUsersDatabase({bool showToast = false}) async {
    if (!_useMainAddress) return;

    try {
      final nama = _senderNameController.text.trim();
      final noHp = _senderPhoneController.text.trim();
      final alamat = _senderAddressController.text.trim();
      final provCode = _senderProvince?.code.trim();
      final kabkotCode = _senderRegency?.code.trim();
      final kecCode = _senderDistrict?.code.trim();
      final kelCode = _senderVillage?.code.trim();

      await _repository.updateUserMainAddress(
        namaLengkap: nama.isNotEmpty ? nama : null,
        noHp: noHp.isNotEmpty ? noHp : null,
        alamatLengkap: alamat.isNotEmpty ? alamat : null,
        latitude: _senderLatitude,
        longitude: _senderLongitude,
        idProvinsi: provCode,
        idKabkot: kabkotCode,
        idKecamatan: kecCode,
        idKelurahan: kelCode,
      );

      // Perbarui cache lokal _userProfile di memori
      _userProfile ??= {};
      if (nama.isNotEmpty) _userProfile!['nama_lengkap'] = nama;
      if (noHp.isNotEmpty) _userProfile!['no_hp'] = noHp;
      if (alamat.isNotEmpty) _userProfile!['alamat_lengkap'] = alamat;
      if (_senderLatitude != null) _userProfile!['latitude'] = _senderLatitude;
      if (_senderLongitude != null) _userProfile!['longitude'] = _senderLongitude;
      if (provCode != null) _userProfile!['id_provinsi'] = provCode;
      if (kabkotCode != null) _userProfile!['id_kabkot'] = kabkotCode;
      if (kecCode != null) _userProfile!['id_kecamatan'] = kecCode;
      if (kelCode != null) _userProfile!['id_kelurahan'] = kelCode;

      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alamat berhasil tersimpan.',
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Peringatan: Gagal menyimpan alamat ke m_users: $e');
    }
  }

  /// Handler toggle switch "Tambah / Gunakan Alamat Utama" (m_users)
  Future<void> _onToggleUseMainAddress(bool value) async {
    setState(() {
      _useMainAddress = value;
    });

    if (!value) {
      // Jika switch dimatikan, kosongkan bagian alamat pengirim agar bisa diisi manual
      setState(() {
        _senderProvince = null;
        _senderRegency = null;
        _senderDistrict = null;
        _senderVillage = null;
        _senderRegencies = [];
        _senderDistricts = [];
        _senderVillages = [];
        _senderAddressController.clear();
        _senderPostalController.clear();
        _senderLatitude = null;
        _senderLongitude = null;
      });
      return;
    }

    // Jika form saat ini sudah diisi oleh pengguna, simpan langsung ke database m_users
    final formHasData = _senderProvince != null ||
        _senderAddressController.text.trim().isNotEmpty ||
        _senderLatitude != null;

    if (formHasData) {
      await _saveSenderAddressToUsersDatabase(showToast: true);
      return;
    }

    // Jika form belum diisi, isi otomatis dari database Supabase tabel m_users
    setState(() {
      _isLoadingMainAddress = true;
    });

    try {
      _userProfile ??= await _repository.getCurrentUserProfile();

      final profile = _userProfile;
      if (profile == null) {
        if (mounted) {
          _showErrorToast('Data profil pengguna tidak ditemukan di tabel m_users.');
          setState(() {
            _useMainAddress = false;
            _isLoadingMainAddress = false;
          });
        }
        return;
      }

      // 1. Isi Nama Lengkap & No HP Pengirim
      final nama = profile['nama_lengkap']?.toString() ?? profile['name']?.toString();
      final phone = profile['no_hp']?.toString() ?? profile['phone']?.toString();
      if (nama != null && nama.isNotEmpty) {
        _senderNameController.text = nama;
      }
      if (phone != null && phone.isNotEmpty) {
        _senderPhoneController.text = phone;
      }

      // 2. Isi Alamat Lengkap
      final alamat = profile['alamat_lengkap']?.toString() ?? profile['address']?.toString();
      if (alamat != null && alamat.isNotEmpty) {
        _senderAddressController.text = alamat;
      }

      // 3. Isi Titik Lokasi Pengiriman (latitude & longitude)
      final latRaw = profile['latitude'];
      final lngRaw = profile['longitude'];
      if (latRaw != null && lngRaw != null) {
        final lat = double.tryParse(latRaw.toString());
        final lng = double.tryParse(lngRaw.toString());
        if (lat != null && lng != null && (lat != 0.0 || lng != 0.0)) {
          _senderLatitude = lat;
          _senderLongitude = lng;
        }
      }

      // 4. Kolom relasi wilayah m_users: id_provinsi, id_kabkot, id_kecamatan, id_kelurahan
      final idProvinsi = profile['id_provinsi']?.toString().trim();
      final idKabkot = profile['id_kabkot']?.toString().trim();
      final idKecamatan = profile['id_kecamatan']?.toString().trim();
      final idKelurahan = profile['id_kelurahan']?.toString().trim();

      // Pastikan master data provinsi tersedia
      if (_provinces.isEmpty) {
        _provinces = await _repository.getProvinces();
      }

      Province? matchedProv;
      if (idProvinsi != null && idProvinsi.isNotEmpty) {
        for (final p in _provinces) {
          if (p.code.trim() == idProvinsi ||
              p.code.replaceAll('.', '') == idProvinsi.replaceAll('.', '')) {
            matchedProv = p;
            break;
          }
        }
      }

      if (matchedProv != null) {
        _senderProvince = matchedProv;
        _isLoadingSenderRegencies = true;
        if (mounted) setState(() {});

        final regencies = await _repository.getRegencies(matchedProv.code);
        _senderRegencies = regencies;
        _isLoadingSenderRegencies = false;

        Regency? matchedReg;
        if (idKabkot != null && idKabkot.isNotEmpty) {
          for (final r in regencies) {
            if (r.code.trim() == idKabkot ||
                r.code.replaceAll('.', '') == idKabkot.replaceAll('.', '')) {
              matchedReg = r;
              break;
            }
          }
        }

        if (matchedReg != null) {
          _senderRegency = matchedReg;
          _isLoadingSenderDistricts = true;
          if (mounted) setState(() {});

          final districts = await _repository.getDistricts(matchedReg.code);
          _senderDistricts = districts;
          _isLoadingSenderDistricts = false;

          District? matchedDist;
          if (idKecamatan != null && idKecamatan.isNotEmpty) {
            for (final d in districts) {
              if (d.code.trim() == idKecamatan ||
                  d.code.replaceAll('.', '') == idKecamatan.replaceAll('.', '')) {
                matchedDist = d;
                break;
              }
            }
          }

          if (matchedDist != null) {
            _senderDistrict = matchedDist;
            _isLoadingSenderVillages = true;
            if (mounted) setState(() {});

            final villages = await _repository.getVillages(matchedDist.code);
            _senderVillages = villages;
            _isLoadingSenderVillages = false;

            Village? matchedVill;
            if (idKelurahan != null && idKelurahan.isNotEmpty) {
              for (final v in villages) {
                if (v.code.trim() == idKelurahan ||
                    v.code.replaceAll('.', '') == idKelurahan.replaceAll('.', '')) {
                  matchedVill = v;
                  break;
                }
              }
            }

            if (matchedVill != null) {
              _senderVillage = matchedVill;
              if (matchedVill.postalCode != null &&
                  matchedVill.postalCode!.isNotEmpty) {
                _senderPostalController.text = matchedVill.postalCode!;
              }
            }
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Alamat berhasil dimuat.'),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorToast('Gagal memuat alamat: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMainAddress = false;
          _isLoadingSenderRegencies = false;
          _isLoadingSenderDistricts = false;
          _isLoadingSenderVillages = false;
        });
      }
    }
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
      _isLoadingReceiverRegencies = true;
    });
    try {
      final regs = await _repository.getRegencies(prov.code);
      if (mounted) {
        setState(() {
          _receiverRegencies = regs;
          _isLoadingReceiverRegencies = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingReceiverRegencies = false);
      }
    }
  }

  Future<void> _onReceiverRegencySelected(Regency reg) async {
    setState(() {
      _receiverRegency = reg;
      _receiverDistricts = [];
      _receiverDistrict = null;
      _receiverVillages = [];
      _receiverVillage = null;
      _isLoadingReceiverDistricts = true;
    });
    try {
      final dists = await _repository.getDistricts(reg.code);
      if (mounted) {
        setState(() {
          _receiverDistricts = dists;
          _isLoadingReceiverDistricts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingReceiverDistricts = false);
      }
    }
  }

  Future<void> _onReceiverDistrictSelected(District dist) async {
    setState(() {
      _receiverDistrict = dist;
      _receiverVillages = [];
      _receiverVillage = null;
      _isLoadingReceiverVillages = true;
    });
    try {
      final vills = await _repository.getVillages(dist.code);
      if (mounted) {
        setState(() {
          _receiverVillages = vills;
          _isLoadingReceiverVillages = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingReceiverVillages = false);
      }
    }
  }

  void _onReceiverVillageSelected(Village vill) {
    setState(() {
      _receiverVillage = vill;
      if (vill.postalCode != null && vill.postalCode!.isNotEmpty) {
        _receiverPostalController.text = vill.postalCode!;
      }
    });
  }

  /// Membuka peta interaktif untuk menentukan titik koordinat GPS pengirim
  Future<void> _pickSenderLocation() async {
    final result = await LocationPickerMapDialog.show(
      context,
      title: 'Pilih Titik Lokasi Pengirim (GPS)',
      initialLocation: (_senderLatitude != null && _senderLongitude != null)
          ? LatLng(_senderLatitude!, _senderLongitude!)
          : null,
      initialCityName: _senderRegency?.name ?? _senderProvince?.name,
    );

    if (result != null) {
      setState(() {
        _senderLatitude = result.latitude;
        _senderLongitude = result.longitude;
      });
      if (_useMainAddress) {
        _saveSenderAddressToUsersDatabase(showToast: true);
      }
    }
  }

  /// Membuka peta interaktif untuk menentukan titik koordinat GPS penerima
  Future<void> _pickReceiverLocation() async {
    final result = await LocationPickerMapDialog.show(
      context,
      title: 'Pilih Titik Lokasi Penerima (GPS)',
      initialLocation: (_receiverLatitude != null && _receiverLongitude != null)
          ? LatLng(_receiverLatitude!, _receiverLongitude!)
          : null,
      initialCityName: _receiverRegency?.name ?? _receiverProvince?.name,
    );

    if (result != null) {
      setState(() {
        _receiverLatitude = result.latitude;
        _receiverLongitude = result.longitude;
      });
    }
  }

  // Perhitungan Biaya Realistis Sesuai Rumus Ekspedisi
  Map<String, double> _calculateCost() {
    final weightGram = int.tryParse(_weightController.text) ?? 1000;
    final lengthCm = int.tryParse(_lengthController.text) ?? 20;
    final widthCm = int.tryParse(_widthController.text) ?? 15;
    final heightCm = int.tryParse(_heightController.text) ?? 10;

    // 1. Berat Aktual (kg)
    final actualWeightKg = weightGram / 1000.0;

    // 2. Berat Volumetrik: (P x L x T) / 6000 kg (sesuai standar ekspedisi)
    final volumetricWeightKg = (lengthCm * widthCm * heightCm) / 6000.0;

    // 3. Prinsip Kurir: Mengambil nilai terbesar antara berat aktual dan volumetrik
    final chargeableWeightKg = max(actualWeightKg, volumetricWeightKg);

    // 4. Pembulatan berat ditagih (minimal 1 kg)
    final billedKg = max(1.0, chargeableWeightKg.ceilToDouble());

    final baseRate = _selectedService?.basePrice ?? 15000.0;
    final shippingFee = baseRate * billedKg;

    // Nilai otomatis barang dari berat & dimensi volumetrik: billedKg * baseRate
    final goodsVal = billedKg * baseRate;
    final autoGoodsVal = goodsVal;

    // Tarif persen premi ekspedisi yang digunakan
    final insuranceRate = _selectedService?.insuranceRate ?? 0.002;
    // Nominal premi asuransi otomatis dari rumus: nilai barang x tarif premi
    final calculatedInsuranceFee = (goodsVal * insuranceRate).roundToDouble();
    // Biaya proteksi asuransi yang aktif ditagihkan (0 jika tanpa asuransi)
    final insuranceFee = (_useInsurance && goodsVal > 0)
        ? calculatedInsuranceFee
        : 0.0;

    const additionalFee = 1000.0;
    const discount = 0.0;
    final total = shippingFee + insuranceFee + additionalFee - discount;

    return {
      'actualKg': actualWeightKg,
      'volumetricKg': volumetricWeightKg,
      'chargeableKg': chargeableWeightKg,
      'billedKg': billedKg,
      'baseRate': baseRate,
      'shippingFee': shippingFee,
      'insuranceFee': insuranceFee,
      'calculatedInsuranceFee': calculatedInsuranceFee,
      'additionalFee': additionalFee,
      'discount': discount,
      'total': total,
      'goodsValue': goodsVal,
      'autoGoodsValue': autoGoodsVal,
      'insuranceRate': insuranceRate,
    };
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Tunggu jika cascading wilayah masih dalam proses pemanggilan jaringan
      if (_isLoadingSenderRegencies ||
          _isLoadingSenderDistricts ||
          _isLoadingSenderVillages ||
          _isLoadingReceiverRegencies ||
          _isLoadingReceiverDistricts ||
          _isLoadingReceiverVillages) {
        _showErrorToast('Sedang memuat data wilayah, harap tunggu sebentar...');
        return;
      }

      // Validasi Step 1: Alamat Pengirim & Penerima
      if (_senderNameController.text.trim().isEmpty ||
          _senderPhoneController.text.trim().isEmpty ||
          _senderAddressController.text.trim().isEmpty) {
        _showErrorToast('Lengkapi nama, telepon, dan alamat pengirim.');
        return;
      }
      if ((_provinces.isNotEmpty && _senderProvince == null) ||
          (_senderRegencies.isNotEmpty && _senderRegency == null) ||
          (_senderDistricts.isNotEmpty && _senderDistrict == null) ||
          (_senderVillages.isNotEmpty && _senderVillage == null)) {
        _showErrorToast(
          'Harap lengkapi pilihan wilayah pengirim yang tersedia.',
        );
        return;
      }
      if (_receiverNameController.text.trim().isEmpty ||
          _receiverPhoneController.text.trim().isEmpty ||
          _receiverAddressController.text.trim().isEmpty) {
        _showErrorToast('Lengkapi nama, telepon, dan alamat penerima.');
        return;
      }
      if ((_provinces.isNotEmpty && _receiverProvince == null) ||
          (_receiverRegencies.isNotEmpty && _receiverRegency == null) ||
          (_receiverDistricts.isNotEmpty && _receiverDistrict == null) ||
          (_receiverVillages.isNotEmpty && _receiverVillage == null)) {
        _showErrorToast(
          'Harap lengkapi pilihan wilayah penerima yang tersedia.',
        );
        return;
      }
      if (_useMainAddress) {
        _saveSenderAddressToUsersDatabase(showToast: true);
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
      // Pastikan nilai/harga asli barang selalu valid dan terisi otomatis jika kosong
      final rawVal = CurrencyFormatter.parseNominal(_goodsValueController.text);
      if (rawVal <= 0) {
        _syncAutoGoodsValueIfNeeded();
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

    final senderCity =
        (_senderRegency?.name != null && _senderRegency!.name.isNotEmpty)
        ? _senderRegency!.name
        : ((_senderProvince?.name != null && _senderProvince!.name.isNotEmpty)
              ? _senderProvince!.name
              : '');
    final receiverCity =
        (_receiverRegency?.name != null && _receiverRegency!.name.isNotEmpty)
        ? _receiverRegency!.name
        : ((_receiverProvince?.name != null &&
                  _receiverProvince!.name.isNotEmpty)
              ? _receiverProvince!.name
              : '');

    final senderPostal = _senderPostalController.text.trim().isNotEmpty
        ? _senderPostalController.text.trim()
        : (_senderVillage?.postalCode ?? '');
    final receiverPostal = _receiverPostalController.text.trim().isNotEmpty
        ? _receiverPostalController.text.trim()
        : (_receiverVillage?.postalCode ?? '');

    final orderPayload = {
      'pengirim_nama': _senderNameController.text.trim(),
      'pengirim_no_hp': _senderPhoneController.text.trim(),
      'pengirim_alamat': _senderAddressController.text.trim(),
      'pengirim_kota': senderCity,
      'pengirim_kode_pos': senderPostal,
      'pengirim_latitude': _senderLatitude,
      'pengirim_longitude': _senderLongitude,
      'penerima_nama': _receiverNameController.text.trim(),
      'penerima_no_hp': _receiverPhoneController.text.trim(),
      'penerima_alamat': _receiverAddressController.text.trim(),
      'penerima_kota': receiverCity,
      'penerima_kode_pos': receiverPostal,
      'penerima_latitude': _receiverLatitude,
      'penerima_longitude': _receiverLongitude,
      'catatan_pengiriman': _itemDescController.text.trim(),
      'itemName': _itemDescController.text.trim(),
      'total_berat_gram': int.tryParse(_weightController.text) ?? 1000,
      'panjang_cm': int.tryParse(_lengthController.text) ?? 20,
      'lebar_cm': int.tryParse(_widthController.text) ?? 15,
      'tinggi_cm': int.tryParse(_heightController.text) ?? 10,
      'total_barang': int.tryParse(_itemCountController.text) ?? 1,
      'nilai_barang':
          cost['goodsValue'] ??
          CurrencyFormatter.parseNominal(_goodsValueController.text),
      'is_insured': _useInsurance,
      'use_insurance': _useInsurance,
      'biaya_asuransi': cost['insuranceFee']!,
      'tarif_asuransi': _selectedService?.insuranceRate ?? 0.002,
      'tarif_asuransi_persen': (_selectedService?.insuranceRate ?? 0.002) * 100,
      'service_type_id': _selectedService?.id ?? 1,
      'serviceType': _selectedService?.name ?? 'Reguler',
      'metode_pembayaran': _paymentMethod,
      'payment_channel': _paymentMethod == 'COD'
          ? 'COD'
          : (_selectedBank?.bankName ?? _paymentChannel),
      'selected_bank': _selectedBank,
      'bank_name': _selectedBank?.bankName,
      'nomor_rekening': _selectedBank?.nomorRekening,
      'nama_pemilik': _selectedBank?.namaPemilik,
      'jenis_bank_id': _selectedBank?.jenisBankId,
      'biaya_pengiriman': cost['shippingFee']!,
      'biaya_layanan_tambahan': cost['additionalFee']!,
      'total_biaya': cost['total']!,
    };

    try {
      if (_useMainAddress) {
        await _saveSenderAddressToUsersDatabase();
      }
      final createdOrder = await _repository.createShipmentOrder(orderPayload);

      if (mounted) {
        // Callback jika ada listener di luar
        widget.onOrderCreated?.call(orderPayload);

        // Langsung arahkan ke Halaman Pembayaran menggantikan halaman formulir
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => PaymentPage(order: createdOrder)),
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
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error,
                    ),
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
            child: _buildCurrentStepContent(isDark),
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
          child: _buildBottomNavigationButtons(),
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
                              : (isDark
                                    ? const Color(0xFF1B2A3D)
                                    : const Color(0xFFF1F5F9))),
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

  Widget _buildCurrentStepContent(bool isDark) {
    final cost = _calculateCost();

    switch (_currentStep) {
      case 0:
        return ShipmentAddressStep(
          isDark: isDark,
          useMainAddress: _useMainAddress,
          onToggleUseMainAddress: _onToggleUseMainAddress,
          isLoadingMainAddress: _isLoadingMainAddress,
          senderNameController: _senderNameController,
          senderPhoneController: _senderPhoneController,
          senderAddressController: _senderAddressController,
          senderPostalController: _senderPostalController,
          receiverNameController: _receiverNameController,
          receiverPhoneController: _receiverPhoneController,
          receiverAddressController: _receiverAddressController,
          receiverPostalController: _receiverPostalController,
          provinces: _provinces,
          senderProvince: _senderProvince,
          senderRegencies: _senderRegencies,
          senderRegency: _senderRegency,
          senderDistricts: _senderDistricts,
          senderDistrict: _senderDistrict,
          senderVillages: _senderVillages,
          senderVillage: _senderVillage,
          isLoadingSenderRegencies: _isLoadingSenderRegencies,
          isLoadingSenderDistricts: _isLoadingSenderDistricts,
          isLoadingSenderVillages: _isLoadingSenderVillages,
          onSenderProvinceSelected: _onSenderProvinceSelected,
          onSenderRegencySelected: _onSenderRegencySelected,
          onSenderDistrictSelected: _onSenderDistrictSelected,
          onSenderVillageSelected: _onSenderVillageSelected,
          receiverProvince: _receiverProvince,
          receiverRegencies: _receiverRegencies,
          receiverRegency: _receiverRegency,
          receiverDistricts: _receiverDistricts,
          receiverDistrict: _receiverDistrict,
          receiverVillages: _receiverVillages,
          receiverVillage: _receiverVillage,
          isLoadingReceiverRegencies: _isLoadingReceiverRegencies,
          isLoadingReceiverDistricts: _isLoadingReceiverDistricts,
          isLoadingReceiverVillages: _isLoadingReceiverVillages,
          onReceiverProvinceSelected: _onReceiverProvinceSelected,
          onReceiverRegencySelected: _onReceiverRegencySelected,
          onReceiverDistrictSelected: _onReceiverDistrictSelected,
          onReceiverVillageSelected: _onReceiverVillageSelected,
          senderLatitude: _senderLatitude,
          senderLongitude: _senderLongitude,
          onPickSenderLocation: _pickSenderLocation,
          receiverLatitude: _receiverLatitude,
          receiverLongitude: _receiverLongitude,
          onPickReceiverLocation: _pickReceiverLocation,
        );
      case 1:
        return ShipmentPackageStep(
          isDark: isDark,
          itemDescController: _itemDescController,
          weightController: _weightController,
          lengthController: _lengthController,
          widthController: _widthController,
          heightController: _heightController,
          itemCountController: _itemCountController,
          serviceTypes: _serviceTypes,
          selectedService: _selectedService,
          useInsurance: _useInsurance,
          cost: cost,
          onServiceSelected: (service) {
            setState(() {
              _selectedService = service;
              _syncAutoGoodsValueIfNeeded();
            });
          },
          onInsuranceChanged: (val) {
            setState(() {
              _useInsurance = val;
              if (_useInsurance) {
                _syncAutoGoodsValueIfNeeded();
              }
            });
          },
          onPackageDimensionsChanged: () {
            _syncAutoGoodsValueIfNeeded();
            setState(() {});
          },
        );
      case 2:
      default:
        final senderCity =
            (_senderRegency?.name != null && _senderRegency!.name.isNotEmpty)
            ? _senderRegency!.name
            : ((_senderProvince?.name != null &&
                      _senderProvince!.name.isNotEmpty)
                  ? _senderProvince!.name
                  : '-');
        final receiverCity =
            (_receiverRegency?.name != null &&
                _receiverRegency!.name.isNotEmpty)
            ? _receiverRegency!.name
            : ((_receiverProvince?.name != null &&
                      _receiverProvince!.name.isNotEmpty)
                  ? _receiverProvince!.name
                  : '-');

        return ShipmentPaymentStep(
          isDark: isDark,
          paymentMethod: _paymentMethod,
          paymentChannel: _paymentChannel,
          onPaymentMethodChanged: (method) {
            setState(() => _paymentMethod = method);
          },
          onPaymentChannelChanged: (channel) {
            setState(() => _paymentChannel = channel);
          },
          banks: _banks,
          selectedBank: _selectedBank,
          onBankSelected: (bank) {
            setState(() {
              _selectedBank = bank;
              _paymentChannel = bank.bankName;
            });
          },
          cost: cost,
          senderLocation: senderCity,
          receiverLocation: receiverCity,
          selectedService: _selectedService,
          weightGramText: _weightController.text,
          useInsurance: _useInsurance,
        );
    }
  }

  Widget _buildBottomNavigationButtons() {
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
}
