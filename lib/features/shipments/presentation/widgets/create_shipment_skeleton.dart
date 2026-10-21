import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

/// Widget skeleton loading placeholder untuk halaman Buat Pengiriman (CreateShipmentPage) SatSet.
/// Meniru tata letak indikator langkah (step indicator), kartu form (card pengirim & penerima),
/// serta tombol navigasi bawah (bottom action bar).
class CreateShipmentSkeleton extends StatelessWidget {
  /// Jika true, menampilkan keseluruhan Scaffold beserta AppBar skeleton.
  final bool showAppBar;

  const CreateShipmentSkeleton({
    super.key,
    this.showAppBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final content = Column(
      children: [
        // 1. Shimmer Step Indicator Bar (Atas)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(
              bottom: BorderSide(color: borderColor, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: CustomShimmer(
                  width: double.infinity,
                  height: 32,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ),
              Expanded(
                child: CustomShimmer(
                  width: double.infinity,
                  height: 32,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ),
              Expanded(
                child: CustomShimmer(
                  width: double.infinity,
                  height: 32,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),

        // 2. Shimmer Scrollable Form Cards
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Card 1: Pengirim Skeleton
                _buildCardSkeleton(
                  cardBg: cardBg,
                  borderColor: borderColor,
                  isDark: isDark,
                  titleWidth: 160,
                  subtitleWidth: 220,
                  badgeWidth: 42,
                  fieldsCount: 4,
                  hasDoubleDropdown: true,
                ),

                const SizedBox(height: 16),

                // Card 2: Penerima Skeleton
                _buildCardSkeleton(
                  cardBg: cardBg,
                  borderColor: borderColor,
                  isDark: isDark,
                  titleWidth: 175,
                  subtitleWidth: 240,
                  badgeWidth: 52,
                  fieldsCount: 3,
                  hasDoubleDropdown: true,
                ),
              ],
            ),
          ),
        ),

        // 3. Shimmer Bottom Navigation Bar
        Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(
              top: BorderSide(color: borderColor, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: CustomShimmer(
            width: double.infinity,
            height: 48,
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ],
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
          title: const CustomShimmer(width: 160, height: 18),
        ),
        body: content,
      );
    }

    return content;
  }

  /// Shimmer Box Kartu Formulir dengan Header dan Input Fields
  Widget _buildCardSkeleton({
    required Color cardBg,
    required Color borderColor,
    required bool isDark,
    required double titleWidth,
    required double subtitleWidth,
    required double badgeWidth,
    required int fieldsCount,
    bool hasDoubleDropdown = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              CustomShimmer(
                width: 36,
                height: 36,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomShimmer(width: titleWidth, height: 15),
                    const SizedBox(height: 6),
                    CustomShimmer(width: subtitleWidth, height: 11),
                  ],
                ),
              ),
              CustomShimmer(
                width: badgeWidth,
                height: 22,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 14),

          // Input Fields Shimmer
          ...List.generate(fieldsCount, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomShimmer(
                    width: 100 + (index * 20 % 60).toDouble(),
                    height: 11,
                  ),
                  const SizedBox(height: 6),
                  CustomShimmer(
                    width: double.infinity,
                    height: 46,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
            );
          }),

          // Row 2 Dropdown (Kecamatan & Kelurahan)
          if (hasDoubleDropdown) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CustomShimmer(width: 80, height: 11),
                        const SizedBox(height: 6),
                        CustomShimmer(
                          width: double.infinity,
                          height: 46,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CustomShimmer(width: 75, height: 11),
                        const SizedBox(height: 6),
                        CustomShimmer(
                          width: double.infinity,
                          height: 46,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
