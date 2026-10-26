import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

import '../../data/datasources/courier_task_status_local_datasource.dart';
import '../../data/datasources/courier_task_status_remote_datasource.dart';
import '../../data/repositories/courier_task_status_repository_impl.dart';
import '../../domain/usecases/get_task_delivery_proof_usecase.dart';
import '../../domain/usecases/get_task_status_detail_usecase.dart';
import '../../domain/usecases/get_task_timeline_usecase.dart';
import '../../domain/usecases/subscribe_task_status_realtime_usecase.dart';
import '../../domain/usecases/update_courier_task_status_usecase.dart';
import '../bloc/courier_task_status_bloc.dart';
import '../bloc/courier_task_status_event.dart';
import '../bloc/courier_task_status_state.dart';
import '../widgets/task_status_action_bar.dart';
import '../widgets/task_status_header_card.dart';
import '../widgets/task_status_party_card.dart';
import '../widgets/task_status_proof_card.dart';
import '../widgets/task_status_timeline_view.dart';

class CourierTaskStatusPage extends StatelessWidget {
  final String shipmentId;
  final String? courierId;

  const CourierTaskStatusPage({
    super.key,
    required this.shipmentId,
    this.courierId,
  });

  @override
  Widget build(BuildContext context) {
    // Inisialisasi dependensi Clean Architecture
    final remoteDataSource = CourierTaskStatusRemoteDataSourceImpl();
    final localDataSource = CourierTaskStatusLocalDataSourceImpl();
    final repository = CourierTaskStatusRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );

    return BlocProvider(
      create: (context) => CourierTaskStatusBloc(
        getTaskStatusDetailUseCase: GetTaskStatusDetailUseCase(repository),
        getTaskTimelineUseCase: GetTaskTimelineUseCase(repository),
        getTaskDeliveryProofUseCase: GetTaskDeliveryProofUseCase(repository),
        updateCourierTaskStatusUseCase: UpdateCourierTaskStatusUseCase(repository),
        subscribeTaskStatusRealtimeUseCase: SubscribeTaskStatusRealtimeUseCase(repository),
      )..add(CourierTaskStatusStarted(
          shipmentId: shipmentId,
          courierId: courierId,
        )),
      child: _CourierTaskStatusView(shipmentId: shipmentId),
    );
  }
}

class _CourierTaskStatusView extends StatelessWidget {
  final String shipmentId;

  const _CourierTaskStatusView({required this.shipmentId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CourierTaskStatusBloc, CourierTaskStatusState>(
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          context.read<CourierTaskStatusBloc>().add(const CourierTaskStatusFeedbackCleared());
        }

        if (state.successMessage != null && state.successMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
          context.read<CourierTaskStatusBloc>().add(const CourierTaskStatusFeedbackCleared());
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: CustomAppBar(
            title: 'Detail Status Tugas',
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Segarkan',
                onPressed: () {
                  context.read<CourierTaskStatusBloc>().add(const CourierTaskStatusRefreshed());
                },
              ),
            ],
          ),
          body: _buildBody(context, state),
          bottomNavigationBar: state.hasData
              ? TaskStatusActionBar(
                  detail: state.taskDetail!,
                  isUpdating: state.isUpdating,
                  onUpdateStatus: (transition, {failureReason, notes}) {
                    context.read<CourierTaskStatusBloc>().add(
                          CourierTaskStatusUpdateRequested(
                            transition: transition,
                            failureReason: failureReason,
                            notes: notes,
                          ),
                        );
                  },
                  onDeliveryCompleted: () {
                    context.read<CourierTaskStatusBloc>().add(const CourierTaskStatusRefreshed());
                  },
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CourierTaskStatusState state) {
    if (state.isLoading && !state.hasData) {
      return const CustomLoading(
        message: 'Memuat data status tugas kurir...',
      );
    }

    if (state.isNotFound) {
      return CustomEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Tugas Tidak Ditemukan',
        description: 'Data pengiriman dengan nomor resi atau ID ini tidak ditemukan di sistem.',
        buttonText: 'Kembali',
        onButtonPressed: () => Navigator.of(context).pop(),
      );
    }

    if (state.isUnauthorized) {
      return CustomEmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Akses Tidak Diizinkan',
        description: 'Tugas ini tidak terdaftar sebagai penugasan aktif Anda. Anda hanya dapat melihat dan memperbarui tugas pengiriman yang ditugaskan kepada Anda.',
        buttonText: 'Kembali',
        onButtonPressed: () => Navigator.of(context).pop(),
      );
    }

    if (state.isNetworkError && !state.hasData) {
      return CustomEmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Koneksi Terputus',
        description: 'Gagal menghubungi server Supabase. Pastikan koneksi internet ponsel aktif dan coba lagi.',
        buttonText: 'Coba Lagi',
        onButtonPressed: () {
          context.read<CourierTaskStatusBloc>().add(CourierTaskStatusStarted(shipmentId: shipmentId));
        },
      );
    }

    if (!state.hasData) {
      return CustomEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Terjadi Kesalahan',
        description: state.errorMessage ?? 'Gagal memuat informasi tugas.',
        buttonText: 'Muat Ulang',
        onButtonPressed: () {
          context.read<CourierTaskStatusBloc>().add(CourierTaskStatusStarted(shipmentId: shipmentId));
        },
      );
    }

    final detail = state.taskDetail!;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<CourierTaskStatusBloc>().add(const CourierTaskStatusRefreshed());
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kartu Ringkasan Status & Nomor Resi
            TaskStatusHeaderCard(
              detail: detail,
              lastUpdated: state.lastUpdated,
              onRefresh: () {
                context.read<CourierTaskStatusBloc>().add(const CourierTaskStatusRefreshed());
              },
            ),

            // Kartu Informasi Pengirim, Penerima & Paket
            TaskStatusPartyCard(
              detail: detail,
            ),

            // Kartu Bukti Penyerahan (jika ada / jika diperlukan)
            TaskStatusProofCard(
              shipmentId: detail.shipmentId,
              proof: state.deliveryProof,
              isDelivered: detail.currentStatusCode.toUpperCase() == 'DELIVERED',
              onProofUpdated: () {
                context.read<CourierTaskStatusBloc>().add(const CourierTaskStatusRefreshed());
              },
            ),

            // Tampilan Kronologi Tahapan Status
            TaskStatusTimelineView(
              timeline: state.timeline,
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
