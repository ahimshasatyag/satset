import 'dart:io';

/// Kontrak untuk mengecek ketersediaan koneksi jaringan
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

/// Implementasi pengecekan koneksi internet menggunakan DNS lookup
class NetworkInfoImpl implements NetworkInfo {
  @override
  Future<bool> get isConnected async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
