import 'package:equatable/equatable.dart';
import 'admin_report_models.dart';

/// Item kronologi jejak pengiriman (t_shipment_tracking) pada detail laporan
class AdminReportTrackingEvent extends Equatable {
  final int id;
  final String statusKode;
  final String statusNama;
  final String? lokasiNama;
  final String? catatan;
  final String? employeeNama;
  final DateTime? createdAt;

  const AdminReportTrackingEvent({
    required this.id,
    required this.statusKode,
    required this.statusNama,
    this.lokasiNama,
    this.catatan,
    this.employeeNama,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        statusKode,
        statusNama,
        lokasiNama,
        catatan,
        employeeNama,
        createdAt,
      ];
}

/// Item referensi bukti pengiriman (t_shipment_proofs) pada detail laporan
class AdminReportProofItem extends Equatable {
  final int id;
  final String jenisBukti;
  final String? filePath;
  final String? penerimaNama;
  final String? catatan;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  const AdminReportProofItem({
    required this.id,
    required this.jenisBukti,
    this.filePath,
    this.penerimaNama,
    this.catatan,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        jenisBukti,
        filePath,
        penerimaNama,
        catatan,
        latitude,
        longitude,
        createdAt,
      ];
}

/// Item lokasi GPS kurir (t_shipment_locations) pada detail laporan
class AdminReportLocationLog extends Equatable {
  final int id;
  final double latitude;
  final double longitude;
  final double? speedMps;
  final double? accuracyM;
  final DateTime? recordedAt;

  const AdminReportLocationLog({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.speedMps,
    this.accuracyM,
    this.recordedAt,
  });

  @override
  List<Object?> get props => [
        id,
        latitude,
        longitude,
        speedMps,
        accuracyM,
        recordedAt,
      ];
}

/// Item ringkas pengiriman pendukung pada Detail Laporan Kurir / Pelanggan
class AdminReportSupportingShipment extends Equatable {
  final int shipmentId;
  final String nomorResi;
  final DateTime? createdAt;
  final String serviceKode;
  final String serviceNama;
  final String statusKode;
  final String statusNama;
  final String pengirimNama;
  final String pengirimKota;
  final String penerimaNama;
  final String penerimaKota;
  final String? courierNama;
  final String metodePembayaran;
  final String statusPembayaran;
  final num totalBiaya;
  final bool hasProof;

  const AdminReportSupportingShipment({
    required this.shipmentId,
    required this.nomorResi,
    this.createdAt,
    required this.serviceKode,
    required this.serviceNama,
    required this.statusKode,
    required this.statusNama,
    required this.pengirimNama,
    required this.pengirimKota,
    required this.penerimaNama,
    required this.penerimaKota,
    this.courierNama,
    required this.metodePembayaran,
    required this.statusPembayaran,
    required this.totalBiaya,
    this.hasProof = false,
  });

  @override
  List<Object?> get props => [
        shipmentId,
        nomorResi,
        createdAt,
        serviceKode,
        serviceNama,
        statusKode,
        statusNama,
        pengirimNama,
        pengirimKota,
        penerimaNama,
        penerimaKota,
        courierNama,
        metodePembayaran,
        statusPembayaran,
        totalBiaya,
        hasProof,
      ];
}

/// Entitas Detail Laporan yang dapat dibuka untuk melihat informasi pendukung lengkap
class AdminReportDetail extends Equatable {
  final String reportType;
  final int recordId;
  final String title;
  final String subtitle;

  // Data spesifik baris yang dipilih
  final AdminShipmentReportRow? shipmentRow;
  final AdminCourierReportRow? courierRow;
  final AdminCustomerReportRow? customerRow;
  final AdminPaymentReportRow? paymentRow;

  // Data pendukung lintas tabel
  final List<AdminReportTrackingEvent> trackingHistory;
  final List<AdminReportProofItem> deliveryProofs;
  final List<AdminReportLocationLog> locationLogs;
  final List<AdminReportSupportingShipment> relatedShipments;

  const AdminReportDetail({
    required this.reportType,
    required this.recordId,
    required this.title,
    required this.subtitle,
    this.shipmentRow,
    this.courierRow,
    this.customerRow,
    this.paymentRow,
    this.trackingHistory = const [],
    this.deliveryProofs = const [],
    this.locationLogs = const [],
    this.relatedShipments = const [],
  });

  @override
  List<Object?> get props => [
        reportType,
        recordId,
        title,
        subtitle,
        shipmentRow,
        courierRow,
        customerRow,
        paymentRow,
        trackingHistory,
        deliveryProofs,
        locationLogs,
        relatedShipments,
      ];
}

