import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

/// Widget viewfinder kamera scanner dengan animasi pemindaian laser,
/// sudut pandang presisi, kontrol senter, jeda/lanjut, dan input manual.
class BarcodeScannerViewfinder extends StatefulWidget {
  final bool isScanning;
  final bool isTorchOn;
  final bool isCameraAvailable;
  final bool isPermissionGranted;
  final int sessionCount;
  final VoidCallback onToggleScan;
  final VoidCallback onToggleTorch;
  final VoidCallback onManualInputTap;
  final VoidCallback onRetryPermission;
  final VoidCallback onOpenHistory;

  const BarcodeScannerViewfinder({
    super.key,
    required this.isScanning,
    required this.isTorchOn,
    this.isCameraAvailable = true,
    this.isPermissionGranted = true,
    required this.sessionCount,
    required this.onToggleScan,
    required this.onToggleTorch,
    required this.onManualInputTap,
    required this.onRetryPermission,
    required this.onOpenHistory,
  });

  @override
  State<BarcodeScannerViewfinder> createState() => _BarcodeScannerViewfinderState();
}

class _BarcodeScannerViewfinderState extends State<BarcodeScannerViewfinder>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _laserController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.isScanning) {
      _laserController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BarcodeScannerViewfinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _laserController.repeat(reverse: true);
      } else {
        _laserController.stop();
      }
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;

        // Tentukan ukuran kotak jendela pemindaian responsif
        final boxWidth = (totalWidth * 0.78).clamp(240.0, 360.0);
        final boxHeight = (boxWidth * 0.65).clamp(160.0, 240.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. Latar Belakang Viewport Kamera / Simulasi Preview
            Container(
              color: isDark ? colorScheme.surface : AppColors.backgroundDark,
              child: widget.isPermissionGranted && widget.isCameraAvailable
                  ? _buildCameraBackgroundPreview(colorScheme, isDark)
                  : _buildCameraUnavailableFallback(theme, colorScheme),
            ),

            // 2. Masking Overlay Gelap dengan Jendela Transparan
            if (widget.isPermissionGranted && widget.isCameraAvailable)
              CustomPaint(
                painter: _ViewfinderOverlayPainter(
                  boxWidth: boxWidth,
                  boxHeight: boxHeight,
                  overlayColor: Colors.black.withOpacity(0.55),
                  borderColor: colorScheme.primary,
                  isScanning: widget.isScanning,
                ),
              ),

            // 3. Garis Laser Animasi Pemindaian Barcode
            if (widget.isPermissionGranted &&
                widget.isCameraAvailable &&
                widget.isScanning)
              Center(
                child: SizedBox(
                  width: boxWidth - 24,
                  height: boxHeight - 24,
                  child: AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      final topOffset = _laserAnimation.value * (boxHeight - 28);
                      return Stack(
                        children: [
                          Positioned(
                            top: topOffset,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colorScheme.primary.withOpacity(0.1),
                                    colorScheme.primary,
                                    colorScheme.secondary,
                                    colorScheme.primary,
                                    colorScheme.primary.withOpacity(0.1),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),

            // 4. Panduan Teks Posisi Barcode
            if (widget.isPermissionGranted && widget.isCameraAvailable)
              Positioned(
                left: 20,
                right: 20,
                top: (totalHeight / 2) + (boxHeight / 2) + 20,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isScanning
                                ? Icons.qr_code_scanner_rounded
                                : Icons.pause_circle_outline_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.isScanning
                                ? 'Arahkan garis laser ke barcode resi paket'
                                : 'Pemindaian kamera dijeda',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // 5. Bilah Kontrol Atas (Status Sesi & Riwayat)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge jumlah paket yang dipindai sesi ini
                  InkWell(
                    onTap: widget.onOpenHistory,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Sesi Ini: ${widget.sessionCount}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Kontrol Senter (Torch)
                  IconButton.filled(
                    tooltip: widget.isTorchOn ? 'Matikan Senter' : 'Nyalakan Senter',
                    style: IconButton.styleFrom(
                      backgroundColor: widget.isTorchOn
                          ? colorScheme.secondary
                          : Colors.black.withOpacity(0.65),
                      foregroundColor: Colors.white,
                    ),
                    icon: Icon(
                      widget.isTorchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      size: 20,
                    ),
                    onPressed: widget.onToggleTorch,
                  ),
                ],
              ),
            ),

            // 6. Bilah Kontrol Bawah (Mulai/Jeda & Input Manual)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  // Tombol Pause / Resume Pemindaian
                  Expanded(
                    child: CustomButton(
                      text: widget.isScanning ? 'Jeda Kamera' : 'Mulai Pindai',
                      variant: widget.isScanning
                          ? ButtonVariant.outlined
                          : ButtonVariant.primary,
                      size: ButtonSize.medium,
                      prefixIcon: Icon(
                        widget.isScanning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 20,
                      ),
                      onPressed: widget.onToggleScan,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tombol Input Manual Barcode
                  Expanded(
                    child: CustomButton(
                      text: 'Input Manual',
                      variant: ButtonVariant.secondary,
                      size: ButtonSize.medium,
                      prefixIcon: const Icon(
                        Icons.keyboard_alt_rounded,
                        size: 20,
                      ),
                      onPressed: widget.onManualInputTap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Tampilan ilustratif background kamera viewport
  Widget _buildCameraBackgroundPreview(ColorScheme colorScheme, bool isDark) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Pola mesh halus simulasi viewfinder aktif
        Opacity(
          opacity: 0.12,
          child: Center(
            child: Icon(
              Icons.camera_alt_outlined,
              size: 160,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }

  /// Tampilan jika izin ditolak atau kamera tidak tersedia
  Widget _buildCameraUnavailableFallback(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isPermissionDenied = !widget.isPermissionGranted;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPermissionDenied
                  ? Icons.no_photography_rounded
                  : Icons.videocam_off_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              isPermissionDenied
                  ? 'Izin Kamera Diperlukan'
                  : 'Kamera Tidak Tersedia',
              style: AppTextStyles.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isPermissionDenied
                  ? 'Aplikasi membutuhkan akses kamera untuk memindai barcode resi paket kurir.'
                  : 'Modul kamera tidak dapat diakses saat ini. Silakan gunakan tombol input manual di bawah.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isPermissionDenied)
                  CustomButton(
                    text: 'Izinkan Kamera',
                    variant: ButtonVariant.primary,
                    size: ButtonSize.small,
                    onPressed: widget.onRetryPermission,
                  ),
                if (isPermissionDenied) const SizedBox(width: 12),
                CustomButton(
                  text: 'Input Resi Manual',
                  variant: ButtonVariant.secondary,
                  size: ButtonSize.small,
                  onPressed: widget.onManualInputTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter untuk menggambar cut-out kotak scanner dan siku sudut pandang
class _ViewfinderOverlayPainter extends CustomPainter {
  final double boxWidth;
  final double boxHeight;
  final Color overlayColor;
  final Color borderColor;
  final bool isScanning;

  _ViewfinderOverlayPainter({
    required this.boxWidth,
    required this.boxHeight,
    required this.overlayColor,
    required this.borderColor,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = overlayColor;

    final center = Offset(size.width / 2, size.height / 2);
    final scanRect = Rect.fromCenter(
      center: center,
      width: boxWidth,
      height: boxHeight,
    );

    // 1. Gambar latar belakang tembus berlubang (hole cut-out)
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)));

    final cutOutPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      holePath,
    );
    canvas.drawPath(cutOutPath, backgroundPaint);

    // 2. Gambar 4 sudut siku bracket
    final cornerPaint = Paint()
      ..color = isScanning ? borderColor : Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;
    const cornerRadius = 16.0;

    // Top-Left Corner
    final tlPath = Path()
      ..moveTo(scanRect.left, scanRect.top + cornerLength)
      ..lineTo(scanRect.left, scanRect.top + cornerRadius)
      ..arcToPoint(
        Offset(scanRect.left + cornerRadius, scanRect.top),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(scanRect.left + cornerLength, scanRect.top);
    canvas.drawPath(tlPath, cornerPaint);

    // Top-Right Corner
    final trPath = Path()
      ..moveTo(scanRect.right - cornerLength, scanRect.top)
      ..lineTo(scanRect.right - cornerRadius, scanRect.top)
      ..arcToPoint(
        Offset(scanRect.right, scanRect.top + cornerRadius),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(scanRect.right, scanRect.top + cornerLength);
    canvas.drawPath(trPath, cornerPaint);

    // Bottom-Left Corner
    final blPath = Path()
      ..moveTo(scanRect.left, scanRect.bottom - cornerLength)
      ..lineTo(scanRect.left, scanRect.bottom - cornerRadius)
      ..arcToPoint(
        Offset(scanRect.left + cornerRadius, scanRect.bottom),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(scanRect.left + cornerLength, scanRect.bottom);
    canvas.drawPath(blPath, cornerPaint);

    // Bottom-Right Corner
    final brPath = Path()
      ..moveTo(scanRect.right - cornerLength, scanRect.bottom)
      ..lineTo(scanRect.right - cornerRadius, scanRect.bottom)
      ..arcToPoint(
        Offset(scanRect.right, scanRect.bottom - cornerRadius),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(scanRect.right, scanRect.bottom - cornerLength);
    canvas.drawPath(brPath, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderOverlayPainter oldDelegate) {
    return oldDelegate.boxWidth != boxWidth ||
        oldDelegate.boxHeight != boxHeight ||
        oldDelegate.isScanning != isScanning ||
        oldDelegate.borderColor != borderColor;
  }
}
