import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/order_shipment.dart';

class OrderShipmentCard extends StatelessWidget {
  final OrderShipment order;
  final VoidCallback? onCardTap;

  const OrderShipmentCard({
    super.key,
    required this.order,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onCardTap ?? () => _showDetailDialog(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Kartu: Resi & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1B2A3D)
                              : AppColors.tertiary50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.trackingNumber,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.tertiary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.serviceType,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusBadge(order.filterStatus),
                ],
              ),
              const SizedBox(height: 12),

              // Nama Barang & Kategori
              Text(
                order.itemName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Rute Asal -> Tujuan
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${order.originCity}  ➔  ${order.destinationCity}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Baris Bawah: Info Kurir & Status Pengiriman
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        order.filterStatus == OrderFilterStatus.inDelivery
                            ? Icons.delivery_dining_rounded
                            : Icons.schedule_rounded,
                        size: 16,
                        color: order.filterStatus == OrderFilterStatus.inDelivery
                            ? AppColors.primary
                            : AppColors.secondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        order.filterStatus == OrderFilterStatus.inDelivery
                            ? 'ETA: ${order.etaMinutes} Menit'
                            : order.filterStatus.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: order.filterStatus ==
                                  OrderFilterStatus.inDelivery
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B2A3D)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      order.courierVehicle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderFilterStatus status) {
    switch (status) {
      case OrderFilterStatus.waitingPickup:
        return const StatusBadge(
          label: 'Menunggu Jemput',
          status: BadgeStatus.warning,
        );
      case OrderFilterStatus.inDelivery:
        return const StatusBadge.satset(
          label: 'Sedang Diantar',
        );
      case OrderFilterStatus.completed:
        return const StatusBadge.success(
          label: 'Selesai',
        );
      case OrderFilterStatus.all:
        return const StatusBadge(label: 'Semua', status: BadgeStatus.info);
    }
  }

  void _showDetailDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(order.itemName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No. Resi: ${order.trackingNumber}'),
            const SizedBox(height: 4),
            Text('Status: ${order.statusDescription}'),
            const SizedBox(height: 4),
            Text('Kurir: ${order.courierName} (${order.courierVehicle})'),
            const SizedBox(height: 4),
            Text('Pengirim: ${order.senderName}'),
            const SizedBox(height: 4),
            Text('Penerima: ${order.receiverName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
