import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';
import '../../domain/entities/scanned_shipment.dart';

/// Card interaktif konfirmasi identitas paket hasil pemindaian dan
/// aksi alur operasional kurir.
class ScannedPackageDetailCard extends StatefulWidget {
  final ScannedShipment shipment;
  final bool isProcessing;
  final bool actionSuccess;
  final String? successMessage;
  final void Function({required String newStatusCode, String? notes}) onConfirmAction;
  final VoidCallback onScanNext;
  final VoidCallback? onOpenTaskDetail;

  const ScannedPackageDetailCard({
    super.key,
    required this.shipment,
    required this.isProcessing,
    required this.actionSuccess,
    this.successMessage,
    required this.onConfirmAction,
    required this.onScanNext,
    this.onOpenTaskDetail,
  });

  @override
  State<ScannedPackageDetailCard> createState() => _ScannedPackageDetailCardState();
}

class _ScannedPackageDetailCardState extends State<ScannedPackageDetailCard> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  BadgeStatus _mapStatusToBadge(String statusCode) {
    switch (statusCode.toUpperCase()) {
      case 'DELIVERED':
        return BadgeStatus.success;
      case 'PICKED_UP':
      case 'OUT_FOR_DELIVERY':
      case 'IN_TRANSIT':
        return BadgeStatus.warning;
      case 'FAILED_DELIVERY':
      case 'CANCELLED':
        return BadgeStatus.error;
      default:
        return BadgeStatus.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shipment = widget.shipment;

    final recommendedCode = shipment.recommendedActionStatusCode;
    final recommendedLabel = shipment.recommendedActionLabel;
    final canPerformAction = shipment.isStatusPermittedForAction &&
        recommendedCode != null &&
        !widget.actionSuccess;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Banner Sukses Tindakan jika aksi telah selesai
                  if (widget.actionSuccess) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Proses Berhasil',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.successMessage ?? 'Status paket telah berhasil diperbarui.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 2. Baris Header: Nomor Resi, Barcode & Badges
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.inventory_2_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    shipment.trackingNumber,
                                    style: AppTextStyles.titleLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Barcode: ${shipment.barcodeValue}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Badge
                      StatusBadge(
                        label: shipment.statusName,
                        status: _mapStatusToBadge(shipment.statusCode),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Ringkasan Detail Pengiriman (Card Rapi)
                  CustomCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Label Jenis Proses
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  shipment.processType == BarcodeScanProcessType.pickup
                                      ? Icons.call_received_rounded
                                      : Icons.local_shipping_rounded,
                                  size: 16,
                                  color: colorScheme.secondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  shipment.processTypeLabel,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${shipment.serviceTypeName} • ${shipment.formattedWeight}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),

                        // Pihak Target (Pengirim/Penerima)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.person_pin_circle_rounded,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${shipment.contextPersonRoleLabel}: ${shipment.contextPersonName}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    shipment.contextPersonPhone,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${shipment.contextAddress}, ${shipment.contextCity}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: colorScheme.onSurface.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Catatan paket jika ada
                        if (shipment.notes != null && shipment.notes!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  size: 14,
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Catatan: ${shipment.notes}',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: colorScheme.onSurface.withOpacity(0.75),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Catatan Operasional Kurir (Input opsional sebelum konfirmasi)
                  if (canPerformAction) ...[
                    CustomTextField(
                      controller: _notesController,
                      label: 'Catatan Operasional (Opsional)',
                      hintText: 'Mis: Diterima oleh pemilik / Paket dititipkan',
                      prefixIcon: const Icon(Icons.edit_note_rounded),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 5. Tombol Aksi Utama Operasional
                  if (canPerformAction)
                    CustomButton(
                      text: recommendedLabel ?? 'Konfirmasi Status',
                      variant: ButtonVariant.primary,
                      size: ButtonSize.large,
                      isLoading: widget.isProcessing,
                      prefixIcon: const Icon(Icons.check_circle_outline_rounded),
                      onPressed: () {
                        widget.onConfirmAction(
                          newStatusCode: recommendedCode,
                          notes: _notesController.text.trim().isNotEmpty
                              ? _notesController.text.trim()
                              : null,
                        );
                      },
                    ),

                  if (canPerformAction) const SizedBox(height: 12),

                  // 6. Tombol Aksi Sekunder: Pindai Paket Berikutnya & Buka Tugas
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Pindai Berikutnya',
                          variant: canPerformAction
                              ? ButtonVariant.outlined
                              : ButtonVariant.primary,
                          size: ButtonSize.medium,
                          prefixIcon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                          onPressed: widget.onScanNext,
                        ),
                      ),
                      if (widget.onOpenTaskDetail != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Detail Tugas',
                            variant: ButtonVariant.secondary,
                            size: ButtonSize.medium,
                            prefixIcon: const Icon(Icons.assignment_outlined, size: 18),
                            onPressed: widget.onOpenTaskDetail,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
