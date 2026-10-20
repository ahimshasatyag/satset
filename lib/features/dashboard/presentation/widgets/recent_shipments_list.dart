import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/shipment.dart';

class RecentShipmentsList extends StatelessWidget {
  final List<Shipment> shipments;
  final Function(Shipment shipment)? onShipmentTap;
  final VoidCallback? onSeeAllTap;

  const RecentShipmentsList({
    super.key,
    required this.shipments,
    this.onShipmentTap,
    this.onSeeAllTap,
  });

  void _showDetailSheet(BuildContext context, Shipment shipment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    shipment.trackingNumber,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primary,
                    ),
                  ),
                  _buildStatusBadge(shipment.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                shipment.itemName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Layanan: ${shipment.serviceType} • Kategori: ${shipment.itemCategory}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _buildLocationRow(
                icon: Icons.storefront_rounded,
                label: 'Asal',
                address: '${shipment.origin.name}, ${shipment.origin.city}',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildLocationRow(
                icon: Icons.location_on_rounded,
                label: 'Tujuan',
                address: '${shipment.destination.name}, ${shipment.destination.city}',
                isDark: isDark,
                iconColor: AppColors.primary,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Tutup Detail',
                isFullWidth: true,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String label,
    required String address,
    required bool isDark,
    Color? iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor ?? AppColors.secondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
              ),
              Text(
                address,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildStatusBadge(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.delivered:
        return const StatusBadge.success(label: 'Terkirim');
      case ShipmentStatus.pending:
        return const StatusBadge(
          label: 'Menunggu',
          status: BadgeStatus.warning,
        );
      case ShipmentStatus.outForDelivery:
        return const StatusBadge.satset(label: 'Di Antar Kurir');
      case ShipmentStatus.inTransit:
        return const StatusBadge(
          label: 'Dalam Perjalanan',
          status: BadgeStatus.info,
        );
      case ShipmentStatus.pickedUp:
        return const StatusBadge(
          label: 'Dijemput',
          status: BadgeStatus.info,
        );
      case ShipmentStatus.cancelled:
        return const StatusBadge(
          label: 'Dibatalkan',
          status: BadgeStatus.error,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    'Riwayat Pengiriman',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onSeeAllTap ?? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Menampilkan seluruh riwayat pengiriman'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
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
              child: const Text('Belum ada riwayat pengiriman.'),
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
                      _showDetailSheet(context, item);
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
                    child: Row(
                      children: [
                        // Icon Box Paket
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: item.status == ShipmentStatus.delivered
                                ? AppColors.success.withValues(alpha: 0.12)
                                : AppColors.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.status == ShipmentStatus.delivered
                                ? Icons.task_alt_rounded
                                : Icons.inventory_2_rounded,
                            color: item.status == ShipmentStatus.delivered
                                ? AppColors.success
                                : AppColors.secondary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Nama Paket, No Resi, Tujuan
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.itemName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Text(
                                    item.trackingNumber,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '• ${item.destination.city}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark
                                          ? AppColors.textMutedDark
                                          : AppColors.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Status Badge
                        _buildStatusBadge(item.status),
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
}
