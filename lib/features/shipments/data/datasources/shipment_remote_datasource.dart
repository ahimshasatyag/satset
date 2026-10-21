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

  /// Menyelesaikan customer_id pengguna yang sedang login
  Future<int> resolveCustomerId({String? userId});
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
      final customerId = await resolveCustomerId();
      if (!_isSupabaseAvailable) {
        return {
          'id': customerId,
          'nama_lengkap': 'Pelanggan SatSet',
          'no_hp': '081234567890',
          'alamat': 'Jl. SatSet Express No. 88',
          'kota': 'Jakarta Selatan',
          'kodepos': '12190',
        };
      }

      final userRows = await _client
          .from(DatabaseConstants.tableUsers)
          .select()
          .eq('id', customerId)
          .limit(1);

      if (userRows.isNotEmpty) {
        return userRows.first;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ServiceTypeModel>> getServiceTypes() async {
    if (!_isSupabaseAvailable) {
      return const [
        ServiceTypeModel(id: 1, code: 'REG', name: 'Reguler', minDays: 2, maxDays: 3, description: 'Layanan standar hemat & andal', basePrice: 15000),
        ServiceTypeModel(id: 2, code: 'EXP', name: 'Express', minDays: 1, maxDays: 1, description: 'Layanan kilat tiba besok', basePrice: 25000),
        ServiceTypeModel(id: 3, code: 'SAMEDAY', name: 'Same Day', minDays: 0, maxDays: 0, description: 'Tiba di hari yang sama (6-8 jam)', basePrice: 20000),
        ServiceTypeModel(id: 4, code: 'INST', name: 'Instant Courier', minDays: 0, maxDays: 0, description: 'Pengantaran langsung point-to-point', basePrice: 30000),
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
        ServiceTypeModel(id: 1, code: 'REG', name: 'Reguler', minDays: 2, maxDays: 3, basePrice: 15000),
        ServiceTypeModel(id: 2, code: 'EXP', name: 'Express', minDays: 1, maxDays: 1, basePrice: 25000),
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
      return [
        RegencyModel(code: '$provinceCode.01', provinceCode: provinceCode, name: 'Kota Pusat', type: 'KOTA'),
        RegencyModel(code: '$provinceCode.02', provinceCode: provinceCode, name: 'Kota Selatan', type: 'KOTA'),
      ];
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
      return [
        DistrictModel(code: '$regencyCode.01', regencyCode: regencyCode, name: 'Kecamatan Barat'),
        DistrictModel(code: '$regencyCode.02', regencyCode: regencyCode, name: 'Kecamatan Timur'),
      ];
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
      return [
        VillageModel(code: '$districtCode.1001', districtCode: districtCode, name: 'Kelurahan Sejahtera', postalCode: '12190'),
        VillageModel(code: '$districtCode.1002', districtCode: districtCode, name: 'Kelurahan Makmur', postalCode: '12191'),
      ];
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
    final nilaiBarang = (data['nilai_barang'] as num?)?.toDouble() ?? 0.0;
    final paymentMethod = (data['metode_pembayaran'] as String? ?? 'TRANSFER').toUpperCase();
    final paymentChannel = data['payment_channel'] as String? ?? (paymentMethod == 'COD' ? 'COD' : 'BCA_VA');
    final catatan = data['catatan_pengiriman'] as String? ?? data['itemName'] as String? ?? 'Paket SatSet';

    // 2. Perhitungan biaya divalidasi oleh formula
    final volumetricWeightKg = (panjangCm * lebarCm * tinggiCm) / 6000.0;
    final actualWeightKg = totalBeratGram / 1000.0;
    final chargeableWeightKg = max(actualWeightKg, volumetricWeightKg);
    final billedKg = max(1, chargeableWeightKg.ceil());

    double baseRatePerKg = 15000;
    if (serviceTypeId == 2) baseRatePerKg = 25000;
    if (serviceTypeId == 3) baseRatePerKg = 20000;

    final shippingFee = baseRatePerKg * billedKg;
    final insuranceFee = nilaiBarang > 0 ? (nilaiBarang * 0.002).clamp(2000.0, 100000.0) : 0.0;
    const additionalFee = 1000.0;
    const discount = 0.0;
    final totalBiaya = shippingFee + insuranceFee + additionalFee - discount;

    // 3. Generate nomor resi & barcode unik
    final now = DateTime.now();
    final datePrefix = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final randomSuffix = (100000 + Random().nextInt(900000)).toString();
    final nomorResi = 'SST-$datePrefix-$randomSuffix';
    final barcodeValue = nomorResi;

    if (!_isSupabaseAvailable) {
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
        senderName: data['pengirim_nama'] as String? ?? 'Pengirim SatSet',
        senderPhone: data['pengirim_no_hp'] as String? ?? '08123456789',
        senderAddress: data['pengirim_alamat'] as String? ?? 'Alamat Asal',
        senderPostalCode: data['pengirim_kode_pos'] as String? ?? '12190',
        receiverName: data['penerima_nama'] as String? ?? 'Penerima SatSet',
        receiverPhone: data['penerima_no_hp'] as String? ?? '08987654321',
        receiverAddress: data['penerima_alamat'] as String? ?? 'Alamat Tujuan',
        receiverPostalCode: data['penerima_kode_pos'] as String? ?? '14045',
        originCity: data['pengirim_kota'] as String? ?? 'Jakarta Selatan',
        destinationCity: data['penerima_kota'] as String? ?? 'Jakarta Barat',
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
          provider: paymentChannel,
          providerReference: paymentMethod == 'COD' ? 'COD-TUNAI' : '8801${Random().nextInt(90000000) + 10000000}',
          createdAt: now,
          updatedAt: now,
          expiredAt: now.add(const Duration(hours: 24)),
        ),
        createdAt: now,
        updatedAt: now,
      );
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
      } else {
        providerRef = '8801${(10000000 + Random().nextInt(90000000))}';
      }

      final paymentPayload = {
        'shipment_id': shipmentIdInt,
        'nomor_pembayaran': paymentNumber,
        'metode_pembayaran': paymentMethod,
        'jumlah_bayar': totalBiaya,
        'status_pembayaran': paymentMethod == 'COD' ? 'PENDING' : 'PENDING',
        'provider': paymentChannel,
        'provider_reference': providerRef,
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
      throw Exception('Gagal membuat pesanan pengiriman: $e');
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
