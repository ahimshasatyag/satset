import 'package:equatable/equatable.dart';

/// Kategori Tab Pengelompokan Pengiriman pada Halaman Delivery Management Admin
class AdminDeliveryTab {
  AdminDeliveryTab._();

  static const String all = 'ALL';
  static const String waitingConfirmation = 'WAITING_CONFIRMATION';
  static const String waitingAssignment = 'WAITING_ASSIGNMENT';
  static const String inProcess = 'IN_PROCESS';
  static const String outForDelivery = 'OUT_FOR_DELIVERY';
  static const String delivered = 'DELIVERED';
  static const String failed = 'FAILED';
  static const String cancelled = 'CANCELLED';

  static const List<Map<String, String>> tabs = [
    {'key': all, 'label': 'Semua'},
    {'key': waitingConfirmation, 'label': 'Menunggu Konfirmasi'},
    {'key': waitingAssignment, 'label': 'Menunggu Penugasan'},
    {'key': inProcess, 'label': 'Dalam Proses'},
    {'key': outForDelivery, 'label': 'Dalam Pengantaran'},
    {'key': delivered, 'label': 'Berhasil'},
    {'key': failed, 'label': 'Gagal'},
    {'key': cancelled, 'label': 'Dibatalkan'},
  ];
}

/// Entitas baris tabel pengiriman pada halaman Delivery Management Admin
class AdminDeliveryItem extends Equatable {
  final int id;
  final String nomorResi;
  final String barcodeValue;
  final int? customerId;
  final String customerNama;
  final String customerEmail;
  final String pengirimNama;
  final String pengirimNoHp;
  final String pengirimAlamat;
  final String pengirimKota;
  final String penerimaNama;
  final String penerimaNoHp;
  final String penerimaAlamat;
  final String penerimaKota;
  final int? serviceTypeId;
  final String serviceKode;
  final String serviceNama;
  final num totalBeratGram;
  final num biayaPengiriman;
  final num totalBiaya;
  final String metodePembayaran;
  final String statusPembayaran;
  final int? courierId;
  final String courierNama;
  final String? courierCode;
  final String? courierNoHp;
  final int? activeAssignmentId;
  final int? statusId;
  final String statusKode;
  final String statusNama;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminDeliveryItem({
    required this.id,
    required this.nomorResi,
    required this.barcodeValue,
    this.customerId,
    required this.customerNama,
    required this.customerEmail,
    required this.pengirimNama,
    required this.pengirimNoHp,
    required this.pengirimAlamat,
    required this.pengirimKota,
    required this.penerimaNama,
    required this.penerimaNoHp,
    required this.penerimaAlamat,
    required this.penerimaKota,
    this.serviceTypeId,
    required this.serviceKode,
    required this.serviceNama,
    required this.totalBeratGram,
    required this.biayaPengiriman,
    required this.totalBiaya,
    required this.metodePembayaran,
    required this.statusPembayaran,
    this.courierId,
    required this.courierNama,
    this.courierCode,
    this.courierNoHp,
    this.activeAssignmentId,
    this.statusId,
    required this.statusKode,
    required this.statusNama,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasCourierAssigned => courierId != null && courierId! > 0;

  bool get isWaitingConfirmation => statusKode.toUpperCase() == 'PENDING';

  bool get isFailedDelivery =>
      statusKode.toUpperCase() == 'FAILED_DELIVERY' ||
      statusKode.toUpperCase() == 'RETURNED';

  bool get isTerminalStatus =>
      statusKode.toUpperCase() == 'DELIVERED' ||
      statusKode.toUpperCase() == 'CANCELLED';

  @override
  List<Object?> get props => [
        id,
        nomorResi,
        barcodeValue,
        customerId,
        customerNama,
        customerEmail,
        pengirimNama,
        pengirimNoHp,
        pengirimAlamat,
        pengirimKota,
        penerimaNama,
        penerimaNoHp,
        penerimaAlamat,
        penerimaKota,
        serviceTypeId,
        serviceKode,
        serviceNama,
        totalBeratGram,
        biayaPengiriman,
        totalBiaya,
        metodePembayaran,
        statusPembayaran,
        courierId,
        courierNama,
        courierCode,
        courierNoHp,
        activeAssignmentId,
        statusId,
        statusKode,
        statusNama,
        createdAt,
        updatedAt,
      ];
}

/// Hasil paginasi beserta ringkasan jumlah per tab status pengiriman
class AdminDeliveriesPaginatedResult extends Equatable {
  final List<AdminDeliveryItem> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final Map<String, int> tabCounts;

  const AdminDeliveriesPaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    this.tabCounts = const {},
  });

  static const empty = AdminDeliveriesPaginatedResult(
    items: [],
    totalCount: 0,
    currentPage: 1,
    pageSize: 10,
    totalPages: 1,
    tabCounts: {
      AdminDeliveryTab.all: 0,
      AdminDeliveryTab.waitingConfirmation: 0,
      AdminDeliveryTab.waitingAssignment: 0,
      AdminDeliveryTab.inProcess: 0,
      AdminDeliveryTab.outForDelivery: 0,
      AdminDeliveryTab.delivered: 0,
      AdminDeliveryTab.failed: 0,
      AdminDeliveryTab.cancelled: 0,
    },
  );

  @override
  List<Object?> get props => [
        items,
        totalCount,
        currentPage,
        pageSize,
        totalPages,
        tabCounts,
      ];
}

