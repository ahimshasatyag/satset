import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import '../entities/admin_report_filter.dart';
import '../entities/admin_report_models.dart';

/// Hasil pemformatan dokumen ekspor laporan (CSV, Excel Spreadsheet XML, atau PDF/Dokumen Cetak)
class AdminReportExportOutput {
  final AdminReportExportFormat format;
  final String fileName;
  final String mimeType;
  final String content;
  final String summaryHeaderText;

  const AdminReportExportOutput({
    required this.format,
    required this.fileName,
    required this.mimeType,
    required this.content,
    required this.summaryHeaderText,
  });
}

class ExportAdminReportUseCase {
  const ExportAdminReportUseCase();

  AdminReportExportOutput execute({
    required AdminReportDataResult reportData,
    required AdminReportExportFormat format,
  }) {
    final filter = reportData.appliedFilter;
    final reportTitle = AdminReportType.labelOf(reportData.reportType);
    final timestamp = DateTime.now();
    final dateSlug =
        '${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}';

    final headers = _buildColumns(reportData.reportType);
    final rows = _buildRows(reportData);
    final summaryText = _buildSummaryText(reportData);
    final filterDescription = _buildFilterDescription(filter);

    switch (format) {
      case AdminReportExportFormat.csv:
        return AdminReportExportOutput(
          format: format,
          fileName:
              'SatSet_${reportData.reportType.toLowerCase()}_report_$dateSlug.csv',
          mimeType: 'text/csv;charset=utf-8',
          content: _generateCsv(
            reportTitle: reportTitle,
            filterDescription: filterDescription,
            summaryText: summaryText,
            headers: headers,
            rows: rows,
          ),
          summaryHeaderText: summaryText,
        );
      case AdminReportExportFormat.excel:
        return AdminReportExportOutput(
          format: format,
          fileName:
              'SatSet_${reportData.reportType.toLowerCase()}_report_$dateSlug.xls',
          mimeType: 'application/vnd.ms-excel;charset=utf-8',
          content: _generateExcelXml(
            reportTitle: reportTitle,
            filterDescription: filterDescription,
            summaryText: summaryText,
            headers: headers,
            rows: rows,
          ),
          summaryHeaderText: summaryText,
        );
      case AdminReportExportFormat.pdf:
        return AdminReportExportOutput(
          format: format,
          fileName:
              'SatSet_${reportData.reportType.toLowerCase()}_report_$dateSlug.html',
          mimeType: 'text/html;charset=utf-8',
          content: _generatePrintablePdfDocument(
            reportTitle: reportTitle,
            filterDescription: filterDescription,
            summaryText: summaryText,
            headers: headers,
            rows: rows,
          ),
          summaryHeaderText: summaryText,
        );
    }
  }

  List<String> _buildColumns(String reportType) {
    switch (reportType) {
      case AdminReportType.courier:
        return const [
          'ID_Kurir',
          'Kode_Kurir',
          'Nama_Kurir',
          'Email',
          'No_HP',
          'Status_Akun',
          'Tugas_Diterima',
          'Pengiriman_Berhasil',
          'Tugas_Berjalan',
          'Gagal_Atau_Retur',
          'Persentase_Berhasil',
          'Jumlah_Bukti_Kirim',
          'Log_GPS',
          'Total_COD_Dikelola',
          'Penugasan_Terakhir',
        ];
      case AdminReportType.customer:
        return const [
          'ID_Pelanggan',
          'Nama_Pelanggan',
          'Email',
          'No_HP',
          'Status_Verifikasi',
          'Total_Pengiriman',
          'Pengiriman_Selesai',
          'Pengiriman_Berjalan',
          'Gagal_Atau_Batal',
          'Metode_Dominan',
          'Total_Nilai_Transaksi',
          'Total_Terbayar',
          'Pengiriman_Terakhir',
        ];
      case AdminReportType.payment:
        return const [
          'ID_Pembayaran',
          'Nomor_Pembayaran',
          'Nomor_Resi',
          'Tanggal_Transaksi',
          'Nama_Pelanggan',
          'Jenis_Layanan',
          'Status_Pengiriman',
          'Kurir_Bertugas',
          'Metode_Pembayaran',
          'Status_Pembayaran',
          'Provider_Referensi',
          'Total_Tagihan',
          'Nominal_Dibayar',
          'Waktu_Lunas',
        ];
      case AdminReportType.shipment:
      default:
        return const [
          'ID_Shipment',
          'Nomor_Resi',
          'Tanggal_Transaksi',
          'Nama_Pelanggan',
          'Pengirim',
          'Kota_Asal',
          'Penerima',
          'Kota_Tujuan',
          'Jenis_Layanan',
          'Status_Pengiriman',
          'Kurir_Bertugas',
          'Berat_Gram',
          'Total_Biaya',
          'Metode_Pembayaran',
          'Status_Pembayaran',
        ];
    }
  }

