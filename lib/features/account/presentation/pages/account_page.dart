import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/domain/entities/user.dart';
import '../../data/datasources/account_local_datasource.dart';
import '../../data/datasources/account_remote_datasource.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/usecases/get_user_account_usecase.dart';
import '../../domain/usecases/logout_account_usecase.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';
import '../bloc/account_state.dart';
import '../widgets/account_address_sheet.dart';
import '../widgets/account_edit_profile_dialog.dart';
import '../widgets/account_legal_dialog.dart';
import '../widgets/account_logout_dialog.dart';
import '../widgets/account_menu_card.dart';
import '../widgets/account_menu_item.dart';
import '../widgets/account_profile_header.dart';
import '../widgets/account_security_dialog.dart';
import '../widgets/account_skeleton.dart';
import '../widgets/account_theme_dialog.dart';

class AccountPage extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;
  final VoidCallback? onLogout;
  final User? user;

  const AccountPage({
    super.key,
    this.onToggleTheme,
    this.isDarkMode,
    this.onLogout,
    this.user,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  AccountBloc? _internalBloc;
  AccountRepository? _repository;

  @override
  void dispose() {
    _internalBloc?.close();
    super.dispose();
  }

  AccountRepository _getOrCreateRepository() {
    if (_repository == null) {
      final remote = AccountRemoteDataSourceImpl(currentUser: widget.user);
      final local = AccountLocalDataSourceImpl();
      _repository = AccountRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );
    }
    return _repository!;
  }

  AccountBloc _getOrCreateBloc(BuildContext context) {
    try {
      return BlocProvider.of<AccountBloc>(context);
    } catch (_) {
      if (_internalBloc == null) {
        final repo = _getOrCreateRepository();
        _internalBloc = AccountBloc(
          getUserAccountUseCase: GetUserAccountUseCase(repo),
          logoutAccountUseCase: LogoutAccountUseCase(repo),
          repository: repo,
        );
      }
      return _internalBloc!;
    }
  }

  void _showEditProfile(BuildContext context, UserAccount account, AccountBloc bloc) async {
    final result = await AccountEditProfileDialog.show(
      context,
      currentName: account.name,
      currentPhone: account.phone,
      currentEmail: account.email,
    );
    if (result != null) {
      bloc.add(AccountProfileUpdated(
        name: result['name']!,
        phone: result['phone']!,
      ));
    }
  }

  void _showAddressManagement(BuildContext context, UserAccount account, AccountBloc bloc) {
    final repo = _getOrCreateRepository();
    AccountAddressSheet.show(
      context,
      addresses: account.addresses,
      repository: repo,
      defaultReceiverName: account.name,
      defaultPhone: account.phone,
      onSaveAddress: (address) {
        bloc.add(AccountAddressSaved(address));
      },
      onDeleteAddress: (addressId) {
        bloc.add(AccountAddressDeleted(addressId));
      },
      onSetPrimaryAddress: (addressId) {
        bloc.add(AccountPrimaryAddressSet(addressId));
      },
    );
  }

  void _showSecurityManagement(BuildContext context, UserAccount account, AccountBloc bloc) {
    AccountSecurityDialog.show(
      context,
      email: account.email,
      isEmailVerified: account.isEmailVerified,
      onResendVerification: () {
        bloc.add(const AccountEmailVerificationResent());
      },
      onChangePassword: (newPassword) {
        bloc.add(AccountPasswordChanged(newPassword));
      },
    );
  }

  void _toggleTheme(BuildContext context) {
    if (widget.onToggleTheme != null) {
      widget.onToggleTheme!();
    } else {
      try {
        context.read<ThemeCubit>().toggleTheme();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _getOrCreateBloc(context);
    final theme = Theme.of(context);
    final isDark = widget.isDarkMode ?? (theme.brightness == Brightness.dark);

    return BlocProvider<AccountBloc>.value(
      value: bloc,
      child: BlocConsumer<AccountBloc, AccountState>(
        listener: (context, state) {
          if (state.isLoggedOut) {
            if (widget.onLogout != null) {
              widget.onLogout!();
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            }
          }
          if (state.actionSuccessMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionSuccessMessage!),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state.notificationMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.notificationMessage!),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.account == null) {
            final isCourierHint = widget.user?.isCourier ?? false;
            return Scaffold(
              backgroundColor:
                  isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
              body: SafeArea(
                child: AccountSkeleton(
                  isCourier: isCourierHint,
                ),
              ),
            );
          }

          final account = state.account ??
              (widget.user != null && widget.user!.isNotEmpty
                  ? UserAccount(
                      id: widget.user!.id,
                      name: widget.user!.name.isNotEmpty
                          ? widget.user!.name
                          : (widget.user!.isCourier
                              ? 'Kurir SatSet'
                              : 'Pelanggan SatSet'),
                      email: widget.user!.email,
                      phone: widget.user!.phone,
                      fullAddress: widget.user!.alamatLengkap,
                      latitude: widget.user!.latitude,
                      longitude: widget.user!.longitude,
                      membershipTier: widget.user!.isCourier
                          ? 'Mitra Kurir SatSet'
                          : 'SatSet Priority Member',
                      isCourier: widget.user!.isCourier,
                      satsetPayBalance: widget.user!.isCourier ? 0 : 450000,
                      savedAddressesCount:
                          widget.user!.alamatLengkap != null ? 1 : 0,
                    )
                  : const UserAccount(
                      id: 'usr-01',
                      name: 'Satria Perkasa',
                      email: 'satria@satset.id',
                      phone: '+62 812-3456-7890',
                    ));

          final isCourier = account.isCourierAccount ||
              (widget.user?.isCourier == true);

          return Scaffold(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            body: SafeArea(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  bloc.add(const AccountProfileLoaded());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Profil Pengguna
                      AccountProfileHeader(
                        account: account,
                        onEditProfile: () => _showEditProfile(context, account, bloc),
                        onResendVerification: () {
                          bloc.add(const AccountEmailVerificationResent());
                        },
                      ),
                      const SizedBox(height: 24),

                      // Bagian 1: Pengiriman & Alamat (Hanya untuk Pelanggan / Customer)
                      if (!isCourier) ...[
                        Text(
                          'Pengiriman & Alamat',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : AppColors.tertiary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        AccountMenuCard(
                          children: [
                            AccountMenuItem(
                              icon: Icons.bookmark_added_rounded,
                              color: AppColors.primary,
                              title: 'Alamat Pengiriman Saya',
                              subtitle: account.addresses.isNotEmpty
                                  ? '${account.addresses.length} Alamat Tersimpan • Utama: ${account.primaryAddress?.label ?? "Aktif"}'
                                  : 'Kelola alamat utama & titik jemput/antar',
                              onTap: () =>
                                  _showAddressManagement(context, account, bloc),
                            ),
                            const Divider(height: 1),
                            AccountMenuItem(
                              icon: Icons.local_shipping_rounded,
                              color: AppColors.tertiary,
                              title: 'Ringkasan Aktivitas Pengiriman',
                              subtitle:
                                  '${account.shipmentCount} Pengiriman Terdaftar pada Sistem SatSet',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Anda memiliki ${account.shipmentCount} riwayat pengiriman di SatSet Delivery.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            AccountMenuItem(
                              icon: Icons.account_balance_wallet_rounded,
                              color: AppColors.secondary,
                              title: 'Metode Pembayaran',
                              subtitle:
                                  'SatSet Pay (Rp ${account.satsetPayBalance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}), QRIS, & Virtual Account',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Saldo SatSet Pay Anda saat ini Rp ${account.satsetPayBalance}. Siap digunakan untuk pengiriman instan.',
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Bagian 2: Keamanan Akun
                      Text(
                        'Keamanan Akun',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : AppColors.tertiary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      AccountMenuCard(
                        children: [
                          AccountMenuItem(
                            icon: Icons.shield_rounded,
                            color: AppColors.primary,
                            title: 'Kredensial & Kata Sandi',
                            subtitle: account.isEmailVerified
                                ? 'Kata Sandi • Email Terverifikasi Supabase Auth'
                                : 'Kata Sandi • Belum Terverifikasi (Kirim Ulang)',
                            onTap: () =>
                                _showSecurityManagement(context, account, bloc),
                          ),
                          const Divider(height: 1),
                          AccountMenuItem(
                            icon: Icons.health_and_safety_rounded,
                            color: const Color(0xFF009688),
                            title: 'Proteksi Paket SatSet Protect',
                            subtitle:
                                'Garansi 100% Ganti Rugi Kerusakan & Kehilangan',
                            onTap: () {
                              AccountLegalDialog.showTermsOfService(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Bagian 3: Pengaturan dan Bantuan
                      Text(
                        'Pengaturan dan Bantuan',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : AppColors.tertiary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      AccountMenuCard(
                        children: [
                          AccountMenuItem(
                            icon: Icons.notifications_active_rounded,
                            color: AppColors.primary,
                            title: 'Pengaturan Notifikasi',
                            subtitle:
                                'Peringatan status kurir real-time & promosi',
                            trailing: Switch(
                              value: account.isNotificationsEnabled,
                              activeThumbColor: AppColors.primary,
                              activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                              onChanged: (val) {
                                bloc.add(AccountNotificationsToggled(val));
                              },
                            ),
                            onTap: () {
                              bloc.add(AccountNotificationsToggled(
                                !account.isNotificationsEnabled,
                              ));
                            },
                          ),
                          const Divider(height: 1),
                          AccountMenuItem(
                            icon: isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: AppColors.secondary,
                            title: 'Tema Tampilan',
                            subtitle: isDark
                                ? 'AppTheme.darkTheme (Mode Gelap Aktif)'
                                : 'AppTheme.lightTheme (Mode Terang Aktif)',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: isDark,
                                  activeThumbColor: AppColors.primary,
                                  activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                                  onChanged: (_) => _toggleTheme(context),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                            onTap: () {
                              AccountThemeDialog.show(
                                context,
                                onToggleTheme: widget.onToggleTheme,
                                isDark: isDark,
                              );
                            },
                          ),
                          const Divider(height: 1),
                          AccountMenuItem(
                            icon: Icons.support_agent_rounded,
                            color: AppColors.tertiary,
                            title: 'Pusat Bantuan & CS 24 Jam',
                            subtitle: 'Hotline 1500-SATSET & WhatsApp Resmi',
                            onTap: () =>
                                AccountLegalDialog.showHelpCenter(context),
                          ),
                          const Divider(height: 1),
                          AccountMenuItem(
                            icon: Icons.privacy_tip_outlined,
                            color: AppColors.secondary,
                            title: 'Kebijakan Privasi',
                            subtitle:
                                'Pengelolaan data aman dengan Supabase RLS',
                            onTap: () =>
                                AccountLegalDialog.showPrivacyPolicy(context),
                          ),
                          const Divider(height: 1),
                          AccountMenuItem(
                            icon: Icons.gavel_rounded,
                            color: AppColors.tertiary,
                            title: 'Syarat & Ketentuan Penggunaan',
                            subtitle: 'Ketentuan layanan pengiriman logistik',
                            onTap: () =>
                                AccountLegalDialog.showTermsOfService(context),
                          ),
                          const Divider(height: 1),
                          AccountMenuItem(
                            icon: Icons.info_outline_rounded,
                            color: AppColors.primary,
                            title: 'Tentang Aplikasi SatSet Delivery',
                            subtitle: 'Versi 1.0.0 • SatSet Logistik Indonesia',
                            onTap: () =>
                                AccountLegalDialog.showAppInfo(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Tombol Keluar dari Akun
                      CustomButton(
                        text: 'Keluar dari Akun',
                        variant: ButtonVariant.outlined,
                        isFullWidth: true,
                        prefixIcon: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.error,
                        ),
                        onPressed: () {
                          AccountLogoutDialog.show(
                            context,
                            onConfirm: () {
                              bloc.add(const AccountLogoutSubmitted());
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
