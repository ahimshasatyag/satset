import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/feedback/custom_empty_state.dart';

import '../../data/datasources/courier_delivery_proof_device_datasource.dart';
import '../../data/datasources/courier_delivery_proof_local_datasource.dart';
import '../../data/datasources/courier_delivery_proof_remote_datasource.dart';
import '../../data/repositories/courier_delivery_proof_repository_impl.dart';
import '../../domain/entities/delivery_proof_task.dart';
import '../../domain/repositories/courier_delivery_proof_repository.dart';
import '../../domain/usecases/get_active_delivery_tasks_usecase.dart';
import '../../domain/usecases/get_delivery_task_by_id_usecase.dart';
import '../../domain/usecases/get_handover_coordinates_usecase.dart';
import '../../domain/usecases/pick_delivery_proof_image_usecase.dart';
import '../../domain/usecases/submit_delivery_proof_usecase.dart';
import '../bloc/courier_delivery_proof_bloc.dart';
import '../bloc/courier_delivery_proof_event.dart';
import '../bloc/courier_delivery_proof_state.dart';
import '../widgets/delivery_proof_form_card.dart';
import '../widgets/delivery_proof_photo_picker_card.dart';
import '../widgets/delivery_proof_success_card.dart';
import '../widgets/delivery_proof_task_info_card.dart';

/// Halaman utama Bukti Pengiriman (Delivery Proof) khusus Kurir pada aplikasi SatSet Delivery
class CourierDeliveryProofPage extends StatefulWidget {
  final User? user;
  final String? courierId;
  final String? initialShipmentId;
  final DeliveryProofTask? initialTask;
  final CourierDeliveryProofRepository? repository;
  final CourierDeliveryProofBloc? bloc;

  const CourierDeliveryProofPage({
    super.key,
    this.user,
    this.courierId,
    this.initialShipmentId,
    this.initialTask,
    this.repository,
    this.bloc,
  });

  @override
  State<CourierDeliveryProofPage> createState() => _CourierDeliveryProofPageState();
}

class _CourierDeliveryProofPageState extends State<CourierDeliveryProofPage> {
  late final CourierDeliveryProofBloc _bloc;

  @override
  void initState() {
    super.initState();

    if (widget.bloc != null) {
      _bloc = widget.bloc!;
    } else {
      final repo = widget.repository ??
          CourierDeliveryProofRepositoryImpl(
            remoteDataSource: CourierDeliveryProofRemoteDataSourceImpl(
              client: Supabase.instance.client,
              currentUser: widget.user,
            ),
            deviceDataSource: CourierDeliveryProofDeviceDataSourceImpl(),
            localDataSource: CourierDeliveryProofLocalDataSourceImpl(),
          );

      _bloc = CourierDeliveryProofBloc(
        getActiveDeliveryTasksUseCase: GetActiveDeliveryTasksUseCase(repo),
        getDeliveryTaskByIdUseCase: GetDeliveryTaskByIdUseCase(repo),
        pickDeliveryProofImageUseCase: PickDeliveryProofImageUseCase(repo),
        getHandoverCoordinatesUseCase: GetHandoverCoordinatesUseCase(repo),
        submitDeliveryProofUseCase: SubmitDeliveryProofUseCase(repo),
        courierId: widget.courierId,
      );
    }

    _bloc.add(CourierDeliveryProofStarted(
      initialShipmentId: widget.initialShipmentId ?? widget.initialTask?.shipmentId,
    ));
  }