  List<List<String>> _buildRows(AdminReportDataResult data) {
    switch (data.reportType) {
      case AdminReportType.courier:
        return data.allFilteredCourierRows.map((r) {
          return [
            r.courierId.toString(),
            r.employeeCode,
            r.namaLengkap,
            r.email,
            r.noHp,
            r.isActive ? 'AKTIF' : 'NONAKTIF',
            r.totalAssigned.toString(),
            r.deliveredCount.toString(),
            r.inProgressCount.toString(),
            r.failedOrReturnedCount.toString(),
            '${r.completionRate.toStringAsFixed(1)}%',
            r.proofUploadedCount.toString(),
            r.gpsLocationsCount.toString(),
            r.totalCodHandled.toStringAsFixed(0),
            r.lastAssignmentAt != null
                ? AdminDateFormatter.formatDateTime(r.lastAssignmentAt)
                : '-',
          ];
        }).toList();

      case AdminReportType.customer:
        return data.allFilteredCustomerRows.map((r) {
          return [
            r.customerId.toString(),
            r.namaLengkap,
            r.email,
            r.noHp,
            r.emailVerified ? 'TERVERIFIKASI' : 'BELUM_VERIFIKASI',
            r.totalShipments.toString(),
            r.deliveredShipments.toString(),
            r.activeShipments.toString(),
            r.failedOrCancelledShipments.toString(),
            r.preferredPaymentMethod,
            r.totalShippingSpend.toStringAsFixed(0),
            r.paidShippingSpend.toStringAsFixed(0),
            r.lastShipmentAt != null
                ? AdminDateFormatter.formatDateTime(r.lastShipmentAt)
                : '-',
          ];
        }).toList();

      case AdminReportType.payment:
        return data.allFilteredPaymentRows.map((r) {
          return [
            r.paymentId.toString(),
            r.nomorPembayaran,
            r.nomorResi,
            AdminDateFormatter.formatDateTime(r.createdAt),
            r.customerNama,
            '${r.serviceKode} - ${r.serviceNama}',
            r.shipmentStatusNama,
            r.courierNama ?? 'Belum Ditugaskan',
            r.metodePembayaran,
            r.statusPembayaran,
            r.providerReference ?? r.provider ?? '-',
            r.totalBiayaShipment.toStringAsFixed(0),
            r.jumlahBayar.toStringAsFixed(0),
            r.paidAt != null
                ? AdminDateFormatter.formatDateTime(r.paidAt)
                : '-',
          ];
        }).toList();

      case AdminReportType.shipment:
      default:
        return data.allFilteredShipmentRows.map((r) {
          return [
            r.shipmentId.toString(),
            r.nomorResi,
            AdminDateFormatter.formatDateTime(r.createdAt),
            r.customerNama,
            r.pengirimNama,
            r.pengirimKota,
            r.penerimaNama,
            r.penerimaKota,
            '${r.serviceKode} - ${r.serviceNama}',
            r.statusNama,
            r.courierNama ?? 'Belum Ditugaskan',
            r.totalBeratGram.toStringAsFixed(0),
            r.totalBiaya.toStringAsFixed(0),
            r.metodePembayaran,
            r.statusPembayaran,
          ];
        }).toList();
    }
  }

