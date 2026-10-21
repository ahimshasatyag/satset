import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../widgets/create_shipment_sheet.dart';
import '../widgets/create_shipment_skeleton.dart';

export '../widgets/create_shipment_skeleton.dart';

/// Halaman penuh untuk pembuatan pesanan pengiriman SatSet
class CreateShipmentPage extends StatelessWidget {
  final dynamic repository;
  final Function(Map<String, dynamic> data)? onOrderCreated;
  final bool isLoading;

  const CreateShipmentPage({
    super.key,
    this.repository,
    this.onOrderCreated,
    this.isLoading = false,
  });

  /// Navigasi langsung ke [CreateShipmentPage] sebagai halaman penuh
  static Future<T?> navigate<T>(
    BuildContext context, {
    Function(Map<String, dynamic> data)? onOrderCreated,
    dynamic repository,
    bool isLoading = false,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (_) => CreateShipmentPage(
          onOrderCreated: onOrderCreated,
          repository: repository,
          isLoading: isLoading,
        ),
      ),
    );
  }

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
      body: SafeArea(
        top: false,
        child: isLoading
            ? const CreateShipmentSkeleton()
            : CreateShipmentSheet(
                repository: repository,
                onOrderCreated: onOrderCreated ??
                    (data) {
                      Navigator.of(context).pop(data);
                    },
              ),
      ),
    );
  }
}
