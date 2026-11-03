import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:satset/features/admin/utils/admin_currency_formatter.dart';
import 'package:satset/features/admin/utils/admin_date_formatter.dart';
import 'package:satset/features/admin/utils/admin_status_helper.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_courier_detail.dart';
import '../../domain/entities/admin_courier_item.dart';

class CourierDetailDialog extends StatefulWidget {
  final AdminCourierDetail detail;
  final bool isActionInProgress;
  final VoidCallback onClose;
  final ValueChanged<AdminCourierItem> onEditProfile;
  final ValueChanged<AdminCourierItem> onToggleStatus;
  final void Function(int assignmentId, int shipmentId, String nomorResi)
      onUnassignTask;
  final ValueChanged<int> onInspectShipmentInDeliveryPage;

  const CourierDetailDialog({
    super.key,
    required this.detail,
    this.isActionInProgress = false,
    required this.onClose,
    required this.onEditProfile,
    required this.onToggleStatus,
    required this.onUnassignTask,
    required this.onInspectShipmentInDeliveryPage,
  });

  @override
  State<CourierDetailDialog> createState() => _CourierDetailDialogState();
}

class _CourierDetailDialogState extends State<CourierDetailDialog> {
  String _assignmentFilter = 'ALL'; // ALL, ACTIVE, COMPLETED

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final courier = widget.detail.courier;
    final loc = courier.lastLocation;
    final hasLiveGps = loc != null && courier.hasActiveAssignment;

