import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../../app/config/supabase_config.dart';
import '../../../../../../app/constants/database_constants.dart';
import '../../../../../../shared/theme/theme.dart';
import '../../../../../../shared/widgets/widgets.dart';
import 'package:satset/features/customer/shipments/domain/entities/shipment.dart';

/// Modal Bottom Sheet Kalkulator Cek Ongkir SatSet
/// Menghitung tarif pengiriman rute kota ke kota (tabel `m_kabkot`)
/// dengan perhitungan jarak dasar 1 km = Rp 6.000.
class TarifCalculatorSheet extends StatefulWidget {
  final VoidCallback? onCreateShipment;
  final SupabaseClient? client;
  final List<Regency>? initialCities;

  const TarifCalculatorSheet({
    super.key,
    this.onCreateShipment,
    this.client,
    this.initialCities,
  });

  /// Helper untuk memunculkan modal bottom sheet Kalkulator Cek Ongkir
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onCreateShipment,
    SupabaseClient? client,
    List<Regency>? initialCities,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TarifCalculatorSheet(
        onCreateShipment: onCreateShipment,
        client: client,
        initialCities: initialCities,
      ),
    );
  }

  /// Daftar kota default (fallback) dari tabel m_kabkot
  static const List<Regency> defaultCities = [
    Regency(
      code: '31.74',
      provinceCode: '31',
      name: 'Kota Jakarta Selatan',
      type: 'KOTA',
    ),
    Regency(
      code: '31.71',
      provinceCode: '31',
      name: 'Kota Jakarta Pusat',
      type: 'KOTA',
    ),
    Regency(
      code: '31.73',
      provinceCode: '31',
      name: 'Kota Jakarta Barat',
      type: 'KOTA',
    ),
    Regency(
      code: '31.75',
      provinceCode: '31',
      name: 'Kota Jakarta Timur',
      type: 'KOTA',
    ),
    Regency(
      code: '31.72',
      provinceCode: '31',
      name: 'Kota Jakarta Utara',
      type: 'KOTA',
    ),
    Regency(
      code: '32.73',
      provinceCode: '32',
      name: 'Kota Bandung',
      type: 'KOTA',
    ),
    Regency(
      code: '32.71',
      provinceCode: '32',
      name: 'Kota Bogor',
      type: 'KOTA',
    ),
    Regency(
      code: '32.76',
      provinceCode: '32',
      name: 'Kota Depok',
      type: 'KOTA',
    ),
    Regency(
      code: '32.75',
      provinceCode: '32',
      name: 'Kota Bekasi',
      type: 'KOTA',
    ),
    Regency(
      code: '36.71',
      provinceCode: '36',
      name: 'Kota Tangerang',
      type: 'KOTA',
    ),
    Regency(
      code: '36.74',
      provinceCode: '36',
      name: 'Kota Tangerang Selatan',
      type: 'KOTA',
    ),
    Regency(
      code: '33.74',
      provinceCode: '33',
      name: 'Kota Semarang',
      type: 'KOTA',
    ),
    Regency(
      code: '35.78',
      provinceCode: '35',
      name: 'Kota Surabaya',
      type: 'KOTA',
    ),
    Regency(
      code: '34.71',
      provinceCode: '34',
      name: 'Kota Yogyakarta',
      type: 'KOTA',
    ),
    Regency(
      code: '33.72',
      provinceCode: '33',
      name: 'Kota Surakarta',
      type: 'KOTA',
    ),
    Regency(
      code: '35.73',
      provinceCode: '35',
      name: 'Kota Malang',
      type: 'KOTA',
    ),
  ];

  @override
  State<TarifCalculatorSheet> createState() => _TarifCalculatorSheetState();
}

class _TarifCalculatorSheetState extends State<TarifCalculatorSheet> {
  List<Regency> _cities = [];
  bool _isLoadingCities = true;

  Regency? _originCity;
  Regency? _destinationCity;

  /// Jarak dalam kilometer (default 1 km sesuai ketentuan)
  int _distanceKm = 1;

  /// Berat paket dalam kilogram (default 1 kg)
  int _weightKg = 1;

