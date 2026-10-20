/// Basis class untuk semua exception di layer data/remote
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

/// Exception spesifik untuk kegagalan autentikasi (login, register, token)
class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Exception saat koneksi internet bermasalah
class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'Tidak ada koneksi internet.']);

  @override
  String toString() => message;
}

/// Exception saat membaca/menulis ke penyimpanan lokal
class CacheException implements Exception {
  final String message;

  const CacheException([this.message = 'Gagal mengakses data penyimpanan lokal.']);

  @override
  String toString() => message;
}

/// Exception saat input tidak lolos validasi bisnis
class ValidationException implements Exception {
  final String message;

  const ValidationException(this.message);

  @override
  String toString() => message;
}
