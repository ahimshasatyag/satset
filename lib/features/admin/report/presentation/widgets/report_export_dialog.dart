import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_report_filter.dart';
import '../../domain/usecases/export_admin_report_usecase.dart';

class ReportExportDialog extends StatelessWidget {
  final AdminReportExportOutput exportOutput;
  final ValueChanged<AdminReportExportFormat> onFormatChanged;
  final VoidCallback onClose;

  const ReportExportDialog({
    super.key,
    required this.exportOutput,
    required this.onFormatChanged,
    required this.onClose,
  });

  String _formatTitle(AdminReportExportFormat format) {
    switch (format) {
      case AdminReportExportFormat.csv:
        return 'Ekspor Laporan ke CSV (.csv)';
      case AdminReportExportFormat.excel:
        return 'Ekspor Laporan ke Microsoft Excel (.xls)';
      case AdminReportExportFormat.pdf:
        return 'Ekspor Laporan ke Dokumen PDF / Cetak';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.file_download_outlined,
                          size: 22,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatTitle(exportOutput.format),
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              Text(
                                'Nama Berkas: ${exportOutput.fileName}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Pilihan Format
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Format CSV (.csv)'),
                    selected: exportOutput.format == AdminReportExportFormat.csv,
                    onSelected: (_) =>
                        onFormatChanged(AdminReportExportFormat.csv),
                  ),
                  ChoiceChip(
                    label: const Text('Format Excel (.xls)'),
                    selected:
                        exportOutput.format == AdminReportExportFormat.excel,
                    onSelected: (_) =>
                        onFormatChanged(AdminReportExportFormat.excel),
                  ),
                  ChoiceChip(
                    label: const Text('Format PDF / Dokumen Cetak'),
                    selected: exportOutput.format == AdminReportExportFormat.pdf,
                    onSelected: (_) =>
                        onFormatChanged(AdminReportExportFormat.pdf),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.backgroundDark
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Text(
                  exportOutput.summaryHeaderText,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      exportOutput.content,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
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
                    onPressed: onClose,
                    child: const Text('Tutup'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: exportOutput.content),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Konten laporan (${exportOutput.fileName}) berhasil disalin ke clipboard.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      onClose();
                    },
                    icon: const Icon(Icons.copy_all_rounded, size: 17),
                    label: const Text('Salin Isi Laporan'),
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

