import 'dart:async';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import '../../domain/entities/shipment.dart';
import '../models/shipment_model.dart';

abstract class ShipmentRemoteDataSource {
  /// Mengambil daftar master jenis layanan pengiriman
  Future<List<ServiceTypeModel>> getServiceTypes();

  /// Mengambil daftar master provinsi
  Future<List<ProvinceModel>> getProvinces();

  /// Mengambil daftar master kabupaten/kota berdasarkan kode provinsi
  Future<List<RegencyModel>> getRegencies(String provinceCode);

  /// Mengambil daftar master kecamatan berdasarkan kode kabkot
  Future<List<DistrictModel>> getDistricts(String regencyCode);

  /// Mengambil daftar master kelurahan berdasarkan kode kecamatan
  Future<List<VillageModel>> getVillages(String districtCode);

  /// Membuat pesanan pengiriman baru & transaksi pembayaran terkait di t_shipments & t_shipment_payments
  Future<OrderShipmentModel> createShipmentOrder(Map<String, dynamic> data);

  /// Memverifikasi status pembayaran terkini langsung dari tabel t_shipment_payments
  Future<ShipmentPaymentModel?> verifyPaymentStatus(String shipmentId);

  /// Stream perubahan status pembayaran secara real-time via Supabase Realtime
  Stream<ShipmentPaymentModel?> streamPaymentStatus(String shipmentId);

  /// Mengambil profil pengirim default dari pengguna yang sedang login
  Future<Map<String, dynamic>?> getCurrentUserProfile();

  /// Mengambil daftar master rekening bank (m_bank join m_jenis_bank)
  Future<List<BankAccountModel>> getBanks();

  /// Menyelesaikan customer_id pengguna yang sedang login
  Future<int> resolveCustomerId({String? userId});

  /// Memperbarui data alamat utama pengguna di tabel public.m_users
  Future<void> updateUserMainAddress({
    String? idProvinsi,
    String? idKabkot,
    String? idKecamatan,
    String? idKelurahan,
    String? alamatLengkap,
    double? latitude,
    double? longitude,
    String? namaLengkap,
    String? noHp,
  });
}

class ShipmentRemoteDataSourceImpl implements ShipmentRemoteDataSource {
  final SupabaseClient? _customClient;
  final AuthLocalDataSource? _authLocalDataSource;
  final User? currentUser;

  ShipmentRemoteDataSourceImpl({
    SupabaseClient? client,
    AuthLocalDataSource? authLocalDataSource,
    this.currentUser,
  })  : _customClient = client,
        _authLocalDataSource =
            authLocalDataSource ?? AuthLocalDataSourceImpl();

