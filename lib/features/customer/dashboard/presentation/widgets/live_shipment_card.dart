import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';
import '../../domain/entities/shipment.dart';
import 'courier_contact_sheet.dart';
import 'mini_map_canvas.dart';

class LiveShipmentCard extends StatelessWidget {
  final Shipment? shipment;
  final VoidCallback? onLiveTrackTap;
  final VoidCallback? onCreateShipmentTap;
  final Function(Shipment shipment)? onShipmentDetailTap;

  const LiveShipmentCard({
    super.key,
    this.shipment,
    this.onLiveTrackTap,
    this.onCreateShipmentTap,
    this.onShipmentDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Jika tidak ada pengiriman aktif saat ini
    if (shipment == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tidak Ada Pengiriman Aktif',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Saat ini Anda tidak memiliki paket yang sedang dalam penjemputan atau pengantaran.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              if (onCreateShipmentTap != null)
                CustomButton(
                  text: 'Buat Pengiriman Baru',
                  prefixIcon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  onPressed: onCreateShipmentTap,
                ),
            ],
          ),
        ),
      );
    }

    final active = shipment!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: () {
          if (onShipmentDetailTap != null) {
            onShipmentDetailTap!(active);
          }
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Kartu: Layanan, No Resi, dan Estimasi Tiba
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            StatusBadge.satset(
                              label: active.serviceName.toUpperCase(),
                              showDot: true,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.backgroundDark
                                      : AppColors.tertiary50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  active.nomorResi,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.tertiary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Penerima: ${active.penerimaNama} (${active.penerimaKota})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Estimasi Tiba Badge jika tersedia
                  if (active.estimasiTiba != null || active.etaMinutes > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF213C5C), Color(0xFF15273C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.tertiary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                color: AppColors.secondary,
                                size: 14,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'ESTIMASI TIBA',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            active.etaDisplay,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. Pratinjau Peta Interaktif (Mini-Map)
              MiniMapCanvas(
                shipment: active,
                height: 170,
                onFullScreenTap: onLiveTrackTap,
              ),
              const SizedBox(height: 16),

              // 3. Indikator Tahapan Pengiriman (Progress Stepper)
              _buildProgressStepper(context, active),

              // 4. Bar Kurir & Tombol Pintas Komunikasi jika kurir tersedia
              if (active.courier != null) ...[
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 10),
                _buildCourierSection(context, active.courier!, isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStepper(BuildContext context, Shipment shipment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStep = shipment.status.stepIndex;

    final steps = [
      {'title': 'Picked Up', 'subtitle': 'Dijemput'},
      {'title': 'In Transit', 'subtitle': 'Di Jalan'},
      {'title': 'Out for Delivery', 'subtitle': 'Diantar'},
      {'title': 'Delivered', 'subtitle': 'Sampai'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.timeline_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tahapan Pengiriman',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
            Text(
              shipment.statusName,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Stepper Visual
        Row(
          children: List.generate(steps.length, (index) {
            final isCompleted = index < currentStep;
            final isCurrent = index == currentStep;

            return Expanded(
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCurrent
                              ? AppColors.primary
                              : (isCompleted
                                  ? AppColors.success
                                  : (isDark
                                      ? const Color(0xFF1E2D40)
                                      : Colors.grey.shade200)),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.secondary
                                : (isCompleted
                                    ? AppColors.success
                                    : Colors.transparent),
                            width: isCurrent ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check,
                                  size: 13, color: Colors.white)
                              : (isCurrent
                                  ? const Icon(
                                      Icons.radio_button_checked,
                                      size: 13,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                      ),
                                    )),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        steps[index]['title']!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: (isCurrent || isCompleted)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isCurrent
                              ? AppColors.primary
                              : (isCompleted
                                  ? (isDark ? Colors.white70 : Colors.black87)
                                  : (isDark ? Colors.white38 : Colors.black38)),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 2.5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: index < currentStep
                              ? AppColors.success
                              : (isDark ? Colors.white12 : Colors.black12),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCourierSection(
    BuildContext context,
    Courier courier,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          padding: const EdgeInsets.all(2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: const Center(
                child: Icon(
                  Icons.sports_motorsports_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                courier.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${courier.vehiclePlate} • ${courier.vehicleType}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            CourierContactSheet.show(context, courier: courier, isChat: false);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_rounded, color: AppColors.success, size: 15),
                SizedBox(width: 4),
                Text(
                  'Telepon',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
