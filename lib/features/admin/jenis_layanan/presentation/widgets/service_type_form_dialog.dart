import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/admin_service_type_item.dart';

class ServiceTypeFormDialog extends StatefulWidget {
  final AdminServiceTypeItem? existingService;
  final void Function({
    required String kode,
    required String namaLayanan,
    required int estimasiHariMin,
    required int estimasiHariMax,
    String? deskripsi,
    num? baseTariffPerKg,
    required bool isActive,
  }) onSubmit;

  const ServiceTypeFormDialog({
    super.key,
    this.existingService,
    required this.onSubmit,
  });

  @override
  State<ServiceTypeFormDialog> createState() => _ServiceTypeFormDialogState();
}

class _ServiceTypeFormDialogState extends State<ServiceTypeFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _kodeController;
  late final TextEditingController _namaController;
  late final TextEditingController _minDaysController;
  late final TextEditingController _maxDaysController;
  late final TextEditingController _tariffController;
  late final TextEditingController _deskripsiController;
  late bool _isActive;

  bool get _isEditing => widget.existingService != null;

  @override
  void initState() {
    super.initState();
    final s = widget.existingService;
    _kodeController = TextEditingController(text: s?.kode ?? '');
    _namaController = TextEditingController(text: s?.namaLayanan ?? '');
    _minDaysController = TextEditingController(
      text: (s?.estimasiHariMin ?? 1).toString(),
    );
    _maxDaysController = TextEditingController(
      text: (s?.estimasiHariMax ?? 3).toString(),
    );
    _tariffController = TextEditingController(
      text: (s?.baseTariffPerKg ?? 15000).toInt().toString(),
    );
    _deskripsiController = TextEditingController(text: s?.deskripsi ?? '');
    _isActive = s?.isActive ?? true;
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _minDaysController.dispose();
    _maxDaysController.dispose();
    _tariffController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final minDays = int.tryParse(_minDaysController.text.trim()) ?? 0;
    final maxDays = int.tryParse(_maxDaysController.text.trim()) ?? 0;
    if (maxDays < minDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Estimasi hari maksimum tidak boleh lebih kecil dari estimasi hari minimum.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final tariff = num.tryParse(
      _tariffController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );

    widget.onSubmit(
      kode: _kodeController.text.trim().toUpperCase(),
      namaLayanan: _namaController.text.trim(),
      estimasiHariMin: minDays,
      estimasiHariMax: maxDays,
      deskripsi: _deskripsiController.text.trim().isEmpty
          ? null
          : _deskripsiController.text.trim(),
      baseTariffPerKg: tariff,
      isActive: _isActive,
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _isEditing
                                  ? Icons.edit_note_rounded
                                  : Icons.add_box_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEditing
                                    ? 'Edit Master Jenis Layanan'
                                    : 'Tambah Jenis Layanan Baru',
                                style: AppTextStyles.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Tabel public.m_service_types',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const Divider(height: 28),

                  // Baris 1: Kode Layanan & Nama Layanan
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: TextFormField(
                          controller: _kodeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Kode Layanan *',
                            hintText: 'Misal: REG, EXP, SAMEDAY',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Kode wajib diisi';
                            }
                            if (v.trim().length > 20) {
                              return 'Maksimal 20 karakter';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 6,
                        child: TextFormField(
                          controller: _namaController,
                          decoration: InputDecoration(
                            labelText: 'Nama Layanan *',
                            hintText: 'Misal: Reguler, Express, Same Day',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Nama layanan wajib diisi';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Baris 2: Estimasi Hari Min, Estimasi Hari Max, & Tarif Dasar / Kg
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _minDaysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Estimasi Min (Hari) *',
                            hintText: '0 untuk Same Day',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) {
                            final n = int.tryParse(v?.trim() ?? '');
                            if (n == null || n < 0) {
                              return 'Angka >= 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _maxDaysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Estimasi Maks (Hari) *',
                            hintText: '0 untuk Same Day',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (v) {
                            final n = int.tryParse(v?.trim() ?? '');
                            if (n == null || n < 0) {
                              return 'Angka >= 0';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _tariffController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Tarif Dasar / Kg (Rp)',
                            hintText: '15000',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Baris 3: Deskripsi Layanan
                  TextFormField(
                    controller: _deskripsiController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi Layanan (deskripsi)',
                      hintText:
                          'Penjelasan cakupan layanan, kecepatan pengantaran, dan keunggulan...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Baris 4: Status Aktif / Nonaktif
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: _isActive,
                      activeThumbColor: AppColors.success,
                      title: Text(
                        _isActive
                            ? 'Status Layanan: Aktif (is_active = true)'
                            : 'Status Layanan: Tidak Aktif (is_active = false)',
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        _isActive
                            ? 'Layanan ditampilkan sebagai pilihan pada formulir pemesanan pengiriman customer.'
                            : 'Layanan disembunyikan dari pemesanan customer baru, namun riwayat pengiriman lama tetap tersimpan.',
                        style: AppTextStyles.bodySmall,
                      ),
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Info Perlindungan Histori Transaksi
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Perubahan konfigurasi atau tarif layanan hanya berlaku untuk pesanan baru dan tidak mengubah total_biaya pada transaksi pengiriman (t_shipments) yang sudah dibuat sebelumnya.',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        onPressed: _handleSubmit,
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: Text(
                          _isEditing
                              ? 'Simpan Perubahan'
                              : 'Tambahkan Layanan',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

