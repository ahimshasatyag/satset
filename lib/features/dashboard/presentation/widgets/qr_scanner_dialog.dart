import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class QRScannerDialog extends StatefulWidget {
  const QRScannerDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const QRScannerDialog(),
    );
  }

  @override
  State<QRScannerDialog> createState() => _QRScannerDialogState();
}

class _QRScannerDialogState extends State<QRScannerDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  void _selectCode(String code) {
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanSize = (size.width * 0.70).clamp(240.0, 320.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF101924),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Dialog
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Pindai Nomor Resi',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Viewfinder Kamera Scanner
            Container(
              width: scanSize,
              height: scanSize,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12, width: 1.5),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Sudut-sudut bidik kamera (Corner borders)
                  ..._buildCorners(),

                  // Garis Laser Animasi
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: scanSize * _laserAnimation.value,
                        left: 20,
                        right: 20,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.primary,
                                AppColors.secondary,
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Teks panduan
                  Positioned(
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Arahkan kamera ke Barcode / QR Resi',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // Tombol Senter (Flashlight)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isFlashOn = !_isFlashOn;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isFlashOn
                              ? AppColors.secondary
                              : Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFlashOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Cepat Resi Simulasi (Untuk Pengujian Instan)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Atau pilih sampel resi untuk diuji:',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickResiChip('SS-98214-ID', 'Aktif (Instant)'),
                _buildQuickResiChip('SS-76219-ID', 'Selesai (Nike)'),
                _buildQuickResiChip('SS-31089-ID', 'Pending (Dokumen)'),
              ],
            ),
            const SizedBox(height: 16),

            CustomButton(
              text: 'Tutup Pemindai',
              variant: ButtonVariant.outlined,
              isFullWidth: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickResiChip(String code, String label) {
    return InkWell(
      onTap: () => _selectCode(code),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code, color: AppColors.secondary, size: 14),
            const SizedBox(width: 6),
            Text(
              code,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '($label)',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCorners() {
    const double length = 22.0;
    const double thickness = 3.5;
    const Color cornerColor = AppColors.secondary;

    return [
      // Top Left
      const Positioned(
        top: 14,
        left: 14,
        child: SizedBox(
          width: length,
          height: length,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: cornerColor, width: thickness),
                left: BorderSide(color: cornerColor, width: thickness),
              ),
            ),
          ),
        ),
      ),
      // Top Right
      const Positioned(
        top: 14,
        right: 14,
        child: SizedBox(
          width: length,
          height: length,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: cornerColor, width: thickness),
                right: BorderSide(color: cornerColor, width: thickness),
              ),
            ),
          ),
        ),
      ),
      // Bottom Left
      const Positioned(
        bottom: 14,
        left: 14,
        child: SizedBox(
          width: length,
          height: length,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cornerColor, width: thickness),
                left: BorderSide(color: cornerColor, width: thickness),
              ),
            ),
          ),
        ),
      ),
      // Bottom Right
      const Positioned(
        bottom: 14,
        right: 14,
        child: SizedBox(
          width: length,
          height: length,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cornerColor, width: thickness),
                right: BorderSide(color: cornerColor, width: thickness),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}
