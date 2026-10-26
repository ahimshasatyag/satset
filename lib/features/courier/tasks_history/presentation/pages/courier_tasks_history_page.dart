import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/feedback/custom_empty_state.dart';
import '../../data/datasources/courier_tasks_history_local_datasource.dart';
import '../../data/datasources/courier_tasks_history_remote_datasource.dart';
import '../../data/repositories/courier_tasks_history_repository_impl.dart';
import '../../domain/entities/courier_task_history_item.dart';
import '../../domain/repositories/courier_tasks_history_repository.dart';
import '../../domain/usecases/get_courier_task_history_detail_usecase.dart';
import '../../domain/usecases/get_courier_task_history_stats_usecase.dart';
import '../../domain/usecases/get_courier_tasks_history_usecase.dart';
import '../bloc/courier_tasks_history_bloc.dart';
import '../bloc/courier_tasks_history_event.dart';
import '../bloc/courier_tasks_history_state.dart';
import '../widgets/courier_task_history_card.dart';
import '../widgets/courier_task_history_detail_sheet.dart';
import '../widgets/courier_task_history_filter_sheet.dart';
import '../widgets/courier_task_history_skeleton.dart';
import '../widgets/courier_task_history_stats_header.dart';

/// Halaman utama Riwayat Tugas khusus Kurir pada aplikasi SatSet Delivery
class CourierTasksHistoryPage extends StatefulWidget {
  final User? user;
  final String? courierId;
  final CourierTasksHistoryRepository? repository;
  final CourierTasksHistoryBloc? bloc;

  const CourierTasksHistoryPage({
    super.key,
    this.user,
    this.courierId,
    this.repository,
    this.bloc,
  });

  @override
  State<CourierTasksHistoryPage> createState() => _CourierTasksHistoryPageState();
}