  String _buildSummaryText(AdminReportDataResult data) {
    switch (data.reportType) {
      case AdminReportType.courier:
        final s = data.courierSummary;
        return 'Total Kurir: ${s.totalCouriers} (Aktif: ${s.activeCouriers}) | Tugas Diterima: ${s.totalAssignedTasks} | Berhasil: ${s.deliveredTasks} | Berjalan: ${s.inProgressTasks} | Gagal/Retur: ${s.failedOrReturnedTasks} | Rasio Keberhasilan: ${s.averageSuccessRate.toStringAsFixed(1)}%';
      case AdminReportType.customer:
        final s = data.customerSummary;
        return 'Total Pelanggan: ${s.totalCustomers} (Aktif Bertransaksi: ${s.transactingCustomers}) | Total Pengiriman: ${s.totalShipments} | Selesai: ${s.completedShipments} | Total Nilai Transaksi: ${AdminCurrencyFormatter.formatRupiah(s.totalTransactionValue)}';
      case AdminReportType.payment:
        final s = data.paymentSummary;
        return 'Total Transaksi: ${s.totalTransactions} (${AdminCurrencyFormatter.formatRupiah(s.totalNominal)}) | Transfer Gateway: ${s.transferCount} (${AdminCurrencyFormatter.formatRupiah(s.transferNominal)}) | COD: ${s.codCount} (${AdminCurrencyFormatter.formatRupiah(s.codNominal)}) | Berhasil: ${s.paidCount} | Menunggu: ${s.pendingCount} | Gagal/Kedaluwarsa: ${s.failedCount + s.expiredCount}';
      case AdminReportType.shipment:
      default:
        final s = data.shipmentSummary;
        return 'Total Paket: ${s.totalPackages} | Berhasil Dikirim: ${s.deliveredCount} | Dalam Proses: ${s.inProcessCount} | Gagal: ${s.failedCount} | Dibatalkan: ${s.cancelledCount} | Dikembalikan: ${s.returnedCount} | Total Nilai: ${AdminCurrencyFormatter.formatRupiah(s.totalRevenue)}';
    }
  }

  String _buildFilterDescription(AdminReportFilter filter) {
    final parts = <String>[];
    if (filter.startDate != null || filter.endDate != null) {
      final startStr = filter.startDate != null
          ? AdminDateFormatter.formatShortDate(filter.startDate)
          : 'Awal';
      final endStr = filter.endDate != null
          ? AdminDateFormatter.formatShortDate(filter.endDate)
          : 'Sekarang';
      parts.add('Periode: $startStr s/d $endStr');
    } else {
      parts.add('Periode: Semua Waktu');
    }
    if (filter.shipmentStatusCode != null &&
        filter.shipmentStatusCode!.isNotEmpty &&
        filter.shipmentStatusCode != 'ALL') {
      parts.add('Status Pengiriman: ${filter.shipmentStatusCode}');
    }
    if (filter.serviceTypeCode != null &&
        filter.serviceTypeCode!.isNotEmpty &&
        filter.serviceTypeCode != 'ALL') {
      parts.add('Layanan: ${filter.serviceTypeCode}');
    }
    if (filter.paymentMethod != null &&
        filter.paymentMethod!.isNotEmpty &&
        filter.paymentMethod != 'ALL') {
      parts.add('Metode Bayar: ${filter.paymentMethod}');
    }
    if (filter.paymentStatus != null &&
        filter.paymentStatus!.isNotEmpty &&
        filter.paymentStatus != 'ALL') {
      parts.add('Status Bayar: ${filter.paymentStatus}');
    }
    if (filter.courierId != null) {
      parts.add('ID Kurir: #${filter.courierId}');
    }
    if (filter.searchQuery.trim().isNotEmpty) {
      parts.add('Kata Kunci: "${filter.searchQuery.trim()}"');
    }
    return parts.join(' • ');
  }

  String _escapeCsvField(String input) {
    final cleaned = input.replaceAll('\r', ' ').replaceAll('\n', ' ');
    if (cleaned.contains(',') || cleaned.contains('"')) {
      return '"${cleaned.replaceAll('"', '""')}"';
    }
    return cleaned;
  }

