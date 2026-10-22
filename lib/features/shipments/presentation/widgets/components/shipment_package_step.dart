import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

import '../../../domain/entities/shipment.dart';
import 'shipment_form_card.dart';

/// Step 2: Form informasi barang & paket, pilihan jenis layanan ekspedisi, dan proteksi asuransi.
class ShipmentPackageStep extends StatelessWidget {
  final bool isDark;

  // Controllers
  final TextEditingController itemDescController;
  final TextEditingController weightController;
  final TextEditingController lengthController;
  final TextEditingController widthController;
  final TextEditingController heightController;
  final TextEditingController itemCountController;

  // Layanan & Asuransi
  final List<OrderServiceType> serviceTypes;
  final OrderServiceType? selectedService;
  final bool useInsurance;
  final Map<String, double> cost;

  // Callbacks
  final ValueChanged<OrderServiceType> onServiceSelected;
  final ValueChanged<bool> onInsuranceChanged;
  final VoidCallback onPackageDimensionsChanged;

  const ShipmentPackageStep({
    super.key,
    required this.isDark,
    required this.itemDescController,
    required this.weightController,
    required this.lengthController,
    required this.widthController,
    required this.heightController,
    required this.itemCountController,
    required this.serviceTypes,
    required this.selectedService,
    required this.useInsurance,
    required this.cost,
    required this.onServiceSelected,
    required this.onInsuranceChanged,
    required this.onPackageDimensionsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final billedKg = cost['billedKg'] ?? 1.0;
    final goodsVal = cost['goodsValue'] ?? 0.0;
    final calculatedInsuranceFee =
        cost['calculatedInsuranceFee'] ??
        (goodsVal * (selectedService?.insuranceRate ?? 0.002)).roundToDouble();
    final serviceName = selectedService?.name ?? 'Reguler';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // INFORMASI BARANG & PAKET CARD
        ShipmentFormCard(
          title: 'Informasi Barang & Paket',
          subtitle: 'Rincian deskripsi, berat, dan dimensi fisik paket',
          icon: Icons.inventory_2_outlined,
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                label: 'Deskripsi / Nama Barang',
                hintText: 'Contoh: Pakaian, Dokumen, Makanan Kering, Aksesoris',
                controller: itemDescController,
                prefixIcon: const Icon(Icons.description_outlined, size: 20),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Berat Total (Gram)',
                      hintText: '1000',
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.scale_rounded, size: 20),
                      onChanged: (_) => onPackageDimensionsChanged(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      label: 'Jumlah Paket (Pcs)',
                      hintText: '1',
                      controller: itemCountController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.layers_outlined, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Dimensi Paket (Panjang x Lebar x Tinggi)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'P (cm)',
                      hintText: '20',
                      controller: lengthController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => onPackageDimensionsChanged(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomTextField(
                      label: 'L (cm)',
                      hintText: '15',
                      controller: widthController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => onPackageDimensionsChanged(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomTextField(
                      label: 'T (cm)',
                      hintText: '10',
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => onPackageDimensionsChanged(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.05,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Berat Volumetrik: ${(cost['volumetricKg'] ?? 0.0).toStringAsFixed(2)} kg (dibulatkan: ${(cost['chargeableKg'] ?? 1.0).ceil()} kg)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // PILIHAN LAYANAN EKSPEDISI CARD
        ShipmentFormCard(
          title: 'Pilihan Jenis Layanan Ekspedisi',
          subtitle: 'Pilih layanan pengiriman sesuai durasi dan tarif premi',
          icon: Icons.local_shipping_outlined,
          isDark: isDark,
          child: Column(
            children: serviceTypes.map((service) {
              final isSelected = selectedService?.id == service.id;
              final serviceShippingCost = service.basePrice * billedKg;

              return GestureDetector(
                onTap: () => onServiceSelected(service),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : (isDark
                              ? const Color(0xFF1B2A3D)
                              : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected ? AppColors.primary : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppColors.primary : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Estimasi Tiba: ${service.estimationLabel}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isSelected
                                            ? AppColors.primary
                                            : Colors.grey)
                                        .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Premi Asuransi: ${service.insuranceRatePercentLabel}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatRupiah(serviceShippingCost),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${formatRupiah(service.basePrice)}/kg × ${billedKg.toInt()} kg',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // PROTEKSI ASURANSI PENGIRIMAN CARD
        ShipmentFormCard(
          title: 'Proteksi Asuransi Pengiriman',
          subtitle: 'Pilih opsi perlindungan kompensasi paket',
          icon: Icons.shield_outlined,
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Opsi 1: Gunakan Asuransi (Ditambah nominal otomatis dari rumus)
              GestureDetector(
                onTap: () => onInsuranceChanged(true),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: useInsurance
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : (isDark
                              ? const Color(0xFF1B2A3D)
                              : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: useInsurance
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: useInsurance,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        onChanged: (val) => onInsuranceChanged(val ?? false),
                      ),
                      const SizedBox(width: 8),
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
                                  'Gunakan Proteksi Asuransi (+${formatRupiah(calculatedInsuranceFee)})',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: useInsurance
                                        ? AppColors.primary
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Kompensasi penggantian hingga 100% senilai ${formatRupiah(goodsVal)} jika paket rusak/hilang selama pengantaran ekspedisi $serviceName.',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        useInsurance
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: useInsurance ? AppColors.primary : Colors.grey,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),

              // Opsi 2: Tanpa Asuransi
              GestureDetector(
                onTap: () => onInsuranceChanged(false),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: !useInsurance
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : (isDark
                              ? const Color(0xFF1B2A3D)
                              : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !useInsurance
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        !useInsurance
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: !useInsurance ? AppColors.primary : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanpa Proteksi Asuransi (Gratis - Rp 0)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: !useInsurance ? AppColors.primary : null,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Kompensasi penggantian standar terbatas sesuai kebijakan syarat & ketentuan ekspedisi.',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
