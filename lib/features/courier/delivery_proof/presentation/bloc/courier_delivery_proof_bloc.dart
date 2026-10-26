import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/delivery_proof_payload.dart';
import '../../domain/entities/delivery_proof_task.dart';
import '../../domain/usecases/get_active_delivery_tasks_usecase.dart';
import '../../domain/usecases/get_delivery_task_by_id_usecase.dart';
import '../../domain/usecases/get_handover_coordinates_usecase.dart';
import '../../domain/usecases/pick_delivery_proof_image_usecase.dart';
import '../../domain/usecases/submit_delivery_proof_usecase.dart';
import 'courier_delivery_proof_event.dart';
import 'courier_delivery_proof_state.dart';

class CourierDeliveryProofBloc
    extends Bloc<CourierDeliveryProofEvent, CourierDeliveryProofState> {
  final GetActiveDeliveryTasksUseCase getActiveDeliveryTasksUseCase;
  final GetDeliveryTaskByIdUseCase getDeliveryTaskByIdUseCase;
  final PickDeliveryProofImageUseCase pickDeliveryProofImageUseCase;
  final GetHandoverCoordinatesUseCase getHandoverCoordinatesUseCase;
  final SubmitDeliveryProofUseCase submitDeliveryProofUseCase;
  final String? courierId;

  CourierDeliveryProofBloc({
    required this.getActiveDeliveryTasksUseCase,
    required this.getDeliveryTaskByIdUseCase,
    required this.pickDeliveryProofImageUseCase,
    required this.getHandoverCoordinatesUseCase,
    required this.submitDeliveryProofUseCase,
    this.courierId,
  }) : super(const CourierDeliveryProofState()) {
    on<CourierDeliveryProofStarted>(_onStarted);
    on<CourierDeliveryProofTaskSelected>(_onTaskSelected);
    on<CourierDeliveryProofImagePicked>(_onImagePicked);
    on<CourierDeliveryProofImageCleared>(_onImageCleared);
    on<CourierDeliveryProofRecipientNameChanged>(_onRecipientNameChanged);
    on<CourierDeliveryProofRelationshipChanged>(_onRelationshipChanged);
    on<CourierDeliveryProofNotesChanged>(_onNotesChanged);
    on<CourierDeliveryProofCoordinatesRefreshed>(_onCoordinatesRefreshed);
    on<CourierDeliveryProofSubmitted>(_onSubmitted);
    on<CourierDeliveryProofReset>(_onReset);
  }

  Future<void> _onStarted(
    CourierDeliveryProofStarted event,
    Emitter<CourierDeliveryProofState> emit,
  ) async {
    emit(state.copyWith(isLoadingTasks: true, errorMessage: null));

    try {
      // 1. Ambil daftar tugas pengantaran aktif
      final tasks = await getActiveDeliveryTasksUseCase.execute(courierId: courierId);

      DeliveryProofTask? selectedTask;

      // 2. Jika ada initialShipmentId, utamakan tugas tersebut
      if (event.initialShipmentId != null && event.initialShipmentId!.isNotEmpty) {
        final found = tasks.where((t) => t.shipmentId == event.initialShipmentId).toList();
        if (found.isNotEmpty) {
          selectedTask = found.first;
        } else {
          selectedTask = await getDeliveryTaskByIdUseCase.execute(
            event.initialShipmentId!,
            courierId: courierId,
          );
        }
      }

      // Jika belum terpilih dan daftar tugas tidak kosong, pilih tugas pertama
      if (selectedTask == null && tasks.isNotEmpty) {
        selectedTask = tasks.first;
      }

      // 3. Ambil koordinat GPS awal jika perangkat mengizinkan
      final coords = await getHandoverCoordinatesUseCase.execute();

      emit(state.copyWith(
        isLoadingTasks: false,
        tasks: tasks,
        selectedTask: selectedTask,
        recipientName: selectedTask?.receiverName ?? '',
        latitude: coords?.latitude,
        longitude: coords?.longitude,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingTasks: false,
        errorMessage: 'Gagal memuat informasi tugas pengiriman: $e',
      ));
    }
  }

  void _onTaskSelected(
    CourierDeliveryProofTaskSelected event,
    Emitter<CourierDeliveryProofState> emit,
  ) {
    emit(state.copyWith(
      selectedTask: event.task,
      recipientName: event.task.receiverName,
      errorMessage: null,
    ));
  }

  Future<void> _onImagePicked(
    CourierDeliveryProofImagePicked event,
    Emitter<CourierDeliveryProofState> emit,
  ) async {
    try {
      final result = await pickDeliveryProofImageUseCase.execute(
        fromCamera: event.fromCamera,
      );

      if (result != null) {
        emit(state.copyWith(
          imageBytes: result.bytes,
          imageFileName: result.fileName,
          imageSizeBytes: result.sizeBytes,
          errorMessage: null,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  void _onImageCleared(
    CourierDeliveryProofImageCleared event,
    Emitter<CourierDeliveryProofState> emit,
  ) {
    emit(state.copyWith(clearImage: true));
  }

  void _onRecipientNameChanged(
    CourierDeliveryProofRecipientNameChanged event,
    Emitter<CourierDeliveryProofState> emit,
  ) {
    emit(state.copyWith(recipientName: event.name));
  }

  void _onRelationshipChanged(
    CourierDeliveryProofRelationshipChanged event,
    Emitter<CourierDeliveryProofState> emit,
  ) {
    emit(state.copyWith(relationship: event.relationship));
  }

  void _onNotesChanged(
    CourierDeliveryProofNotesChanged event,
    Emitter<CourierDeliveryProofState> emit,
  ) {
    emit(state.copyWith(notes: event.notes));
  }

  Future<void> _onCoordinatesRefreshed(
    CourierDeliveryProofCoordinatesRefreshed event,
    Emitter<CourierDeliveryProofState> emit,
  ) async {
    emit(state.copyWith(isCapturingGps: true));
    final coords = await getHandoverCoordinatesUseCase.execute();
    emit(state.copyWith(
      isCapturingGps: false,
      latitude: coords?.latitude,
      longitude: coords?.longitude,
    ));
  }

  Future<void> _onSubmitted(
    CourierDeliveryProofSubmitted event,
    Emitter<CourierDeliveryProofState> emit,
  ) async {
    // 1. Validasi tugas aktif
    if (state.selectedTask == null) {
      emit(state.copyWith(
        errorMessage: 'Pilih tugas pengantaran yang akan diselesaikan.',
      ));
      return;
    }

    if (state.selectedTask!.isDelivered) {
      emit(state.copyWith(
        errorMessage: 'Paket ini sudah diserahkan sebelumnya (status DELIVERED).',
      ));
      return;
    }

    // 2. Validasi lampiran foto
    if (state.imageBytes == null || state.imageBytes!.isEmpty) {
      emit(state.copyWith(
        errorMessage: 'Foto bukti penyerahan paket wajib dilampirkan.',
      ));
      return;
    }

    // 3. Validasi nama penerima
    if (state.recipientName.trim().isEmpty) {
      emit(state.copyWith(
        errorMessage: 'Nama penerima aktual wajib diisi.',
      ));
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: null));

    try {
      final payload = DeliveryProofPayload(
        shipmentId: state.selectedTask!.shipmentId,
        courierId: courierId,
        imageBytes: state.imageBytes!,
        fileName: state.imageFileName ?? 'proof_${state.selectedTask!.shipmentId}.jpg',
        recipientName: state.recipientName.trim(),
        relationship: state.relationship,
        notes: state.notes.trim().isNotEmpty ? state.notes.trim() : null,
        latitude: state.latitude,
        longitude: state.longitude,
        deliveredAt: DateTime.now(),
      );

      final proofResult = await submitDeliveryProofUseCase.execute(payload);

      emit(state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        submittedProof: proofResult,
        successMessage: 'Bukti penyerahan berhasil disimpan dan paket telah ditandai DELIVERED.',
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: 'Gagal mengirimkan bukti pengiriman: $e',
      ));
    }
  }

  void _onReset(
    CourierDeliveryProofReset event,
    Emitter<CourierDeliveryProofState> emit,
  ) {
    emit(const CourierDeliveryProofState());
    add(CourierDeliveryProofStarted(initialShipmentId: null));
  }
}
