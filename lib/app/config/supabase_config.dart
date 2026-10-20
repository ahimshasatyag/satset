import 'package:supabase_flutter/supabase_flutter.dart';

/// Konfigurasi koneksi Supabase aplikasi SatSet
class SupabaseConfig {
  SupabaseConfig._();

  /// URL endpoint Supabase project
  static const String url = 'https://hgcrfwoicjbbxngugmth.supabase.co';

  /// Kunci API publishable Supabase
  static const String publishableKey = 'sb_publishable_QnY4qHnLXhuZw4QzesnhLw_1bEDzjWM';

  /// Getter instans Supabase Client aktif
  static SupabaseClient get client => Supabase.instance.client;

  /// Inisialisasi service Supabase saat bootstrap aplikasi
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
    );
  }
}
