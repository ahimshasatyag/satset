import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/repositories/account_repository.dart';
import 'account_address_form_dialog.dart';

class AccountAddressSheet extends StatelessWidget {
  final List<UserAddress> addresses;
  final AccountRepository repository;
  final String defaultReceiverName;
  final String defaultPhone;
  final ValueChanged<UserAddress> onSaveAddress;
  final ValueChanged<String> onDeleteAddress;
  final ValueChanged<String> onSetPrimaryAddress;

  const AccountAddressSheet({
    super.key,
    required this.addresses,
    required this.repository,
    required this.defaultReceiverName,
    required this.defaultPhone,
    required this.onSaveAddress,
    required this.onDeleteAddress,
    required this.onSetPrimaryAddress,
  });

  static Future<void> show(
    BuildContext context, {
    required List<UserAddress> addresses,
    required AccountRepository repository,
    required String defaultReceiverName,
    required String defaultPhone,
    required ValueChanged<UserAddress> onSaveAddress,
    required ValueChanged<String> onDeleteAddress,
    required ValueChanged<String> onSetPrimaryAddress,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AccountAddressSheet(
        addresses: addresses,
        repository: repository,
        defaultReceiverName: defaultReceiverName,
        defaultPhone: defaultPhone,
        onSaveAddress: onSaveAddress,
        onDeleteAddress: onDeleteAddress,
        onSetPrimaryAddress: onSetPrimaryAddress,
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserAddress address) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Alamat?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus alamat "${address.label}"? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onDeleteAddress(address.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, [UserAddress? address]) async {
    final result = await AccountAddressFormDialog.show(
      context,
      repository: repository,
      initialAddress: address,
      defaultReceiverName: defaultReceiverName,
      defaultPhone: defaultPhone,
    );
    if (result != null) {
      onSaveAddress(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bookmark_added_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alamat Saya',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Kelola titik penjemputan dan pengantaran Anda.',
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
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Daftar Alamat
          Expanded(
            child: addresses.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off_rounded,
                            size: 56,
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum Ada Alamat Tersimpan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tambahkan alamat utama untuk memudahkan pengiriman Anda.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            text: 'Tambah Alamat',
                            size: ButtonSize.small,
                            onPressed: () => _openForm(context),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = addresses[index];
                      final isPrimary = item.isPrimary;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.surfaceVariantLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isPrimary
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight),
                            width: isPrimary ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  item.label,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isPrimary)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Utama',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: 'Ubah Alamat',
                                  onPressed: () => _openForm(context, item),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: AppColors.error,
                                  ),
                                  tooltip: 'Hapus Alamat',
                                  onPressed: () =>
                                      _confirmDelete(context, item),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.receiverName} • ${item.phone}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.fullAddress,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            if (item.villageName != null || item.districtName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  [
                                    if (item.villageName != null)
                                      item.villageName,
                                    if (item.districtName != null)
                                      item.districtName,
                                    if (item.regencyName != null)
                                      item.regencyName,
                                    if (item.provinceName != null)
                                      item.provinceName,
                                    if (item.postalCode != null &&
                                        item.postalCode!.isNotEmpty)
                                      item.postalCode,
                                  ].join(', '),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight,
                                  ),
                                ),
                              ),
                            if (!isPrimary)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 14,
                                    ),
                                    label: const Text(
                                      'Jadikan Alamat Utama',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                    onPressed: () =>
                                        onSetPrimaryAddress(item.id),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Action
          Padding(
            padding: const EdgeInsets.all(20),
            child: CustomButton(
              text: 'Tambah Alamat Baru',
              isFullWidth: true,
              prefixIcon: const Icon(Icons.add_location_alt_rounded),
              onPressed: () => _openForm(context),
            ),
          ),
        ],
      ),
    );
  }
}
