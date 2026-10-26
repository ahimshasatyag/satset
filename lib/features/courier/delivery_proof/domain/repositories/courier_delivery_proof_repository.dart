import 'dart:typed_data';
import '../entities/delivery_proof_item.dart';
import '../entities/delivery_proof_payload.dart';
import '../entities/delivery_proof_task.dart';

/// Kontrak repository untuk fitur Bukti Pengiriman (Delivery Proof) khusus Kurir
abstract class CourierDeliveryProofRepository {
  /// Mengambil daftar tugas pengantaran yang sedang aktif dan siap diserahkan
  Future<List<DeliveryProofTask>> getActiveDeliveryTasks({String? courierId});

  /// Mengambil informasi satu tugas pengantaran spesifik berdasarkan ID pengiriman
  Future<DeliveryProofTask?> getTaskByShipmentId(
    String shipmentId, {
    String? courierId,
  });

  /// Mengambil foto bukti melalui kamera perangkat atau galeri
  Future<({Uint8List bytes, String fileName, int sizeBytes})?> pickProofImage({
    required bool fromCamera,
  });

  /// Mengambil koordinat GPS lokasi penyerahan terkini jika izin tersedia
  Future<({double latitude, double longitude})?> getCurrentHandoverCoordinates();

  /// Mengirimkan bukti penyerahan paket secara lengkap:
  /// 1. Unggah foto ke Supabase Storage
  /// 2. Simpan metadata ke `t_shipment_proofs`
  /// 3. Perbarui status pengiriman di `t_shipments` menjadi DELIVERED (id=8)
  /// 4. Catat riwayat pergerakan pada `t_shipment_tracking`
  /// 5. Tandai penugasan kurir di `t_shipment_assignments` sebagai selesai
  Future<DeliveryProofItem> submitDeliveryProof(DeliveryProofPayload payload);
}
