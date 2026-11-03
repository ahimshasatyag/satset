import '../../domain/entities/operational_settings.dart';

class ServiceTypeSettingItemModel extends ServiceTypeSettingItem {
  const ServiceTypeSettingItemModel({
    required super.id,
    required super.kode,
    required super.namaLayanan,
    required super.estimasiHariMin,
    required super.estimasiHariMax,
    required super.deskripsi,
    required super.isActive,
    required super.baseTariffPerKg,
    super.createdAt,
  });

  factory ServiceTypeSettingItemModel.fromMap(Map<String, dynamic> map) {
    final code = (map['kode']?.toString() ?? 'REG').toUpperCase();
    num tariff = 10000;
    switch (code) {
      case 'INSTANT':
      case 'SAMEDAY':
        tariff = 25000;
        break;
      case 'EXP':
      case 'EXPRESS':
        tariff = 18000;
        break;
      case 'CARGO':
        tariff = 8000;
        break;
      case 'REG':
      case 'REGULER':
      default:
        tariff = 10000;
        break;
    }

    return ServiceTypeSettingItemModel(
      id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
      kode: code,
      namaLayanan: map['nama_layanan']?.toString() ?? code,
      estimasiHariMin:
          int.tryParse(map['estimasi_hari_min']?.toString() ?? '1') ?? 1,
      estimasiHariMax:
          int.tryParse(map['estimasi_hari_max']?.toString() ?? '3') ?? 3,
      deskripsi: map['deskripsi']?.toString() ?? '-',
      isActive: map['is_active'] != false,
      baseTariffPerKg: tariff,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }
}

class ShipmentStatusSettingItemModel extends ShipmentStatusSettingItem {
  const ShipmentStatusSettingItemModel({
    required super.id,
    required super.kode,
    required super.namaStatus,
    required super.urutan,
    super.isFinal,
  });

  factory ShipmentStatusSettingItemModel.fromMap(Map<String, dynamic> map) {
    final code = (map['kode']?.toString() ?? '').toUpperCase();
    final isFinal = code == 'DELIVERED' ||
        code == 'CANCELLED' ||
        code == 'RETURNED';

    return ShipmentStatusSettingItemModel(
      id: int.tryParse(map['id']?.toString() ?? '') ?? 0,
      kode: code,
      namaStatus: map['nama_status']?.toString() ?? code,
      urutan: int.tryParse(map['urutan']?.toString() ?? '99') ?? 99,
      isFinal: isFinal,
    );
  }
}

