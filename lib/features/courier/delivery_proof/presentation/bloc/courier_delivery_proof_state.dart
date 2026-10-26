import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../domain/entities/delivery_proof_item.dart';
import '../../domain/entities/delivery_proof_task.dart';
import '../../domain/entities/recipient_relationship.dart';

class CourierDeliveryProofState extends Equatable {
  final bool isLoadingTasks;
  final bool isSubmitting;
  final bool isCapturingGps;
  final List<DeliveryProofTask> tasks;
  final DeliveryProofTask? selectedTask;
  final Uint8List? imageBytes;
  final String? imageFileName;
  final int? imageSizeBytes;
  final String recipientName;
  final RecipientRelationship relationship;
  final String notes;
  final double? latitude;
  final double? longitude;
  final bool isSuccess;
  final DeliveryProofItem? submittedProof;
  final String? errorMessage;
  final String? successMessage;

  const CourierDeliveryProofState({
    this.isLoadingTasks = false,
    this.isSubmitting = false,
    this.isCapturingGps = false,
    this.tasks = const [],
    this.selectedTask,
    this.imageBytes,
    this.imageFileName,
    this.imageSizeBytes,
    this.recipientName = '',
    this.relationship = RecipientRelationship.self,
    this.notes = '',
    this.latitude,
    this.longitude,
    this.isSuccess = false,
    this.submittedProof,
    this.errorMessage,
    this.successMessage,
  });

  /// True jika formulir lengkap dan siap dikirim
  bool get isFormValid =>
      selectedTask != null &&
      selectedTask!.canSubmitProof &&
      imageBytes != null &&
      imageBytes!.isNotEmpty &&
      recipientName.trim().isNotEmpty &&
      !isSubmitting;

  /// True jika ada foto bukti yang terlampir
  bool get hasImage => imageBytes != null && imageBytes!.isNotEmpty;

  /// True jika koordinat GPS penyerahan berhasil diperoleh
  bool get hasLocation =>
      latitude != null &&
      longitude != null &&
      latitude != 0.0 &&
      longitude != 0.0;

  /// Format teks ukuran berkas foto
  String get formattedFileSize {
    if (imageSizeBytes == null || imageSizeBytes == 0) return '0 KB';
    if (imageSizeBytes! < 1024) return '$imageSizeBytes B';
    if (imageSizeBytes! < 1024 * 1024) {
      return '${(imageSizeBytes! / 1024).toStringAsFixed(1)} KB';
    }
    return '${(imageSizeBytes! / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  CourierDeliveryProofState copyWith({
    bool? isLoadingTasks,
    bool? isSubmitting,
    bool? isCapturingGps,
    List<DeliveryProofTask>? tasks,
    DeliveryProofTask? selectedTask,
    bool clearSelectedTask = false,
    Uint8List? imageBytes,
    bool clearImage = false,
    String? imageFileName,
    int? imageSizeBytes,
    String? recipientName,
    RecipientRelationship? relationship,
    String? notes,
    double? latitude,
    double? longitude,
    bool? isSuccess,
    DeliveryProofItem? submittedProof,
    String? errorMessage,
    String? successMessage,
  }) {
    return CourierDeliveryProofState(
      isLoadingTasks: isLoadingTasks ?? this.isLoadingTasks,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCapturingGps: isCapturingGps ?? this.isCapturingGps,
      tasks: tasks ?? this.tasks,
      selectedTask: clearSelectedTask ? null : (selectedTask ?? this.selectedTask),
      imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
      imageFileName: clearImage ? null : (imageFileName ?? this.imageFileName),
      imageSizeBytes: clearImage ? null : (imageSizeBytes ?? this.imageSizeBytes),
      recipientName: recipientName ?? this.recipientName,
      relationship: relationship ?? this.relationship,
      notes: notes ?? this.notes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isSuccess: isSuccess ?? this.isSuccess,
      submittedProof: submittedProof ?? this.submittedProof,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoadingTasks,
        isSubmitting,
        isCapturingGps,
        tasks,
        selectedTask,
        imageBytes,
        imageFileName,
        imageSizeBytes,
        recipientName,
        relationship,
        notes,
        latitude,
        longitude,
        isSuccess,
        submittedProof,
        errorMessage,
        successMessage,
      ];
}
