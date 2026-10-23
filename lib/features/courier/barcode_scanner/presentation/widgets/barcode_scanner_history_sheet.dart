import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

/// Bottom sheet ringkasan daftar barcode paket yang telah dipindai sesi kurir ini
class BarcodeScannerHistorySheet extends StatelessWidget {
  final List<String> recentCodes;
  final ValueChanged<String> onSelectCode;
  final VoidCallback onClearHistory;

  const BarcodeScannerHistorySheet({
    super.key,
    required this.recentCodes,
    required this.onSelectCode,
    required this.onClearHistory,
  });

  static Future<void> show(
    BuildContext context, {
    required List<String> recentCodes,
    required ValueChanged<String> onSelectCode,
    required VoidCallback onClearHistory,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BarcodeScannerHistorySheet(
        recentCodes: recentCodes,
        onSelectCode: (code) {
          Navigator.of(ctx).pop();
          onSelectCode(code);
        },
        onClearHistory: () {
          onClearHistory();
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.65,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history_rounded, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Riwayat Sesi (${recentCodes.length})',
                    style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (recentCodes.isNotEmpty)
                TextButton(
                  onPressed: onClearHistory,
                  child: const Text('Bersihkan'),
                ),
            ],
          ),
          const Divider(),
          if (recentCodes.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 48,
                      color: colorScheme.onSurface.withOpacity(0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada barcode yang dipindai sesi ini',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: recentCodes.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final code = recentCodes[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      code,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Ketuk untuk memeriksa ulang paket',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => onSelectCode(code),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
