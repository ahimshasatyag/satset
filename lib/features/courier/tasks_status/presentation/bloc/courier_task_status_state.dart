import 'package:equatable/equatable.dart';
import '../../domain/entities/delivery_proof_summary.dart';
import '../../domain/entities/status_transition_option.dart';
import '../../domain/entities/task_status_detail.dart';
import '../../domain/entities/task_status_step.dart';

class CourierTaskStatusState extends Equatable {
  final bool isLoading;
  final bool isUpdating;
  final TaskStatusDetail? taskDetail;
  final List<TaskStatusStep> timeline;
  final DeliveryProofSummary? deliveryProof;
  final DateTime? lastUpdated;
  final bool isSuccess;
  final String? successMessage;
  final String? errorMessage;
  final bool isUnauthorized;
  final bool isNotFound;
  final bool isNetworkError;

  const CourierTaskStatusState({
    this.isLoading = false,
    this.isUpdating = false,
    this.taskDetail,
    this.timeline = const [],
    this.deliveryProof,
    this.lastUpdated,
    this.isSuccess = false,
    this.successMessage,
    this.errorMessage,
    this.isUnauthorized = false,
    this.isNotFound = false,
    this.isNetworkError = false,
  });

  /// True jika data tugas berhasil dimuat
  bool get hasData => taskDetail != null;

  /// True jika ada bukti pengiriman yang tersedia
  bool get hasProof => deliveryProof != null;

  /// Daftar opsi aksi transisi status berikutnya yang diizinkan untuk tugas saat ini
  List<StatusTransitionOption> get availableTransitions =>
      taskDetail?.validNextTransitions ?? const [];

  CourierTaskStatusState copyWith({
    bool? isLoading,
    bool? isUpdating,
    TaskStatusDetail? taskDetail,
    List<TaskStatusStep>? timeline,
    DeliveryProofSummary? deliveryProof,
    bool clearDeliveryProof = false,
    DateTime? lastUpdated,
    bool? isSuccess,
    String? successMessage,
    bool clearSuccessMessage = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isUnauthorized,
    bool? isNotFound,
    bool? isNetworkError,
  }) {
    return CourierTaskStatusState(
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      taskDetail: taskDetail ?? this.taskDetail,
      timeline: timeline ?? this.timeline,
      deliveryProof: clearDeliveryProof ? null : (deliveryProof ?? this.deliveryProof),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isSuccess: isSuccess ?? this.isSuccess,
      successMessage: clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
      isNotFound: isNotFound ?? this.isNotFound,
      isNetworkError: isNetworkError ?? this.isNetworkError,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isUpdating,
        taskDetail,
        timeline,
        deliveryProof,
        lastUpdated,
        isSuccess,
        successMessage,
        errorMessage,
        isUnauthorized,
        isNotFound,
        isNetworkError,
      ];
}
