import 'package:equatable/equatable.dart';

/// Statistik ringkasan riwayat tugas kurir
class CourierTaskHistoryStats extends Equatable {
  final int totalCount;
  final int completedCount;
  final int failedCount;
  final int returnedCount;
  final int cancelledCount;

  const CourierTaskHistoryStats({
    this.totalCount = 0,
    this.completedCount = 0,
    this.failedCount = 0,
    this.returnedCount = 0,
    this.cancelledCount = 0,
  });

  @override
  List<Object?> get props => [
        totalCount,
        completedCount,
        failedCount,
        returnedCount,
        cancelledCount,
      ];
}
