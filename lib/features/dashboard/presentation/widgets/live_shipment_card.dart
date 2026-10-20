import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/shipment.dart';
import 'courier_contact_sheet.dart';
import 'mini_map_canvas.dart';

class LiveShipmentCard extends StatelessWidget {
  final Shipment shipment;
  final VoidCallback? onLiveTrackTap;

  const LiveShipmentCard({
    super.key,
    required this.shipment,
    this.onLiveTrackTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            // 1. Header Kartu: Layanan, No Resi, dan ETA Dinamis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const StatusBadge.satset(
                          label: 'SATSET INSTANT',
                          showDot: true,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.backgroundDark
                                : AppColors.tertiary50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            shipment.trackingNumber,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.tertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      shipment.itemName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                // ETA Dinamis Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        shipment.etaDisplay,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. Pratinjau Peta Interaktif (Mini-Map)
            MiniMapCanvas(
              shipment: shipment,
              height: 190,
              onFullScreenTap: onLiveTrackTap,
            ),
            const SizedBox(height: 18),

            // 3. Indikator Tahapan Pengiriman (Progress Stepper)
            _buildProgressStepper(context, shipment),
            const SizedBox(height: 18),

            const Divider(),
            const SizedBox(height: 12),

            // 4. Bar Kurir & Tombol Pintas Komunikasi (Telepon & Chat)
            if (shipment.courier != null)
              _buildCourierSection(context, shipment.courier!, isDark),
          ],
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
      {'title': 'Out for Delivery', 'subtitle': 'Mendekat'},
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
              shipment.status.label,
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
                  // Dot Stepper
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
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
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : (isCurrent
                                  ? const Icon(
                                      Icons.radio_button_checked,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black45,
                                      ),
                                    )),
                        ),
                      ),
                      const SizedBox(height: 6),
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

                  // Garis Penghubung antar step
                  if (index < steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
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
        // Avatar Kurir
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Container(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              child: const Center(
                child: Icon(
                  Icons.sports_motorsports_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Info Nama & Kendaraan Kurir
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      courier.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.star_rounded,
                      color: AppColors.secondary, size: 14),
                  Text(
                    '${courier.rating}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${courier.vehiclePlate} • Kurir SatSet',
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

        // Tombol Pintas: Telepon
        InkWell(
          onTap: () {
            CourierContactSheet.show(context, courier: courier, isChat: false);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.phone_in_talk_rounded,
                    color: AppColors.success, size: 16),
                SizedBox(width: 4),
                Text(
                  'Telepon',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Tombol Pintas: Chat
        InkWell(
          onTap: () {
            CourierContactSheet.show(context, courier: courier, isChat: true);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 15),
                SizedBox(width: 4),
                Text(
                  'Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
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
