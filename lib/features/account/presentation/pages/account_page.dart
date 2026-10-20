import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../data/datasources/account_local_datasource.dart';
import '../../data/datasources/account_remote_datasource.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/entities/user_account.dart';
import '../../domain/usecases/get_user_account_usecase.dart';
import '../../domain/usecases/logout_account_usecase.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';
import '../bloc/account_state.dart';
import '../widgets/account_logout_dialog.dart';
import '../widgets/account_menu_card.dart';
import '../widgets/account_menu_item.dart';
import '../widgets/account_profile_header.dart';

class AccountPage extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool? isDarkMode;
  final VoidCallback? onLogout;

  const AccountPage({
    super.key,
    this.onToggleTheme,
    this.isDarkMode,
    this.onLogout,
  });

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  AccountBloc? _internalBloc;

  @override
  void dispose() {
    _internalBloc?.close();
    super.dispose();
  }

  AccountBloc _getOrCreateBloc(BuildContext context) {
    try {
      return BlocProvider.of<AccountBloc>(context);
    } catch (_) {
      if (_internalBloc == null) {
        final remote = AccountRemoteDataSourceImpl();
        final local = AccountLocalDataSourceImpl();
        final repo = AccountRepositoryImpl(
          remoteDataSource: remote,
          localDataSource: local,
        );
        _internalBloc = AccountBloc(
          getUserAccountUseCase: GetUserAccountUseCase(repo),
          logoutAccountUseCase: LogoutAccountUseCase(repo),
          repository: repo,
        );
      }
      return _internalBloc!;
    }
  }

  void _showFeatureDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _getOrCreateBloc(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider<AccountBloc>.value(
      value: bloc,
      child: BlocConsumer<AccountBloc, AccountState>(
        listener: (context, state) {
          if (state.isLoggedOut) {
            if (widget.onLogout != null) {
              widget.onLogout!();
            }
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
          final account = state.account ??
              const UserAccount(
                id: 'usr-01',
                name: 'Satria Perkasa',
                email: 'satria@satset.id',
                phone: '+62 812-3456-7890',
              );

          return Scaffold(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            body: SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kartu Profil Pengguna
                    AccountProfileHeader(account: account),
                    const SizedBox(height: 24),

                    // Bagian 1: Pengiriman & Transaksi
                    Text(
                      'Pengiriman & Transaksi',
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
                          title: 'Daftar Alamat Tersimpan',
                          subtitle:
                              'Rumah, Kantor SCBD, Gudang SatSet (${account.savedAddressesCount})',
                          onTap: () => _showFeatureDialog(
                            context,
                            'Alamat Tersimpan',
                            'Kelola titik jemput dan antar favorit Anda untuk proses pemesanan lebih cepat.',
                          ),
                        ),
                        const Divider(height: 1),
                        AccountMenuItem(
                          icon: Icons.account_balance_wallet_rounded,
                          color: AppColors.secondary,
                          title: 'Metode Pembayaran',
                          subtitle:
                              'SatSet Pay (Rp ${account.satsetPayBalance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}), QRIS, Kartu Debit',
                          onTap: () => _showFeatureDialog(
                            context,
                            'Metode Pembayaran',
                            'Saldo SatSet Pay Anda saat ini Rp ${account.satsetPayBalance}. Siap digunakan untuk pengiriman instan.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Bagian 2: Layanan & Perlindungan
                    Text(
                      'Layanan & Perlindungan',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : AppColors.tertiary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    AccountMenuCard(
                      children: [
                        AccountMenuItem(
                          icon: Icons.security_rounded,
                          color: const Color(0xFF009688),
                          title: 'Riwayat Klaim Asuransi',
                          subtitle: 'Garansi SatSet Protect 100% Ganti Rugi',
                          onTap: () => _showFeatureDialog(
                            context,
                            'Klaim Asuransi SatSet Protect',
                            'Seluruh pengiriman dilindungi hingga Rp 25.000.000 dengan jaminan penyelesaian klaim dalam 24 jam.',
                          ),
                        ),
                        const Divider(height: 1),
                        AccountMenuItem(
                          icon: Icons.support_agent_rounded,
                          color: AppColors.tertiary,
                          title: 'Pusat Bantuan & CS 24 Jam',
                          subtitle: 'Hubungi Live Chat Operator SatSet',
                          onTap: () => _showFeatureDialog(
                            context,
                            'Pusat Bantuan SatSet',
                            'Customer Service SatSet siap melayani Anda 24/7 melalui hotline 1500-SATSET.',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Bagian 3: Pengaturan Sistem
                    Text(
                      'Pengaturan Sistem',
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
                          subtitle: 'Peringatan status kurir real-time & promo',
                          trailing: Switch(
                            value: account.isNotificationsEnabled,
                            activeThumbColor: AppColors.primary,
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
                        if (widget.onToggleTheme != null)
                          AccountMenuItem(
                            icon: widget.isDarkMode == true
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            color: AppColors.secondary,
                            title: 'Tema Tampilan',
                            subtitle: widget.isDarkMode == true
                                ? 'Mode Gelap (Aktif)'
                                : 'Mode Terang (Aktif)',
                            trailing: Switch(
                              value: widget.isDarkMode == true,
                              activeThumbColor: AppColors.primary,
                              onChanged: (_) => widget.onToggleTheme!(),
                            ),
                            onTap: widget.onToggleTheme,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tombol Logout
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
