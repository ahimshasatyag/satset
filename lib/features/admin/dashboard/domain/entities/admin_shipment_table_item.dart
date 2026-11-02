import 'package:equatable/equatable.dart';

/// Entity item tabel pengiriman terbaru pada dashboard admin
class AdminShipmentTableItem extends Equatable {
  final int id;
  final String nomorResi;
  final String barcodeValue;
  final String pengirimNama;
  final String pengirimKota;
  final String penerimaNama;
  final String penerimaKota;
  final String serviceKode;
  final String serviceNama;
  final String courierNama;
  final String courierCode;
  final String statusKode;
  final String statusNama;
  final num totalBiaya;
  final String metodePembayaran;
  final String statusPembayaran;
  final DateTime createdAt;

  const AdminShipmentTableItem({
    required this.id,
    required this.nomorResi,
    required this.barcodeValue,
    required this.pengirimNama,
    required this.pengirimKota,
    required this.penerimaNama,
    required this.penerimaKota,
    required this.serviceKode,
    required this.serviceNama,
    required this.courierNama,
    required this.courierCode,
    required this.statusKode,
    required this.statusNama,
    required this.totalBiaya,
    required this.metodePembayaran,
    required this.statusPembayaran,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        nomorResi,
        barcodeValue,
        pengirimNama,
        pengirimKota,
        penerimaNama,
        penerimaKota,
        serviceKode,
        serviceNama,
        courierNama,
        courierCode,
        statusKode,
        statusNama,
        totalBiaya,
        metodePembayaran,
        statusPembayaran,
        createdAt,
      ];
}

/// Entity hasil paginasi tabel pengiriman admin
class AdminShipmentsPaginatedResult extends Equatable {
  final List<AdminShipmentTableItem> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final int totalPages;

  const AdminShipmentsPaginatedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
  });

  static const empty = AdminShipmentsPaginatedResult(
    items: [],
    totalCount: 0,
    currentPage: 1,
    pageSize: 10,
    totalPages: 1,
  );

  @override
  List<Object?> get props => [items, totalCount, currentPage, pageSize, totalPages];
}

