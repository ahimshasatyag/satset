import 'package:flutter/material.dart';
import 'package:satset/shared/widgets/widgets.dart';
import 'remember_me_checkbox.dart';

/// Form input interaktif untuk email dan kata sandi dengan validasi lengkap
class LoginForm extends StatefulWidget {
  final String? initialEmail;
  final bool initialRememberMe;
  final bool isLoading;
  final void Function(String email, String password, bool rememberMe) onLogin;
  final VoidCallback onForgotPasswordTap;

  const LoginForm({
    super.key,
    this.initialEmail,
    this.initialRememberMe = false,
    this.isLoading = false,
    required this.onLogin,
    required this.onForgotPasswordTap,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late bool _rememberMe;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _passwordController = TextEditingController();
    _rememberMe = widget.initialRememberMe;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onLogin(
        _emailController.text.trim(),
        _passwordController.text,
        _rememberMe,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input Email
          CustomTextField(
            label: 'Alamat Email',
            hintText: 'nama@satset.id',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            isRequired: true,
            enabled: !widget.isLoading,
            prefixIcon: const Icon(Icons.mail_outline_rounded),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email tidak boleh kosong';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                return 'Masukkan format email yang valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Input Kata Sandi
          CustomTextField(
            label: 'Kata Sandi',
            hintText: 'Masukkan kata sandi akun',
            controller: _passwordController,
            isPassword: true,
            isRequired: true,
            textInputAction: TextInputAction.done,
            enabled: !widget.isLoading,
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            onSubmitted: (_) => _handleSubmit(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kata sandi tidak boleh kosong';
              }
              if (value.length < 6) {
                return 'Kata sandi minimal 6 karakter';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Ingat Saya & Lupa Password
          RememberMeCheckbox(
            value: _rememberMe,
            onChanged: (val) {
              setState(() {
                _rememberMe = val ?? false;
              });
            },
            onForgotPasswordTap: widget.onForgotPasswordTap,
          ),
          const SizedBox(height: 24),

          // Tombol Masuk Utama (Primary SatSet Red)
          CustomButton(
            text: widget.isLoading ? 'Memverifikasi...' : 'Masuk Sat-Set',
            isLoading: widget.isLoading,
            onPressed: widget.isLoading ? null : _handleSubmit,
            prefixIcon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}
