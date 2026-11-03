import 'package:equatable/equatable.dart';

/// Entitas kurir (`m_employee` dengan `id_users_role = 2`) untuk penugasan pengiriman
class AdminAssignableCourier extends Equatable {
  final int id;
  final String employeeCode;
  final String namaLengkap;
  final String email;
  final String noHp;
  final String? alamatLengkap;
  final String? fotoUrl;
  final bool isActive;
  final int idUsersRole;
  final int activeAssignmentsCount;
  final int completedAssignmentsCount;

  const AdminAssignableCourier({
    required this.id,
    required this.employeeCode,
    required this.namaLengkap,
    required this.email,
    required this.noHp,
    this.alamatLengkap,
    this.fotoUrl,
    required this.isActive,
    this.idUsersRole = 2,
    this.activeAssignmentsCount = 0,
    this.completedAssignmentsCount = 0,
  });

  /// Kurir memenuhi kriteria penugasan apabila akun aktif dan memiliki role kurir (id_users_role = 2)
  bool get isEligibleForAssignment => isActive && idUsersRole == 2;

  /// Indikator ketersediaan kurir berdasarkan beban tugas aktif
  String get availabilityLabel {
    if (!isActive) return 'Nonaktif';
    if (activeAssignmentsCount == 0) return 'Tersedia (Siap Tugas)';
    return 'Sedang Bertugas ($activeAssignmentsCount paket aktif)';
  }

  @override
  List<Object?> get props => [
        id,
        employeeCode,
        namaLengkap,
        email,
        noHp,
        alamatLengkap,
        fotoUrl,
        isActive,
        idUsersRole,
        activeAssignmentsCount,
        completedAssignmentsCount,
      ];
}