  String _generateCsv({
    required String reportTitle,
    required String filterDescription,
    required String summaryText,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('# SATSET DELIVERY - ${reportTitle.toUpperCase()}');
    buffer.writeln('# Filter: $filterDescription');
    buffer.writeln('# Ringkasan: $summaryText');
    buffer.writeln(headers.map(_escapeCsvField).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_escapeCsvField).join(','));
    }
    return buffer.toString();
  }

  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _generateExcelXml({
    required String reportTitle,
    required String filterDescription,
    required String summaryText,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<?mso-application progid="Excel.Sheet"?>');
    buffer.writeln(
      '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" '
      'xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">',
    );
    buffer.writeln('<Worksheet ss:Name="Laporan SatSet">');
    buffer.writeln('<Table>');

    // Baris Judul
    buffer.writeln(
      '<Row><Cell><Data ss:Type="String">${_escapeXml('SATSET DELIVERY - $reportTitle')}</Data></Cell></Row>',
    );
    buffer.writeln(
      '<Row><Cell><Data ss:Type="String">${_escapeXml('Filter: $filterDescription')}</Data></Cell></Row>',
    );
    buffer.writeln(
      '<Row><Cell><Data ss:Type="String">${_escapeXml('Ringkasan: $summaryText')}</Data></Cell></Row>',
    );
    buffer.writeln('<Row></Row>');

    // Header Kolom
    buffer.write('<Row>');
    for (final h in headers) {
      buffer.write(
        '<Cell><Data ss:Type="String">${_escapeXml(h)}</Data></Cell>',
      );
    }
    buffer.writeln('</Row>');

    // Data Baris
    for (final row in rows) {
      buffer.write('<Row>');
      for (final cell in row) {
        buffer.write(
          '<Cell><Data ss:Type="String">${_escapeXml(cell)}</Data></Cell>',
        );
      }
      buffer.writeln('</Row>');
    }

    buffer.writeln('</Table>');
    buffer.writeln('</Worksheet>');
    buffer.writeln('</Workbook>');
    return buffer.toString();
  }

  String _generatePrintablePdfDocument({
    required String reportTitle,
    required String filterDescription,
    required String summaryText,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    final printedAt = AdminDateFormatter.formatDateTime(DateTime.now());
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="id"><head><meta charset="UTF-8">');
    buffer.writeln('<title>SatSet Delivery - ${_escapeXml(reportTitle)}</title>');
    buffer.writeln('<style>');
    buffer.writeln(
      'body { font-family: Arial, sans-serif; margin: 24px; font-size: 12px; } '
      'h1 { margin: 0 0 4px 0; font-size: 18px; } '
      '.meta { margin-bottom: 12px; font-size: 11px; } '
      '.summary { padding: 10px 12px; border: 1px solid #ccc; margin-bottom: 16px; font-weight: bold; } '
      'table { width: 100%; border-collapse: collapse; font-size: 11px; } '
      'th, td { border: 1px solid #999; padding: 6px 8px; text-align: left; } '
      'th { font-weight: bold; } '
      '@media print { @page { size: landscape; margin: 12mm; } }',
    );
    buffer.writeln('</style></head><body>');
    buffer.writeln('<h1>SATSET DELIVERY - ${_escapeXml(reportTitle.toUpperCase())}</h1>');
    buffer.writeln(
      '<div class="meta">Waktu Cetak: ${_escapeXml(printedAt)} | ${_escapeXml(filterDescription)}</div>',
    );
    buffer.writeln('<div class="summary">${_escapeXml(summaryText)}</div>');
    buffer.writeln('<table><thead><tr>');
    for (final h in headers) {
      buffer.write('<th>${_escapeXml(h.replaceAll('_', ' '))}</th>');
    }
    buffer.writeln('</tr></thead><tbody>');
    for (final row in rows) {
      buffer.write('<tr>');
      for (final cell in row) {
        buffer.write('<td>${_escapeXml(cell)}</td>');
      }
      buffer.writeln('</tr>');
    }
    buffer.writeln('</tbody></table>');
    buffer.writeln('</body></html>');
    return buffer.toString();
  }
}

