import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

/// Widget skeleton loading placeholder untuk Halaman Dashboard Customer SatSet
/// Ditampilkan saat BLoC berada dalam kondisi [DashboardLoading].
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Skeleton Header (Avatar, Sapaan Nama, Lokasi, Notifikasi)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const CustomShimmer.circle(size: 48),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomShimmer(width: 170, height: 18),
                      SizedBox(height: 6),
                      CustomShimmer(width: 220, height: 13),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const CustomShimmer.circle(size: 42),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // 2. Skeleton Smart Tracking Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: const Row(
                children: [
                  CustomShimmer.circle(size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: CustomShimmer(width: double.infinity, height: 16),
                  ),
                  SizedBox(width: 12),
                  CustomShimmer(width: 65, height: 34),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Skeleton Carousel Slider Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor),
                ),
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(18)),
                  child: CustomShimmer(
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // 3. Skeleton 4 Kartu Ringkasan Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    CustomShimmer(width: 150, height: 16),
                    CustomShimmer(width: 70, height: 12),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(4, (index) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomShimmer.circle(size: 34),
                              SizedBox(height: 8),
                              CustomShimmer(width: 24, height: 18),
                              SizedBox(height: 4),
                              CustomShimmer(width: 48, height: 9),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 4. Skeleton Menu Aksi Cepat (Quick Actions Grid)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    CustomShimmer(width: 90, height: 16),
                    CustomShimmer(width: 80, height: 12),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(4, (index) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 6,
                          ),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomShimmer.circle(size: 42),
                              SizedBox(height: 8),
                              CustomShimmer(width: 50, height: 11),
                              SizedBox(height: 4),
                              CustomShimmer(width: 40, height: 9),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 5. Skeleton Live Shipment Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CustomShimmer(width: 80, height: 20),
                              SizedBox(width: 8),
                              CustomShimmer(width: 100, height: 18),
                            ],
                          ),
                          SizedBox(height: 8),
                          CustomShimmer(width: 160, height: 16),
                        ],
                      ),
                      CustomShimmer(width: 85, height: 38),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF131D2A)
                          : const Color(0xFFE8EEF4),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Center(
                      child: CustomShimmer(width: 120, height: 28),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      CustomShimmer(width: 110, height: 13),
                      CustomShimmer(width: 70, height: 13),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(4, (index) {
                      return Expanded(
                        child: Row(
                          children: [
                            const CustomShimmer.circle(size: 20),
                            if (index < 3)
                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4),
                                  child: CustomShimmer(
                                    width: double.infinity,
                                    height: 3,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 6. Skeleton Recent Shipments List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    CustomShimmer(width: 140, height: 16),
                    CustomShimmer(width: 70, height: 14),
                  ],
                ),
                const SizedBox(height: 10),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: const Row(
                        children: [
                          CustomShimmer(width: 44, height: 44),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomShimmer(width: 110, height: 13),
                                SizedBox(height: 6),
                                CustomShimmer(width: 170, height: 14),
                                SizedBox(height: 6),
                                CustomShimmer(width: 130, height: 11),
                              ],
                            ),
                          ),
                          SizedBox(width: 10),
                          CustomShimmer(width: 65, height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
