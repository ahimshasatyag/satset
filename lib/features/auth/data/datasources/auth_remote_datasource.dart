import '../models/user_model.dart';

/// Kontrak Remote Data Source untuk berinteraksi dengan API server
abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String email,
    required String password,
  });

  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<UserModel> loginWithGoogle();

  Future<void> forgotPassword(String email);

  Future<void> logout();
}

/// Implementasi Remote Data Source dengan simulasi endpoint REST API SatSet
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // Simulasi latency jaringan
    await Future.delayed(const Duration(milliseconds: 1000));

    // Validasi format dasar
    if (!email.contains('@') || password.length < 6) {
      throw Exception('Format email tidak valid atau kata sandi minimal 6 karakter.');
    }

    // Mock response sukses autentikasi
    return UserModel(
      id: 'usr_satset_${DateTime.now().millisecondsSinceEpoch}',
      name: email.split('@').first.toUpperCase(),
      email: email,
      phone: '+6281234567890',
      token: 'jwt_token_${DateTime.now().millisecondsSinceEpoch}',
      role: 'customer',
    );
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!email.contains('@') || password.length < 6) {
      throw Exception('Format data pendaftaran tidak lengkap atau kata sandi terlalu pendek.');
    }

    return UserModel(
      id: 'usr_satset_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      phone: phone,
      token: 'jwt_token_${DateTime.now().millisecondsSinceEpoch}',
      role: 'customer',
    );
  }

  @override
  Future<UserModel> loginWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 1200));

    return UserModel(
      id: 'usr_google_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Google User',
      email: 'user.satset@gmail.com',
      phone: '+6289876543210',
      photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde',
      token: 'jwt_google_token_${DateTime.now().millisecondsSinceEpoch}',
      role: 'customer',
    );
  }

  @override
  Future<void> forgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!email.contains('@')) {
      throw Exception('Email tidak terdaftar atau format tidak valid.');
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 400));
  }
}
