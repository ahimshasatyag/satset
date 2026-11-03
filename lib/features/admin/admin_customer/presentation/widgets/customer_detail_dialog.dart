import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_customer_detail.dart';
import '../../domain/entities/admin_customer_item.dart';

class CustomerDetailDialog extends StatefulWidget {
  final AdminCustomerDetail detail;
  final bool isActionInProgress;
  final VoidCallback onClose;
  final ValueChanged<AdminCustomerItem> onEditProfile;
  final ValueChanged<AdminCustomerItem> onToggleVerification;
  final ValueChanged<int> onOpenDeliveryPage;

  const CustomerDetailDialog({
    super.key,
    required this.detail,
    this.isActionInProgress = false,
    required this.onClose,
    required this.onEditProfile,
    required this.onToggleVerification,
    required this.onOpenDeliveryPage,
  });

  @override
  State<CustomerDetailDialog> createState() => _CustomerDetailDialogState();
}

class _CustomerDetailDialogState extends State<CustomerDetailDialog> {
  int? _expandedShipmentId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final customer = widget.detail.customer;
    final addresses = widget.detail.additionalAddresses;
    final shipments = widget.detail.shipments;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 850),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Detail Customer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                    child: Text(
                      customer.namaLengkap.isNotEmpty
                          ? customer.namaLengkap[0].toUpperCase()
                          : 'C',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
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
                              customer.namaLengkap,
                              style: AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: (customer.emailVerified
                                        ? AppColors.success
                                        : AppColors.warning)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                customer.emailVerified
                                    ? 'Email Terverifikasi'
                                    : 'Belum Terverifikasi',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: customer.emailVerified
                                      ? AppColors.success
                                      : AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID Customer: #${customer.id} • Role: Pelanggan (id_users_role = ${customer.idUsersRole}) • Registrasi: ${AdminDateFormatter.formatDateTime(customer.createdAt)}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => widget.onEditProfile(customer),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Profil & Wilayah'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => widget.onToggleVerification(customer),
                    icon: Icon(
                      customer.emailVerified
                          ? Icons.mark_email_unread_outlined
                          : Icons.verified_rounded,
                      size: 16,
                      color: customer.emailVerified
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                    label: Text(
                      customer.emailVerified
                          ? 'Cabut Verifikasi'
                          : 'Verifikasi Email',
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),

            // 2. Body Konten Detail Customer
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ringkasan Aktivitas Pengiriman & Pembayaran Customer
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildStatBadge(
                          isDark: isDark,
                          label: 'Total Pengiriman',
                          value: '${customer.totalShipmentsCount} Paket',
                          color: AppColors.primary,
                          icon: Icons.inventory_2_rounded,
                        ),
                        _buildStatBadge(
                          isDark: isDark,
                          label: 'Pengiriman Berhasil',
                          value: '${customer.deliveredShipmentsCount} Paket',
                          color: AppColors.success,
                          icon: Icons.check_circle_rounded,
                        ),
                        _buildStatBadge(
                          isDark: isDark,
                          label: 'Sedang Berlangsung',
                          value: '${customer.ongoingShipmentsCount} Paket',
                          color: AppColors.secondary,
                          icon: Icons.local_shipping_rounded,
                        ),
                        _buildStatBadge(
                          isDark: isDark,
                          label: 'Gagal / Dibatalkan',
                          value: '${customer.failedShipmentsCount} Paket',
                          color: AppColors.error,
                          icon: Icons.cancel_rounded,
                        ),
                        _buildStatBadge(
                          isDark: isDark,
                          label: 'Total Nilai Transaksi',
                          value: AdminCurrencyFormatter.formatRupiah(
                            customer.totalTransactionAmount,
                          ),
                          color: AppColors.tertiary,
                          icon: Icons.account_balance_wallet_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Informasi Profil Utama & Alamat Wilayah + Peta Koordinat
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 740;
                        final profileSection = _buildProfileAndPrimaryAddressCard(
                          isDark,
                          customer,
                        );
                        final mapAndAddressesSection =
                            _buildCoordinatesAndAdditionalAddressesCard(
                          isDark,
                          customer,
                          addresses,
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: profileSection),
                              const SizedBox(width: 16),
                              Expanded(flex: 6, child: mapAndAddressesSection),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            profileSection,
                            const SizedBox(height: 16),
                            mapAndAddressesSection,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    // Riwayat Pengiriman Customer (t_shipments + t_shipment_tracking)
                    _buildShipmentsHistorySection(isDark, shipments),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required bool isDark,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 182,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAndPrimaryAddressCard(
    bool isDark,
    AdminCustomerItem customer,
  ) {
    final rows = [
      ('Nama Lengkap', customer.namaLengkap),
      ('Email Terdaftar', customer.email),
      ('Nomor Telepon / HP', customer.noHp),
      (
        'Status Verifikasi Email',
        customer.emailVerified
            ? 'Terverifikasi (${customer.emailVerifiedAt != null ? AdminDateFormatter.formatDateTime(customer.emailVerifiedAt) : "Aktif"})'
            : 'Belum Terverifikasi'
      ),
      (
        'Metode Autentikasi',
        customer.googleId != null && customer.googleId!.isNotEmpty
            ? 'Google OAuth (${customer.googleId})'
            : 'Email & Password (m_users)'
      ),
      ('Alamat Utama', customer.alamatLengkap ?? '-'),
      (
        'Provinsi (m_provinsi)',
        customer.namaProvinsi ?? customer.idProvinsi ?? '-'
      ),
      (
        'Kabupaten/Kota (m_kabkot)',
        customer.namaKabkot ?? customer.idKabkot ?? '-'
      ),
      (
        'Kecamatan (m_kecamatan)',
        customer.namaKecamatan ?? customer.idKecamatan ?? '-'
      ),
      (
        'Kelurahan (m_kelurahan)',
        customer.namaKelurahan ?? customer.idKelurahan ?? '-'
      ),
      ('Kode Pos', customer.kodePos ?? '-'),
      (
        'Koordinat Utama',
        customer.hasCoordinates
            ? '${customer.latitude!.toStringAsFixed(5)}, ${customer.longitude!.toStringAsFixed(5)}'
            : 'Belum diatur'
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_pin_circle_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Profil & Alamat Utama Customer (m_users)',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 155,
                    child: Text(
                      r.$1,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.$2,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCoordinatesAndAdditionalAddressesCard(
    bool isDark,
    AdminCustomerItem customer,
    List<AdminCustomerAddressRecord> addresses,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bookmark_added_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Titik Koordinat & Daftar Buku Alamat (m_address & m_label)',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (customer.hasCoordinates) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 165,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(
                      customer.latitude!,
                      customer.longitude!,
                    ),
                    initialZoom: 14.5,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.satset.delivery',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            customer.latitude!,
                            customer.longitude!,
                          ),
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.home_rounded,
                              color: AppColors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (addresses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Customer ini belum menyimpan daftar alamat tambahan pada tabel m_address (menggunakan alamat utama pada m_users).',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, index) {
                final addr = addresses[index];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (addr.labelNama != null &&
                              addr.labelNama!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                addr.labelNama!,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (addr.isUtama)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Alamat Utama',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Text(
                            AdminDateFormatter.formatShortDate(addr.createdAt),
                            style: AppTextStyles.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (addr.namaPenerima != null || addr.noHp != null)
                        Text(
                          '${addr.namaPenerima ?? customer.namaLengkap} (${addr.noHp ?? customer.noHp})',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      Text(
                        addr.alamatLengkap,
                        style: AppTextStyles.bodySmall,
                      ),
                      if (addr.formattedWilayah.isNotEmpty)
                        Text(
                          addr.formattedWilayah,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildShipmentsHistorySection(
    bool isDark,
    List<AdminCustomerShipmentRecord> shipments,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Riwayat Pengiriman Customer (${shipments.length} Transaksi di t_shipments)',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (shipments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Customer ini belum pernah membuat pesanan pengiriman pada t_shipments.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: shipments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final s = shipments[index];
                final isExpanded = _expandedShipmentId == s.id;
                final statusColor = AdminStatusHelper.getStatusColor(
                  s.statusKode,
                  isDark: isDark,
                );

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      s.nomorResi,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.14,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        s.statusNama,
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        s.serviceNama,
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Penerima: ${s.penerimaNama} (${s.penerimaNoHp}) • Tujuan: ${s.penerimaAlamat}, ${s.penerimaKota}',
                                  style: AppTextStyles.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tanggal Pesan: ${AdminDateFormatter.formatDateTime(s.createdAt)} • '
                                  'Metode Bayar: ${s.metodePembayaran} (${s.statusPembayaran}) • '
                                  'Total Biaya: ${AdminCurrencyFormatter.formatRupiah(s.totalBiaya)}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _expandedShipmentId =
                                        isExpanded ? null : s.id;
                                  });
                                },
                                icon: Icon(
                                  isExpanded
                                      ? Icons.expand_less_rounded
                                      : Icons.timeline_rounded,
                                  size: 16,
                                ),
                                label: Text(
                                  isExpanded
                                      ? 'Tutup Kronologi'
                                      : 'Kronologi (${s.trackingSteps.length})',
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () =>
                                    widget.onOpenDeliveryPage(s.id),
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 14,
                                ),
                                label: const Text('Buka di Delivery'),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Kronologi Perjalanan Paket dari t_shipment_tracking
                      if (isExpanded) ...[
                        const Divider(height: 16),
                        if (s.trackingSteps.isEmpty)
                          Text(
                            'Belum ada catatan kronologi pada t_shipment_tracking.',
                            style: AppTextStyles.labelSmall,
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: s.trackingSteps.map((step) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.fiber_manual_record,
                                      size: 10,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${AdminDateFormatter.formatDateTime(step.createdAt)} — ${step.statusNama}'
                                        '${step.lokasiNama != null ? " (${step.lokasiNama})" : ""}'
                                        '${step.catatan != null ? ": ${step.catatan}" : ""}',
                                        style: AppTextStyles.labelSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

