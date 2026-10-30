import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../app/config/supabase_config.dart';
import '../../../../app/constants/database_constants.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../../auth/data/utils/validators.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/user_account.dart';
import '../bloc/account_bloc.dart';
import '../bloc/account_event.dart';

/// Halaman Edit Akun SatSet
/// Memperbarui Nama Lengkap, Email, dan Nomor Telepon langsung ke tabel
/// database Supabase `m_users` atau `m_employee` berdasarkan pengecekan `id_users_roles`.
class EditAccountPage extends StatefulWidget {
  final UserAccount? account;
  final User? user;
  final SupabaseClient? client;

  const EditAccountPage({
    super.key,
    this.account,
    this.user,
    this.client,
  });

  /// Route helper dengan transisi halus ke halaman Edit Akun
  static SmoothPageRoute<bool?> route({
    UserAccount? account,
    User? user,
    SupabaseClient? client,
  }) {
    return SmoothPageRoute<bool?>(
      child: EditAccountPage(
        account: account,
        user: user,
        client: client,
      ),
    );
  }

  @override
  State<EditAccountPage> createState() => _EditAccountPageState();
}

class _EditAccountPageState extends State<EditAccountPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  /// Nilai id_users_roles:
  /// 2 = Mitra Kurir / Pegawai (tabel `m_employee`)
  /// 3 = Pelanggan (tabel `m_users`)
  int? _idUsersRoles;
  String _targetTable = DatabaseConstants.tableUsers;
  String? _recordId;
  String? _initialEmail;

  bool get _isSupabaseAvailable {
    if (widget.client != null) return true;
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient get _client => widget.client ?? SupabaseConfig.client;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.account?.name ?? widget.user?.name ?? '',
    );
    _emailController = TextEditingController(
      text: widget.account?.email ?? widget.user?.email ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.account?.phone ?? widget.user?.phone ?? '',
    );
    _initialEmail = widget.account?.email ?? widget.user?.email;

    _resolveInitialRole();
    _loadProfileFromSupabase();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Menentukan role awal berdasarkan entitas yang diberikan sebelum query ke database
  void _resolveInitialRole() {
    int? role = widget.user?.idUsersRole;
    if (role == null) {
      if (widget.account?.isCourierAccount == true ||
          widget.user?.isCourier == true) {
        role = 2;
      } else {
        role = 3;
      }
    }

    _idUsersRoles = role;
    if (_idUsersRoles == 2) {
      _targetTable = DatabaseConstants.tableEmployee;
    } else {
      _targetTable = DatabaseConstants.tableUsers;
    }
  }

  /// Mengambil data akun terkini dari Supabase dan mengecek `id_users_roles`
  Future<void> _loadProfileFromSupabase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authLocal = AuthLocalDataSourceImpl();
      final localUser = widget.user ?? await authLocal.getUser();
      final authUser = _isSupabaseAvailable ? _client.auth.currentUser : null;

      String targetEmail = (_initialEmail ??
              localUser?.email ??
              authUser?.email ??
              '')
          .trim()
          .toLowerCase();

      String? targetId = widget.account?.id ?? localUser?.id ?? authUser?.id;

      if (!_isSupabaseAvailable) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      Map<String, dynamic>? userRow;
      Map<String, dynamic>? employeeRow;

      // 1. Cek pada tabel m_users
      try {
        if (targetEmail.isNotEmpty) {
          userRow = await _client
              .from(DatabaseConstants.tableUsers)
              .select()
              .eq(UserTableColumns.email, targetEmail)
              .maybeSingle();
        }
        if (userRow == null && targetId != null && targetId.isNotEmpty) {
          userRow = await _client
              .from(DatabaseConstants.tableUsers)
              .select()
              .eq(UserTableColumns.id, targetId)
              .maybeSingle();
        }
      } catch (_) {}

      // 2. Cek pada tabel m_employee
      try {
        if (targetEmail.isNotEmpty) {
          employeeRow = await _client
              .from(DatabaseConstants.tableEmployee)
              .select()
              .eq(EmployeeTableColumns.email, targetEmail)
              .maybeSingle();
        }
        if (employeeRow == null && targetId != null && targetId.isNotEmpty) {
          employeeRow = await _client
              .from(DatabaseConstants.tableEmployee)
              .select()
              .or('${DatabaseConstants.colId}.eq.$targetId,user_id.eq.$targetId')
              .maybeSingle();
        }
      } catch (_) {}

      // 3. Pengecekan id_users_roles dari row database
      int? detectedRoleId;

      // Cek dari row tabel m_users (bisa id_users_roles atau id_users_role)
      if (userRow != null) {
        final val = userRow['id_users_roles'] ?? userRow['id_users_role'];
        if (val != null) {
          detectedRoleId = int.tryParse(val.toString());
        }
      }

      // Cek dari row tabel m_employee jika belum ditemukan
      if (detectedRoleId == null && employeeRow != null) {
        final val = employeeRow['id_users_roles'] ?? employeeRow['id_users_role'];
        if (val != null) {
          detectedRoleId = int.tryParse(val.toString());
        }
      }

      // Fallback ke localUser / widget
      detectedRoleId ??= widget.user?.idUsersRole ?? localUser?.idUsersRole;

      // Jika masih null, simpulkan dari keberadaan data tabel
      if (detectedRoleId == null) {
        if (employeeRow != null ||
            widget.account?.isCourierAccount == true ||
            localUser?.isCourier == true) {
          detectedRoleId = 2; // Kurir / Pegawai
        } else {
          detectedRoleId = 3; // Pelanggan
        }
      }

      _idUsersRoles = detectedRoleId;

      // 4. Petakan data profil sesuai id_users_roles
      if (_idUsersRoles == 2 || (employeeRow != null && userRow == null)) {
        // PERAN KURIR / PEGAWAI -> Tabel m_employee
        _targetTable = DatabaseConstants.tableEmployee;

        final row = employeeRow ?? userRow;
        _recordId = row?[DatabaseConstants.colId]?.toString() ?? targetId;

        final name = row?[EmployeeTableColumns.namaLengkap]?.toString() ??
            row?[EmployeeTableColumns.nama]?.toString() ??
            row?['nama_lengkap']?.toString() ??
            row?['nama']?.toString();

        final email = row?[EmployeeTableColumns.email]?.toString() ??
            row?['email']?.toString() ??
            targetEmail;

        final phone = row?[EmployeeTableColumns.noHp]?.toString() ??
            row?[EmployeeTableColumns.telepon]?.toString() ??
            row?['no_hp']?.toString() ??
            row?['telepon']?.toString();

        if (name != null && name.isNotEmpty) _nameController.text = name;
        if (email.isNotEmpty) {
          _emailController.text = email;
          _initialEmail = email;
        }
        if (phone != null && phone.isNotEmpty) _phoneController.text = phone;
      } else {
        // PERAN PELANGGAN -> Tabel m_users
        _targetTable = DatabaseConstants.tableUsers;

        final row = userRow ?? employeeRow;
        _recordId = row?[UserTableColumns.id]?.toString() ?? targetId;

        final name = row?[UserTableColumns.namaLengkap]?.toString() ??
            row?['nama_lengkap']?.toString();

        final email = row?[UserTableColumns.email]?.toString() ??
            row?['email']?.toString() ??
            targetEmail;

        final phone = row?[UserTableColumns.noHp]?.toString() ??
            row?['no_hp']?.toString();

        if (name != null && name.isNotEmpty) _nameController.text = name;
        if (email.isNotEmpty) {
          _emailController.text = email;
          _initialEmail = email;
        }
        if (phone != null && phone.isNotEmpty) _phoneController.text = phone;
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat profil terbaru: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Menyimpan pembaruan akun ke database Supabase
  Future<void> _saveAccount() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim().toLowerCase();
    final newPhone = _phoneController.text.trim();

    try {
      if (_isSupabaseAvailable) {
        // Pengecekan id_users_roles untuk memilih target tabel update
        if (_idUsersRoles == 2 || _targetTable == DatabaseConstants.tableEmployee) {
          // UPDATE TABEL m_employee
          final updateData = <String, dynamic>{
            EmployeeTableColumns.namaLengkap: newName,
            EmployeeTableColumns.nama: newName,
            EmployeeTableColumns.email: newEmail,
            EmployeeTableColumns.noHp: newPhone,
            EmployeeTableColumns.telepon: newPhone,
            EmployeeTableColumns.updatedAt: DateTime.now().toIso8601String(),
          };

          if (_recordId != null &&
              _recordId!.isNotEmpty &&
              _recordId != 'usr-01' &&
              _recordId != 'courier-01') {
            await _client
                .from(DatabaseConstants.tableEmployee)
                .update(updateData)
                .eq(DatabaseConstants.colId, _recordId!);
          } else if (_initialEmail != null && _initialEmail!.isNotEmpty) {
            await _client
                .from(DatabaseConstants.tableEmployee)
                .update(updateData)
                .eq(EmployeeTableColumns.email, _initialEmail!);
          } else {
            await _client
                .from(DatabaseConstants.tableEmployee)
                .update(updateData)
                .eq(EmployeeTableColumns.email, newEmail);
          }
        } else {
          // UPDATE TABEL m_users
          final updateData = <String, dynamic>{
            UserTableColumns.namaLengkap: newName,
            UserTableColumns.email: newEmail,
            UserTableColumns.noHp: newPhone,
            UserTableColumns.updatedAt: DateTime.now().toIso8601String(),
          };

          if (_recordId != null &&
              _recordId!.isNotEmpty &&
              _recordId != 'usr-01') {
            await _client
                .from(DatabaseConstants.tableUsers)
                .update(updateData)
                .eq(UserTableColumns.id, _recordId!);
          } else if (_initialEmail != null && _initialEmail!.isNotEmpty) {
            await _client
                .from(DatabaseConstants.tableUsers)
                .update(updateData)
                .eq(UserTableColumns.email, _initialEmail!);
          } else {
            await _client
                .from(DatabaseConstants.tableUsers)
                .update(updateData)
                .eq(UserTableColumns.email, newEmail);
          }
        }

        // Jika email diubah dan user memiliki sesi aktif di Supabase Auth, sinkronkan ke Auth
        if (_client.auth.currentUser != null &&
            _initialEmail != null &&
            _initialEmail != newEmail) {
          try {
            await _client.auth.updateUser(UserAttributes(email: newEmail));
          } catch (_) {}
        }
      }

      // Sinkronkan ke penyimpanan lokal sesi pengguna
      try {
        final authLocal = AuthLocalDataSourceImpl();
        final currentLocal = await authLocal.getUser();
        if (currentLocal != null) {
          await authLocal.saveUser(
            currentLocal.copyWith(
              name: newName,
              email: newEmail,
              phone: newPhone,
            ),
          );
        }
      } catch (_) {}

      // Sinkronkan ke AccountBloc jika tersedia di tree
      if (mounted) {
        try {
          context.read<AccountBloc>().add(
                AccountProfileUpdated(
                  name: newName,
                  phone: newPhone,
                  email: newEmail,
                ),
              );
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Profil akun berhasil diperbarui.',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Gagal menyimpan akun: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCourierRole = _idUsersRoles == 2;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Edit Akun',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Memuat informasi profil dari database...',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProfileFromSupabase,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Avatar
                      _buildHeaderCard(context, isDark, isCourierRole),
                      const SizedBox(height: 20),

                      // Pesan Error jika ada
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Formulir Informasi Profil
                      _buildFormCard(context, isDark),
                      const SizedBox(height: 28),

                      // Tombol Aksi
                      CustomButton(
                        text: 'Simpan Perubahan',
                        isLoading: _isSaving,
                        isFullWidth: true,
                        size: ButtonSize.large,
                        prefixIcon: const Icon(Icons.save_rounded, size: 20),
                        onPressed: _saveAccount,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// Kartu Header Profil
  Widget _buildHeaderCard(
    BuildContext context,
    bool isDark,
    bool isCourierRole,
  ) {
    final roleColor = isCourierRole ? AppColors.primary : AppColors.secondary;
    final displayName = _nameController.text.isNotEmpty
        ? _nameController.text
        : 'Pengguna SatSet';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 44,
                backgroundColor: roleColor.withValues(alpha: 0.15),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: roleColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Kartu Input Formulir Profil
  Widget _buildFormCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Data Akun',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Pastikan nama, email, dan no telp sesuai dan aktif.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 1. Nama Lengkap
          CustomTextField(
            label: 'Nama Lengkap',
            hintText: 'Masukkan nama lengkap',
            controller: _nameController,
            isRequired: true,
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            validator: Validators.validateName,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // 2. Email
          CustomTextField(
            label: 'Alamat Email',
            hintText: 'nama@satset.id',
            controller: _emailController,
            isRequired: true,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            validator: Validators.validateEmail,
            helperText:
                'Email digunakan untuk otentikasi login Supabase Auth.',
          ),
          const SizedBox(height: 16),

          // 3. Nomor Telepon / No HP
          CustomTextField(
            label: 'Nomor Telepon / WhatsApp',
            hintText: 'Contoh: 081234567890',
            controller: _phoneController,
            isRequired: true,
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
            validator: Validators.validatePhone,
            helperText:
                'Digunakan untuk notifikasi dan koordinasi pengiriman.',
          ),
        ],
      ),
    );
  }
}
