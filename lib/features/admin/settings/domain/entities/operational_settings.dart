import 'package:equatable/equatable.dart';

class ServiceTypeSettingItem extends Equatable {
  final int id;
  final String kode;
  final String namaLayanan;
  final int estimasiHariMin;
  final int estimasiHariMax;
  final String deskripsi;
  final bool isActive;
  final num baseTariffPerKg;
  final DateTime? createdAt;

  const ServiceTypeSettingItem({
    required this.id,
    required this.kode,
    required this.namaLayanan,
    required this.estimasiHariMin,
    required this.estimasiHariMax,
    required this.deskripsi,
    required this.isActive,
    required this.baseTariffPerKg,
    this.createdAt,
  });

  String get slaDisplay {
    if (estimasiHariMin == 0 && estimasiHariMax == 0) {
      return 'Same Day (Hari Ini Tiba)';
    }
    if (estimasiHariMin == estimasiHariMax) {
      return '$estimasiHariMin Hari Kerja';
    }
    return '$estimasiHariMin - $estimasiHariMax Hari Kerja';
  }

  @override
  List<Object?> get props => [
        id,
        kode,
        namaLayanan,
        estimasiHariMin,
        estimasiHariMax,
        deskripsi,
        isActive,
        baseTariffPerKg,
        createdAt,
      ];
}

class ShipmentStatusSettingItem extends Equatable {
  final int id;
  final String kode;
  final String namaStatus;
  final int urutan;
  final bool isFinal;

  const ShipmentStatusSettingItem({
    required this.id,
    required this.kode,
    required this.namaStatus,
    required this.urutan,
    this.isFinal = false,
  });

  @override
  List<Object?> get props => [id, kode, namaStatus, urutan, isFinal];
}

class OperationalSettings extends Equatable {
  final List<ServiceTypeSettingItem> serviceTypes;
  final List<ShipmentStatusSettingItem> shipmentStatuses;
  final int maxPackageWeightKg;
  final num insuranceRatePercent;
  final bool autoConfirmCodShipments;
  final String historicalIntegrityNotice;

  const OperationalSettings({
    this.serviceTypes = const [],
    this.shipmentStatuses = const [],
    this.maxPackageWeightKg = 50,
    this.insuranceRatePercent = 0.2,
    this.autoConfirmCodShipments = false,
    this.historicalIntegrityNotice =
        'Perubahan status aktif/nonaktif pada master jenis layanan (m_service_types) hanya berlaku untuk pembuatan pesanan baru oleh pelanggan. Perubahan ini tidak akan mengubah nilai tarif (total_biaya) maupun riwayat pesanan yang sudah tercatat pada t_shipments.',
  });

  OperationalSettings copyWith({
    List<ServiceTypeSettingItem>? serviceTypes,
    List<ShipmentStatusSettingItem>? shipmentStatuses,
    int? maxPackageWeightKg,
    num? insuranceRatePercent,
    bool? autoConfirmCodShipments,
    String? historicalIntegrityNotice,
  }) {
    return OperationalSettings(
      serviceTypes: serviceTypes ?? this.serviceTypes,
      shipmentStatuses: shipmentStatuses ?? this.shipmentStatuses,
      maxPackageWeightKg: maxPackageWeightKg ?? this.maxPackageWeightKg,
      insuranceRatePercent: insuranceRatePercent ?? this.insuranceRatePercent,
      autoConfirmCodShipments:
          autoConfirmCodShipments ?? this.autoConfirmCodShipments,
      historicalIntegrityNotice:
          historicalIntegrityNotice ?? this.historicalIntegrityNotice,
    );
  }

  @override
  List<Object?> get props => [
        serviceTypes,
        shipmentStatuses,
        maxPackageWeightKg,
        insuranceRatePercent,
        autoConfirmCodShipments,
        historicalIntegrityNotice,
      ];
}

