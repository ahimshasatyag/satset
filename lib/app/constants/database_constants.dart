/// Konstanta skema basis data PostgreSQL Supabase SatSet
class DatabaseConstants {
  DatabaseConstants._();

  /// Nama tabel master pengguna
  static const String tableUsers = 'm_users';
}

/// Kolom-kolom tabel m_users di Supabase
class UserTableColumns {
  UserTableColumns._();

  static const String id = 'id';
  static const String namaLengkap = 'nama_lengkap';
  static const String email = 'email';
  static const String noHp = 'no_hp';
  static const String password = 'password';
  static const String role = 'role';
  static const String googleId = 'google_id';
  static const String alamatLengkap = 'alamat_lengkap';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String resetToken = 'reset_token';
  static const String tokenExpiredAt = 'token_expired_at';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}
