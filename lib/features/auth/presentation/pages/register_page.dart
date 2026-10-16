import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Halaman Pendaftaran Akun Baru SatSet
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            AuthRegisterSubmitted(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phone: _phoneController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Daftar Akun SatSet',
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            CustomDialog.showSuccess(
              context: context,
              title: 'Pendaftaran Berhasil!',
              message: 'Selamat datang di SatSet.id, ${state.user.name}. Akun Anda siap digunakan.',
              confirmText: 'Mulai Pengiriman',
              onConfirm: () {
                Navigator.pop(context); // Kembali ke login atau dashboard
              },
            );
          } else if (state is AuthFailure) {
            CustomDialog.showError(
              context: context,
              title: 'Pendaftaran Gagal',
              message: state.errorMessage,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buat Akun SatSet Baru 🚀',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Nikmati kirim paket instan, tarif hemat, dan pelacakan live akurat.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Input Nama Lengkap
                  CustomTextField(
                    label: 'Nama Lengkap',
                    hintText: 'Contoh: Budi Pratama',
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    isRequired: true,
                    enabled: !isLoading,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nama lengkap wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Input Email
                  CustomTextField(
                    label: 'Alamat Email',
                    hintText: 'nama@satset.id',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    isRequired: true,
                    enabled: !isLoading,
                    prefixIcon: const Icon(Icons.mail_outline_rounded),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Email wajib diisi';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Input Nomor HP / WhatsApp
                  CustomTextField(
                    label: 'Nomor WhatsApp / HP',
                    hintText: '081234567890',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    isRequired: true,
                    enabled: !isLoading,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nomor HP wajib diisi';
                      }
                      if (val.trim().length < 9) {
                        return 'Nomor HP minimal 9 digit';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Input Kata Sandi
                  CustomTextField(
                    label: 'Kata Sandi',
                    hintText: 'Minimal 6 karakter kombinasi',
                    controller: _passwordController,
                    isPassword: true,
                    isRequired: true,
                    textInputAction: TextInputAction.next,
                    enabled: !isLoading,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Kata sandi wajib diisi';
                      }
                      if (val.length < 6) {
                        return 'Kata sandi minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Konfirmasi Kata Sandi
                  CustomTextField(
                    label: 'Ulangi Kata Sandi',
                    hintText: 'Ketik ulang kata sandi Anda',
                    controller: _confirmPasswordController,
                    isPassword: true,
                    isRequired: true,
                    textInputAction: TextInputAction.done,
                    enabled: !isLoading,
                    prefixIcon: const Icon(Icons.lock_reset_rounded),
                    onSubmitted: (_) => _handleSubmit(),
                    validator: (val) {
                      if (val != _passwordController.text) {
                        return 'Konfirmasi kata sandi tidak cocok';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Tombol Daftar
                  CustomButton(
                    text: isLoading ? 'Memproses Pendaftaran...' : 'Daftar Sekarang',
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _handleSubmit,
                    prefixIcon: const Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(height: 20),

                  // Tautan ke Halaman Login
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Sudah memiliki akun? ',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Masuk di Sini',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
