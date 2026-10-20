import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import '../../domain/entities/live_track_shipment.dart';

class LiveTrackMap extends StatelessWidget {
  final bool isDark;
  final double pulseValue;
  final double zoomScale;
  final List<LiveTrackShipment> shipments;
  final int selectedIndex;
  final ValueChanged<int> onShipmentTapped;

  const LiveTrackMap({
    super.key,
    required this.isDark,
    required this.pulseValue,
    required this.zoomScale,
    required this.shipments,
    required this.selectedIndex,
    required this.onShipmentTapped,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapUp: (details) {
            _handleTap(details.localPosition, constraints.biggest);
          },
          child: Transform.scale(
            scale: zoomScale,
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _FullScreenMapPainter(
                isDark: isDark,
                pulseValue: pulseValue,
                shipments: shipments,
                selectedIndex: selectedIndex,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(Offset tapPos, Size size) {
    if (shipments.isEmpty) return;

    int? closestIndex;
    double minDistance = 45.0; // Radius toleransi sentuhan dalam pixel

    for (int i = 0; i < shipments.length; i++) {
      final s = shipments[i];
      final normX = (s.longitude - 106.75) / (106.88 - 106.75);
      final normY = (s.latitude - -6.30) / (-6.15 - -6.30);
      final x = (normX.clamp(0.15, 0.85)) * size.width;
      final y = (1.0 - normY.clamp(0.15, 0.85)) * size.height;

      final dist = (Offset(x, y) - tapPos).distance;
      if (dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }

    if (closestIndex != null) {
      onShipmentTapped(closestIndex);
    }
  }
}

class _FullScreenMapPainter extends CustomPainter {
  final bool isDark;
  final double pulseValue;
  final List<LiveTrackShipment> shipments;
  final int selectedIndex;

  _FullScreenMapPainter({
    required this.isDark,
    required this.pulseValue,
    required this.shipments,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 1. Latar Belakang Peta (Dark / Light)
    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF101924) : const Color(0xFFE5ECF4);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    // 2. Ruang Terbuka Hijau & Taman Kota
    final greenPaint = Paint()
      ..color = isDark ? const Color(0xFF14241F) : const Color(0xFFD6EADA);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(width * 0.1, height * 0.15, width * 0.35, height * 0.25),
        const Radius.circular(16),
      ),
      greenPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(width * 0.55, height * 0.5, width * 0.38, height * 0.28),
        const Radius.circular(16),
      ),
      greenPaint,
    );

    // 3. Saluran Air / Sungai
    final waterPaint = Paint()
      ..color = isDark ? const Color(0xFF132235) : const Color(0xFFCFE2F4)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    final riverPath = Path()
      ..moveTo(width * 0.8, 0)
      ..quadraticBezierTo(width * 0.7, height * 0.45, width * 0.95, height);
    canvas.drawPath(riverPath, waterPaint);

    // 4. Jaringan Jalan Arteri & Sekunder
    final roadPaint = Paint()
      ..color = isDark ? const Color(0xFF1D2C3F) : const Color(0xFFD8E1EC)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
        Offset(0, height * 0.35), Offset(width, height * 0.35), roadPaint);
    canvas.drawLine(
        Offset(0, height * 0.65), Offset(width, height * 0.65), roadPaint);
    canvas.drawLine(
        Offset(width * 0.45, 0), Offset(width * 0.45, height), roadPaint);

    // 5. Jalan Bebas Hambatan (Highway Utama)
    final mainRoad = Path()
      ..moveTo(0, height * 0.8)
      ..cubicTo(
        width * 0.3,
        height * 0.75,
        width * 0.7,
        height * 0.25,
        width,
        height * 0.2,
      );
    final mainRoadPaint = Paint()
      ..color = isDark ? const Color(0xFF26384E) : const Color(0xFFC7D3E2)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    canvas.drawPath(mainRoad, mainRoadPaint);

    // Garis Tengah Putus-putus Highway
    final dashRoadPaint = Paint()
      ..color = isDark ? const Color(0xFF384F6C) : const Color(0xFFFFFFFF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(mainRoad, dashRoadPaint);

    // 6. Gambar Titik Kurir Live di Peta
    for (int i = 0; i < shipments.length; i++) {
      final order = shipments[i];
      final normX = (order.longitude - 106.75) / (106.88 - 106.75);
      final normY = (order.latitude - -6.30) / (-6.15 - -6.30);
      final x = (normX.clamp(0.15, 0.85)) * width;
      final y = (1.0 - normY.clamp(0.15, 0.85)) * height;
      final pos = Offset(x, y);

      final isSelected = i == selectedIndex;

      // Efek Radar Berdenyut (Pulse Waves)
      final radarRadius = 16.0 + (pulseValue * 20.0);
      final radarPaint = Paint()
        ..color = (isSelected ? AppColors.primary : AppColors.secondary)
            .withValues(alpha: (1.0 - pulseValue).clamp(0.0, 0.8))
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.8;
      canvas.drawCircle(pos, radarRadius, radarPaint);

      // Pin Lingkaran Kurir
      final pinPaint = Paint()
        ..color = isSelected ? AppColors.primary : AppColors.secondary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, isSelected ? 16 : 12, pinPaint);

      // Border Pin Kurir
      canvas.drawCircle(
        pos,
        isSelected ? 16 : 12,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      // Titik Pusat Pin
      canvas.drawCircle(pos, 4, Paint()..color = Colors.white);

      // Label ETA Kurir Mengambang di Atas Pin
      final tp = TextPainter(
        text: TextSpan(
          text: order.etaMinutes > 0 ? '${order.etaMinutes}m' : 'Tiba',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelBg = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(pos.dx, pos.dy - 24),
          width: tp.width + 12,
          height: tp.height + 6,
        ),
        const Radius.circular(6),
      );

      canvas.drawRRect(
        labelBg,
        Paint()
          ..color = isSelected
              ? AppColors.primary
              : const Color(0xFF1B2A3D).withValues(alpha: 0.9),
      );
      tp.paint(
        canvas,
        Offset(pos.dx - (tp.width / 2), pos.dy - 24 - (tp.height / 2)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FullScreenMapPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.shipments != shipments ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.isDark != isDark;
  }
}
