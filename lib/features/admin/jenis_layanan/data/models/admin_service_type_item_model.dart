import '../../domain/entities/admin_service_type_item.dart';

class AdminServiceTypeItemModel extends AdminServiceTypeItem {
  const AdminServiceTypeItemModel({
    required super.id,
    required super.kode,
    required super.namaLayanan,
    super.deskripsi,
    required super.estimasiHariMin,
    required super.estimasiHariMax,
    required super.isActive,
    required super.baseTariffPerKg,
    required super.insuranceRateDecimal,
    super.hasCustomTariffColumn = false,
    super.totalShipmentsCount = 0,
    super.activeShipmentsCount = 0,
    super.deliveredShipmentsCount = 0,
    super.totalRevenueAmount = 0,
    super.createdAt,
    super.updatedAt,
  });

  factory AdminServiceTypeItemModel.fromMap(
    Map<String, dynamic> map, {
    int totalShipmentsCount = 0,
    int activeShipmentsCount = 0,
    int deliveredShipmentsCount = 0,
    num totalRevenueAmount = 0,
  }) {
    final id = int.tryParse(map['id']?.toString() ?? '0') ?? 0;
    final kode = (map['kode'] ?? '').toString().toUpperCase();
    final namaLayanan = (map['nama_layanan'] ?? '-').toString();
    final deskripsi = map['deskripsi']?.toString();
    final estimasiMin =
        int.tryParse(map['estimasi_hari_min']?.toString() ?? '1') ?? 1;
    final estimasiMax =
        int.tryParse(map['estimasi_hari_max']?.toString() ?? '3') ?? 3;
    final isActive = map['is_active'] != false;

    final hasCustomTariff = map.containsKey('harga_dasar') &&
        map['harga_dasar'] != null;
    final dbTariff = num.tryParse(map['harga_dasar']?.toString() ?? '');
    final dbInsRate = double.tryParse(map['tarif_asuransi']?.toString() ?? '');

    final resolvedTariff = dbTariff ?? _resolveStandardTariff(kode, id);
    final resolvedInsurance = dbInsRate ?? _resolveStandardInsuranceRate(kode, id);

    return AdminServiceTypeItemModel(
      id: id,
      kode: kode,
      namaLayanan: namaLayanan,
      deskripsi: deskripsi,
      estimasiHariMin: estimasiMin,
      estimasiHariMax: estimasiMax,
      isActive: isActive,
      baseTariffPerKg: resolvedTariff,
      insuranceRateDecimal: resolvedInsurance,
      hasCustomTariffColumn: hasCustomTariff,
      totalShipmentsCount: totalShipmentsCount,
      activeShipmentsCount: activeShipmentsCount,
      deliveredShipmentsCount: deliveredShipmentsCount,
      totalRevenueAmount: totalRevenueAmount,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  /// Aturan tarif standar sistem SatSet Delivery sesuai skema layanan
  static num _resolveStandardTariff(String kode, int id) {
    final c = kode.toUpperCase();
    if (c == 'EXP' || c == 'EXPRESS' || id == 2) return 25000;
    if (c == 'SAMEDAY' || c == 'SDS' || id == 3) return 20000;
    if (c == 'INST' || c == 'INSTANT' || id == 4) return 30000;
    if (c == 'CARGO' || c == 'KGO') return 12000;
    return 15000;
  }

  static double _resolveStandardInsuranceRate(String kode, int id) {
    final c = kode.toUpperCase();
    if (c == 'EXP' || c == 'EXPRESS' || id == 2) return 0.003;
    if (c == 'SAMEDAY' || c == 'SDS' || id == 3) return 0.004;
    if (c == 'INST' || c == 'INSTANT' || id == 4) return 0.005;
    return 0.002;
  }
}

