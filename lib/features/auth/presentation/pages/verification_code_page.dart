import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'reset_password_page.dart';

/// Halaman verifikasi kode unik (OTP) yang dikirim ke email pengguna
class VerificationCodePage extends StatefulWidget {
  final String email;

  const VerificationCodePage({
    super.key,
    required this.email,
  });

  @override
  State<VerificationCodePage> createState() => _VerificationCodePageState();
}

class _VerificationCodePageState extends State<VerificationCodePage> {
  static const int _codeLength = 6;
  static const int _initialCountdown = 180; // 3 menit (180 detik)

  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  Timer? _countdownTimer;
  int _secondsRemaining = _initialCountdown;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = _initialCountdown;
      _canResend = false;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _canResend = true;
        });
      }
    });
  }

  String get _currentCode {
    return _controllers.map((c) => c.text).join();
  }

  bool get _isCodeComplete {
    return _currentCode.length == _codeLength;
  }

  void _handleDigitChange(int index, String value) {
    if (value.length > 1) {
      // Menangani paste teks utuh (misal paste "123456")
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < _codeLength; i++) {
        if (i < digits.length) {
          _controllers[i].text = digits[i];
        }
      }
      final nextIndex = digits.length < _codeLength ? digits.length : _codeLength - 1;
      _focusNodes[nextIndex].requestFocus();
      setState(() {});
      if (_isCodeComplete) {
        _submitVerification();
      }
      return;
    }

    if (value.isNotEmpty) {
      if (index < _codeLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
    setState(() {});

    if (_isCodeComplete) {
      _submitVerification();
    }
  }

  void _handleBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      setState(() {});
    }
  }

  void _submitVerification() {
    if (!_isCodeComplete) return;

    context.read<AuthBloc>().add(
          AuthVerifyCodeSubmitted(
            email: widget.email,
            code: _currentCode,
          ),
        );
  }

  void _clearCode() {
    for (final controller in _controllers) {
      controller.clear();
    }
    if (_focusNodes.isNotEmpty) {
      _focusNodes[0].requestFocus();
    }
    setState(() {});
  }

  void _handleResendCode() {
    if (!_canResend) return;

    context.read<AuthBloc>().add(
          AuthResendCodeSubmitted(widget.email),
        );
    _startCountdown();
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  /// Menampilkan modal bottom sheet konfirmasi dari widgets.dart sebelum kembali ke login
  void _handleBackToLogin() {
    CustomBottomSheet.showWarning(
      context: context,
      title: 'Tinggalkan Halaman?',
      message: 'Apakah kamu yakin ingin meninggalkan kode OTP untuk login?',
      confirmText: 'Ya, Kembali',
      cancelText: 'Batal',
      onConfirm: () {
        if (mounted) {
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _handleBackToLogin();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Stack(
        children: [
          // Background motif selaras halaman autentikasi
          Positioned.fill(
            child: Image.asset(
              'assets/images/Background.png',
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),

          // Overlay lembut untuk mode gelap
          if (isDark)
            Positioned.fill(
              child: Container(
                color: AppColors.backgroundDark.withValues(alpha: 0.85),
              ),
            ),

          BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthCodeVerifiedSuccess) {
                // Menuju ke halaman atur ulang kata sandi baru
                Navigator.pushReplacement(
                  context,
                  SmoothPageRoute(
                    child: BlocProvider.value(
                      value: context.read<AuthBloc>(),
                      child: ResetPasswordPage(
                        email: state.email,
                        code: state.code,
                      ),
                    ),
                  ),
                );
              } else if (state is AuthResendCodeSuccess) {
                CustomDialog.showSuccess(
                  context: context,
                  title: 'Kode Terkirim! ✉️',
                  message: state.message,
                  confirmText: 'Mengerti',
                );
              } else if (state is AuthFailure) {
                _clearCode();
                CustomDialog.showError(
                  context: context,
                  title: 'Verifikasi Gagal',
                  message: state.errorMessage,
                  confirmText: 'Coba Lagi',
                );
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;

              return SafeArea(
                child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: CustomCard(
                      variant: CardVariant.elevated,
                      padding: const EdgeInsets.all(24),
                      borderRadius: BorderRadius.circular(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon Badge Ilustrasi OTP
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mark_email_read_rounded,
                              size: 38,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Judul & Deskripsi
                          Text(
                            'Verifikasi Kode Unik',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.headlineSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Masukkan 6 digit kode verifikasi yang telah kami kirimkan ke alamat email:',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Chip Tampilan Email Terkirim dengan tombol Ubah
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : AppColors.primary50,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : AppColors.primary200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.mail_outline_rounded, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    widget.email,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.primary800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: _handleBackToLogin,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Text(
                                      'Ubah',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // 6 Box Input Digit OTP
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(_codeLength, (index) {
                              return _buildOtpBox(
                                index: index,
                                isDark: isDark,
                                enabled: !isLoading,
                              );
                            }),
                          ),
                          const SizedBox(height: 28),

                          // Tombol Verifikasi
                          CustomButton.gradient(
                            text: isLoading ? 'Memverifikasi...' : 'Verifikasi Kode',
                            isLoading: isLoading,
                            onPressed: (_isCodeComplete && !isLoading) ? _submitVerification : null,
                            size: ButtonSize.large,
                            suffixIcon: const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Timer & Tombol Kirim Ulang
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Tidak menerima kode? ',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              if (_canResend)
                                InkWell(
                                  onTap: isLoading ? null : _handleResendCode,
                                  child: Text(
                                    'Kirim Ulang',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDuration(_secondsRemaining),
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Tombol Kembali
                          CustomButton.ghost(
                            text: 'Kembali ke Login',
                            onPressed: _handleBackToLogin,
                            size: ButtonSize.small,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
        },
          ),
        ],
      ),
    ),
  );
  }

  /// Kotak input digit individu dengan highlight border saat aktif
  Widget _buildOtpBox({
    required int index,
    required bool isDark,
    required bool enabled,
  }) {
    final hasValue = _controllers[index].text.isNotEmpty;
    final isFocused = _focusNodes[index].hasFocus;

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
          _handleBackspace(index);
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 56,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFocused
                ? AppColors.primary
                : (hasValue
                    ? (isDark ? AppColors.primary400 : AppColors.primary)
                    : (isDark ? AppColors.borderDark : AppColors.borderLight)),
            width: isFocused ? 2 : 1.5,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            enabled: enabled,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: index == _codeLength - 1 ? TextInputAction.done : TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
            onChanged: (value) => _handleDigitChange(index, value),
          ),
        ),
      ),
    );
  }
}
