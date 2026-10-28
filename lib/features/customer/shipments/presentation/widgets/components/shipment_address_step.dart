import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

import '../../../domain/entities/shipment.dart';
import 'shipment_form_card.dart';

/// Step 1: Form input alamat pengirim dan alamat penerima serta pilihan wilayah bertingkat (cascading).
class ShipmentAddressStep extends StatelessWidget {
  final bool isDark;

  // Controllers: Pengirim
  final TextEditingController senderNameController;
  final TextEditingController senderPhoneController;
  final TextEditingController senderAddressController;
  final TextEditingController senderPostalController;

  // Controllers: Penerima
  final TextEditingController receiverNameController;
  final TextEditingController receiverPhoneController;
  final TextEditingController receiverAddressController;
  final TextEditingController receiverPostalController;

  // Master Data Provinsi
  final List<Province> provinces;

  // Cascading Region: Pengirim
  final Province? senderProvince;
  final List<Regency> senderRegencies;
  final Regency? senderRegency;
  final List<District> senderDistricts;
  final District? senderDistrict;
  final List<Village> senderVillages;
  final Village? senderVillage;
  final bool isLoadingSenderRegencies;
  final bool isLoadingSenderDistricts;
  final bool isLoadingSenderVillages;
  final ValueChanged<Province> onSenderProvinceSelected;
  final ValueChanged<Regency> onSenderRegencySelected;
  final ValueChanged<District> onSenderDistrictSelected;
  final ValueChanged<Village> onSenderVillageSelected;

  // Cascading Region: Penerima
  final Province? receiverProvince;
  final List<Regency> receiverRegencies;
  final Regency? receiverRegency;
  final List<District> receiverDistricts;
  final District? receiverDistrict;
  final List<Village> receiverVillages;
  final Village? receiverVillage;
  final bool isLoadingReceiverRegencies;
  final bool isLoadingReceiverDistricts;
  final bool isLoadingReceiverVillages;
  final ValueChanged<Province> onReceiverProvinceSelected;
  final ValueChanged<Regency> onReceiverRegencySelected;
  final ValueChanged<District> onReceiverDistrictSelected;
  final ValueChanged<Village> onReceiverVillageSelected;

  // Koordinat Peta (Latitude & Longitude)
  final double? senderLatitude;
  final double? senderLongitude;
  final double? receiverLatitude;
  final double? receiverLongitude;
  final VoidCallback? onPickSenderLocation;
  final VoidCallback? onPickReceiverLocation;

  // Switch Alamat Utama (m_users)
  final bool useMainAddress;
  final ValueChanged<bool>? onToggleUseMainAddress;
  final bool isLoadingMainAddress;

  const ShipmentAddressStep({
    super.key,
    required this.isDark,
    required this.senderNameController,
    required this.senderPhoneController,
    required this.senderAddressController,
    required this.senderPostalController,
    this.senderLatitude,
    this.senderLongitude,
    this.onPickSenderLocation,
    this.useMainAddress = false,
    this.onToggleUseMainAddress,
    this.isLoadingMainAddress = false,
    required this.receiverNameController,
    required this.receiverPhoneController,
    required this.receiverAddressController,
    required this.receiverPostalController,
    this.receiverLatitude,
    this.receiverLongitude,
    this.onPickReceiverLocation,
    required this.provinces,
    required this.senderProvince,
    required this.senderRegencies,
    required this.senderRegency,
    required this.senderDistricts,
    required this.senderDistrict,
    required this.senderVillages,
    required this.senderVillage,
    required this.isLoadingSenderRegencies,
    required this.isLoadingSenderDistricts,
    required this.isLoadingSenderVillages,
    required this.onSenderProvinceSelected,
    required this.onSenderRegencySelected,
    required this.onSenderDistrictSelected,
    required this.onSenderVillageSelected,
    required this.receiverProvince,
    required this.receiverRegencies,
    required this.receiverRegency,
    required this.receiverDistricts,
    required this.receiverDistrict,
    required this.receiverVillages,
    required this.receiverVillage,
    required this.isLoadingReceiverRegencies,
    required this.isLoadingReceiverDistricts,
    required this.isLoadingReceiverVillages,
    required this.onReceiverProvinceSelected,
    required this.onReceiverRegencySelected,
    required this.onReceiverDistrictSelected,
    required this.onReceiverVillageSelected,
  });

