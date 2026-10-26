import 'dart:typed_data';
import '../../domain/entities/delivery_proof_item.dart';
import '../../domain/entities/delivery_proof_payload.dart';
import '../../domain/entities/delivery_proof_task.dart';
import '../../domain/entities/recipient_relationship.dart';
import '../../domain/repositories/courier_delivery_proof_repository.dart';
import '../datasources/courier_delivery_proof_device_datasource.dart';
import '../datasources/courier_delivery_proof_local_datasource.dart';
import '../datasources/courier_delivery_proof_remote_datasource.dart';
import '../models/delivery_proof_item_model.dart';

class CourierDeliveryProofRepositoryImpl
    implements CourierDeliveryProofRepository {
  final CourierDeliveryProofRemoteDataSource remoteDataSource;
  final CourierDeliveryProofDeviceDataSource deviceDataSource;
  final CourierDeliveryProofLocalDataSource localDataSource;

  CourierDeliveryProofRepositoryImpl({
    required this.remoteDataSource,
    required this.deviceDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<DeliveryProofTask>> getActiveDeliveryTasks({String? courierId}) async {
    return await remoteDataSource.getActiveDeliveryTasks(courierId: courierId);
  }

  @override
  Future<DeliveryProofTask?> getTaskByShipmentId(
    String shipmentId, {
    String? courierId,
  }) async {
    return await remoteDataSource.getTaskByShipmentId(
      shipmentId,
      courierId: courierId,
    );
  }

  @override
  Future<({Uint8List bytes, String fileName, int sizeBytes})?> pickProofImage({
    required bool fromCamera,
  }) async {
    return await deviceDataSource.pickImage(fromCamera: fromCamera);
  }

  @override
  Future<({double latitude, double longitude})?> getCurrentHandoverCoordinates() async {
    return await deviceDataSource.getCurrentLocation();
  }

  @override
  Future<DeliveryProofItem> submitDeliveryProof(DeliveryProofPayload payload) async {
    // 1. Selesaikan identitas kurir aktif
    final courierId = await remoteDataSource.resolveCourierId(
      overrideId: payload.courierId,
    );

    // 2. Unggah berkas foto bukti ke Supabase Storage
    final uploadedUrl = await remoteDataSource.uploadProofImage(
      shipmentId: payload.shipmentId,
      bytes: payload.imageBytes,
      fileName: payload.fileName,
    );

    // 3. Simpan data bukti ke tabel `t_shipment_proofs`
    final proofModel = DeliveryProofItemModel(
      shipmentId: payload.shipmentId,
      courierId: courierId,
      proofType: 'FOTO_PENYERAHAN',
      filePath: uploadedUrl,
      recipientName: payload.recipientName.trim(),
      relationship: payload.relationship,
      notes: payload.combinedNotes,
      latitude: payload.latitude,
      longitude: payload.longitude,
      createdAt: payload.deliveredAt,
    );

    final savedProof = await remoteDataSource.recordDeliveryProof(proofModel);

    // 4. Ambil detail tugas untuk data pendukung barcode & kota
    final task = await remoteDataSource.getTaskByShipmentId(payload.shipmentId);

    // 5. Perbarui status t_shipments menjadi DELIVERED dan catat t_shipment_tracking
    await remoteDataSource.completeShipmentDelivery(
      shipmentId: payload.shipmentId,
      courierId: courierId,
      recipientName: payload.recipientName.trim(),
      relationshipText: payload.relationship.label,
      notes: payload.notes,
      latitude: payload.latitude,
      longitude: payload.longitude,
      barcodeValue: task?.barcodeValue ?? task?.trackingNumber,
      destinationCity: task?.receiverCity,
    );

    // 6. Simpan riwayat bukti terakhir ke penyimpanan lokal
    await localDataSource.saveLastCompletedProof(savedProof);

    return savedProof;
  }
}
