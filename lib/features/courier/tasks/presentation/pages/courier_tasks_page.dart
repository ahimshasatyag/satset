import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/feedback/custom_empty_state.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import '../../data/datasources/courier_tasks_local_datasource.dart';
import '../../data/datasources/courier_tasks_remote_datasource.dart';
import '../../data/repositories/courier_tasks_repository_impl.dart';
import '../../domain/entities/courier_task.dart';
import '../../domain/repositories/courier_tasks_repository.dart';
import '../../domain/usecases/get_courier_tasks_usecase.dart';
import '../../domain/usecases/stream_courier_tasks_usecase.dart';
import '../../domain/usecases/update_task_status_usecase.dart';
import '../bloc/courier_tasks_bloc.dart';
import '../bloc/courier_tasks_event.dart';
import '../bloc/courier_tasks_state.dart';
import '../widgets/courier_task_card.dart';
import '../widgets/courier_task_detail_bottom_sheet.dart';
import '../widgets/courier_task_filter_tabs.dart';
import 'package:satset/features/courier/delivery_proof/presentation/pages/courier_delivery_proof_page.dart';
import 'package:satset/features/courier/notifications/presentation/pages/courier_notifications_page.dart';
import 'package:satset/features/courier/tasks_status/presentation/pages/courier_task_status_page.dart';
import '../widgets/courier_tasks_skeleton.dart';

class CourierTasksPage extends StatefulWidget {
  final User? user;
  final String? courierId;
  final CourierTasksRepository? repository;
  final CourierTasksBloc? bloc;

  /// Callback opsional untuk navigasi ke halaman spesifik kurir
  final VoidCallback? onNavigateToScanner;
  final VoidCallback? onNavigateToLocationTracking;
  final VoidCallback? onNavigateToDeliveryProof;
  final VoidCallback? onNavigateToTaskHistory;
  final VoidCallback? onNavigateToNotifications;
  final Function(String shipmentId)? onNavigateToTaskStatus;

  const CourierTasksPage({
    super.key,
    this.user,
    this.courierId,
    this.repository,
    this.bloc,
    this.onNavigateToScanner,
    this.onNavigateToLocationTracking,
    this.onNavigateToDeliveryProof,
    this.onNavigateToTaskHistory,
    this.onNavigateToNotifications,
    this.onNavigateToTaskStatus,
  });

  @override
  State<CourierTasksPage> createState() => _CourierTasksPageState();
}