    final filteredAssignments = widget.detail.assignments.where((a) {
      if (_assignmentFilter == 'ACTIVE') return a.isActiveTask;
      if (_assignmentFilter == 'COMPLETED') return !a.isActiveTask;
      return true;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980, maxHeight: 840),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Detail Kurir
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
                    backgroundImage: courier.fotoUrl != null &&
                            courier.fotoUrl!.trim().isNotEmpty
                        ? NetworkImage(courier.fotoUrl!.trim())
                        : null,
                    child: courier.fotoUrl == null ||
                            courier.fotoUrl!.trim().isEmpty
                        ? Text(
                            courier.namaLengkap.isNotEmpty
                                ? courier.namaLengkap[0].toUpperCase()
                                : 'K',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              courier.namaLengkap,
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
                                color: (courier.isActive
                                        ? AppColors.success
                                        : AppColors.error)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                courier.isActive
                                    ? 'Akun Aktif'
                                    : 'Akun Nonaktif',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: courier.isActive
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kode Pegawai: ${courier.employeeCode} • ID Employee: #${courier.id} • Role: Kurir (id_users_role = ${courier.idUsersRole})',
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
                    onPressed: () => widget.onEditProfile(courier),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit Profil'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => widget.onToggleStatus(courier),
                    icon: Icon(
                      courier.isActive
                          ? Icons.person_off_rounded
                          : Icons.verified_user_rounded,
                      size: 16,
                      color: courier.isActive
                          ? AppColors.error
                          : AppColors.success,
                    ),
                    label: Text(
                      courier.isActive ? 'Nonaktifkan' : 'Aktifkan',
                      style: TextStyle(
                        color: courier.isActive
                            ? AppColors.error
                            : AppColors.success,
                      ),
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

            // 2. Body Konten Detail Kurir
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Ringkasan Beban Kerja & Performa Pengiriman Kurir
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildMetricBadge(
                          isDark: isDark,
                          label: 'Tugas Aktif Saat Ini',
                          value: '${courier.activeTasksCount} Paket',
                          color: AppColors.secondary,
                          icon: Icons.local_shipping_rounded,
                        ),
                        _buildMetricBadge(
                          isDark: isDark,
                          label: 'Total Pernah Ditangani',
                          value: '${courier.totalHandledCount} Paket',
                          color: AppColors.primary,
                          icon: Icons.inventory_2_rounded,
                        ),
                        _buildMetricBadge(
                          isDark: isDark,
                          label: 'Pengiriman Berhasil',
                          value: '${courier.deliveredCount} Paket',
                          color: AppColors.success,
                          icon: Icons.check_circle_rounded,
                        ),
                        _buildMetricBadge(
                          isDark: isDark,
                          label: 'Pengiriman Gagal / Retur',
                          value: '${courier.failedCount} Paket',
                          color: AppColors.error,
                          icon: Icons.report_problem_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Informasi Profil & Pemantauan Lokasi GPS Terakhir
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 720;
                        final profileCard = _buildProfileInfoCard(
                          isDark,
                          courier,
                        );
                        final locationCard = _buildLocationMonitoringCard(
                          isDark,
                          courier,
                          loc,
                          hasLiveGps,
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 5, child: profileCard),
                              const SizedBox(width: 16),
                              Expanded(flex: 6, child: locationCard),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            profileCard,
                            const SizedBox(height: 16),
                            locationCard,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    // Daftar Penugasan Pengiriman (t_shipment_assignments)
                    _buildAssignmentsSection(
                      context,
                      isDark,
                      filteredAssignments,
                    ),
                    const SizedBox(height: 18),

                    // Riwayat Aktivitas Kurir (t_shipment_tracking)
                    _buildActivityHistorySection(isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBadge({
    required bool isDark,
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 215,
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
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
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

  Widget _buildProfileInfoCard(bool isDark, AdminCourierItem courier) {
    final rows = [
      ('Nama Lengkap', courier.namaLengkap),
      ('Kode Identitas Employee', courier.employeeCode),
      ('Role Employee', 'Kurir (id_users_role = ${courier.idUsersRole})'),
      ('Email Terdaftar', courier.email),
      ('Nomor Telepon / HP', courier.noHp),
      ('Alamat Lengkap', courier.alamatLengkap ?? '-'),
      (
        'ID Supabase Auth',
        (courier.authUserId != null && courier.authUserId!.isNotEmpty)
            ? courier.authUserId!
            : 'Terautentikasi via m_employee'
      ),
      (
        'Tanggal Bergabung',
        AdminDateFormatter.formatDateTime(courier.createdAt)
      ),
      (
        'Pembaruan Terakhir',
        courier.updatedAt != null
            ? AdminDateFormatter.formatDateTime(courier.updatedAt!)
            : '-'
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
                Icons.badge_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Informasi Profil & Identitas Employee (m_employee)',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...rows.map((r) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 145,
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

  Widget _buildLocationMonitoringCard(
    bool isDark,
    AdminCourierItem courier,
    AdminCourierLastLocation? loc,
    bool hasLiveGps,
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
                Icons.gps_fixed_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pemantauan Lokasi GPS Kurir (t_shipment_locations)',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!courier.hasActiveAssignment)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.location_disabled_rounded,
                      size: 38,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kurir sedang tidak menjalankan tugas aktif.',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pelacakan GPS hanya ditampilkan apabila kurir sedang memiliki penugasan pengiriman aktif.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (!hasLiveGps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons. satellite_alt_rounded,
                      size: 38,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Koordinat GPS Belum Tersedia di t_shipment_locations',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kurir memiliki tugas aktif, namun perangkat kurir belum mengirimkan titik koordinat lokasi terbaru.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                Text(
                  'Koordinat: (${loc!.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)})',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (loc.nomorResi != null)
                  Text(
                    'Resi Tugas: ${loc.nomorResi}',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                Text(
                  'Diperbarui: ${AdminDateFormatter.formatDateTime(loc.recordedAt)}',
                  style: AppTextStyles.labelSmall,
                ),
                if (loc.speedMps != null)
                  Text(
                    'Kecepatan: ${loc.speedMps!.toStringAsFixed(1)} m/s',
                    style: AppTextStyles.labelSmall,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 205,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(loc.latitude, loc.longitude),
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
                          point: LatLng(loc.latitude, loc.longitude),
                          width: 44,
                          height: 44,
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
                              Icons.two_wheeler_rounded,
                              color: AppColors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssignmentsSection(
    BuildContext context,
    bool isDark,
    List<AdminCourierAssignmentRecord> assignments,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.assignment_ind_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Daftar Penugasan Pengiriman Kurir (t_shipment_assignments)',
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                children: [
                  ChoiceChip(
                    label: Text(
                      'Semua (${widget.detail.assignments.length})',
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _assignmentFilter == 'ALL',
                    onSelected: (_) =>
                        setState(() => _assignmentFilter = 'ALL'),
                  ),
                  ChoiceChip(
                    label: Text(
                      'Tugas Aktif (${widget.detail.activeAssignments.length})',
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _assignmentFilter == 'ACTIVE',
                    onSelected: (_) =>
                        setState(() => _assignmentFilter = 'ACTIVE'),
                  ),
                  ChoiceChip(
                    label: Text(
                      'Riwayat Selesai (${widget.detail.pastAssignments.length})',
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: _assignmentFilter == 'COMPLETED',
                    onSelected: (_) =>
                        setState(() => _assignmentFilter = 'COMPLETED'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (assignments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'Belum ada data penugasan pengiriman untuk kategori ini.',
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
              itemCount: assignments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final a = assignments[index];
                final statusColor = AdminStatusHelper.getStatusColor(
                  a.statusKode,
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
                  child: Row(
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
                                  a.nomorResi,
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
                                    color: statusColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    a.statusNama,
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
                                    a.serviceNama,
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
                              'Penerima: ${a.penerimaNama} (${a.penerimaNoHp}) • Tujuan: ${a.penerimaAlamat}, ${a.penerimaKota}',
                              style: AppTextStyles.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ditugaskan: ${AdminDateFormatter.formatDateTime(a.assignedAt)}'
                              '${a.completedAt != null ? " • Selesai: ${AdminDateFormatter.formatDateTime(a.completedAt)}" : ""}'
                              '${a.unassignedAt != null ? " • Dilepas: ${AdminDateFormatter.formatDateTime(a.unassignedAt)}" : ""}'
                              ' • Biaya: ${AdminCurrencyFormatter.formatRupiah(a.totalBiaya)}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                widget.onInspectShipmentInDeliveryPage(
                              a.shipmentId,
                            ),
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 15,
                            ),
                            label: const Text('Buka Pengiriman'),
                          ),
                          if (a.isActiveTask)
                            TextButton.icon(
                              onPressed: () => widget.onUnassignTask(
                                a.assignmentId,
                                a.shipmentId,
                                a.nomorResi,
                              ),
                              icon: const Icon(
                                Icons.link_off_rounded,
                                size: 15,
                                color: AppColors.error,
                              ),
                              label: const Text(
                                'Lepas Tugas',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                        ],
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

  Widget _buildActivityHistorySection(bool isDark) {
    final logs = widget.detail.activityLogs;

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
                Icons.history_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Riwayat Aktivitas & Pembaruan Status Kurir (t_shipment_tracking)',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            Text(
              'Belum ada catatan aktivitas perubahan status oleh kurir ini pada t_shipment_tracking.',
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, index) {
                final log = logs[index];
                final color = AdminStatusHelper.getStatusColor(
                  log.statusKode,
                  isDark: isDark,
                );

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${log.nomorResi} • ${log.statusNama}',
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                AdminDateFormatter.formatDateTime(
                                  log.createdAt,
                                ),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                          if (log.lokasiNama != null &&
                              log.lokasiNama!.isNotEmpty)
                            Text(
                              'Lokasi: ${log.lokasiNama}',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (log.catatan != null && log.catatan!.isNotEmpty)
                            Text(
                              log.catatan!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

