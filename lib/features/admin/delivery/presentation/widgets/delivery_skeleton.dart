import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';

/// Widget dasar animasi shimmer/pulse untuk skeleton loading halaman Delivery Management.
class DeliverySkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const DeliverySkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<DeliverySkeletonBox> createState() => _DeliverySkeletonBoxState();
}

class _DeliverySkeletonBoxState extends State<DeliverySkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.35,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.borderLight;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: _animation.value),
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.rectangle
                ? BorderRadius.circular(widget.borderRadius)
                : null,
          ),
        );
      },
    );
  }
}

/// Skeleton loading lengkap untuk konten utama halaman AdminDeliveryPage.
class AdminDeliverySkeleton extends StatelessWidget {
  const AdminDeliverySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Skeleton Header Banner Delivery Management
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DeliverySkeletonBox(width: 340, height: 22),
                      SizedBox(height: 8),
                      DeliverySkeletonBox(width: 560, height: 14),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                DeliverySkeletonBox(width: 52, height: 52, borderRadius: 14),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Skeleton Tab Pengelompokan Status Pengiriman
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(8, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: const Row(
                      children: [
                        DeliverySkeletonBox(
                          width: 18,
                          height: 18,
                          borderRadius: 4,
                        ),
                        SizedBox(width: 8),
                        DeliverySkeletonBox(width: 95, height: 14),
                        SizedBox(width: 8),
                        DeliverySkeletonBox(
                          width: 24,
                          height: 18,
                          borderRadius: 10,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Skeleton Bar Pencarian & Filter Komprehensif
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                DeliverySkeletonBox(width: 280, height: 38, borderRadius: 10),
                DeliverySkeletonBox(width: 215, height: 38, borderRadius: 10),
                DeliverySkeletonBox(width: 195, height: 38, borderRadius: 10),
                DeliverySkeletonBox(width: 185, height: 38, borderRadius: 10),
                DeliverySkeletonBox(width: 205, height: 38, borderRadius: 10),
                DeliverySkeletonBox(width: 230, height: 38, borderRadius: 10),
                DeliverySkeletonBox(width: 150, height: 38, borderRadius: 10),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Skeleton Tabel Daftar Transaksi Pengiriman
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DeliverySkeletonBox(width: 220, height: 18),
                      SizedBox(height: 6),
                      DeliverySkeletonBox(width: 310, height: 12),
                    ],
                  ),
                ),
                DeliveryTableRowsSkeleton(rowCount: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton baris-baris tabel untuk DeliveryDataTable saat sedang memuat data.
class DeliveryTableRowsSkeleton extends StatelessWidget {
  final int rowCount;

  const DeliveryTableRowsSkeleton({super.key, this.rowCount = 6});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: List.generate(rowCount, (index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: const Row(
            children: [
              // Resi & Barcode
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DeliverySkeletonBox(width: 130, height: 14),
                  SizedBox(height: 6),
                  DeliverySkeletonBox(width: 95, height: 11),
                ],
              ),
              SizedBox(width: 22),
              // Pengirim
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DeliverySkeletonBox(width: 105, height: 14),
                    SizedBox(height: 6),
                    DeliverySkeletonBox(width: 85, height: 11),
                  ],
                ),
              ),
              SizedBox(width: 16),
              // Penerima
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DeliverySkeletonBox(width: 105, height: 14),
                    SizedBox(height: 6),
                    DeliverySkeletonBox(width: 85, height: 11),
                  ],
                ),
              ),
              SizedBox(width: 16),
              // Alamat Asal & Tujuan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DeliverySkeletonBox(width: 145, height: 12),
                    SizedBox(height: 6),
                    DeliverySkeletonBox(width: 145, height: 12),
                  ],
                ),
              ),
              SizedBox(width: 16),
              // Layanan & Berat
              DeliverySkeletonBox(width: 75, height: 24, borderRadius: 8),
              SizedBox(width: 18),
              // Biaya & Pembayaran
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DeliverySkeletonBox(width: 85, height: 14),
                  SizedBox(height: 6),
                  DeliverySkeletonBox(width: 65, height: 18, borderRadius: 6),
                ],
              ),
              SizedBox(width: 18),
              // Kurir
              DeliverySkeletonBox(width: 110, height: 14),
              SizedBox(width: 18),
              // Status Pengiriman
              DeliverySkeletonBox(width: 115, height: 26, borderRadius: 20),
              SizedBox(width: 18),
              // Aksi
              DeliverySkeletonBox(width: 80, height: 30, borderRadius: 8),
            ],
          ),
        );
      }),
    );
  }
}