class _CourierTasksPageState extends State<CourierTasksPage> {
  late final CourierTasksBloc _bloc;
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.bloc != null) {
      _bloc = widget.bloc!;
    } else {
      final repo = widget.repository ??
          CourierTasksRepositoryImpl(
            remoteDataSource: CourierTasksRemoteDataSourceImpl(
              currentUser: widget.user,
            ),
            localDataSource: CourierTasksLocalDataSourceImpl(),
          );

      _bloc = CourierTasksBloc(
        getCourierTasksUseCase: GetCourierTasksUseCase(repo),
        updateTaskStatusUseCase: UpdateTaskStatusUseCase(repo),
        streamCourierTasksUseCase: StreamCourierTasksUseCase(repo),
      );
    }

    _bloc.add(const CourierTasksFetched());
    _bloc.add(const CourierTasksSubscriptionStarted());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _bloc.add(const CourierTasksLoadMore());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    if (widget.bloc == null) {
      _bloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<CourierTasksBloc, CourierTasksState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            appBar: AppBar(
              title: Column(
                children: [
                  const Text(
                    'Tugas Kurir',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (state.lastUpdatedAt != null)
                    Text(
                      'Pembaruan: ${_formatUpdateTime(state.lastUpdatedAt!)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.normal,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                ],
              ),
              centerTitle: true,
              elevation: 0,
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifikasi Tugas',
                  onPressed: () {
                    if (widget.onNavigateToNotifications != null) {
                      widget.onNavigateToNotifications!();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CourierNotificationsPage(
                            courierId: widget.courierId,
                          ),
                        ),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Segarkan Tugas',
                  onPressed: () {
                    _bloc.add(const CourierTasksFetched(isRefresh: true));
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  _bloc.add(const CourierTasksFetched(isRefresh: true));
                },
                child: Column(
                  children: [
                    // Offline / Gangguan Jaringan Banner
                    if (state.isOffline)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        color: AppColors.warningLight,
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off_rounded,
                                size: 16, color: AppColors.warningDark),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Koneksi terputus. Menampilkan data tersimpan di perangkat.',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warningDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Header: Pencarian & Filter Tabs
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Search Box
                          TextField(
                            controller: _searchCtrl,
                            onChanged: (val) {
                              _bloc.add(CourierTasksSearchChanged(val));
                            },
                            decoration: InputDecoration(
                              hintText: 'Cari nomor resi / nama penerima...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                              prefixIcon: const Icon(Icons.search_rounded,
                                  size: 20, color: AppColors.primary),
                              suffixIcon: _searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded,
                                          size: 18),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        _bloc.add(
                                            const CourierTasksSearchChanged(''));
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.surfaceVariantDark
                                  : AppColors.surfaceVariantLight,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Filter Tabs (Kelompok & Jenis)
                          CourierTaskFilterTabs(
                            selectedGroup: state.selectedGroup,
                            selectedType: state.selectedType,
                            pendingCount: state.pendingCount,
                            inProgressCount: state.inProgressCount,
                            completedCount: state.completedCount,
                            onGroupChanged: (group) {
                              _bloc.add(CourierTasksGroupChanged(group));
                            },
                            onTypeChanged: (type) {
                              _bloc.add(CourierTasksTypeFilterChanged(type));
                            },
                          ),
                        ],
                      ),
                    ),

                    // Body List / State Handling
                    Expanded(
                      child: _buildBody(context, state, isDark),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, CourierTasksState state, bool isDark) {
    if (state.isLoading && state.tasks.isEmpty) {
      return const CourierTasksSkeleton();
    }

    if (state.status == CourierTasksStatus.failure && state.tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.error),
              const SizedBox(height: 14),
              Text(
                'Terjadi Kesalahan',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                state.errorMessage ?? 'Gagal memuat tugas kurir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _bloc.add(const CourierTasksFetched(isRefresh: true));
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final displayed = state.displayedTasks;

    if (displayed.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: CustomEmptyState(
          title: _emptyStateTitle(state.selectedGroup),
          description:
              _emptyStateDescription(state.selectedGroup, state.searchQuery),
          icon: _emptyStateIcon(state.selectedGroup),
          buttonText: 'Muat Ulang',
          onButtonPressed: () {
            _bloc.add(const CourierTasksFetched(isRefresh: true));
          },
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      itemCount: displayed.length + (state.hasReachedMax ? 0 : 1),
      itemBuilder: (context, index) {
        if (index >= displayed.length) {
          final shimmerColor = (isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariantLight)
              .withValues(alpha: 0.5);
          return Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            child: CourierTaskCardSkeleton(
              shimmerColor: shimmerColor,
              isDark: isDark,
            ),
          );
        }

        final task = displayed[index];
        return CourierTaskCard(
          task: task,
          onTap: () => _openTaskDetail(task),
          onQuickAction: () => _openTaskDetail(task),
        );
      },
    );
  }

  void _openTaskDetail(CourierTask task) {
    CourierTaskDetailBottomSheet.show(
      context,
      task: task,
      onUpdateStatus: (newStatusCode, notes) {
        _bloc.add(CourierTaskStatusUpdated(
          taskId: task.id,
          shipmentId: task.shipmentId,
          newStatusCode: newStatusCode,
          notes: notes,
        ));
      },
      onOpenScanner: widget.onNavigateToScanner,
      onOpenLocationTracking: widget.onNavigateToLocationTracking,
      onOpenDeliveryProof: () {
        if (widget.onNavigateToDeliveryProof != null) {
          widget.onNavigateToDeliveryProof!();
        } else {
          Navigator.of(context).push(
            SmoothPageRoute(
              child: CourierDeliveryProofPage(
                user: widget.user,
                initialShipmentId: task.shipmentId,
              ),
            ),
          );
        }
      },
      onOpenTaskHistory: widget.onNavigateToTaskHistory,
      onOpenTaskStatus: () {
        if (widget.onNavigateToTaskStatus != null) {
          widget.onNavigateToTaskStatus!(task.shipmentId);
        } else {
          Navigator.of(context).push(
            SmoothPageRoute(
              child: CourierTaskStatusPage(
                shipmentId: task.shipmentId,
                courierId: widget.user?.id ?? widget.courierId,
              ),
            ),
          );
        }
      },
    );
  }

  String _emptyStateTitle(CourierTaskGroup group) {
    switch (group) {
      case CourierTaskGroup.pending:
        return 'Tidak Ada Tugas Baru';
      case CourierTaskGroup.inProgress:
        return 'Tidak Ada Tugas Berlangsung';
      case CourierTaskGroup.completed:
        return 'Belum Ada Tugas Selesai';
    }
  }

  String _emptyStateDescription(CourierTaskGroup group, String search) {
    if (search.trim().isNotEmpty) {
      return 'Tidak ada tugas yang sesuai dengan pencarian "$search".';
    }
    switch (group) {
      case CourierTaskGroup.pending:
        return 'Saat ini belum ada tugas pengambilan atau pengantaran baru yang ditugaskan kepada Anda.';
      case CourierTaskGroup.inProgress:
        return 'Anda tidak sedang mengerjakan tugas aktif. Pilih tugas di tab "Perlu Dikerjakan" untuk memulai.';
      case CourierTaskGroup.completed:
        return 'Daftar riwayat tugas yang telah berhasil diselesaikan akan tercantum di sini.';
    }
  }

  IconData _emptyStateIcon(CourierTaskGroup group) {
    switch (group) {
      case CourierTaskGroup.pending:
        return Icons.assignment_outlined;
      case CourierTaskGroup.inProgress:
        return Icons.local_shipping_outlined;
      case CourierTaskGroup.completed:
        return Icons.task_alt_rounded;
    }
  }

  String _formatUpdateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 45) {
      return 'Baru saja';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} mnt lalu';
    }
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }
}
