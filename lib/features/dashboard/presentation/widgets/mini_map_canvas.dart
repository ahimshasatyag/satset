import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import '../../domain/entities/shipment.dart';

class MiniMapCanvas extends StatefulWidget {
  final Shipment shipment;
  final double height;
  final VoidCallback? onFullScreenTap;

  const MiniMapCanvas({
    super.key,
    required this.shipment,
    this.height = 200,
    this.onFullScreenTap,
  });

  @override
  State<MiniMapCanvas> createState() => _MiniMapCanvasState();
}

class _MiniMapCanvasState extends State<MiniMapCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  double _zoomScale = 1.0;
  final bool _isNightMode = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    setState(() {
      _zoomScale = (_zoomScale + 0.15).clamp(0.8, 1.6);
    });
  }

  void _zoomOut() {
    setState(() {
      _zoomScale = (_zoomScale - 0.15).clamp(0.8, 1.6);
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomScale = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark || _isNightMode;

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2A) : const Color(0xFFE8EEF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Peta Vektor Kustom Berbasis CustomPainter
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return Transform.scale(
                scale: _zoomScale,
                child: CustomPaint(
                  size: Size(double.infinity, widget.height),
                  painter: _MapGridPainter(
                    isDark: isDark,
                    pulseValue: _pulseController.value,
                    progress: widget.shipment.progressPercentage,
                    courierEtaMinutes: widget.shipment.etaMinutes,
                  ),
                ),
              );
            },
          ),

          // Overlay Kontrol Mini-Map (Kanan Atas)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? Colors.black87 : Colors.white)
                    .withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMapIconButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Perbesar Peta',
                    onTap: _zoomIn,
                    isDark: isDark,
                  ),
                  Container(
                    height: 1,
                    width: 20,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  _buildMapIconButton(
                    icon: Icons.remove_rounded,
                    tooltip: 'Perkecil Peta',
                    onTap: _zoomOut,
                    isDark: isDark,
                  ),
                  Container(
                    height: 1,
                    width: 20,
                    color: isDark ? Colors.white12 : Colors.black12,
                  ),
                  _buildMapIconButton(
                    icon: Icons.my_location_rounded,
                    tooltip: 'Pusatkan ke Kurir',
                    onTap: _resetZoom,
                    isDark: isDark,
                    iconColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // Badge Real-Time GPS (Kiri Atas)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1B2A3D) : Colors.white)
                    .withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulsing green dot
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      return Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success
                                  .withValues(alpha: 1.0 - _pulseController.value),
                              blurRadius: 6 * _pulseController.value,
                              spreadRadius: 2 * _pulseController.value,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'GPS REAL-TIME',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? AppColors.white : AppColors.tertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Speed & Distance Indicator (Kiri Bawah)
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black87 : Colors.white)
                    .withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.speed_rounded,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '38 km/jam • ${widget.shipment.distanceKm} km ke tujuan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tombol Buka Peta Penuh / Live Track (Kanan Bawah)
          if (widget.onFullScreenTap != null)
            Positioned(
              bottom: 10,
              right: 10,
              child: InkWell(
                onTap: widget.onFullScreenTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fullscreen_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Peta Penuh',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
    Color? iconColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            icon,
            size: 16,
            color: iconColor ?? (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  final bool isDark;
  final double pulseValue;
  final double progress;
  final int courierEtaMinutes;

  _MapGridPainter({
    required this.isDark,
    required this.pulseValue,
    required this.progress,
    required this.courierEtaMinutes,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 1. Gambar Blok Taman Hijau Kota
    final parkPaint = Paint()
      ..color = (isDark ? const Color(0xFF172922) : const Color(0xFFD6EADA))
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(width * 0.05, height * 0.1, width * 0.25, height * 0.35),
        const Radius.circular(12),
      ),
      parkPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(width * 0.65, height * 0.55, width * 0.3, height * 0.35),
        const Radius.circular(12),
      ),
      parkPaint,
    );

    // 2. Gambar Jaringan Jalan Utama & Sekunder
    final roadSecondary = Paint()
      ..color = (isDark ? const Color(0xFF1E2D40) : const Color(0xFFDDE3EB))
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke;

    final roadPrimary = Paint()
      ..color = (isDark ? const Color(0xFF25374D) : const Color(0xFFD0D9E4))
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke;

    // Grid jalan
    canvas.drawLine(Offset(0, height * 0.3), Offset(width, height * 0.3), roadSecondary);
    canvas.drawLine(Offset(0, height * 0.7), Offset(width, height * 0.7), roadSecondary);
    canvas.drawLine(Offset(width * 0.3, 0), Offset(width * 0.3, height), roadSecondary);
    canvas.drawLine(Offset(width * 0.75, 0), Offset(width * 0.75, height), roadSecondary);

    // Jalan diagonal utama
    final diagonalPath = Path()
      ..moveTo(0, height * 0.9)
      ..cubicTo(
        width * 0.35,
        height * 0.85,
        width * 0.65,
        height * 0.15,
        width,
        height * 0.1,
      );
    canvas.drawPath(diagonalPath, roadPrimary);

    // 3. Jalur Rute Pengiriman (Delivery Route)
    final origin = Offset(width * 0.15, height * 0.75);
    final destination = Offset(width * 0.82, height * 0.25);

    final routePath = Path()
      ..moveTo(origin.dx, origin.dy)
      ..cubicTo(
        width * 0.35,
        height * 0.70,
        width * 0.45,
        height * 0.35,
        destination.dx,
        destination.dy,
      );

    // Garis Glow rute
    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.25)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, glowPaint);

    // Garis Inti Rute Pengiriman (Gradient Merah ke Oranye)
    final routePaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.tertiary, AppColors.primary, AppColors.secondary],
      ).createShader(Rect.fromPoints(origin, destination))
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(routePath, routePaint);

    // 4. Hitung Posisi Kurir di sepanjang Kurva Rute
    // Menggunakan progress faktor dinamis (e.g. 0.65)
    final courierFactor = progress.clamp(0.15, 0.95);
    final courierX = _bezierValue(origin.dx, width * 0.35, width * 0.45, destination.dx, courierFactor);
    final courierY = _bezierValue(origin.dy, height * 0.70, height * 0.35, destination.dy, courierFactor);
    final courierPos = Offset(courierX, courierY);

    // 5. Marker Origin (Warehouse SatSet)
    final originBg = Paint()
      ..color = AppColors.tertiary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(origin, 9, originBg);
    canvas.drawCircle(
      origin,
      9,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 6. Marker Destination (Rumah Penerima)
    final destBg = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(destination, 11, destBg);
    canvas.drawCircle(
      destination,
      11,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Titik tengah rumah
    canvas.drawCircle(destination, 4, Paint()..color = Colors.white);

    // 7. Marker Kurir Aktif (Real-Time Pulsing Radar)
    final radarRadius = 14.0 + (pulseValue * 16.0);
    final radarOpacity = (1.0 - pulseValue).clamp(0.0, 1.0);
    final radarPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: radarOpacity * 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(courierPos, radarRadius, radarPaint);

    // Badan Pin Kurir
    final courierBg = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.primary, AppColors.secondary],
      ).createShader(Rect.fromCircle(center: courierPos, radius: 14))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(courierPos, 13, courierBg);

    canvas.drawCircle(
      courierPos,
      13,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Titik pusat motor kurir
    canvas.drawCircle(courierPos, 4.5, Paint()..color = Colors.white);

    // 8. Tooltip Mengambang di atas Kurir (ETA)
    final textPainter = TextPainter(
      text: TextSpan(
        text: '⚡ $courierEtaMinutes Min',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(courierPos.dx, courierPos.dy - 24),
        width: textPainter.width + 12,
        height: textPainter.height + 6,
      ),
      const Radius.circular(6),
    );

    final tooltipPaint = Paint()
      ..color = const Color(0xFF1E2D40)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(tooltipRect, tooltipPaint);
    textPainter.paint(
      canvas,
      Offset(
        courierPos.dx - (textPainter.width / 2),
        courierPos.dy - 24 - (textPainter.height / 2),
      ),
    );
  }

  double _bezierValue(double p0, double p1, double p2, double p3, double t) {
    final oneMinusT = 1.0 - t;
    return (math.pow(oneMinusT, 3) * p0) +
        (3 * math.pow(oneMinusT, 2) * t * p1) +
        (3 * oneMinusT * math.pow(t, 2) * p2) +
        (math.pow(t, 3) * p3);
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.courierEtaMinutes != courierEtaMinutes;
  }
}