  @override
  void dispose() {
    if (widget.bloc == null) {
      _bloc.close();
    }
    super.dispose();
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<CourierDeliveryProofBloc, CourierDeliveryProofState>(
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            _showErrorSnackBar(context, state.errorMessage!);
          } else if (state.successMessage != null && state.successMessage!.isNotEmpty) {
            _showSuccessSnackBar(context, state.successMessage!);
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Bukti Pengiriman'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                if (!state.isSuccess)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Muat Ulang Tugas',
                    onPressed: state.isSubmitting
                        ? null
                        : () {
                            _bloc.add(CourierDeliveryProofStarted(
                              initialShipmentId: state.selectedTask?.shipmentId,
                            ));
                          },
                  ),
              ],
            ),
            body: SafeArea(
              child: _buildBody(context, state, isDark),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    CourierDeliveryProofState state,
    bool isDark,
  ) {
    // 1. Tampilan Hasil Sukses Penyerahan
    if (state.isSuccess && state.selectedTask != null && state.submittedProof != null) {
      return DeliveryProofSuccessCard(
        task: state.selectedTask!,
        proof: state.submittedProof!,
        imageBytes: state.imageBytes,
        onBackToTasks: () => Navigator.of(context).pop(true),
        onResetForNextTask: () => _bloc.add(const CourierDeliveryProofReset()),
      );
    }

    // 2. Tampilan Loading Awal
    if (state.isLoadingTasks && state.selectedTask == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Memeriksa data tugas pengantaran...',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 3. Tampilan Tidak Ada Tugas Aktif
    if (state.selectedTask == null && state.tasks.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: CustomEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Tidak Ada Tugas Pengantaran',
            description:
                'Saat ini Anda tidak memiliki tugas pengantaran yang siap diserahkan. Pastikan tugas sudah diambil dari gudang sortir atau hub.',
            buttonText: 'Muat Ulang Tugas',
            onButtonPressed: () {
              _bloc.add(const CourierDeliveryProofStarted());
            },
          ),
        ),
      );
    }

    final selectedTask = state.selectedTask;
    if (selectedTask == null) {
      return const SizedBox.shrink();
    }

    // 4. Formulir Pengisian Bukti Pengiriman
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Peringatan jika paket sudah berstatus DELIVERED
            if (selectedTask.isDelivered) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Paket ini telah berhasil diserahkan sebelumnya (status DELIVERED).',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Kartu Ringkasan Tugas
            DeliveryProofTaskInfoCard(
              task: selectedTask,
              allTasks: state.tasks,
              onSelectTask: (task) {
                _bloc.add(CourierDeliveryProofTaskSelected(task));
              },
            ),
            const SizedBox(height: 14),

            // Kartu Pengambilan Foto Bukti
            DeliveryProofPhotoPickerCard(
              imageBytes: state.imageBytes,
              imageFileName: state.imageFileName,
              formattedFileSize: state.formattedFileSize,
              hasError: state.errorMessage != null && state.imageBytes == null,
              onPickCamera: () {
                _bloc.add(const CourierDeliveryProofImagePicked(fromCamera: true));
              },
              onPickGallery: () {
                _bloc.add(const CourierDeliveryProofImagePicked(fromCamera: false));
              },
              onClearImage: () {
                _bloc.add(const CourierDeliveryProofImageCleared());
              },
            ),
            const SizedBox(height: 14),

            // Kartu Formulir Isian
            DeliveryProofFormCard(
              initialRecipientName: state.recipientName,
              selectedRelationship: state.relationship,
              notes: state.notes,
              latitude: state.latitude,
              longitude: state.longitude,
              isCapturingGps: state.isCapturingGps,
              hasNameError: state.errorMessage != null && state.recipientName.trim().isEmpty,
              onRecipientNameChanged: (name) {
                _bloc.add(CourierDeliveryProofRecipientNameChanged(name));
              },
              onRelationshipChanged: (rel) {
                _bloc.add(CourierDeliveryProofRelationshipChanged(rel));
              },
              onNotesChanged: (notes) {
                _bloc.add(CourierDeliveryProofNotesChanged(notes));
              },
              onRefreshGps: () {
                _bloc.add(const CourierDeliveryProofCoordinatesRefreshed());
              },
            ),
          ],
        ),

        // Sticky Bottom Submit Button
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: state.isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  state.isSubmitting
                      ? 'Mengirim Bukti & Memperbarui Status...'
                      : 'Konfirmasi Paket Diserahkan',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark ? Colors.white12 : Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: state.isFormValid && !state.isSubmitting
                    ? () => _bloc.add(const CourierDeliveryProofSubmitted())
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
