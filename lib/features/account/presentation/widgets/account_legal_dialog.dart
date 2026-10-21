import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';

class AccountLegalDialog {
  AccountLegalDialog._();

  /// Menampilkan dialog Kebijakan Privasi
  static void showPrivacyPolicy(BuildContext context) {
    _showContentDialog(
      context,
      title: 'Kebijakan Privasi',
      icon: Icons.privacy_tip_outlined,
      content: '''
1. Pengumpulan Informasi Pribadi
SatSet Delivery mengumpulkan data pengguna seperti nama lengkap, nomor telepon, alamat pengiriman, dan titik koordinat semata-mata untuk keperluan kelancaran pemesanan dan pengantaran logistik Anda.

2. Penggunaan Data Supabase & RLS
Seluruh profil pelanggan dan alamat pengiriman dilindungi oleh teknologi PostgreSQL Row Level Security (RLS) pada Supabase. Pengguna lain atau pihak yang tidak berhak tidak dapat mengakses catatan pengiriman atau informasi akun Anda.

3. Kredensial & Autentikasi
Kata sandi Anda disimpan menggunakan enkripsi hashing aman dan Supabase Auth. Tim SatSet Delivery tidak pernah menanyakan kata sandi akun Anda melalui sambungan telepon atau pesan singkat.

4. Hubungan dengan Pihak Ketiga
Informasi alamat penjemputan dan penerimaan hanya dibagikan kepada kurir yang ditugaskan pada nomor resi aktif yang bersangkutan.
''',
    );
  }

  /// Menampilkan dialog Syarat & Ketentuan Penggunaan
  static void showTermsOfService(BuildContext context) {
    _showContentDialog(
      context,
      title: 'Syarat & Ketentuan',
      icon: Icons.gavel_rounded,
      content: '''
1. Akun Pelanggan
Pengguna bertanggung jawab penuh atas kerahasiaan kata sandi serta segala kegiatan yang terjadi di bawah akun yang terdaftar pada sistem SatSet Delivery.

2. Pemesanan Pengiriman
Setiap pemesanan paket wajib menyertakan alamat yang jelas, kode pos valid, dan nomor kontak penerima yang dapat dihubungi kurir di lapangan.

3. Pembatalan & Asuransi
Pengiriman yang dilindungi program SatSet Protect tunduk pada evaluasi bukti kondisi fisik barang pada saat serah terima oleh petugas kurir.

4. Perubahan Layanan
SatSet Delivery berhak sewaktu-waktu memperbarui ketentuan operasional dan tarif pengiriman sesuai dengan regulasi logistik nasional yang berlaku.
''',
    );
  }

  /// Menampilkan dialog Pusat Bantuan & CS
  static void showHelpCenter(BuildContext context) {
    _showContentDialog(
      context,
      title: 'Pusat Bantuan & CS 24 Jam',
      icon: Icons.support_agent_rounded,
      content: '''
Butuh bantuan terkait akun atau pesanan pengiriman SatSet?

• Hotline Pelanggan: 1500-SATSET (1500-728738) Bebas Pulsa
• WhatsApp CS Resmi: +62 812-9900-SATSET
• Email Bantuan: support@satset.id
• Jam Operasional: Siap melayani 24 Jam Nonstop setiap hari

Petugas customer service kami selalu siap membantu pengecekan resi, klaim proteksi paket, dan pembaruan data akun.
''',
    );
  }

  /// Menampilkan dialog Informasi Aplikasi
  static void showAppInfo(BuildContext context) {
    _showContentDialog(
      context,
      title: 'Tentang SatSet Delivery',
      icon: Icons.info_outline_rounded,
      content: '''
SatSet Delivery — Sat-Set Sampai, Hati Pun Santai.

• Versi Aplikasi: v1.0.0
• Build: 2026.10
• Engine: Flutter & Supabase Real-time Cloud
• Pengembang: Tim Pengembang SatSet Logistik Indonesia

Aplikasi pengiriman kilat dan kargo terpercaya yang menghubungkan seluruh wilayah nusantara dengan transparansi pelacakan real-time dan tarif hemat.
''',
    );
  }

  static void _showContentDialog(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String content,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: Text(
                      content.trim(),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: CustomButton(
                    text: 'Tutup',
                    size: ButtonSize.small,
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
