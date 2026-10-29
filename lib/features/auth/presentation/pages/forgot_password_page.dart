import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

import '../../data/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'verification_code_page.dart';

/// Halaman Lupa Kata Sandi aplikasi SatSet
class ForgotPasswordPage extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordPage({
    super.key,
    this.initialEmail,
  });

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _hasPrecached = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasPrecached) {
      _hasPrecached = true;
      precacheImage(const AssetImage('assets/images/Background.png'), context)
          .catchError((_) {});
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        AuthForgotPasswordSubmitted(_emailController.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background motif dari Background.png menutupi seluruh layar secara penuh
            Positioned.fill(
              child: Image.asset(
                'assets/images/Background.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox(),
              ),
            ),

            // Lapisan overlay halus untuk mode gelap
            if (isDark)
              Positioned.fill(
                child: Container(
                  color: AppColors.backgroundDark.withValues(alpha: 0.85),
                ),
              ),

            BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthForgotPasswordSuccess) {
                  CustomDialog.showSuccess(
                    context: context,
                    title: 'Kode Verifikasi Terkirim! ✉️',
                    message:
                        'Kode verifikasi telah dikirimkan ke ${state.email}. Silakan periksa kotak masuk atau folder spam Anda.',
                    confirmText: 'Lanjutkan Verifikasi',
                    onConfirm: () {
                      Navigator.pushReplacement(
                        context,
                        SmoothPageRoute(
                          child: BlocProvider.value(
                            value: context.read<AuthBloc>(),
                            child: VerificationCodePage(email: state.email),
                          ),
                        ),
                      );
                    },
                  );
                } else if (state is AuthFailure) {
                  CustomDialog.showError(
                    context: context,
                    title: 'Permintaan Gagal',
                    message: state.errorMessage,
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoading;

                return SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 48,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: CustomCard(
                                variant: CardVariant.elevated,
                                padding: const EdgeInsets.all(24),
                                borderRadius: BorderRadius.circular(20),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Icon Ilustrasi Kunci
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.lock_reset_rounded,
                                          size: 42,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 20),

                                      // Judul & Deskripsi
                                      Text(
                                        'Atur Ulang Kata Sandi',
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.headlineSmall.copyWith(
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimaryLight,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Masukkan alamat email yang terdaftar pada akun SatSet Anda. Kode unik (OTP) akan dikirimkan ke email Anda melalui Supabase untuk memverifikasi akun.',
                                        textAlign: TextAlign.center,
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondaryLight,
                                        ),
                                      ),
                                      const SizedBox(height: 28),

                                      // Input Email
                                      CustomTextField(
                                        label: 'Alamat Email Terdaftar',
                                        hintText: 'nama@satset.id',
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        isRequired: true,
                                        enabled: !isLoading,
                                        prefixIcon: const Icon(
                                          Icons.mail_outline_rounded,
                                        ),
                                        validator: Validators.validateEmail,
                                      ),
                                      const SizedBox(height: 24),

                                      // Tombol Kirim Kode Verifikasi
                                      CustomButton(
                                        text: isLoading
                                            ? 'Mengirim Kode Unik...'
                                            : 'Kirim Kode Verifikasi',
                                        isLoading: isLoading,
                                        onPressed: isLoading ? null : _handleSubmit,
                                        prefixIcon: const Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 16),

                                      // Tombol Batal
                                      CustomButton.ghost(
                                        text: 'Kembali ke Halaman Masuk',
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
