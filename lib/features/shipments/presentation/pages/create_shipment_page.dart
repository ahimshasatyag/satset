import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../widgets/create_shipment_sheet.dart';

/// Halaman penuh untuk pembuatan pesanan pengiriman SatSet
class CreateShipmentPage extends StatelessWidget {
  final dynamic repository;
  final Function(Map<String, dynamic> data)? onOrderCreated;

  const CreateShipmentPage({
    super.key,
    this.repository,
    this.onOrderCreated,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Buat Pengiriman Baru',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: CreateShipmentSheet(
        repository: repository,
        onOrderCreated: onOrderCreated ??
            (data) {
              Navigator.of(context).pop(data);
            },
      ),
    );
  }
}
