import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Halaman Lupa Kata Sandi aplikasi SatSet
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

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
      appBar: const CustomAppBar(
        title: 'Lupa Kata Sandi',
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthForgotPasswordSuccess) {
            CustomDialog.showSuccess(
              context: context,
              title: 'Email Terkirim!',
              message:
                  'Tautan instruksi reset kata sandi telah dikirim ke ${state.email}. Silakan periksa kotak masuk atau spam.',
              confirmText: 'Kembali ke Login',
              onConfirm: () => Navigator.pop(context),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Judul & Deskripsi
                  Text(
                    'Atur Ulang Kata Sandi',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Masukkan alamat email yang terdaftar pada akun SatSet Anda. Kami akan mengirimkan tautan untuk mengatur ulang kata sandi.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Input Email
                  CustomTextField(
                    label: 'Alamat Email Terdaftar',
                    hintText: 'nama@satset.id',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    isRequired: true,
                    enabled: !isLoading,
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email wajib diisi';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value.trim())) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Tombol Kirim Tautan
                  CustomButton(
                    text: isLoading ? 'Mengirim Permintaan...' : 'Kirim Tautan Reset',
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _handleSubmit,
                    prefixIcon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(height: 20),

                  // Tombol Batal
                  CustomButton.ghost(
                    text: 'Kembali ke Halaman Masuk',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
