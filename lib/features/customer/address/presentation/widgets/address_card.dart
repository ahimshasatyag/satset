import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:satset/shared/theme/theme.dart';

import '../../domain/entities/customer_address.dart';

class AddressCard extends StatelessWidget {
  final CustomerAddress address;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSetPrimary;

  const AddressCard({
    super.key,
    required this.address,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.onSetPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPrimary = address.isPrimary;

    // Latar & Garis Tepi Khusus jika Alamat Utama atau Terpilih
    Color cardBorderColor;
    double cardBorderWidth;

    if (isSelected) {
      cardBorderColor = AppColors.primary;
      cardBorderWidth = 2.0;
    } else if (isPrimary) {
      cardBorderColor = AppColors.primary.withValues(alpha: 0.4);
      cardBorderWidth = 1.5;
    } else {
      cardBorderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
      cardBorderWidth = 1.0;
    }

    final cardBgColor = isPrimary
        ? (isDark
              ? AppColors.primary900.withValues(alpha: 0.25)
              : AppColors.primary50.withValues(alpha: 0.6))
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor, width: cardBorderWidth),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onLongPress != null
              ? () {
                  HapticFeedback.mediumImpact();
                  onLongPress!();
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Baris 1: Tag Label & Status Alamat
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon Type
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isPrimary
                            ? AppColors.primary
                            : (isDark
                                  ? Colors.white12
                                  : AppColors.surfaceVariantLight),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPrimary
                            ? Icons.home_rounded
                            : Icons.location_on_rounded,
                        size: 16,
                        color: isPrimary
                            ? Colors.white
                            : (isDark
                                  ? Colors.white70
                                  : AppColors.textSecondaryLight),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Title / Label
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  address.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isPrimary
                                            ? AppColors.primary
                                            : (isDark
                                                  ? AppColors.textPrimaryDark
                                                  : AppColors.textPrimaryLight),
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (address.latitude != null && address.longitude != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.pin_drop_rounded,
                                        size: 10,
                                        color: AppColors.success,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'GPS',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (isPrimary) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Utama',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            isPrimary
                                ? (address.sourceType.isUserPrimary
                                      ? 'Alamat Utama (Profil Akun)'
                                      : 'Alamat Utama')
                                : (address.sourceType.isUserPrimary
                                      ? 'Profil Akun'
                                      : 'Alamat Tersimpan'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textMutedLight,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Radio Checkmark jika dalam Mode Seleksi
                    if (isSelectionMode)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                      ? Colors.white38
                                      : AppColors.textDisabledLight),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
                const SizedBox(height: 12),

                // Nama Penerima & Nomor Telepon
                Row(
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 14,
                      color: isDark
                          ? Colors.white60
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      address.receiverName,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (address.phoneNumber.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white38
                              : AppColors.textDisabledLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.phone_rounded,
                        size: 14,
                        color: isDark
                            ? Colors.white60
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        address.phoneNumber,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),

                // Email Penerima jika ada
                if (address.email != null && address.email!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 13,
                        color: isDark
                            ? Colors.white60
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        address.email!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),

                // Alamat Lengkap
                Text(
                  address.fullAddress.trim().isNotEmpty
                      ? address.fullAddress
                      : '(Alamat jalan belum diisi)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 8),

                // Badge Tag Wilayah (Kelurahan, Kecamatan, Kab/Kota, Provinsi, Kode Pos)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 13,
                        color: isDark
                            ? Colors.white60
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          address.formattedRegion,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w500,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Footer Tombol Aksi
                Row(
                  children: [
                    // Jadikan Alamat Utama (Hanya untuk yang belum utama)
                    if (!isPrimary && onSetPrimary != null) ...[
                      InkWell(
                        onTap: onSetPrimary,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_border_rounded,
                                size: 16,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Jadikan Utama',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                    ] else ...[
                      const Spacer(),
                    ],

                    // Tombol Edit
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: isDark
                              ? Colors.white70
                              : AppColors.textSecondaryLight,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text('Ubah'),
                      ),

                    // Tombol Hapus (Untuk Alamat Tambahan m_address)
                    if (!isPrimary && onDelete != null) ...[
                      const SizedBox(width: 4),
                      TextButton.icon(
                        onPressed: onDelete,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: Colors.redAccent,
                        ),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 15,
                        ),
                        label: const Text('Hapus'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
