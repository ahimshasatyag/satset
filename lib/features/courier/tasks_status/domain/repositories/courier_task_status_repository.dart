import '../entities/delivery_proof_summary.dart';
import '../entities/task_status_detail.dart';
import '../entities/task_status_step.dart';

/// Kontrak repositori untuk memuat detail status tugas dan mengelola pembaruan status kurir
abstract class CourierTaskStatusRepository {
  /// Mengambil detail informasi tugas pengiriman kurir
  Future<TaskStatusDetail> getTaskStatusDetail(
    String shipmentId, {
    String? courierId,
  });

  /// Mengambil kronologi riwayat perubahan status dari `t_shipment_tracking`
  Future<List<TaskStatusStep>> getTaskTimeline(String shipmentId);

  /// Mengambil ringkasan bukti serah terima dari `t_shipment_proofs` jika tersedia
  Future<DeliveryProofSummary?> getTaskDeliveryProof(String shipmentId);

  /// Memperbarui status pengiriman secara resmi ke Supabase
  Future<void> updateTaskStatus({
    required String shipmentId,
    required String courierId,
    required int targetStatusId,
    required String targetStatusCode,
    String? notes,
    String? failureReason,
    String? locationName,
    double? latitude,
    double? longitude,
  });

  /// Aliran perubahan data pengiriman secara realtime via Supabase channel
  Stream<TaskStatusDetail> subscribeToTaskRealtime(String shipmentId);
}
