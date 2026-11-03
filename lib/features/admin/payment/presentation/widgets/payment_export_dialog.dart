import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_payment_item.dart';

class PaymentExportDialog extends StatelessWidget {
  final AdminPaymentsPaginatedResult paymentsResult;

  const PaymentExportDialog({
    super.key,
    required this.paymentsResult,
  });

  String _generateCsvContent() {
    final buffer = StringBuffer();
    buffer.writeln(
      'ID_Pembayaran,Nomor_Pembayaran,Nomor_Resi,Nama_Customer,Email_Customer,Layanan,Metode_Pembayaran,Bank_Provider,Referensi_Gateway,Tagihan_Shipment,Jumlah_Bayar,Status_Pembayaran,Waktu_Transaksi,Waktu_Lunas',
    );
    for (final item in paymentsResult.items) {
      final cleanName = item.customerNama.replaceAll(',', ' ');
      final cleanProvider =
          (item.namaJenisBank ?? item.provider ?? '-').replaceAll(',', ' ');
      final cleanRef = (item.providerReference ?? '-').replaceAll(',', ' ');
      final createdStr = AdminDateFormatter.formatDateTime(item.createdAt);
      final paidStr =
          item.paidAt != null ? AdminDateFormatter.formatDateTime(item.paidAt) : '-';

      buffer.writeln(
        '${item.id},${item.nomorPembayaran},${item.nomorResi},$cleanName,${item.customerEmail},${item.serviceNama},${item.metodePembayaran},$cleanProvider,$cleanRef,${item.totalBiayaShipment},${item.jumlahBayar},${item.normalizedStatus},$createdStr,$paidStr',
      );
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final csvText = _generateCsvContent();
    final stats = paymentsResult.summaryStats;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Ekspor Laporan Transaksi Pembayaran (CSV)',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ringkasan Total: ${stats.totalTransactions} transaksi (${AdminCurrencyFormatter.formatRupiah(stats.totalAmount)}) • Lunas: ${stats.paidCount} (${AdminCurrencyFormatter.formatRupiah(stats.paidAmount)}) • COD: ${stats.codTotalCount} (${AdminCurrencyFormatter.formatRupiah(stats.codTotalAmount)})',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      csvText,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: csvText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Data laporan CSV pembayaran berhasil disalin ke clipboard.',
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.copy_all_rounded, size: 17),
                    label: const Text('Salin CSV ke Clipboard'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