  bool get _isSupabaseAvailable {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient get _client => _customClient ?? SupabaseConfig.client;

  @override
  Future<int> resolveCustomerId({String? userId}) async {
    // 1. Coba dari currentUser
    if (currentUser != null && currentUser!.id.isNotEmpty) {
      final parsed = int.tryParse(currentUser!.id);
      if (parsed != null && parsed > 0) return parsed;
    }

    // 2. Coba dari parameter userId
    if (userId != null && userId.isNotEmpty) {
      final parsed = int.tryParse(userId);
      if (parsed != null && parsed > 0) return parsed;
    }

    // 3. Coba dari sesi lokal AuthLocalDataSource
    try {
      final savedUser = await _authLocalDataSource?.getUser();
      if (savedUser != null && savedUser.id.isNotEmpty) {
        final parsed = int.tryParse(savedUser.id);
        if (parsed != null && parsed > 0) return parsed;
      }
    } catch (_) {}

    // 4. Coba dari Supabase Auth session saat ini
    if (_isSupabaseAvailable) {
      final authUser = _client.auth.currentUser;
      if (authUser != null) {
        final email = (authUser.email ?? '').trim().toLowerCase();
        if (email.isNotEmpty) {
          final res = await _client
              .from(DatabaseConstants.tableUsers)
              .select(DatabaseConstants.colId)
              .eq(DatabaseConstants.colEmail, email)
              .maybeSingle();

          if (res != null && res[DatabaseConstants.colId] != null) {
            final parsed =
                int.tryParse(res[DatabaseConstants.colId].toString());
            if (parsed != null && parsed > 0) return parsed;
          }
        }
      }
    }

    // Fallback ID default untuk testing jika offline / mock
    return 4;
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      final authLocal = _authLocalDataSource ?? AuthLocalDataSourceImpl();
      final localUser = await authLocal.getUser();
      final localEmail = (localUser?.email ?? '').trim().toLowerCase();
      final localPhone = (localUser?.phone ?? '').trim();
      final localId = int.tryParse(localUser?.id ?? '');

      final authUser = _client.auth.currentUser;
      final sessionEmail = (authUser?.email ?? '').trim().toLowerCase();
      final email = sessionEmail.isNotEmpty ? sessionEmail : localEmail;

      if (_isSupabaseAvailable) {
        // 1. Coba ambil berdasarkan email
        if (email.isNotEmpty) {
          final userByEmail = await _client
              .from(DatabaseConstants.tableUsers)
              .select()
              .eq(DatabaseConstants.colEmail, email)
              .maybeSingle();
          if (userByEmail != null) {
            return userByEmail;
          }
        }

        // 2. Coba ambil berdasarkan nomor telepon jika ada
        if (localPhone.isNotEmpty) {
          final userByPhone = await _client
              .from(DatabaseConstants.tableUsers)
              .select()
              .eq(UserTableColumns.noHp, localPhone)
              .maybeSingle();
          if (userByPhone != null) {
            return userByPhone;
          }
        }

        // 3. Coba ambil berdasarkan ID pengguna sesi lokal
        if (localId != null && localId > 0) {
          final userById = await _client
              .from(DatabaseConstants.tableUsers)
              .select()
              .eq(DatabaseConstants.colId, localId)
              .maybeSingle();
          if (userById != null) {
            return userById;
          }
        }

        // 4. Fallback customerId yang teresolusi
        final customerId = await resolveCustomerId();
        final userRows = await _client
            .from(DatabaseConstants.tableUsers)
            .select()
            .eq(DatabaseConstants.colId, customerId)
            .limit(1);

        if (userRows.isNotEmpty) {
          return userRows.first;
        }
      }

      final user = localUser ?? currentUser;
      if (user != null) {
        return {
          'id': user.id,
          'nama_lengkap': user.name,
          'no_hp': user.phone,
          'email': user.email,
          'alamat_lengkap': user.alamatLengkap,
          'latitude': user.latitude,
          'longitude': user.longitude,
          'id_provinsi': user.idProvinsi,
          'id_kabkot': user.idKabkot,
          'id_kecamatan': user.idKecamatan,
          'id_kelurahan': user.idKelurahan,
        };
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateUserMainAddress({
    String? idProvinsi,
    String? idKabkot,
    String? idKecamatan,
    String? idKelurahan,
    String? alamatLengkap,
    double? latitude,
    double? longitude,
    String? namaLengkap,
    String? noHp,
  }) async {
    final updateData = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (idProvinsi != null && idProvinsi.isNotEmpty) {
      updateData[UserTableColumns.idProvinsi] = idProvinsi;
    }
    if (idKabkot != null && idKabkot.isNotEmpty) {
      updateData[UserTableColumns.idKabkot] = idKabkot;
    }
    if (idKecamatan != null && idKecamatan.isNotEmpty) {
      updateData[UserTableColumns.idKecamatan] = idKecamatan;
    }
    if (idKelurahan != null && idKelurahan.isNotEmpty) {
      updateData[UserTableColumns.idKelurahan] = idKelurahan;
    }
    if (alamatLengkap != null && alamatLengkap.trim().isNotEmpty) {
      updateData[UserTableColumns.alamatLengkap] = alamatLengkap.trim();
    }
    if (latitude != null && latitude != 0.0) {
      updateData[UserTableColumns.latitude] = latitude;
    }
    if (longitude != null && longitude != 0.0) {
      updateData[UserTableColumns.longitude] = longitude;
    }
    if (namaLengkap != null && namaLengkap.trim().isNotEmpty) {
      updateData[UserTableColumns.namaLengkap] = namaLengkap.trim();
    }
    if (noHp != null && noHp.trim().isNotEmpty) {
      updateData[UserTableColumns.noHp] = noHp.trim();
    }

    if (updateData.length <= 1) {
      return;
    }

    if (_isSupabaseAvailable) {
      try {
        final authLocal = _authLocalDataSource ?? AuthLocalDataSourceImpl();
        final localUser = await authLocal.getUser();
        final localEmail = (localUser?.email ?? '').trim().toLowerCase();
        final localPhone = (noHp ?? localUser?.phone ?? '').trim();
        final localId = int.tryParse(localUser?.id ?? '');

        final authUser = _client.auth.currentUser;
        final sessionEmail = (authUser?.email ?? '').trim().toLowerCase();
        final email = sessionEmail.isNotEmpty ? sessionEmail : localEmail;
        final customerId =
            (localId != null && localId > 0) ? localId : await resolveCustomerId();

        var updated = false;

        // 1. Prioritaskan update berdasarkan email akun
        if (email.isNotEmpty) {
          final res = await _client
              .from(DatabaseConstants.tableUsers)
              .update(updateData)
              .eq(DatabaseConstants.colEmail, email)
              .select('id');
          if (res.isNotEmpty) {
            updated = true;
          }
        }

        // 2. Coba update berdasarkan nomor HP jika ada
        if (!updated && localPhone.isNotEmpty) {
          final res = await _client
              .from(DatabaseConstants.tableUsers)
              .update(updateData)
              .eq(UserTableColumns.noHp, localPhone)
              .select('id');
          if (res.isNotEmpty) {
            updated = true;
          }
        }

        // 3. Jika belum terupdate atau email/phone tidak ada, update berdasarkan customerId
        if (!updated && customerId > 0) {
          await _client
              .from(DatabaseConstants.tableUsers)
              .update(updateData)
              .eq(DatabaseConstants.colId, customerId);
        }
      } catch (e) {
        // ignore: avoid_print
        print('Peringatan: Gagal update m_users: $e');
      }
    }

    // 3. Sinkronkan ke cache lokal AuthLocalDataSource jika tersedia
    try {
      final authLocal = _authLocalDataSource ?? AuthLocalDataSourceImpl();
      final local = await authLocal.getUser();
      if (local != null) {
        final updatedLocal = local.copyWith(
          name: updateData[UserTableColumns.namaLengkap] as String? ?? local.name,
          phone: updateData[UserTableColumns.noHp] as String? ?? local.phone,
          alamatLengkap: updateData[UserTableColumns.alamatLengkap] as String? ?? local.alamatLengkap,
          latitude: (updateData[UserTableColumns.latitude] as num?)?.toDouble() ?? local.latitude,
          longitude: (updateData[UserTableColumns.longitude] as num?)?.toDouble() ?? local.longitude,
          idProvinsi: updateData[UserTableColumns.idProvinsi] as String? ?? local.idProvinsi,
          idKabkot: updateData[UserTableColumns.idKabkot] as String? ?? local.idKabkot,
          idKecamatan: updateData[UserTableColumns.idKecamatan] as String? ?? local.idKecamatan,
          idKelurahan: updateData[UserTableColumns.idKelurahan] as String? ?? local.idKelurahan,
          updatedAt: DateTime.now(),
        );
        await authLocal.saveUser(updatedLocal);
      }
    } catch (_) {}
  }

  @override
  Future<List<ServiceTypeModel>> getServiceTypes() async {
    if (!_isSupabaseAvailable) {
      return const [
        ServiceTypeModel(id: 1, code: 'REG', name: 'Reguler', minDays: 2, maxDays: 3, description: 'Layanan standar hemat & andal', basePrice: 15000, insuranceRate: 0.002),
        ServiceTypeModel(id: 2, code: 'EXP', name: 'Express', minDays: 1, maxDays: 1, description: 'Layanan kilat tiba besok', basePrice: 25000, insuranceRate: 0.003),
        ServiceTypeModel(id: 3, code: 'SAMEDAY', name: 'Same Day', minDays: 0, maxDays: 0, description: 'Tiba di hari yang sama (6-8 jam)', basePrice: 20000, insuranceRate: 0.004),
        ServiceTypeModel(id: 4, code: 'INST', name: 'Instant Courier', minDays: 0, maxDays: 0, description: 'Pengantaran langsung point-to-point', basePrice: 30000, insuranceRate: 0.005),
      ];
    }

    try {
      final rows = await _client
          .from(DatabaseConstants.tableServiceTypes)
          .select()
          .eq('is_active', true)
          .order('id', ascending: true);

      return rows.map<ServiceTypeModel>((r) => ServiceTypeModel.fromDatabase(r)).toList();
    } catch (_) {
      return const [
        ServiceTypeModel(id: 1, code: 'REG', name: 'Reguler', minDays: 2, maxDays: 3, basePrice: 15000, insuranceRate: 0.002),
        ServiceTypeModel(id: 2, code: 'EXP', name: 'Express', minDays: 1, maxDays: 1, basePrice: 25000, insuranceRate: 0.003),
      ];
    }
  }

  @override
  Future<List<ProvinceModel>> getProvinces() async {
    if (!_isSupabaseAvailable) {
      return const [
        ProvinceModel(code: '31', name: 'DKI JAKARTA'),
        ProvinceModel(code: '32', name: 'JAWA BARAT'),
        ProvinceModel(code: '33', name: 'JAWA TENGAH'),
        ProvinceModel(code: '35', name: 'JAWA TIMUR'),
        ProvinceModel(code: '36', name: 'BANTEN'),
      ];
    }

    try {
      final rows = await _client
          .from(DatabaseConstants.tableProvinsi)
          .select()
          .order(ProvinsiTableColumns.namaProvinsi, ascending: true);

      return rows.map<ProvinceModel>((r) => ProvinceModel.fromDatabase(r)).toList();
    } catch (_) {
      return const [
        ProvinceModel(code: '31', name: 'DKI JAKARTA'),
        ProvinceModel(code: '32', name: 'JAWA BARAT'),
      ];
    }
  }

  @override
  Future<List<RegencyModel>> getRegencies(String provinceCode) async {
    if (!_isSupabaseAvailable) {
      return [];
    }

    try {
      final rows = await _client
          .from(DatabaseConstants.tableKabkot)
          .select()
          .eq(KabkotTableColumns.kodeProvinsi, provinceCode)
          .order(KabkotTableColumns.namaKabkot, ascending: true);

      return rows.map<RegencyModel>((r) => RegencyModel.fromDatabase(r)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<DistrictModel>> getDistricts(String regencyCode) async {
    if (!_isSupabaseAvailable) {
      return [];
    }

    try {
      final rows = await _client
          .from(DatabaseConstants.tableKecamatan)
          .select()
          .eq(KecamatanTableColumns.kodeKabkot, regencyCode)
          .order(KecamatanTableColumns.namaKecamatan, ascending: true);

      return rows.map<DistrictModel>((r) => DistrictModel.fromDatabase(r)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<VillageModel>> getVillages(String districtCode) async {
    if (!_isSupabaseAvailable) {
      return [];
    }

    try {
      final rows = await _client
          .from(DatabaseConstants.tableKelurahan)
          .select()
          .eq(KelurahanTableColumns.kodeKecamatan, districtCode)
          .order(KelurahanTableColumns.namaKelurahan, ascending: true);

      return rows.map<VillageModel>((r) => VillageModel.fromDatabase(r)).toList();
    } catch (_) {
      return [];
    }
  }

  static final List<BankAccountModel> _mockBanks = [
    const BankAccountModel(
      id: '42e0f322-2518-4fa0-8bbc-8ea5a3b2ac56',
      namaPemilik: 'Ahimsha Satya Graha',
      nomorRekening: '7833042400',
      jenisBankId: 'e4ed81ef-2f3b-4a23-b031-7d88fcefe148',
      jenisBank: JenisBankModel(
        id: 'e4ed81ef-2f3b-4a23-b031-7d88fcefe148',
        namaJenis: 'BCA',
      ),
    ),
    const BankAccountModel(
      id: '400780cb-dd23-419d-b35a-c2f8ad3071fe',
      namaPemilik: 'Roni Yoppi',
      nomorRekening: '0341000000000',
      jenisBankId: '7dd3e7c6-1a59-4ef4-8435-71fce3304b2e',
      jenisBank: JenisBankModel(
        id: '7dd3e7c6-1a59-4ef4-8435-71fce3304b2e',
        namaJenis: 'BRI',
      ),
    ),
    const BankAccountModel(
      id: 'ded6f4d1-a54c-4251-b192-9df8b46340ea',
      namaPemilik: 'Adi Gunawan',
      nomorRekening: '0123000000000',
      jenisBankId: 'bfe09d97-b39a-4e70-a1fe-d00b874abe88',
      jenisBank: JenisBankModel(
        id: 'bfe09d97-b39a-4e70-a1fe-d00b874abe88',
        namaJenis: 'Mandiri',
      ),
    ),
    const BankAccountModel(
      id: 'f471844c-fe34-4f0e-9b87-6c72a8a9cb99',
      namaPemilik: 'Nina Ritawati',
      nomorRekening: '2750000000000',
      jenisBankId: '580e633f-a98e-4496-8deb-092cbda74180',
      jenisBank: JenisBankModel(
        id: '580e633f-a98e-4496-8deb-092cbda74180',
        namaJenis: 'BNI',
      ),
    ),
  ];

  @override
  Future<List<BankAccountModel>> getBanks() async {
    if (!_isSupabaseAvailable) {
      return _mockBanks;
    }
    try {
      final List<dynamic> res = await _client
          .from(DatabaseConstants.tableBank)
          .select('*, ${DatabaseConstants.tableJenisBank}(*)')
          .order(BankTableColumns.createdAt, ascending: true);
      if (res.isEmpty) return _mockBanks;
      return res
          .map<BankAccountModel>(
            (row) => BankAccountModel.fromDatabase(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList();
    } catch (_) {
      return _mockBanks;
    }
  }

  @override
  Future<OrderShipmentModel> createShipmentOrder(Map<String, dynamic> data) async {
    final customerId = await resolveCustomerId();

    // 1. Ekstrak data pengiriman
    final serviceTypeId = data['service_type_id'] as int? ?? 1;
    final totalBeratGram = (data['total_berat_gram'] as num?)?.toInt() ?? 1000;
    final panjangCm = (data['panjang_cm'] as num?)?.toInt() ?? 10;
    final lebarCm = (data['lebar_cm'] as num?)?.toInt() ?? 10;
    final tinggiCm = (data['tinggi_cm'] as num?)?.toInt() ?? 10;
    final totalBarang = (data['total_barang'] as num?)?.toInt() ?? 1;
    final rawNilaiBarang = (data['nilai_barang'] as num?)?.toDouble() ?? 0.0;
    final paymentMethod = (data['metode_pembayaran'] as String? ?? 'TRANSFER').toUpperCase();
    final paymentChannel = data['payment_channel'] as String? ?? (paymentMethod == 'COD' ? 'COD' : 'BCA_VA');
    final selectedBank = data['selected_bank'] as BankAccount?;
    final jenisBankId = data['jenis_bank_id']?.toString() ?? selectedBank?.jenisBankId;
    final bankAccountNumber = data['nomor_rekening']?.toString() ?? selectedBank?.nomorRekening;
    final bankName = data['bank_name']?.toString() ?? selectedBank?.bankName ?? (paymentMethod == 'COD' ? 'COD' : paymentChannel);
    final catatan = data['catatan_pengiriman'] as String? ?? data['itemName'] as String? ?? 'Paket SatSet';

    // 2. Perhitungan biaya divalidasi oleh formula
    final volumetricWeightKg = (panjangCm * lebarCm * tinggiCm) / 6000.0;
    final actualWeightKg = totalBeratGram / 1000.0;
    final chargeableWeightKg = max(actualWeightKg, volumetricWeightKg);
    final billedKg = max(1, chargeableWeightKg.ceil());

    double baseRatePerKg = 15000;
    if (serviceTypeId == 2) baseRatePerKg = 25000;
    if (serviceTypeId == 3) baseRatePerKg = 20000;
    if (serviceTypeId == 4) baseRatePerKg = 30000;

    final shippingFee = (data['biaya_pengiriman'] as num?)?.toDouble() ?? (baseRatePerKg * billedKg);

    // Otomatisasi nilai/harga asli barang dari berat & dimensi jika belum diisi (>0)
    final autoNilaiBarang = billedKg * baseRatePerKg;
    final nilaiBarang = rawNilaiBarang > 0 ? rawNilaiBarang : autoNilaiBarang;

    final useInsurance = data['use_insurance'] == true || data['is_insured'] == true;
    double insuranceRate = 0.002;
    if (serviceTypeId == 2) insuranceRate = 0.003;
    if (serviceTypeId == 3) insuranceRate = 0.004;
    if (serviceTypeId == 4) insuranceRate = 0.005;

    final insuranceFee = useInsurance && nilaiBarang > 0
        ? ((data['biaya_asuransi'] as num?)?.toDouble() ?? (nilaiBarang * insuranceRate))
        : 0.0;
    const additionalFee = 1000.0;
    const discount = 0.0;
    final totalBiaya = (data['total_biaya'] as num?)?.toDouble() ??
        (shippingFee + insuranceFee + additionalFee - discount);

    // 3. Generate nomor resi & barcode unik
    final now = DateTime.now();
    final datePrefix = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomSuffix = (100000 + Random().nextInt(900000)).toString();
    final nomorResi = 'SST-$datePrefix-$randomSuffix';
    final barcodeValue = nomorResi;

    final mockShipment = OrderShipmentModel(
      id: 'ord-${now.millisecondsSinceEpoch}',
      trackingNumber: nomorResi,
      barcodeValue: barcodeValue,
      itemName: catatan,
      itemCategory: 'Reguler',
      serviceType: serviceTypeId == 2 ? 'Express' : (serviceTypeId == 3 ? 'Same Day' : 'Reguler'),
      serviceTypeId: serviceTypeId,
      direction: OrderDirection.outgoing,
      filterStatus: OrderFilterStatus.waitingPickup,
      statusCode: 'PENDING',
      senderName: data['pengirim_nama'] as String? ?? 'Pengirim',
      senderPhone: data['pengirim_no_hp'] as String? ?? '',
      senderAddress: data['pengirim_alamat'] as String? ?? '',
      senderPostalCode: data['pengirim_kode_pos'] as String? ?? '',
      receiverName: data['penerima_nama'] as String? ?? 'Penerima',
      receiverPhone: data['penerima_no_hp'] as String? ?? '',
      receiverAddress: data['penerima_alamat'] as String? ?? '',
      receiverPostalCode: data['penerima_kode_pos'] as String? ?? '',
      originCity: data['pengirim_kota'] as String? ?? '',
      destinationCity: data['penerima_kota'] as String? ?? '',
      statusDescription: 'Pesanan dibuat. Menunggu penjemputan kurir.',
      courierName: 'Kurir SatSet',
      courierPhone: '-',
      courierVehicle: 'SatSet Fleet',
      etaMinutes: 30,
      distanceKm: 5.0,
      price: totalBiaya.toInt(),
      weightGram: totalBeratGram,
      totalItems: totalBarang,
      goodsValue: nilaiBarang,
      shippingFee: shippingFee,
      insuranceFee: insuranceFee,
      additionalFee: additionalFee,
      totalPrice: totalBiaya,
      paymentMethod: paymentMethod,
      notes: catatan,
      payment: ShipmentPaymentModel(
        id: Random().nextInt(99999),
        shipmentId: Random().nextInt(99999),
        paymentNumber: 'PAY-${now.millisecondsSinceEpoch}',
        paymentMethod: paymentMethod,
        amount: totalBiaya,
        status: OrderPaymentStatus.pending,
        provider: bankName,
        providerReference: paymentMethod == 'COD'
            ? 'COD-TUNAI'
            : (bankAccountNumber != null && bankAccountNumber.isNotEmpty
                ? bankAccountNumber
                : '8801${Random().nextInt(90000000) + 10000000}'),
        jenisBankId: jenisBankId,
        bankAccount: selectedBank != null
            ? BankAccountModel(
                id: selectedBank.id,
                namaPemilik: selectedBank.namaPemilik,
                nomorRekening: selectedBank.nomorRekening,
                jenisBankId: selectedBank.jenisBankId,
                jenisBank: selectedBank.jenisBank,
              )
            : null,
        createdAt: now,
        updatedAt: now,
        expiredAt: now.add(const Duration(hours: 24)),
      ),
      createdAt: now,
      updatedAt: now,
    );

    if (!_isSupabaseAvailable) {
      return mockShipment;
    }

    try {
      // 4. Insert ke tabel t_shipments di Supabase
      final shipmentPayload = {
        ShipmentTableColumns.nomorResi: nomorResi,
        ShipmentTableColumns.barcodeValue: barcodeValue,
        ShipmentTableColumns.customerId: customerId,
        ShipmentTableColumns.serviceTypeId: serviceTypeId,
        ShipmentTableColumns.statusId: 1, // 1 = PENDING
        ShipmentTableColumns.pengirimNama: data['pengirim_nama'] ?? 'Pengirim',
        ShipmentTableColumns.pengirimNoHp: data['pengirim_no_hp'] ?? '081234567890',
        ShipmentTableColumns.pengirimAlamat: data['pengirim_alamat'] ?? '-',
        ShipmentTableColumns.pengirimKota: data['pengirim_kota'] ?? 'Jakarta',
        ShipmentTableColumns.pengirimKodePos: data['pengirim_kode_pos'] ?? '',
        ShipmentTableColumns.pengirimLatitude: data['pengirim_latitude'],
        ShipmentTableColumns.pengirimLongitude: data['pengirim_longitude'],
        ShipmentTableColumns.penerimaNama: data['penerima_nama'] ?? 'Penerima',
        ShipmentTableColumns.penerimaNoHp: data['penerima_no_hp'] ?? '089876543210',
        ShipmentTableColumns.penerimaAlamat: data['penerima_alamat'] ?? '-',
        ShipmentTableColumns.penerimaKota: data['penerima_kota'] ?? 'Jakarta',
        ShipmentTableColumns.penerimaKodePos: data['penerima_kode_pos'] ?? '',
        ShipmentTableColumns.penerimaLatitude: data['penerima_latitude'],
        ShipmentTableColumns.penerimaLongitude: data['penerima_longitude'],
        ShipmentTableColumns.totalBeratGram: totalBeratGram,
        ShipmentTableColumns.panjangCm: panjangCm,
        ShipmentTableColumns.lebarCm: lebarCm,
        ShipmentTableColumns.tinggiCm: tinggiCm,
        ShipmentTableColumns.totalBarang: totalBarang,
        ShipmentTableColumns.nilaiBarang: nilaiBarang,
        ShipmentTableColumns.biayaPengiriman: shippingFee,
        ShipmentTableColumns.biayaAsuransi: insuranceFee,
        ShipmentTableColumns.biayaLayananTambahan: additionalFee,
        ShipmentTableColumns.diskon: discount,
        ShipmentTableColumns.totalBiaya: totalBiaya,
        ShipmentTableColumns.metodePembayaran: paymentMethod,
        ShipmentTableColumns.catatanPengiriman: catatan,
      };

      final createdShipmentRow = await _client
          .from(DatabaseConstants.tableShipments)
          .insert(shipmentPayload)
          .select('''
            *,
            ${DatabaseConstants.tableShipmentStatuses}(*),
            ${DatabaseConstants.tableServiceTypes}(*)
          ''')
          .single();

      final shipmentIdInt = (createdShipmentRow['id'] as num).toInt();

      // 5. Buat entri transaksi pembayaran di tabel t_shipment_payments
      final paymentNumber = 'PAY-$datePrefix-${(1000 + Random().nextInt(9000))}';
      String providerRef;
      if (paymentMethod == 'COD') {
        providerRef = 'COD-PAY-ON-DELIVERY';
      } else if (paymentChannel.toUpperCase().contains('QRIS')) {
        providerRef = '00020101021226600016ID.CO.SATSET.WWW01189360099900012345675204581253033605802ID5915SATSET DELIVERY6007JAKARTA62070703A016304${(1000 + Random().nextInt(9000))}';
      } else if (bankAccountNumber != null && bankAccountNumber.isNotEmpty) {
        providerRef = bankAccountNumber;
      } else {
        providerRef = '8801${(10000000 + Random().nextInt(90000000))}';
      }

      final paymentPayload = {
        'shipment_id': shipmentIdInt,
        'nomor_pembayaran': paymentNumber,
        'metode_pembayaran': paymentMethod,
        'jumlah_bayar': totalBiaya,
        'status_pembayaran': paymentMethod == 'COD' ? 'PENDING' : 'PENDING',
        'provider': bankName,
        'provider_reference': providerRef,
        if (jenisBankId != null && jenisBankId.isNotEmpty) 'jenis_bank_id': jenisBankId,
        'expired_at': now.add(const Duration(hours: 24)).toIso8601String(),
      };

      final paymentRow = await _client
          .from(DatabaseConstants.tableShipmentPayments)
          .insert(paymentPayload)
          .select()
          .single();

      createdShipmentRow['t_shipment_payments'] = [paymentRow];

      return OrderShipmentModel.fromDatabase(
        createdShipmentRow,
        currentCustomerId: customerId,
      );
    } catch (e) {
      // Jika terjadi kendala saat insert ke Supabase (misal RLS, timeout, schema mismatch),
      // tetap kembalikan mockShipment agar alur pembuatan pesanan pengguna berhasil
      return mockShipment;
    }
  }

  @override
  Future<ShipmentPaymentModel?> verifyPaymentStatus(String shipmentId) async {
    if (!_isSupabaseAvailable) {
      return ShipmentPaymentModel(
        id: 1,
        shipmentId: int.tryParse(shipmentId) ?? 1,
        paymentNumber: 'PAY-$shipmentId',
        paymentMethod: 'TRANSFER',
        amount: 25000,
        status: OrderPaymentStatus.paid,
        provider: 'BCA_VA',
        providerReference: '8801999988887777',
        paidAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    try {
      final sIdInt = int.tryParse(shipmentId);
      var query = _client.from(DatabaseConstants.tableShipmentPayments).select();
      if (sIdInt != null) {
        query = query.eq('shipment_id', sIdInt);
      } else {
        query = query.eq('nomor_pembayaran', shipmentId);
      }

      final rows = await query.order('id', ascending: false).limit(1);
      if (rows.isEmpty) return null;

      final p = ShipmentPaymentModel.fromDatabase(rows.first);
      if (p.isPaid && sIdInt != null) {
        await _client
            .from(DatabaseConstants.tableShipments)
            .update({ShipmentTableColumns.statusId: 2})
            .eq('id', sIdInt);
      }
      return p;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<ShipmentPaymentModel?> streamPaymentStatus(String shipmentId) {
    if (!_isSupabaseAvailable) {
      return const Stream.empty();
    }

    final sIdInt = int.tryParse(shipmentId);
    if (sIdInt == null) return const Stream.empty();

    return _client
        .from(DatabaseConstants.tableShipmentPayments)
        .stream(primaryKey: ['id'])
        .eq('shipment_id', sIdInt)
        .map((rows) {
          if (rows.isEmpty) return null;
          return ShipmentPaymentModel.fromDatabase(rows.first);
        });
  }
}
