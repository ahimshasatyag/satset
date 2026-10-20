import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class CreateShipmentSheet extends StatefulWidget {
  final Function(Map<String, dynamic> data) onOrderCreated;

  const CreateShipmentSheet({
    super.key,
    required this.onOrderCreated,
  });

  static void show(
    BuildContext context, {
    required Function(Map<String, dynamic> data) onOrderCreated,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateShipmentSheet(onOrderCreated: onOrderCreated),
    );
  }

  @override
  State<CreateShipmentSheet> createState() => _CreateShipmentSheetState();
}

class _CreateShipmentSheetState extends State<CreateShipmentSheet> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _receiverController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  String _selectedService = 'SATSET Instant';
  String _pickupSchedule = 'Jemput Sekarang';
  int _estimatedPrice = 24000;

  @override
  void dispose() {
    _itemController.dispose();
    _receiverController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _submit() {
    final item = _itemController.text.trim();
    final receiver = _receiverController.text.trim();
    final dest = _destinationController.text.trim();

    if (item.isEmpty || dest.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi nama barang dan alamat tujuan.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).pop();
    widget.onOrderCreated({
      'itemName': item,
      'receiverName': receiver.isEmpty ? 'Penerima SatSet' : receiver,
      'destinationCity': dest,
      'serviceType': _selectedService,
      'price': _estimatedPrice,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Judul Form
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Buat Pengiriman Baru',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nama Barang
            CustomTextField(
              label: 'Nama Barang / Paket',
              hintText: 'Contoh: Kue Lebaran, Dokumen Akta, Kamera',
              controller: _itemController,
              prefixIcon: const Icon(Icons.inventory_2_outlined, size: 20),
            ),
            const SizedBox(height: 14),

            // Nama Penerima
            CustomTextField(
              label: 'Nama Penerima',
              hintText: 'Nama lengkap penerima barang',
              controller: _receiverController,
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            ),
            const SizedBox(height: 14),

            // Alamat Tujuan
            CustomTextField(
              label: 'Alamat Tujuan Pengiriman',
              hintText: 'Ketik alamat lengkap atau pilih dari peta',
              controller: _destinationController,
              prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
            ),
            const SizedBox(height: 16),

            // Pilihan Layanan Pengiriman
            Text(
              'Pilihan Layanan',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildServiceChip(
                  label: 'Instant (1-2 Jam)',
                  price: 24000,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                _buildServiceChip(
                  label: 'Sameday (6 Jam)',
                  price: 18000,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Jadwal Penjemputan Kurir
            Text(
              'Waktu Penjemputan',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Jemput Sekarang', 'Nanti Sore (16:00)', 'Besok Pagi']
                  .map((schedule) {
                final isSelected = _pickupSchedule == schedule;
                return ChoiceChip(
                  label: Text(schedule, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  selectedColor: AppColors.secondary.withValues(alpha: 0.2),
                  onSelected: (val) {
                    if (val) setState(() => _pickupSchedule = schedule);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Total Biaya & Tombol Submit
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimasi Biaya',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      Text(
                        'Rp ${_estimatedPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Panggil Kurir',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceChip({
    required String label,
    required int price,
    required bool isDark,
  }) {
    final isSelected = _selectedService.startsWith(label.split(' ').first);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedService = label;
            _estimatedPrice = price;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : (isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white : Colors.black87),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppColors.primary : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