  Widget _buildRegionDropdown<T>({
    required String label,
    String? hintText,
    String? disabledHint,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
    bool enabled = true,
    bool isLoading = false,
  }) {
    String effectiveHint;
    if (isLoading) {
      effectiveHint = 'Memuat $label...';
    } else if (!enabled) {
      effectiveHint =
          disabledHint ?? 'Pilih wilayah sebelumnya terlebih dahulu';
    } else if (items.isEmpty) {
      effectiveHint = 'Tidak ada data $label';
    } else {
      effectiveHint = hintText ?? 'Pilih $label';
    }

    final isActuallyEnabled = enabled && !isLoading && items.isNotEmpty;

    return SearchableDropdown<T>(
      label: label,
      value: items.contains(value) ? value : null,
      items: items,
      itemLabel: itemLabel,
      onChanged: onChanged,
      isDark: isDark,
      enabled: isActuallyEnabled,
      isLoading: isLoading,
      hintText: effectiveHint,
      emptyHintText: 'Tidak ada data $label',
      searchHint: 'Cari $label...',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SENDER SECTION CARD
        ShipmentFormCard(
          title: 'Alamat Pengirim (Asal)',
          subtitle: 'Lokasi dan rincian kontak penjemputan paket',
          icon: Icons.outbox_rounded,
          isDark: isDark,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Asal',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Switch Gunakan Alamat Utama (m_users)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: useMainAddress
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : (isDark
                          ? const Color(0xFF1B2A3D)
                          : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: useMainAddress
                        ? AppColors.primary.withValues(alpha: 0.35)
                        : (isDark ? Colors.white12 : Colors.black12),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isLoadingMainAddress
                        ? null
                        : () => onToggleUseMainAddress?.call(!useMainAddress),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: useMainAddress
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : (isDark
                                      ? Colors.white10
                                      : Colors.black.withValues(alpha: 0.06)),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.home_work_rounded,
                              size: 20,
                              color: useMainAddress
                                  ? AppColors.primary
                                  : (isDark ? Colors.white70 : Colors.black54),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                 Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  runSpacing: 2,
                                  children: [
                                    const Text(
                                      'Tambah Alamat Utama',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (useMainAddress)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 1.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.success
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'SINKRON',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.success,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isLoadingMainAddress
                                      ? 'Menghubungkan...'
                                      : (useMainAddress
                                          ? 'Alamat & GPS tersinkron otomatis'
                                          : 'Simpan otomatis provinsi, kota, alamat & GPS'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? Colors.white60
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isLoadingMainAddress)
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            )
                          else
                            Switch.adaptive(
                              value: useMainAddress,
                              onChanged: onToggleUseMainAddress,
                              activeTrackColor: AppColors.primary,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              CustomTextField(
                label: 'Nama Lengkap Pengirim',
                hintText: 'Nama pengirim paket',
                controller: senderNameController,
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Nomor Telepon / WhatsApp',
                hintText: '0812xxxxxxxx',
                controller: senderPhoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              ),
              const SizedBox(height: 12),
              _buildRegionDropdown<Province>(
                label: 'Provinsi Pengirim',
                hintText: 'Pilih Provinsi',
                value: senderProvince,
                items: provinces,
                itemLabel: (p) => p.name,
                onChanged: (p) {
                  if (p != null) onSenderProvinceSelected(p);
                },
              ),
              const SizedBox(height: 10),
              _buildRegionDropdown<Regency>(
                label: 'Kabupaten / Kota',
                hintText: 'Pilih Kabupaten/Kota',
                disabledHint: 'Pilih provinsi terlebih dahulu',
                value: senderRegency,
                items: senderRegencies,
                itemLabel: (r) => r.name,
                onChanged: (r) {
                  if (r != null) onSenderRegencySelected(r);
                },
                enabled: senderProvince != null,
                isLoading: isLoadingSenderRegencies,
              ),
              const SizedBox(height: 10),
              _buildRegionDropdown<District>(
                label: 'Kecamatan',
                hintText: 'Pilih Kecamatan',
                disabledHint: 'Pilih kabupaten/kota terlebih dahulu',
                value: senderDistrict,
                items: senderDistricts,
                itemLabel: (d) => d.name,
                onChanged: (d) {
                  if (d != null) onSenderDistrictSelected(d);
                },
                enabled: senderRegency != null,
                isLoading: isLoadingSenderDistricts,
              ),
              const SizedBox(height: 10),
              _buildRegionDropdown<Village>(
                label: 'Kelurahan',
                hintText: 'Pilih Kelurahan',
                disabledHint: 'Pilih kecamatan terlebih dahulu',
                value: senderVillage,
                items: senderVillages,
                itemLabel: (v) => v.name,
                onChanged: (v) {
                  if (v != null) onSenderVillageSelected(v);
                },
                enabled: senderDistrict != null,
                isLoading: isLoadingSenderVillages,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      label: 'Alamat Lengkap Pengirim',
                      hintText: 'Nama jalan, nomor rumah, RT/RW, patokan',
                      controller: senderAddressController,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Kode Pos',
                      hintText: '12xxx',
                      controller: senderPostalController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildLocationPickerBadge(
                label: 'Titik Lokasi Pengirim',
                latitude: senderLatitude,
                longitude: senderLongitude,
                onTap: onPickSenderLocation,
                isSender: true,
              ),
            ],
          ),
        ),

        // RECIPIENT SECTION CARD
        ShipmentFormCard(
          title: 'Alamat Penerima (Tujuan)',
          subtitle: 'Lokasi dan rincian kontak tujuan pengantaran',
          icon: Icons.move_to_inbox_rounded,
          isDark: isDark,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Tujuan',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Nama Lengkap Penerima',
                hintText: 'Nama penerima paket',
                controller: receiverNameController,
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Nomor Telepon / WhatsApp',
                hintText: '0812xxxxxxxx',
                controller: receiverPhoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              ),
              const SizedBox(height: 12),
              _buildRegionDropdown<Province>(
                label: 'Provinsi Penerima',
                hintText: 'Pilih Provinsi',
                value: receiverProvince,
                items: provinces,
                itemLabel: (p) => p.name,
                onChanged: (p) {
                  if (p != null) onReceiverProvinceSelected(p);
                },
              ),
              const SizedBox(height: 10),
              _buildRegionDropdown<Regency>(
                label: 'Kabupaten / Kota',
                hintText: 'Pilih Kabupaten/Kota',
                disabledHint: 'Pilih provinsi terlebih dahulu',
                value: receiverRegency,
                items: receiverRegencies,
                itemLabel: (r) => r.name,
                onChanged: (r) {
                  if (r != null) onReceiverRegencySelected(r);
                },
                enabled: receiverProvince != null,
                isLoading: isLoadingReceiverRegencies,
              ),
              const SizedBox(height: 10),
              _buildRegionDropdown<District>(
                label: 'Kecamatan',
                hintText: 'Pilih Kecamatan',
                disabledHint: 'Pilih kabupaten/kota terlebih dahulu',
                value: receiverDistrict,
                items: receiverDistricts,
                itemLabel: (d) => d.name,
                onChanged: (d) {
                  if (d != null) onReceiverDistrictSelected(d);
                },
                enabled: receiverRegency != null,
                isLoading: isLoadingReceiverDistricts,
              ),
              const SizedBox(height: 10),
              _buildRegionDropdown<Village>(
                label: 'Kelurahan',
                hintText: 'Pilih Kelurahan',
                disabledHint: 'Pilih kecamatan terlebih dahulu',
                value: receiverVillage,
                items: receiverVillages,
                itemLabel: (v) => v.name,
                onChanged: (v) {
                  if (v != null) onReceiverVillageSelected(v);
                },
                enabled: receiverDistrict != null,
                isLoading: isLoadingReceiverVillages,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: CustomTextField(
                      label: 'Alamat Lengkap Penerima',
                      hintText: 'Nama jalan, gedung, nomor rumah, RT/RW',
                      controller: receiverAddressController,
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Kode Pos',
                      hintText: '14xxx',
                      controller: receiverPostalController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildLocationPickerBadge(
                label: 'Titik Lokasi Penerima',
                latitude: receiverLatitude,
                longitude: receiverLongitude,
                onTap: onPickReceiverLocation,
                isSender: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPickerBadge({
    required String label,
    required double? latitude,
    required double? longitude,
    required VoidCallback? onTap,
    required bool isSender,
  }) {
    final hasCoord = latitude != null &&
        longitude != null &&
        latitude != 0.0 &&
        longitude != 0.0;
    final accentColor = isSender ? AppColors.primary : AppColors.secondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasCoord
            ? accentColor.withValues(alpha: 0.07)
            : (isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasCoord
              ? accentColor.withValues(alpha: 0.35)
              : (isDark ? Colors.white10 : Colors.black12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hasCoord
                  ? accentColor.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasCoord
                  ? Icons.pin_drop_rounded
                  : Icons.add_location_alt_outlined,
              size: 20,
              color: hasCoord ? accentColor : Colors.grey,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (hasCoord)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'GPS TERPASANG',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  (latitude != null && longitude != null)
                      ? 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}'
                      : 'Buka Google Maps untuk menentukan titik koordinat presisi',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: hasCoord ? 'monospace' : null,
                    color: hasCoord
                        ? (isDark ? Colors.white70 : Colors.black87)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(
              hasCoord ? Icons.edit_location_alt_rounded : Icons.map_rounded,
              size: 14,
            ),
            label: Text(
              hasCoord ? 'Ubah' : 'Buka Peta',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
