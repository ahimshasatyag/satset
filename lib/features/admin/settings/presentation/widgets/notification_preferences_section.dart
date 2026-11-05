import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/notification_preferences.dart';

class NotificationPreferencesSection extends StatefulWidget {
  final NotificationPreferences preferences;
  final bool isSaving;
  final ValueChanged<NotificationPreferences> onSavePreferences;

  const NotificationPreferencesSection({
    super.key,
    required this.preferences,
    required this.isSaving,
    required this.onSavePreferences,
  });

  @override
  State<NotificationPreferencesSection> createState() =>
      _NotificationPreferencesSectionState();
}

class _NotificationPreferencesSectionState
    extends State<NotificationPreferencesSection> {
  late bool _notifyOrders;
  late bool _notifyStatus;
  late bool _notifyAssignments;
  late bool _notifyPayments;
  late bool _notifyFailed;
  late bool _soundAlert;

  @override
  void initState() {
    super.initState();
    _initValues(widget.preferences);
  }

  void _initValues(NotificationPreferences p) {
    _notifyOrders = p.notifyNewShipmentOrders;
    _notifyStatus = p.notifyShipmentStatusChanges;
    _notifyAssignments = p.notifyCourierAssignments;
    _notifyPayments = p.notifyPaymentTransactions;
    _notifyFailed = p.notifyFailedDeliveries;
    _soundAlert = p.soundAlertEnabled;
  }

  @override
  void didUpdateWidget(covariant NotificationPreferencesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preferences != oldWidget.preferences) {
      _initValues(widget.preferences);
    }
  }

  void _handleSave() {
    final updated = widget.preferences.copyWith(
      notifyNewShipmentOrders: _notifyOrders,
      notifyShipmentStatusChanges: _notifyStatus,
      notifyCourierAssignments: _notifyAssignments,
      notifyPaymentTransactions: _notifyPayments,
      notifyFailedDeliveries: _notifyFailed,
      soundAlertEnabled: _soundAlert,
    );
    widget.onSavePreferences(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Preferensi Notifikasi & Pemantauan Log (t_notifications)',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Atur jenis peristiwa operasional yang akan memicu notifikasi peringatan pada dashboard administrator.',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),

          // Ringkasan Notifikasi Aktual pada t_notifications
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.backgroundDark
                  : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Wrap(
              spacing: 24,
              runSpacing: 10,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Riwayat Notifikasi',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.preferences.totalExistingNotifications} Pesan',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifikasi Belum Dibaca',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.preferences.unreadNotificationsCount} Pesan',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 300,
                  child: Text(
                    widget.preferences.backendNote,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Switch Preferences
          _PreferenceSwitchTile(
            title: 'Pesanan Pengiriman Baru Masuk',
            subtitle:
                'Dapatkan pemberitahuan seketika saat pelanggan berhasil membuat pesanan pengiriman (t_shipments status PENDING).',
            value: _notifyOrders,
            isDark: isDark,
            onChanged: (val) => setState(() => _notifyOrders = val),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          _PreferenceSwitchTile(
            title: 'Perubahan Kronologi Status Pengiriman',
            subtitle:
                'Pemberitahuan perubahan status paket saat paket dijemput, tiba di sortir, atau dalam perjalanan.',
            value: _notifyStatus,
            isDark: isDark,
            onChanged: (val) => setState(() => _notifyStatus = val),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          _PreferenceSwitchTile(
            title: 'Penugasan Kurir (t_shipment_assignments)',
            subtitle:
                'Pemberitahuan saat kurir menerima penugasan baru atau saat terjadi pelepasan tugas (unassigned).',
            value: _notifyAssignments,
            isDark: isDark,
            onChanged: (val) => setState(() => _notifyAssignments = val),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          _PreferenceSwitchTile(
            title: 'Transaksi Pembayaran Masuk & Lunas',
            subtitle:
                'Pemberitahuan mutasi transaksi pembayaran (transfer gateway lunas atau penerimaan setoran COD).',
            value: _notifyPayments,
            isDark: isDark,
            onChanged: (val) => setState(() => _notifyPayments = val),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          _PreferenceSwitchTile(
            title: 'Peringatan Pengiriman Gagal (FAILED_DELIVERY)',
            subtitle:
                'Peringatan prioritas tinggi ketika kurir melaporkan kegagalan pengantaran paket kepada penerima.',
            value: _notifyFailed,
            isDark: isDark,
            onChanged: (val) => setState(() => _notifyFailed = val),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          _PreferenceSwitchTile(
            title: 'Bunyi Alarm / Notifikasi Suara',
            subtitle:
                'Putar efek audio pemberitahuan saat terjadi event realtime pada aplikasi web admin.',
            value: _soundAlert,
            isDark: isDark,
            onChanged: (val) => setState(() => _soundAlert = val),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.icon(
                onPressed: widget.isSaving ? null : _handleSave,
                icon: widget.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  widget.isSaving
                      ? 'Menyimpan...'
                      : 'Simpan Preferensi Notifikasi',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreferenceSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _PreferenceSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11.5,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

