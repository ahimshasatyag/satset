import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';
import '../../domain/entities/shipment.dart';
import 'shipment_detail_sheet.dart';

class RecentShipmentsList extends StatelessWidget {
  final List<Shipment> shipments;
  final Function(Shipment shipment)? onShipmentTap;
  final VoidCallback? onSeeAllTap;
  final String? activeFilter;

  const RecentShipmentsList({
    super.key,
    required this.shipments,
    this.onShipmentTap,
    this.onSeeAllTap,
    this.activeFilter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    activeFilter != null
                        ? 'Pengiriman (${_filterLabel(activeFilter!)})'
                        : 'Pengiriman Terbaru',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              if (onSeeAllTap != null)
                TextButton(
                  onPressed: onSeeAllTap,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Daftar Item Riwayat
          if (shipments.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: CustomEmptyState(
                icon: Icons.inventory_2_outlined,
                title: activeFilter != null
                    ? 'Tidak Ada Paket di Kategori Ini'
                    : 'Belum Ada Pengiriman',
                description: activeFilter != null
                    ? 'Tidak ditemukan paket pelanggan dengan status ${_filterLabel(activeFilter!)}.'
                    : 'Anda belum memiliki riwayat pengiriman paket. Tekan "Buat Pengiriman" untuk mulai mengirim!',
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shipments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = shipments[index];
                return InkWell(
                  onTap: () {
                    if (onShipmentTap != null) {
                      onShipmentTap!(item);
                    } else {
                      ShipmentDetailSheet.show(context, item);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // Icon Box Paket
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: item.isDelivered
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : (item.isInTransit
                                        ? AppColors.primary.withValues(alpha: 0.12)
                                        : AppColors.secondary.withValues(alpha: 0.12)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item.isDelivered
                                    ? Icons.task_alt_rounded
                                    : (item.isInTransit
                                        ? Icons.local_shipping_rounded
                                        : Icons.inventory_2_rounded),
                                color: item.isDelivered
                                    ? AppColors.success
                                    : (item.isInTransit
                                        ? AppColors.primary
                                        : AppColors.secondary),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Resi & Nama Penerima
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.nomorResi,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1E2D40)
                                              : Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.serviceName,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Penerima: ${item.penerimaNama} (${item.penerimaKota})',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Status Badge
                            _buildStatusBadge(item),
                          ],
                        ),

                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 8),

                        // Informasi Tanggal Pembuatan & Estimasi Tiba
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 12,
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item.formattedCreatedAt,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight,
                                  ),
                                ),
                              ],
                            ),
                            if (item.estimasiTiba != null)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    size: 12,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Est: ${item.etaDisplay}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              )
                            else if (item.isDelivered)
                              const Text(
                                'Paket Telah Tiba',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  static String _filterLabel(String filter) {
    switch (filter) {
      case 'waiting':
        return 'Menunggu Konfirmasi';
      case 'process':
        return 'Sedang Diproses';
      case 'transit':
        return 'Dalam Perjalanan';
      case 'delivered':
        return 'Telah Terkirim';
      default:
        return filter;
    }
  }

  static Widget _buildStatusBadge(Shipment shipment) {
    if (shipment.isDelivered) {
      return StatusBadge.success(label: shipment.statusName);
    } else if (shipment.isInTransit) {
      return StatusBadge(label: shipment.statusName, status: BadgeStatus.info);
    } else if (shipment.isInProcess) {
      return StatusBadge.satset(label: shipment.statusName);
    } else {
      return StatusBadge(label: shipment.statusName, status: BadgeStatus.warning);
    }
  }
}
