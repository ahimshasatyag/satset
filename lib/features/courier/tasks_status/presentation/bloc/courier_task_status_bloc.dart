import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/courier_task_status_remote_datasource.dart';
import '../../domain/usecases/get_task_delivery_proof_usecase.dart';
import '../../domain/usecases/get_task_status_detail_usecase.dart';
import '../../domain/usecases/get_task_timeline_usecase.dart';
import '../../domain/usecases/subscribe_task_status_realtime_usecase.dart';
import '../../domain/usecases/update_courier_task_status_usecase.dart';
import 'courier_task_status_event.dart';
import 'courier_task_status_state.dart';

class CourierTaskStatusBloc
    extends Bloc<CourierTaskStatusEvent, CourierTaskStatusState> {
  final GetTaskStatusDetailUseCase getTaskStatusDetailUseCase;
  final GetTaskTimelineUseCase getTaskTimelineUseCase;
  final GetTaskDeliveryProofUseCase getTaskDeliveryProofUseCase;
  final UpdateCourierTaskStatusUseCase updateCourierTaskStatusUseCase;
  final SubscribeTaskStatusRealtimeUseCase subscribeTaskStatusRealtimeUseCase;

  StreamSubscription? _realtimeSubscription;
  String? _currentShipmentId;
  String? _currentCourierId;

  CourierTaskStatusBloc({
    required this.getTaskStatusDetailUseCase,
    required this.getTaskTimelineUseCase,
    required this.getTaskDeliveryProofUseCase,
    required this.updateCourierTaskStatusUseCase,
    required this.subscribeTaskStatusRealtimeUseCase,
  }) : super(const CourierTaskStatusState()) {
    on<CourierTaskStatusStarted>(_onStarted);
    on<CourierTaskStatusRefreshed>(_onRefreshed);
    on<CourierTaskStatusRealtimeUpdated>(_onRealtimeUpdated);
    on<CourierTaskStatusUpdateRequested>(_onUpdateRequested);
    on<CourierTaskStatusFeedbackCleared>(_onFeedbackCleared);
  }

  Future<void> _onStarted(
    CourierTaskStatusStarted event,
    Emitter<CourierTaskStatusState> emit,
  ) async {
    _currentShipmentId = event.shipmentId;
    _currentCourierId = event.courierId;

    emit(state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
      isUnauthorized: false,
      isNotFound: false,
      isNetworkError: false,
    ));

    try {
      final detail = await getTaskStatusDetailUseCase.execute(
        event.shipmentId,
        courierId: event.courierId,
      );

      final timeline = await getTaskTimelineUseCase.execute(event.shipmentId);
      final proof = await getTaskDeliveryProofUseCase.execute(event.shipmentId);

      emit(state.copyWith(
        isLoading: false,
        taskDetail: detail,
        timeline: timeline,
        deliveryProof: proof,
        clearDeliveryProof: proof == null,
        lastUpdated: DateTime.now(),
      ));

      // Inisialisasi Realtime Subscription
      _subscribeRealtime(event.shipmentId);
    } on TaskNotFoundException {
      emit(state.copyWith(
        isLoading: false,
        isNotFound: true,
        errorMessage: 'Tugas pengiriman dengan ID tersebut tidak ditemukan.',
      ));
    } on TaskNotAssignedException {
      emit(state.copyWith(
        isLoading: false,
        isUnauthorized: true,
        errorMessage: 'Tugas ini tidak ditugaskan kepada Anda atau akses kurir tidak sah.',
      ));
    } on SocketException {
      emit(state.copyWith(
        isLoading: false,
        isNetworkError: true,
        errorMessage: 'Koneksi jaringan terputus. Pastikan perangkat terhubung ke internet.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat detail tugas: ${e.toString()}',
      ));
    }
  }

  void _subscribeRealtime(String shipmentId) {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = subscribeTaskStatusRealtimeUseCase.call(shipmentId).listen(
      (updatedDetail) {
        add(CourierTaskStatusRealtimeUpdated(updatedDetail));
      },
      onError: (_) {
        // Realtime fallback tetap tenang
      },
    );
  }

  Future<void> _onRefreshed(
    CourierTaskStatusRefreshed event,
    Emitter<CourierTaskStatusState> emit,
  ) async {
    final shipmentId = _currentShipmentId;
    if (shipmentId == null || shipmentId.isEmpty) return;

    try {
      final detail = await getTaskStatusDetailUseCase.execute(
        shipmentId,
        courierId: _currentCourierId,
      );
      final timeline = await getTaskTimelineUseCase.execute(shipmentId);
      final proof = await getTaskDeliveryProofUseCase.execute(shipmentId);

      emit(state.copyWith(
        taskDetail: detail,
        timeline: timeline,
        deliveryProof: proof,
        clearDeliveryProof: proof == null,
        lastUpdated: DateTime.now(),
        clearErrorMessage: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Gagal menyegarkan data: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRealtimeUpdated(
    CourierTaskStatusRealtimeUpdated event,
    Emitter<CourierTaskStatusState> emit,
  ) async {
    final shipmentId = _currentShipmentId ?? event.updatedDetail.shipmentId;
    List<dynamic> additionalData = const [];
    try {
      final results = await Future.wait([
        getTaskTimelineUseCase.execute(shipmentId),
        getTaskDeliveryProofUseCase.execute(shipmentId),
      ]);
      additionalData = results;
    } catch (_) {}

    final timeline = additionalData.isNotEmpty ? additionalData[0] as List : state.timeline;
    final proof = additionalData.length > 1 ? additionalData[1] : state.deliveryProof;

    emit(state.copyWith(
      taskDetail: event.updatedDetail,
      timeline: timeline.cast(),
      deliveryProof: proof,
      clearDeliveryProof: proof == null,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _onUpdateRequested(
    CourierTaskStatusUpdateRequested event,
    Emitter<CourierTaskStatusState> emit,
  ) async {
    final shipmentId = _currentShipmentId;
    if (shipmentId == null || shipmentId.isEmpty) {
      emit(state.copyWith(errorMessage: 'ID Pengiriman tidak valid.'));
      return;
    }

    emit(state.copyWith(
      isUpdating: true,
      clearErrorMessage: true,
      clearSuccessMessage: true,
    ));

    try {
      await updateCourierTaskStatusUseCase.call(
        shipmentId: shipmentId,
        courierId: _currentCourierId ?? '',
        targetStatusId: event.transition.targetStatusId,
        targetStatusCode: event.transition.statusCode,
        notes: event.notes,
        failureReason: event.failureReason,
        locationName: event.locationName,
        latitude: event.latitude,
        longitude: event.longitude,
      );

      emit(state.copyWith(
        isUpdating: false,
        isSuccess: true,
        successMessage: 'Status berhasil diperbarui menjadi "${event.transition.statusName}".',
      ));

      // Refresh data terbaru segera
      add(const CourierTaskStatusRefreshed());
    } on TaskNotAssignedException {
      emit(state.copyWith(
        isUpdating: false,
        isUnauthorized: true,
        errorMessage: 'Anda tidak memiliki hak akses untuk memperbarui tugas ini.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isUpdating: false,
        errorMessage: 'Gagal memperbarui status: ${e.toString()}',
      ));
    }
  }

  void _onFeedbackCleared(
    CourierTaskStatusFeedbackCleared event,
    Emitter<CourierTaskStatusState> emit,
  ) {
    emit(state.copyWith(
      clearErrorMessage: true,
      clearSuccessMessage: true,
      isSuccess: false,
    ));
  }

  @override
  Future<void> close() {
    _realtimeSubscription?.cancel();
    return super.close();
  }
}
