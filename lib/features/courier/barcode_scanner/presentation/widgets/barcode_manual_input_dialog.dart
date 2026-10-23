import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

/// Dialog untuk memasukkan nomor barcode atau nomor resi secara manual
class BarcodeManualInputDialog extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  final List<String> recentCodes;

  const BarcodeManualInputDialog({
    super.key,
    required this.onSubmit,
    this.recentCodes = const [],
  });

  /// Menampilkan dialog input manual barcode secara modal
  static Future<String?> show(
    BuildContext context, {
    List<String> recentCodes = const [],
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BarcodeManualInputDialog(
        recentCodes: recentCodes,
        onSubmit: (code) => Navigator.of(ctx).pop(code),
      ),
    );
  }

  @override
  State<BarcodeManualInputDialog> createState() => _BarcodeManualInputDialogState();
}

class _BarcodeManualInputDialogState extends State<BarcodeManualInputDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _validationError = 'Nomor barcode atau resi tidak boleh kosong';
      });
      return;
    }
    widget.onSubmit(text);
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      setState(() {
        _controller.text = data.text!.trim().toUpperCase();
        _validationError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Judul
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.qr_code_2_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Input Barcode Manual',
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Ketik nomor resi atau barcode pada label paket',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Field Input
            CustomTextField(
              controller: _controller,
              label: 'Nomor Barcode / Nomor Resi',
              hintText: 'Contoh: SST-20261023-001',
              autofocus: true,
              errorText: _validationError,
              prefixIcon: Icon(
                Icons.barcode_reader,
                color: colorScheme.primary,
              ),
              suffixIcon: IconButton(
                tooltip: 'Tempel dari Clipboard',
                icon: const Icon(Icons.content_paste_rounded),
                onPressed: _pasteFromClipboard,
              ),
              inputFormatters: [
                UpperCaseTextFormatter(),
              ],
              onSubmitted: (_) => _handleSubmit(),
              onChanged: (_) {
                if (_validationError != null) {
                  setState(() => _validationError = null);
                }
              },
            ),
            const SizedBox(height: 12),

            // Opsi Riwayat Barcode Sesi Terkini
            if (widget.recentCodes.isNotEmpty) ...[
              Text(
                'Terakhir dipindai sesi ini:',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: widget.recentCodes.take(4).map((code) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(code, style: AppTextStyles.labelSmall),
                        avatar: const Icon(Icons.history, size: 14),
                        onPressed: () {
                          _controller.text = code;
                          setState(() => _validationError = null);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 8),

            // Tombol Aksi
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Batal',
                    variant: ButtonVariant.outlined,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Cari Paket',
                    variant: ButtonVariant.primary,
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    onPressed: _handleSubmit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Formatter huruf besar otomatis
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
