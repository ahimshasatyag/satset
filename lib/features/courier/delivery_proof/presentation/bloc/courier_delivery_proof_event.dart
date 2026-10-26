import 'package:equatable/equatable.dart';
import '../../domain/entities/delivery_proof_task.dart';
import '../../domain/entities/recipient_relationship.dart';

abstract class CourierDeliveryProofEvent extends Equatable {
  const CourierDeliveryProofEvent();

  @override
  List<Object?> get props => [];
}

/// Inisialisasi awal halaman dengan memuat tugas pengantaran aktif
class CourierDeliveryProofStarted extends CourierDeliveryProofEvent {
  final String? initialShipmentId;

  const CourierDeliveryProofStarted({this.initialShipmentId});

  @override
  List<Object?> get props => [initialShipmentId];
}

/// Memilih tugas yang akan diserahkan jika ada lebih dari 1 tugas
class CourierDeliveryProofTaskSelected extends CourierDeliveryProofEvent {
  final DeliveryProofTask task;

  const CourierDeliveryProofTaskSelected(this.task);

  @override
  List<Object?> get props => [task];
}

/// Mengambil foto bukti melalui kamera atau galeri
class CourierDeliveryProofImagePicked extends CourierDeliveryProofEvent {
  final bool fromCamera;

  const CourierDeliveryProofImagePicked({required this.fromCamera});

  @override
  List<Object?> get props => [fromCamera];
}

/// Menghapus foto bukti terpilih untuk mengambil ulang
class CourierDeliveryProofImageCleared extends CourierDeliveryProofEvent {
  const CourierDeliveryProofImageCleared();
}

/// Perubahan nama penerima aktual pada formulir
class CourierDeliveryProofRecipientNameChanged extends CourierDeliveryProofEvent {
  final String name;

  const CourierDeliveryProofRecipientNameChanged(this.name);

  @override
  List<Object?> get props => [name];
}

/// Perubahan pilihan hubungan penerima dengan tujuan
class CourierDeliveryProofRelationshipChanged extends CourierDeliveryProofEvent {
  final RecipientRelationship relationship;

  const CourierDeliveryProofRelationshipChanged(this.relationship);

  @override
  List<Object?> get props => [relationship];
}

/// Perubahan catatan penyerahan opsional
class CourierDeliveryProofNotesChanged extends CourierDeliveryProofEvent {
  final String notes;

  const CourierDeliveryProofNotesChanged(this.notes);

  @override
  List<Object?> get props => [notes];
}

/// Meminta pengambilan ulang koordinat GPS penyerahan
class CourierDeliveryProofCoordinatesRefreshed extends CourierDeliveryProofEvent {
  const CourierDeliveryProofCoordinatesRefreshed();
}

/// Mengirimkan formulir bukti penyerahan ke backend Supabase
class CourierDeliveryProofSubmitted extends CourierDeliveryProofEvent {
  const CourierDeliveryProofSubmitted();
}

/// Mengatur ulang formulir untuk tugas baru
class CourierDeliveryProofReset extends CourierDeliveryProofEvent {
  const CourierDeliveryProofReset();
}
