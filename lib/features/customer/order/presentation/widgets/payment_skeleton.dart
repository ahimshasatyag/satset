import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

/// Widget skeleton loading placeholder untuk Halaman Pembayaran (PaymentPage) SatSet.
/// Meniru tata letak status banner, barcode resi, ringkasan tagihan, dan instruksi gateway pembayaran.
class PaymentSkeleton extends StatelessWidget {
  /// Jika true, menampilkan keseluruhan Scaffold beserta AppBar skeleton.
  final bool showAppBar;

  const PaymentSkeleton({
    super.key,
    this.showAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final innerBoxBg =
        isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF8FAFC);

    final content = SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Shimmer Status Banner Card
          _buildStatusBannerSkeleton(cardBg, borderColor, innerBoxBg, isDark),
          const SizedBox(height: 16),

          // 2. Shimmer Barcode & No. Resi Card
          _buildResiBarcodeSkeleton(cardBg, borderColor, innerBoxBg, isDark),
          const SizedBox(height: 16),

          // 3. Shimmer Ringkasan Tagihan & Rincian Biaya
          _buildBillSummarySkeleton(cardBg, borderColor, isDark),
          const SizedBox(height: 16),

          // 4. Shimmer Instruksi Pembayaran (Virtual Account & Langkah)
          _buildInstructionsSkeleton(cardBg, borderColor, innerBoxBg, isDark),
          const SizedBox(height: 24),

          // 5. Shimmer Tombol Aksi Verifikasi / Selesai
          CustomShimmer(
            width: double.infinity,
            height: 48,
            borderRadius: BorderRadius.circular(14),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    if (showAppBar) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: cardBg,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const CustomShimmer(width: 150, height: 18),
        ),
        body: content,
      );
    }

    return content;
  }

  /// Shimmer Status Banner
  Widget _buildStatusBannerSkeleton(
      Color cardBg, Color borderColor, Color innerBoxBg, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              CustomShimmer.circle(size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomShimmer(width: 160, height: 15),
                    SizedBox(height: 6),
                    CustomShimmer(width: 210, height: 11),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: innerBoxBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomShimmer.circle(size: 16),
                SizedBox(width: 8),
                CustomShimmer(width: 130, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer Nomor Resi & Garis-garis Barcode
  Widget _buildResiBarcodeSkeleton(
      Color cardBg, Color borderColor, Color innerBoxBg, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomShimmer(width: 130, height: 12),
              CustomShimmer.circle(size: 18),
            ],
          ),
          const SizedBox(height: 10),
          const CustomShimmer(width: 190, height: 22),
          const SizedBox(height: 12),
          // Barcode container with shimmer stripes
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: innerBoxBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(24, (index) {
                final isThick = index % 3 == 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: CustomShimmer(
                    width: isThick ? 4 : 2,
                    height: double.infinity,
                    borderRadius: BorderRadius.circular(1),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          const CustomShimmer(width: 120, height: 10),
        ],
      ),
    );
  }

  /// Shimmer Ringkasan Tagihan & Rincian Pengiriman
  Widget _buildBillSummarySkeleton(
      Color cardBg, Color borderColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomShimmer(width: 180, height: 16),
          const SizedBox(height: 14),
          _buildSummaryRowSkeleton(80, 110),
          _buildSummaryRowSkeleton(70, 75),
          _buildSummaryRowSkeleton(90, 120),
          _buildSummaryRowSkeleton(60, 140),
          Divider(height: 20, color: borderColor),
          _buildSummaryRowSkeleton(110, 85),
          _buildSummaryRowSkeleton(95, 75),
          _buildSummaryRowSkeleton(80, 70),
          Divider(height: 20, color: borderColor),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomShimmer(width: 125, height: 16),
              CustomShimmer(width: 95, height: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRowSkeleton(double labelWidth, double valueWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomShimmer(width: labelWidth, height: 12),
          CustomShimmer(width: valueWidth, height: 12),
        ],
      ),
    );
  }

  /// Shimmer Instruksi Gateway / Virtual Account
  Widget _buildInstructionsSkeleton(
      Color cardBg, Color borderColor, Color innerBoxBg, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CustomShimmer(width: 165, height: 14),
              CustomShimmer(
                width: 80,
                height: 20,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Shimmer Virtual Account Code Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: innerBoxBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomShimmer(width: 120, height: 10),
                    SizedBox(height: 6),
                    CustomShimmer(width: 160, height: 16),
                  ],
                ),
                CustomShimmer(
                  width: 55,
                  height: 28,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Shimmer Panduan Pembayaran
          const CustomShimmer(width: 130, height: 13),
          const SizedBox(height: 10),
          ...List.generate(4, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomShimmer.circle(size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomShimmer(
                      width: double.infinity,
                      height: index == 3 ? 24 : 12,
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
}
