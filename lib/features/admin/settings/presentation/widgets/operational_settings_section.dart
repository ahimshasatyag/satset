import 'package:flutter/material.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/operational_settings.dart';

class OperationalSettingsSection extends StatelessWidget {
  final OperationalSettings settings;
  final void Function(int serviceTypeId, bool isActive) onToggleServiceStatus;

  const OperationalSettingsSection({
    super.key,
    required this.settings,
    required this.onToggleServiceStatus,
  });

  Future<void> _handleConfirmToggle(
    BuildContext context,
    ServiceTypeSettingItem item,
    bool nextState,
  ) async {
    final actionText = nextState ? 'mengaktifkan' : 'menonaktifkan';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${nextState ? 'Aktifkan' : 'Nonaktifkan'} Layanan ${item.kode}?'),
        content: Text(
          'Apakah Anda yakin ingin $actionText jenis layanan "${item.namaLayanan}"? '
          'Layanan ini ${nextState ? 'akan tersedia' : 'tidak akan muncul'} pada opsi pemesanan baru pelanggan di aplikasi. '
          'Seluruh pesanan pengiriman historis pada t_shipments tetap aman dan tidak berubah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Ya, ${nextState ? 'Aktifkan' : 'Nonaktifkan'}'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      onToggleServiceStatus(item.id, nextState);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pengaturan Operasional Pengiriman (m_service_types & m_shipment_statuses)',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola ketersediaan jenis layanan, SLA estimasi pengiriman, dan aturan master status pengiriman.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 16),

          // Peringatan Integritas Riwayat Pengiriman
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user_outlined, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proteksi Integritas Riwayat Transaksi (Database Constraint Guarantee)',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        settings.historicalIntegrityNotice,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Daftar Master Jenis Layanan
          Text(
            'Master Ketersediaan Jenis Layanan (m_service_types)',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          if (settings.serviceTypes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Tidak ada data jenis layanan di tabel m_service_types.',
                style: AppTextStyles.bodySmall,
              ),
            )
          else
            Column(
              children: settings.serviceTypes.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Text(
                          item.kode,
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  item.namaLayanan,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: theme.dividerColor),
                                  ),
                                  child: Text(
                                    'SLA: ${item.slaDisplay}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${item.deskripsi} • Tarif Dasar: ${AdminCurrencyFormatter.formatRupiah(item.baseTariffPerKg)}/Kg',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: item.isActive,
                        onChanged: (val) => _handleConfirmToggle(context, item, val),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // Master Referensi Status Pengiriman (m_shipment_statuses)
          Text(
            'Alur Status Pengiriman Resmi (m_shipment_statuses)',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: settings.shipmentStatuses.map((st) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${st.urutan}.',
                      style: AppTextStyles.labelSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      st.namaStatus,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '[${st.kode}]',
                      style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

