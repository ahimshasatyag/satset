import 'package:flutter/material.dart';
import 'package:satset/shared/theme/app_colors.dart';

/// Helper konfigurasi visual dan label status pengiriman & pembayaran untuk Admin
class AdminStatusHelper {
  AdminStatusHelper._();

  /// Mengembalikan nama label status dari kode status pengiriman
  static String getStatusLabel(String? code) {
    final c = (code ?? '').toUpperCase();
    switch (c) {
      case 'PENDING':
        return 'Menunggu Konfirmasi';
      case 'CONFIRMED':
        return 'Dikonfirmasi';
      case 'PICKUP_SCHEDULED':
        return 'Jadwal Pickup';
      case 'PICKED_UP':
        return 'Telah Di-pickup';
      case 'IN_TRANSIT':
        return 'Dalam Pengiriman';
      case 'AT_SORTING_CENTER':
        return 'Sorting Center';
      case 'OUT_FOR_DELIVERY':
        return 'Sedang Diantar';
      case 'DELIVERED':
        return 'Berhasil Terkirim';
      case 'FAILED_DELIVERY':
        return 'Gagal Terkirim';
      case 'RETURNED':
        return 'Dikembalikan';
      case 'CANCELLED':
        return 'Dibatalkan';
      default:
        return code ?? 'Tidak Diketahui';
    }
  }

  /// Warna badge status pengiriman (menggunakan palet resmi AppColors)
  static Color getStatusColor(String? code, {bool isDark = false}) {
    final c = (code ?? '').toUpperCase();
    switch (c) {
      case 'DELIVERED':
        return AppColors.success;
      case 'FAILED_DELIVERY':
      case 'CANCELLED':
        return AppColors.error;
      case 'PENDING':
      case 'PICKUP_SCHEDULED':
        return AppColors.warning;
      case 'CONFIRMED':
      case 'PICKED_UP':
      case 'IN_TRANSIT':
      case 'AT_SORTING_CENTER':
      case 'OUT_FOR_DELIVERY':
        return AppColors.info;
      default:
        return isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    }
  }

  /// Warna background badge status pengiriman yang kontras
  static Color getStatusBgColor(String? code, {bool isDark = false}) {
    final baseColor = getStatusColor(code, isDark: isDark);
    return baseColor.withValues(alpha: isDark ? 0.2 : 0.12);
  }

  /// Label status pembayaran
  static String getPaymentStatusLabel(String? status) {
    final s = (status ?? '').toUpperCase();
    switch (s) {
      case 'PAID':
      case 'SUCCESS':
      case 'BERHASIL':
        return 'Lunas';
      case 'PENDING':
      case 'MENUNGGU':
        return 'Menunggu Pembayaran';
      case 'COD':
        return 'COD (Bayar di Tempat)';
      case 'FAILED':
      case 'GAGAL':
        return 'Gagal';
      case 'EXPIRED':
      case 'KADALUARSA':
        return 'Kadaluarsa';
      default:
        return status ?? '-';
    }
  }

  /// Warna badge status pembayaran
  static Color getPaymentStatusColor(String? status, {bool isDark = false}) {
    final s = (status ?? '').toUpperCase();
    switch (s) {
      case 'PAID':
      case 'SUCCESS':
      case 'BERHASIL':
        return AppColors.success;
      case 'COD':
        return AppColors.secondary;
      case 'PENDING':
      case 'MENUNGGU':
        return AppColors.warning;
      case 'FAILED':
      case 'GAGAL':
      case 'EXPIRED':
        return AppColors.error;
      default:
        return isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    }
  }
}

