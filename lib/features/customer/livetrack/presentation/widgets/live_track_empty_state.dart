import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/live_track_shipment.dart';

class LiveTrackEmptyState extends StatelessWidget {
  final OrderDirection direction;
  final OrderFilterStatus filterStatus;
  final String searchQuery;
  final VoidCallback onRefresh;
  final VoidCallback? onResetFilter;
  final VoidCallback? onClearSearch;
  final VoidCallback? onSwitchToOutgoing;

  const LiveTrackEmptyState({
    super.key,
    required this.direction,
    required this.filterStatus,
    required this.searchQuery,
    required this.onRefresh,
    this.onResetFilter,
    this.onClearSearch,
    this.onSwitchToOutgoing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Resolusi Judul
    String title;
    if (searchQuery.isNotEmpty) {
      title = 'Resi Tidak Ditemukan';
    } else {
      switch (filterStatus) {
        case OrderFilterStatus.waitingPickup:
          title = 'Belum Ada Paket Menunggu Pickup';
          break;
        case OrderFilterStatus.inDelivery:
          title = 'Tidak Ada Kurir Sedang Diantar';
          break;
        case OrderFilterStatus.completed:
          title = 'Belum Ada Pengiriman Selesai';
          break;
        case OrderFilterStatus.all:
          title = 'Tidak Ada Pengiriman Aktif';
          break;
      }
    }

    // Resolusi Deskripsi
    String subtitle;
    if (searchQuery.isNotEmpty) {
      subtitle =
          'Tidak ditemukan nomor resi atau nama "$searchQuery" pada daftar ${direction.label.toLowerCase()}. Pastikan nomor resi sudah tepat.';
    } else if (direction == OrderDirection.incoming) {
      subtitle = filterStatus == OrderFilterStatus.all
          ? 'Belum ada paket masuk yang sedang menuju ke alamat atau nomor telepon Anda saat ini.'
          : 'Tidak ada paket masuk pada kategori "${filterStatus.label}". Coba pilih filter Semua untuk melihat seluruh kiriman.';
    } else {
      subtitle = filterStatus == OrderFilterStatus.all
          ? 'Anda belum memiliki kiriman paket yang sedang berjalan di SatSet Delivery.'
          : 'Tidak ada paket pada status "${filterStatus.label}". Coba ubah filter status atau periksa kembali nanti.';
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.surfaceDark : Colors.white)
              .withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gambar Ilustrasi Resmi SatSet Live Tracking
            Container(
              height: 140,
              width: double.infinity,
              alignment: Alignment.center,
              child: Image.asset(
                'assets/images/Splash2.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Judul
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 6),

            // Deskripsi Informasi
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 18),

            // Tombol Aksi Cepat
            if (searchQuery.isNotEmpty && onClearSearch != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onClearSearch,
                  icon: const Icon(Icons.clear_rounded, size: 16),
                  label: const Text(
                    'Hapus Pencarian',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ] else if (filterStatus != OrderFilterStatus.all && onResetFilter != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onResetFilter,
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text(
                    'Tampilkan Semua Status',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Tombol Pilihan Tab Lain / Refresh
            Row(
              children: [
                if (direction == OrderDirection.incoming && onSwitchToOutgoing != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSwitchToOutgoing,
                      icon: const Icon(Icons.outbox_rounded, size: 15),
                      label: const Text(
                        'Kiriman Saya',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded, size: 15),
                    label: const Text(
                      'Perbarui Data',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      side: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