  /// Harga tarif dasar per 1 km
  static const int basePricePerKm = 6000;

  bool get _isSupabaseAvailable {
    if (widget.client != null) return true;
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient get _client => widget.client ?? SupabaseConfig.client;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  /// Memuat daftar kabupaten/kota dari database Supabase tabel m_kabkot
  Future<void> _loadCities() async {
    if (widget.initialCities != null && widget.initialCities!.isNotEmpty) {
      setState(() {
        _cities = widget.initialCities!;
        _originCity = _cities.first;
        _destinationCity = _cities.length > 1 ? _cities[1] : _cities.first;
        _isLoadingCities = false;
      });
      return;
    }

    if (!_isSupabaseAvailable) {
      setState(() {
        _cities = TarifCalculatorSheet.defaultCities;
        _originCity = _cities.first;
        _destinationCity = _cities.length > 5 ? _cities[5] : _cities.last;
        _isLoadingCities = false;
      });
      return;
    }

    try {
      final rows = await _client
          .from(DatabaseConstants.tableKabkot)
          .select()
          .order(KabkotTableColumns.namaKabkot, ascending: true);

      final loaded = (rows as List)
          .map<Regency>(
            (r) {
              final map = r as Map<String, dynamic>;
              return Regency(
                code: map[KabkotTableColumns.kodeKabkot]?.toString() ?? '',
                provinceCode:
                    map[KabkotTableColumns.kodeProvinsi]?.toString() ?? '',
                name: map[KabkotTableColumns.namaKabkot]?.toString() ?? '',
                type: map[KabkotTableColumns.jenis]?.toString() ?? 'KOTA',
              );
            },
          )
          .toList();

      if (mounted) {
        setState(() {
          _cities =
              loaded.isNotEmpty ? loaded : TarifCalculatorSheet.defaultCities;
          _originCity = _cities.first;
          _destinationCity =
              _cities.length > 5 ? _cities[5] : _cities.last;
          _isLoadingCities = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cities = TarifCalculatorSheet.defaultCities;
          _originCity = _cities.first;
          _destinationCity =
              _cities.length > 5 ? _cities[5] : _cities.last;
          _isLoadingCities = false;
        });
      }
    }
  }

  /// Menukar kota asal dan kota tujuan
  void _swapCities() {
    setState(() {
      final temp = _originCity;
      _originCity = _destinationCity;
      _destinationCity = temp;
    });
  }

  /// Format angka ke Rupiah
  String _formatRupiah(num amount) {
    return 'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Perhitungan Tarif: 1 km = Rp 6.000
    // Biaya dasar rute = jarak * Rp 6.000
    final baseCost = _distanceKm * basePricePerKm;

    // 1. SATSET Reguler: 1 km = Rp 6.000 (dikalikan berat kg)
    final regulerPrice = baseCost * _weightKg;

    // 2. SATSET Sameday: rasio 1.3x dari reguler
    final samedayPrice =
        (_distanceKm * basePricePerKm * 1.3 * _weightKg).round();

    // 3. SATSET Instant: rasio 1.6x dari reguler
    final instantPrice =
        (_distanceKm * basePricePerKm * 1.6 * _weightKg).round();

    final originName = _originCity?.name ?? 'Kota Asal';
    final destinationName = _destinationCity?.name ?? 'Kota Tujuan';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Row (Title & Close Button)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.calculate_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kalkulator Cek Ongkir',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rute kota ke kota (m_kabkot) • Rp 6.000 / km',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card Pemilihan Rute Kota Asal & Kota Tujuan (m_kabkot)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dropdown Kota Asal (Pengirim)
                  SearchableDropdown<Regency>(
                    label: 'Kota Asal (Pengirim)',
                    hintText: 'Pilih Kota Asal',
                    searchHint: 'Cari kabupaten / kota asal...',
                    value: _originCity,
                    items: _cities,
                    isLoading: _isLoadingCities,
                    itemLabel: (r) => r.name,
                    itemSubtitle: (r) => r.type,
                    onChanged: (val) {
                      if (val != null) setState(() => _originCity = val);
                    },
                  ),
                  const SizedBox(height: 6),

                  // Tombol Tukar Rute (Swap)
                  Center(
                    child: InkWell(
                      onTap: _swapCities,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_vert_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Tukar Rute',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Dropdown Kota Tujuan (Penerima)
                  SearchableDropdown<Regency>(
                    label: 'Kota Tujuan (Penerima)',
                    hintText: 'Pilih Kota Tujuan',
                    searchHint: 'Cari kabupaten / kota tujuan...',
                    value: _destinationCity,
                    items: _cities,
                    isLoading: _isLoadingCities,
                    itemLabel: (r) => r.name,
                    itemSubtitle: (r) => r.type,
                    onChanged: (val) {
                      if (val != null) setState(() => _destinationCity = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Card Banner Ringkasan Rute & Tarif Dasar (1 km = Rp 6.000)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.route_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$originName ➔ $destinationName',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tarif Dasar: ${_formatRupiah(basePricePerKm)} / 1 km',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Parameter Penentu Tarif: Jarak (km) & Berat (kg)
            Row(
              children: [
                // 1. Kontrol Jarak Rute (Km)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceVariantDark.withValues(alpha: 0.5)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jarak Rute',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: _distanceKm > 1
                                  ? () => setState(() => _distanceKm--)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.remove_circle_outline,
                                  size: 22,
                                  color: _distanceKm > 1
                                      ? AppColors.primary
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            Text(
                              '$_distanceKm Km',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _distanceKm++),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.add_circle_outline,
                                  size: 22,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Kontrol Berat Paket (Kg)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceVariantDark.withValues(alpha: 0.5)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Berat Paket',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: _weightKg > 1
                                  ? () => setState(() => _weightKg--)
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.remove_circle_outline,
                                  size: 22,
                                  color: _weightKg > 1
                                      ? AppColors.secondary
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            Text(
                              '$_weightKg Kg',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            InkWell(
                              onTap: () => setState(() => _weightKg++),
                              borderRadius: BorderRadius.circular(8),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.add_circle_outline,
                                  size: 22,
                                  color: AppColors.secondary,
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
            ),
            const SizedBox(height: 10),

            // Pilihan Cepat Jarak (Quick Distance Chips)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [1, 5, 10, 25, 50].map((km) {
                  final isSelected = _distanceKm == km;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text('$km Km'),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      backgroundColor: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.surfaceDark : Colors.white),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                      ),
                      onPressed: () => setState(() => _distanceKm = km),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            const Divider(),

            // Hasil Estimasi Tarif Layanan
            const Text(
              'Pilihan Layanan Pengiriman SatSet',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // 1. SATSET Reguler (Rp 6.000 / km)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.tertiary,
                  size: 20,
                ),
              ),
              title: const Text(
                'SATSET Reguler (1-2 Hari)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                'Estimasi tarif standar: $_distanceKm km × ${_formatRupiah(basePricePerKm)}',
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Text(
                _formatRupiah(regulerPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.tertiary,
                ),
              ),
            ),
            const Divider(height: 1),

            // 2. SATSET Sameday (6-8 Jam)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              title: const Text(
                'SATSET Sameday (6-8 Jam)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: const Text(
                'Sampai di hari yang sama',
                style: TextStyle(fontSize: 11),
              ),
              trailing: Text(
                _formatRupiah(samedayPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const Divider(height: 1),

            // 3. SATSET Instant (1-2 Jam)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: const Text(
                'SATSET Instant (1-2 Jam)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: const Text(
                'Pengiriman kilat prioritas',
                style: TextStyle(fontSize: 11),
              ),
              trailing: Text(
                _formatRupiah(instantPrice),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Tombol Buat Pesanan
            CustomButton(
              text: 'Lanjutkan Buat Pesanan (+ Kirim)',
              isFullWidth: true,
              size: ButtonSize.large,
              prefixIcon: const Icon(Icons.send_rounded, size: 20),
              onPressed: () {
                Navigator.of(context).pop();
                widget.onCreateShipment?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
