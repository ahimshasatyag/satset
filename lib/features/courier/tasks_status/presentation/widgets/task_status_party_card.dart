import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/utils/currency_formatter.dart';
import 'package:satset/shared/widgets/widgets.dart';
import '../../domain/entities/task_status_detail.dart';

class TaskStatusPartyCard extends StatelessWidget {
  final TaskStatusDetail detail;

  const TaskStatusPartyCard({
    super.key,
    required this.detail,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke papan klip'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return CustomCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Pengiriman',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),

          // Pihak Pengirim (Pickup)
          _buildPartySection(
            context: context,
            title: 'Pengirim (Alamat Penjemputan)',
            icon: Icons.storefront_rounded,
            name: detail.senderName,
            phone: detail.senderPhone,
            address: detail.fullSenderAddress,
            textSecondary: textSecondary,
            isDark: isDark,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),

          // Pihak Penerima (Delivery)
          _buildPartySection(
            context: context,
            title: 'Penerima (Alamat Tujuan)',
            icon: Icons.location_on_rounded,
            name: detail.receiverName,
            phone: detail.receiverPhone,
            address: detail.fullReceiverAddress,
            textSecondary: textSecondary,
            isDark: isDark,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),

          // Detail Fisik & Biaya
          Row(
            children: [
              if (detail.totalWeightGram != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Berat',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(detail.totalWeightGram! / 1000).toStringAsFixed(2)} kg',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (detail.shippingCost != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biaya Pengiriman',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.formatRupiah(detail.shippingCost!),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Catatan Tambahan Pengiriman
          if (detail.shippingNotes != null && detail.shippingNotes!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Catatan Khusus:',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail.shippingNotes!.trim(),
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPartySection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String name,
    required String phone,
    required String address,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTextStyles.labelSmall.copyWith(
                color: textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (phone.isNotEmpty && phone != '-')
              InkWell(
                onTap: () => _copyToClipboard(context, phone, 'Nomor HP'),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        phone,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          address,
          style: AppTextStyles.bodyMedium.copyWith(
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}