class _CourierTasksHistoryPageState extends State<CourierTasksHistoryPage> {
  late final CourierTasksHistoryBloc _bloc;
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.bloc != null) {
      _bloc = widget.bloc!;
    } else {
      final repo = widget.repository ??
          CourierTasksHistoryRepositoryImpl(
            remoteDataSource: CourierTasksHistoryRemoteDataSourceImpl(
              currentUser: widget.user,
            ),
            localDataSource: CourierTasksHistoryLocalDataSourceImpl(),
          );

      _bloc = CourierTasksHistoryBloc(
        getCourierTasksHistoryUseCase: GetCourierTasksHistoryUseCase(repo),
        getCourierTaskHistoryDetailUseCase:
            GetCourierTaskHistoryDetailUseCase(repo),
        getCourierTaskHistoryStatsUseCase:
            GetCourierTaskHistoryStatsUseCase(repo),
        courierId: widget.courierId ?? widget.user?.id,
      );
    }

    _bloc.add(const CourierTaskHistoryFetched());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _bloc.add(const CourierTaskHistoryLoadMore());
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

  void _openFilterSheet(CourierTasksHistoryState state) {
    CourierTaskHistoryFilterSheet.show(
      context,
      selectedTaskType: state.selectedTaskType,
      selectedStatusCode: state.selectedStatusCode,
      startDate: state.startDate,
      endDate: state.endDate,
      datePresetLabel: state.datePresetLabel,
      onApply: ({
        required CourierHistoryTaskType taskType,
        required String statusCode,
        DateTime? startDate,
        DateTime? endDate,
        String? presetLabel,
      }) {
        _bloc.add(CourierTaskHistoryTaskTypeChanged(taskType));
        _bloc.add(CourierTaskHistoryStatusFilterChanged(statusCode));
        _bloc.add(CourierTaskHistoryDateRangeChanged(
          startDate: startDate,
          endDate: endDate,
          presetLabel: presetLabel,
        ));
      },
      onReset: () {
        _bloc.add(const CourierTaskHistoryFiltersReset());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<CourierTasksHistoryBloc, CourierTasksHistoryState>(
        listener: (context, state) {
          if (state.errorMessage != null &&
              state.status == CourierTaskHistoryStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }

          // Buka modal detail ketika data detail siap dimuat
          if (state.detail != null && !state.isDetailLoading) {
            final currentDetail = state.detail!;
            _bloc.add(const CourierTaskHistoryDetailDismissed());
            CourierTaskHistoryDetailSheet.show(context, detail: currentDetail);
          }

          if (state.detailError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.detailError!),
                backgroundColor: AppColors.error,
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
              title: const Text(
                'Riwayat Tugas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              elevation: 0,
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              actions: [
                IconButton(
                  tooltip: 'Filter Riwayat',
                  onPressed: () => _openFilterSheet(state),
                  icon: Badge(
                    isLabelVisible: state.hasActiveFilters,
                    label: Text('${state.activeFilterCount}'),
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.tune_rounded),
                  ),
                ),
              ],
            ),
            body: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                _bloc.add(const CourierTaskHistoryFetched(isRefresh: true));
              },
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 1. Header Ringkasan Statistik
                  SliverToBoxAdapter(
                    child: CourierTaskHistoryStatsHeader(
                      stats: state.stats,
                      onTotalTap: () {
                        _bloc.add(const CourierTaskHistoryStatusFilterChanged('ALL'));
                      },
                      onCompletedTap: () {
                        _bloc.add(const CourierTaskHistoryStatusFilterChanged('DELIVERED'));
                      },
                      onFailedTap: () {
                        _bloc.add(const CourierTaskHistoryStatusFilterChanged('FAILED_DELIVERY'));
                      },
                      onReturnedTap: () {
                        _bloc.add(const CourierTaskHistoryStatusFilterChanged('RETURNED'));
                      },
                    ),
                  ),

                  // 2. Kolom Pencarian
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) {
                            _bloc.add(CourierTaskHistorySearchChanged(val));
                          },
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: 'Cari nomor resi atau nama penerima...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white38 : AppColors.textMutedLight,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: isDark ? Colors.white54 : AppColors.textSecondaryLight,
                            ),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      _bloc.add(const CourierTaskHistorySearchChanged(''));
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. Bilah Filter Cepat Horizontal
                  SliverToBoxAdapter(
                    child: _buildQuickFilterChips(state, isDark),
                  ),

                  // 4. Daftar Riwayat / Loading / Empty / Error
                  _buildContentSliver(state, isDark),

                  // 5. Loading More Indicator
                  if (state.status == CourierTaskHistoryStatus.loadingMore)
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickFilterChips(
    CourierTasksHistoryState state,
    bool isDark,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Filter Cepat Jenis Tugas
          _buildQuickChip(
            label: state.selectedTaskType == CourierHistoryTaskType.all
                ? 'Semua Tugas'
                : (state.selectedTaskType == CourierHistoryTaskType.pickup
                    ? 'Pickup'
                    : 'Delivery'),
            isActive: state.selectedTaskType != CourierHistoryTaskType.all,
            icon: Icons.filter_alt_outlined,
            onTap: () => _openFilterSheet(state),
            isDark: isDark,
          ),
          const SizedBox(width: 8),

          // Filter Cepat Status
          _buildQuickChip(
            label: state.selectedStatusCode == 'ALL'
                ? 'Semua Status'
                : (state.selectedStatusCode == 'DELIVERED'
                    ? 'Selesai'
                    : (state.selectedStatusCode == 'FAILED_DELIVERY'
                        ? 'Gagal'
                        : state.selectedStatusCode)),
            isActive: state.selectedStatusCode != 'ALL',
            icon: Icons.checklist_rounded,
            onTap: () => _openFilterSheet(state),
            isDark: isDark,
          ),
          const SizedBox(width: 8),

          // Filter Cepat Tanggal
          _buildQuickChip(
            label: state.datePresetLabel ?? 'Semua Waktu',
            isActive: state.startDate != null,
            icon: Icons.calendar_today_rounded,
            onTap: () => _openFilterSheet(state),
            isDark: isDark,
          ),

          if (state.hasActiveFilters) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                _searchCtrl.clear();
                _bloc.add(const CourierTaskHistoryFiltersReset());
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.close_rounded, size: 14, color: AppColors.error),
                    SizedBox(width: 4),
                    Text(
                      'Hapus Filter',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required bool isActive,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.white70 : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : (isDark ? Colors.white : AppColors.textPrimaryLight),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: isActive
                  ? Colors.white
                  : (isDark ? Colors.white54 : AppColors.textMutedLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSliver(
    CourierTasksHistoryState state,
    bool isDark,
  ) {
    // 1. Loading State
    if (state.status == CourierTaskHistoryStatus.loading) {
      return const SliverToBoxAdapter(
        child: CourierTaskHistorySkeleton(itemCount: 4),
      );
    }

    // 2. Error / Offline State
    if (state.status == CourierTaskHistoryStatus.failure) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 56,
                  color: isDark ? Colors.white38 : Colors.black26,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gagal Memuat Riwayat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  state.errorMessage ??
                      'Terjadi gangguan koneksi internet. Silakan coba kembali.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    _bloc.add(const CourierTaskHistoryFetched());
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. Empty State
    if (state.tasks.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: CustomEmptyState(
          icon: Icons.history_rounded,
          title: state.hasActiveFilters
              ? 'Tidak Ditemukan Riwayat'
              : 'Belum Ada Riwayat Tugas',
          description: state.hasActiveFilters
              ? 'Tidak ada riwayat tugas kurir yang cocok dengan kata kunci atau filter yang Anda terapkan.'
              : 'Seluruh riwayat tugas pengambilan dan pengantaran yang pernah ditugaskan kepada Anda akan tampil di sini setelah diselesaikan.',
          buttonText: state.hasActiveFilters ? 'Reset Filter' : 'Perbarui',
          onButtonPressed: () {
            if (state.hasActiveFilters) {
              _searchCtrl.clear();
              _bloc.add(const CourierTaskHistoryFiltersReset());
            } else {
              _bloc.add(const CourierTaskHistoryFetched());
            }
          },
        ),
      );
    }

    // 4. List Riwayat Tugas
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = state.tasks[index];
            return CourierTaskHistoryCard(
              item: item,
              onTap: () {
                _bloc.add(
                  CourierTaskHistoryDetailRequested(
                    shipmentId: item.shipmentId,
                    taskId: item.id,
                  ),
                );
              },
            );
          },
          childCount: state.tasks.length,
        ),
      ),
    );
  }
}
