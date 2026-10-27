import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

import 'package:satset/features/main_navigation/presentation/pages/main_navigation_page.dart';

import '../../data/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'register_page.dart';

/// Halaman Pendaftaran Akun Khusus Kurir SatSet Express.
/// Menyimpan data pendaftaran ke tabel PostgreSQL `m_employee`
/// dengan email, nama lengkap, no_hp, password ter-hash, dan id_users_role=2.
class CourierRegisterPage extends StatefulWidget {
  const CourierRegisterPage({super.key});

  @override
  State<CourierRegisterPage> createState() => _CourierRegisterPageState();
}

class _CourierRegisterPageState extends State<CourierRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alamatController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _hasMinLength = false;
  bool _hasMixedCase = false;
  bool _hasDigits = false;
  bool _hasSpecialChars = false;

  double? _latitude;
  double? _longitude;
  bool _hasPrecached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasPrecached) {
      _hasPrecached = true;
      precacheImage(const AssetImage('assets/images/Background.png'), context);
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePasswordRules);

    // Ambil koordinat lokasi terakhir kurir jika izin lokasi tersedia
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.always ||
            perm == LocationPermission.whileInUse) {
          final pos = await Geolocator.getLastKnownPosition();
          if (pos != null && mounted) {
            setState(() {
              _latitude = pos.latitude;
              _longitude = pos.longitude;
            });
          }
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePasswordRules);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _alamatController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePasswordRules() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasMixedCase =
          password.contains(RegExp(r'[a-z]')) &&
          password.contains(RegExp(r'[A-Z]'));
      _hasDigits = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChars = password.contains(RegExp(r'[!@#\$&*~_.,\-]'));
    });
  }

  int get _strengthScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasMixedCase) score++;
    if (_hasDigits) score++;
    if (_hasSpecialChars) score++;
    return score;
  }

  Color _getStrengthColor() {
    switch (_strengthScore) {
      case 1:
        return AppColors.error;
      case 2:
        return AppColors.warning;
      case 3:
        return Colors.orange;
      case 4:
        return AppColors.success;
      default:
        return AppColors.borderLight;
    }
  }

  String _getStrengthText() {
    switch (_strengthScore) {
      case 1:
        return 'Sangat Lemah';
      case 2:
        return 'Cukup';
      case 3:
        return 'Baik';
      case 4:
        return 'Sangat Kuat';
      default:
        return 'Masukkan kata sandi';
    }
  }

  void _submitCourierRegister() {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      CustomDialog.showWarning(
        context: context,
        title: 'Kata Sandi Berbeda',
        message: 'Konfirmasi kata sandi tidak cocok dengan kata sandi utama.',
      );
      return;
    }

    if (_strengthScore < 2) {
      CustomDialog.showWarning(
        context: context,
        title: 'Kata Sandi Terlalu Lemah',
        message: 'Gunakan kombinasi minimal 8 karakter, huruf besar & kecil, serta angka untuk keamanan akun kurir Anda.',
      );
      return;
    }

    context.read<AuthBloc>().add(
      AuthCourierRegisterSubmitted(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        alamatLengkap: _alamatController.text.trim().isNotEmpty
            ? _alamatController.text.trim()
            : null,
        latitude: _latitude,
        longitude: _longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          // Background motif SatSet
          Positioned.fill(
            child: Image.asset(
              'assets/images/Background.png',
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),

          if (isDark)
            Positioned.fill(
              child: Container(
                color: AppColors.backgroundDark.withValues(alpha: 0.85),
              ),
            ),

          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthSuccess) {
                CustomDialog.showSuccess(
                  context: context,
                  title: 'Pendaftaran Kurir Berhasil! 🎉',
                  message: 'Akun resmi kurir berhasil didaftarkan ke tabel m_employee dengan hak akses Kurir (id_users_role=2).',
                  confirmText: 'Buka Dashboard Kurir',
                  onConfirm: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => MainNavigationPage(
                          user: state.user,
                          isCourierMode: true,
                        ),
                      ),
                      (route) => false,
                    );
                  },
                );
              } else if (state is AuthFailure) {
                CustomDialog.showError(
                  context: context,
                  title: 'Gagal Mendaftar Kurir',
                  message: state.errorMessage,
                  confirmText: 'Periksa Kembali',
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              return SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Logo & Badge Kurir
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.surfaceDark
                                        : AppColors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight,
                                    ),
                                  ),
                                  child: Image.asset(
                                    'assets/images/LogoTextSatset.png',
                                    height: 56,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.delivery_dining_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'PENDAFTARAN MITRA KURIR',
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                              letterSpacing: 0.5,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          Center(
                            child: Text(
                              'Daftar Akun Kurir',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.headlineMedium.copyWith(
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              'Data akun kurir akan disimpan ke tabel m_employee dengan akses penugasan pengiriman.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Kartu Form Pendaftaran Kurir
                          CustomCard(
                            variant: CardVariant.elevated,
                            padding: const EdgeInsets.all(22),
                            borderRadius: BorderRadius.circular(20),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. Nama Lengkap
                                  Text(
                                    'Nama Lengkap Kurir',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CustomTextField(
                                    controller: _nameController,
                                    hintText: 'Contoh: Ahmad Fauzi',
                                    prefixIcon: const Icon(
                                      Icons.badge_outlined,
                                      size: 20,
                                    ),
                                    textInputAction: TextInputAction.next,
                                    validator: Validators.validateName,
                                  ),
                                  const SizedBox(height: 16),

                                  // 2. Email Kurir
                                  Text(
                                    'Alamat Email',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CustomTextField(
                                    controller: _emailController,
                                    hintText: 'kurir@satset.id',
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      size: 20,
                                    ),
                                    textInputAction: TextInputAction.next,
                                    validator: Validators.validateEmail,
                                  ),
                                  const SizedBox(height: 16),

                                  // 3. Nomor Handphone (no_hp)
                                  Text(
                                    'Nomor Handphone (WhatsApp Aktif)',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CustomTextField(
                                    controller: _phoneController,
                                    hintText: '081234567890',
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: const Icon(
                                      Icons.phone_outlined,
                                      size: 20,
                                    ),
                                    textInputAction: TextInputAction.next,
                                    validator: Validators.validatePhone,
                                  ),
                                  const SizedBox(height: 16),

                                  // 4. Alamat Domisili / Basecamp
                                  Text(
                                    'Alamat Domisili / Pangkalan (Opsional)',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CustomTextField(
                                    controller: _alamatController,
                                    hintText: 'Jl. Merdeka No. 45, Jakarta',
                                    prefixIcon: const Icon(
                                      Icons.location_on_outlined,
                                      size: 20,
                                    ),
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 16),

                                  // 5. Kata Sandi
                                  Text(
                                    'Kata Sandi',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CustomTextField(
                                    controller: _passwordController,
                                    hintText: 'Minimal 8 karakter',
                                    isPassword: true,
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 20,
                                    ),
                                    textInputAction: TextInputAction.next,
                                    validator: Validators.validatePassword,
                                  ),
                                  const SizedBox(height: 8),

                                  // Indikator Kekuatan Password
                                  if (_passwordController.text.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: _strengthScore / 4,
                                              backgroundColor: isDark
                                                  ? AppColors.surfaceVariantDark
                                                  : AppColors.borderLight,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    _getStrengthColor(),
                                                  ),
                                              minHeight: 4,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          _getStrengthText(),
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                color: _getStrengthColor(),
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],

                                  // 6. Konfirmasi Kata Sandi
                                  Text(
                                    'Konfirmasi Kata Sandi',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CustomTextField(
                                    controller: _confirmPasswordController,
                                    hintText: 'Ulangi kata sandi Anda',
                                    isPassword: true,
                                    prefixIcon: const Icon(
                                      Icons.lock_reset_rounded,
                                      size: 20,
                                    ),
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) =>
                                        _submitCourierRegister(),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Konfirmasi kata sandi wajib diisi';
                                      }
                                      if (val != _passwordController.text) {
                                        return 'Kata sandi tidak cocok';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 24),

                                  // Tombol Submit Pendaftaran Kurir
                                  CustomButton(
                                    text: 'Daftar sebagai Kurir',
                                    prefixIcon: const Icon(
                                      Icons.app_registration_rounded,
                                      size: 20,
                                    ),
                                    variant: ButtonVariant.primary,
                                    isLoading: isLoading,
                                    onPressed: isLoading
                                        ? null
                                        : _submitCourierRegister,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Tautan kembali ke Login
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Sudah punya akun kurir SatSet? ',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Text(
                                    'Masuk di Sini',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Tautan beralih ke registrasi pelanggan jika salah halaman
                          Center(
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context.read<AuthBloc>(),
                                      child: const RegisterPage(),
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Daftar sebagai Pelanggan SatSet',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
