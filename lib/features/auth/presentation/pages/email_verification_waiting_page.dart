import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/app/constants/database_constants.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

import 'login_page.dart';

/// Halaman Loading dan Menunggu Verifikasi Email Pengguna Baru
///
/// Menampilkan animasi [assets/icon/loading.json] saat menunggu konfirmasi email,
/// dan otomatis menampilkan animasi [assets/icon/Check Mark - Success.json]
/// setelah kolom [email_verified] pada tabel `public.m_users` bernilai true,
/// kemudian otomatis berpindah ke halaman login tanpa tombol lanjut.
class EmailVerificationWaitingPage extends StatefulWidget {
  final String email;
  final String? name;
  final String? password;
  final DateTime? registeredAt;
  final bool isAlreadyVerified;

  const EmailVerificationWaitingPage({
    super.key,
    required this.email,
    this.name,
    this.password,
    this.registeredAt,
    this.isAlreadyVerified = false,
  });

  @override
  State<EmailVerificationWaitingPage> createState() =>
      _EmailVerificationWaitingPageState();
}

class _EmailVerificationWaitingPageState
    extends State<EmailVerificationWaitingPage>
    with WidgetsBindingObserver {
  Timer? _pollingTimer;
  RealtimeChannel? _realtimeChannel;
  StreamSubscription<AuthState>? _authSubscription;

  Timer? _cooldownTimer;
  int _cooldownSeconds = 60;
  bool _canResend = false;

  bool _isChecking = false;
  bool _isVerified = false;
  DateTime? _verifiedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isAlreadyVerified) {
      _isVerified = true;
      _verifiedAt = DateTime.now();
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted) {
          _navigateToLogin();
        }
      });
    } else {
      _startCooldownTimer();
      _initVerificationWatcher();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _cooldownTimer?.cancel();
    _authSubscription?.cancel();
    _unsubscribeRealtime();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isVerified) {
      _checkVerificationStatus();
    }
  }

  void _unsubscribeRealtime() {
    try {
      if (_realtimeChannel != null) {
        SupabaseConfig.client.removeChannel(_realtimeChannel!);
        _realtimeChannel = null;
      }
    } catch (_) {}
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    setState(() {
      _canResend = false;
      _cooldownSeconds = 60;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds > 1) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _canResend = true;
          _cooldownSeconds = 0;
        });
      }
    });
  }

  /// Memastikan bahwa waktu verifikasi benar-benar baru terjadi (setelah atau saat pendaftaran)
  /// untuk mencegah akun lama dengan emailConfirmedAt kemarin dianggap sudah terverifikasi otomatis.
  bool _isFreshVerification(DateTime? verifiedAt) {
    if (widget.registeredAt == null || verifiedAt == null) return true;
    return !verifiedAt.isBefore(
      widget.registeredAt!.subtract(const Duration(seconds: 30)),
    );
  }

  /// Inisialisasi pendengar perubahan verifikasi email (Realtime + Polling + Auth Listener)
  void _initVerificationWatcher() {
    final cleanEmail = widget.email.trim().toLowerCase();

    // Polling periodik dimulai setelah jeda (6 detik) untuk memberi waktu user membuka aplikasi email
    Future.delayed(const Duration(seconds: 6), () {
      if (!mounted || _isVerified) return;
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!_isVerified && mounted) {
          _checkVerificationStatus();
        }
      });
    });

    // Supabase Auth listener untuk mendeteksi event konfirmasi email dari tautan browser/deep-link
    try {
      _authSubscription = SupabaseConfig.client.auth.onAuthStateChange.listen((
        data,
      ) async {
        final user =
            data.session?.user ?? SupabaseConfig.client.auth.currentUser;
        if (user != null && user.email?.trim().toLowerCase() == cleanEmail) {
          if (user.emailConfirmedAt != null) {
            final verifiedIso = user.emailConfirmedAt!;
            final verifiedAt = DateTime.tryParse(verifiedIso) ?? DateTime.now();

            // Cegah verifikasi otomatis jika timestamp konfirmasi adalah sesi lama
            if (!_isFreshVerification(verifiedAt)) {
              return;
            }

            await _updateUserTableVerified(cleanEmail, verifiedIso);
            _handleVerifiedSuccess(verifiedAt);
          }
        }
      });
    } catch (_) {}

    // Supabase Realtime channel pada tabel public.m_users
    try {
      _realtimeChannel = SupabaseConfig.client
          .channel('public:m_users:email=$cleanEmail')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: DatabaseConstants.tableUsers,
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: UserTableColumns.email,
              value: cleanEmail,
            ),
            callback: (payload) {
              final newRecord = payload.newRecord;
              final rawVerified =
                  newRecord[UserTableColumns.emailVerified] ??
                  newRecord['email_verified'];
              final isVerified =
                  rawVerified == true ||
                  rawVerified == 1 ||
                  rawVerified?.toString().toLowerCase() == 'true';

              if (isVerified && mounted) {
                final rawAt =
                    newRecord[UserTableColumns.emailVerifiedAt] ??
                    newRecord['email_verified_at'];
                DateTime? verifiedAt;
                if (rawAt != null) {
                  verifiedAt = DateTime.tryParse(rawAt.toString());
                }

                if (!_isFreshVerification(verifiedAt)) {
                  return;
                }

                _handleVerifiedSuccess(verifiedAt);
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  /// Memperbarui kolom email_verified dan email_verified_at pada tabel m_users di Supabase
  Future<void> _updateUserTableVerified(
    String email,
    String verifiedIso,
  ) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      await SupabaseConfig.client
          .from(DatabaseConstants.tableUsers)
          .update({
            UserTableColumns.emailVerified: true,
            UserTableColumns.emailVerifiedAt: verifiedIso,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .ilike(UserTableColumns.email, cleanEmail);
      debugPrint(
        'Berhasil memperbarui m_users: email_verified=true untuk $cleanEmail',
      );
    } catch (e) {
      debugPrint('Peringatan: Gagal memperbarui m_users: $e');
    }
  }

  /// Memeriksa status verifikasi ke Supabase Auth & tabel PostgreSQL `m_users`
  Future<bool> _checkVerificationStatus({
    bool showFeedbackOnFailure = false,
  }) async {
    if (_isChecking || _isVerified) return _isVerified;

    if (mounted) {
      setState(() {
        _isChecking = true;
      });
    }

    try {
      final cleanEmail = widget.email.trim().toLowerCase();

      // 1. Jika kata sandi tersedia dari pendaftaran, periksa ke Supabase Auth
      // Jika email SUDAH diverifikasi di email pengguna, signInWithPassword akan BERHASIL
      // Jika email BELUM diverifikasi, Supabase Auth akan melempar: 'Email not confirmed'
      if (widget.password != null && widget.password!.isNotEmpty) {
        try {
          final authResponse = await SupabaseConfig.client.auth
              .signInWithPassword(
                email: cleanEmail,
                password: widget.password!,
              );
          final authUser = authResponse.user;
          if (authUser != null && authUser.emailConfirmedAt != null) {
            final verifiedIso = authUser.emailConfirmedAt!;
            final verifiedAt = DateTime.tryParse(verifiedIso) ?? DateTime.now();

            if (_isFreshVerification(verifiedAt)) {
              await _updateUserTableVerified(cleanEmail, verifiedIso);
              _handleVerifiedSuccess(verifiedAt);
              return true;
            } else {
              debugPrint(
                'Konfirmasi Supabase ($verifiedAt) lebih lama dari pendaftaran (${widget.registeredAt}). Mengabaikan.',
              );
            }
          }
        } on AuthException catch (e) {
          // Normal jika email belum dikonfirmasi: 'Email not confirmed'
          debugPrint('Status email Supabase: ${e.message}');
        } catch (e) {
          debugPrint('Pengecekan signIn error: $e');
        }
      }

      // 2. Coba perbarui user langsung dari server Supabase Auth (jika ada sesi aktif / deep-link)
      try {
        final userResponse = await SupabaseConfig.client.auth.getUser();
        final authUser = userResponse.user;
        if (authUser != null &&
            authUser.email?.trim().toLowerCase() == cleanEmail &&
            authUser.emailConfirmedAt != null) {
          final verifiedIso = authUser.emailConfirmedAt!;
          final verifiedAt = DateTime.tryParse(verifiedIso) ?? DateTime.now();

          if (_isFreshVerification(verifiedAt)) {
            await _updateUserTableVerified(cleanEmail, verifiedIso);
            _handleVerifiedSuccess(verifiedAt);
            return true;
          }
        }
      } catch (_) {}

      // 3. Periksa status di Supabase Auth currentUser lokal
      final currentAuthUser = SupabaseConfig.client.auth.currentUser;
      if (currentAuthUser != null &&
          currentAuthUser.email?.trim().toLowerCase() == cleanEmail &&
          currentAuthUser.emailConfirmedAt != null) {
        final verifiedIso = currentAuthUser.emailConfirmedAt!;
        final verifiedAt = DateTime.tryParse(verifiedIso) ?? DateTime.now();

        if (_isFreshVerification(verifiedAt)) {
          await _updateUserTableVerified(cleanEmail, verifiedIso);
          _handleVerifiedSuccess(verifiedAt);
          return true;
        }
      }

      // 4. Periksa langsung apakah kolom email_verified pada tabel public.m_users sudah bernilai true
      final data = await SupabaseConfig.client
          .from(DatabaseConstants.tableUsers)
          .select(
            '${UserTableColumns.id}, ${UserTableColumns.emailVerified}, ${UserTableColumns.emailVerifiedAt}',
          )
          .ilike(UserTableColumns.email, cleanEmail)
          .maybeSingle();

      if (data != null && mounted) {
        final rawVerified =
            data[UserTableColumns.emailVerified] ?? data['email_verified'];
        final isVerified =
            rawVerified == true ||
            rawVerified == 1 ||
            rawVerified?.toString().toLowerCase() == 'true';

        if (isVerified) {
          final rawAt =
              data[UserTableColumns.emailVerifiedAt] ??
              data['email_verified_at'];
          DateTime? verifiedAt;
          if (rawAt != null) {
            verifiedAt = DateTime.tryParse(rawAt.toString());
          }

          if (_isFreshVerification(verifiedAt)) {
            _handleVerifiedSuccess(verifiedAt);
            return true;
          }
        }
      }

      if (showFeedbackOnFailure && mounted && !_isVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Email belum terkonfirmasi. Silakan buka aplikasi email dan klik tautan verifikasi akun terlebih dahulu.',
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  /// Pengecekan manual status verifikasi ketika pengguna menekan tombol cek status
  Future<void> _handleManualCheck() async {
    await _checkVerificationStatus(showFeedbackOnFailure: true);
  }

  /// Dipanggil saat email berhasil terverifikasi pada tabel m_users
  void _handleVerifiedSuccess(DateTime? verifiedAt) {
    if (_isVerified) return;

    HapticFeedback.mediumImpact();
    _pollingTimer?.cancel();
    _unsubscribeRealtime();

    if (mounted) {
      setState(() {
        _isVerified = true;
        _verifiedAt = verifiedAt ?? DateTime.now();
      });

      // Otomatis berpindah ke halaman login setelah animasi sukses selesai (2.2 detik)
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (mounted) {
          _navigateToLogin();
        }
      });
    }
  }

  /// Membuka aplikasi email (Gmail / Default Mail) di perangkat
  Future<void> _handleOpenEmailApp() async {
    const channel = MethodChannel('id.satset.app/email');
    try {
      final opened = await channel.invokeMethod<bool>('openEmailApp');
      if (opened != true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Silakan periksa aplikasi Gmail atau Email Anda.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Silakan buka aplikasi Gmail atau Email Anda untuk konfirmasi.',
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Mengirim ulang email verifikasi via Supabase Auth
  Future<void> _handleResendEmail() async {
    if (!_canResend) return;

    try {
      final cleanEmail = widget.email.trim().toLowerCase();
      await SupabaseConfig.client.auth.resend(
        type: OtpType.signup,
        email: cleanEmail,
        emailRedirectTo: 'io.supabase.satset://login-callback',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tautan verifikasi baru berhasil dikirim ke $cleanEmail!',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _startCooldownTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim ulang email: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _navigateToLogin() async {
    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (_) {}

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && mounted && !_isVerified) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Silakan buka email Anda dan konfirmasi akun terlebih dahulu.',
              ),
              backgroundColor: AppColors.primary,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background motif dari Background.png
              Positioned.fill(
                child: Image.asset(
                  'assets/images/Background.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  gaplessPlayback: true,
                ),
              ),

              // Lapisan overlay halus untuk mode gelap
              if (isDark)
                Positioned.fill(
                  child: Container(
                    color: AppColors.backgroundDark.withValues(alpha: 0.88),
                  ),
                ),

              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: CustomCard(
                        variant: CardVariant.elevated,
                        padding: const EdgeInsets.all(28),
                        borderRadius: BorderRadius.circular(24),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: _isVerified
                              ? _buildVerifiedState(isDark)
                              : _buildWaitingState(isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tampilan Loading Menunggu Verifikasi Email dengan assets/icon/loading.json
  Widget _buildWaitingState(bool isDark) {
    return Column(
      key: const ValueKey('waiting_state'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Animasi Lottie Loading Files
        Lottie.asset(
          'assets/icon/loading.json',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),

        // Judul Utama
        Text(
          'Menunggu Verifikasi Email',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineSmall.copyWith(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),

        // Deskripsi informasi
        Text(
          'Silakan periksa kotak masuk atau folder spam email Anda untuk mengonfirmasi akun:',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),

        // Badge Email Penerima
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.primary50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mail_outline_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.email,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Status Monitoring Realtime Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.backgroundDark.withValues(alpha: 0.5)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Menunggu Konfirmasi...',
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Otomatis mengarah ke login setelah email dikonfirmasi.',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tombol Buka Aplikasi Email
        CustomButton(
          text: 'Buka Aplikasi Email',
          size: ButtonSize.medium,
          isFullWidth: true,
          prefixIcon: const Icon(
            Icons.mail_rounded,
            size: 18,
            color: Colors.white,
          ),
          onPressed: _handleOpenEmailApp,
        ),
        const SizedBox(height: 12),

        // Tombol Cek Status Verifikasi
        CustomButton(
          text: _isChecking
              ? 'Memeriksa Verifikasi...'
              : 'Cek Status Verifikasi',
          variant: ButtonVariant.outlined,
          size: ButtonSize.medium,
          isFullWidth: true,
          isLoading: _isChecking,
          prefixIcon: const Icon(Icons.refresh_rounded, size: 18),
          onPressed: _isChecking ? null : _handleManualCheck,
        ),
        const SizedBox(height: 12),

        // Tombol Kirim Ulang Email dengan Cooldown
        CustomButton(
          text: _canResend
              ? 'Kirim Ulang Email Verifikasi'
              : 'Kirim Ulang Email ($_cooldownSeconds s)',
          variant: ButtonVariant.ghost,
          size: ButtonSize.medium,
          isFullWidth: true,
          prefixIcon: const Icon(Icons.send_rounded, size: 16),
          onPressed: _canResend ? _handleResendEmail : null,
        ),
        const SizedBox(height: 12),

        // Petunjuk Tambahan
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withValues(alpha: 0.5)
                : AppColors.primary50.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Buka email Anda lalu klik tautan konfirmasi untuk mengaktifkan akun.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tampilan Sukses dengan Check Mark - Success.json (tanpa button lanjut, otomatis ke login)
  Widget _buildVerifiedState(bool isDark) {
    return Column(
      key: const ValueKey('verified_state'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Animasi Centang Sukses Lottie
        Lottie.asset(
          'assets/icon/Check Mark - Success.json',
          width: 130,
          height: 130,
          repeat: false,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 16),

        // Judul Berhasil
        Text(
          'Email Berhasil Diverifikasi! 🎉',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),

        // Pesan Sukses
        Text(
          'Selamat ${widget.name != null && widget.name!.isNotEmpty ? widget.name : "Pengguna SatSet"}! '
          'Akun Anda telah aktif.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),

        // Chip timestamp verifikasi
        if (_verifiedAt != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_rounded,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  'Terverifikasi pada ${_verifiedAt!.toLocal().hour.toString().padLeft(2, '0')}:${_verifiedAt!.toLocal().minute.toString().padLeft(2, '0')} WIB',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // Indikator otomatis menuju halaman login
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Membuka halaman masuk...',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
