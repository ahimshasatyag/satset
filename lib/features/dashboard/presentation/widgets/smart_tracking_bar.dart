import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import 'qr_scanner_dialog.dart';

class SmartTrackingBar extends StatefulWidget {
  final Function(String trackingNumber) onTrack;
  final bool isLoading;

  const SmartTrackingBar({
    super.key,
    required this.onTrack,
    this.isLoading = false,
  });

  @override
  State<SmartTrackingBar> createState() => _SmartTrackingBarState();
}

class _SmartTrackingBarState extends State<SmartTrackingBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) {
      _focusNode.unfocus();
      widget.onTrack(query);
    }
  }

  Future<void> _openScanner() async {
    final scannedCode = await QRScannerDialog.show(context);
    if (scannedCode != null && scannedCode.isNotEmpty && mounted) {
      _controller.text = scannedCode;
      widget.onTrack(scannedCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _focusNode.hasFocus
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: _focusNode.hasFocus ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.25)
                  : AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            // Icon Pencarian
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 6),
              child: Icon(
                Icons.search_rounded,
                color: _focusNode.hasFocus
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight),
                size: 24,
              ),
            ),

            // Input Resi
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.characters,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
                decoration: InputDecoration(
                  hintText: 'Lacak no. resi (cth: SS-98214-ID)',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    fontWeight: FontWeight.normal,
                    letterSpacing: 0,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),

            // Tombol Bersihkan jika ada teks
            if (_hasText)
              IconButton(
                icon: const Icon(Icons.cancel_rounded, size: 20),
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textMutedLight,
                onPressed: () {
                  _controller.clear();
                  setState(() => _hasText = false);
                },
                tooltip: 'Hapus',
              ),

            // Garis pembatas vertikal halus
            Container(
              height: 24,
              width: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              margin: const EdgeInsets.symmetric(horizontal: 4),
            ),

            // Tombol Pemindai Barcode / QR
            IconButton(
              tooltip: 'Pindai Barcode / QR',
              icon: const Icon(
                Icons.qr_code_scanner_rounded,
                color: AppColors.secondary,
                size: 22,
              ),
              onPressed: _openScanner,
            ),

            // Tombol Aksi "Lacak"
            GestureDetector(
              onTap: widget.isLoading ? null : _submit,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                child: widget.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lacak',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
