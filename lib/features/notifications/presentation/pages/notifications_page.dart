import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/theme/theme.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../customer/livetrack/presentation/pages/live_track_page.dart';
import '../../data/datasources/notification_local_datasource.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_all_notifications_as_read_usecase.dart';
import '../../domain/usecases/mark_notification_as_read_usecase.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_empty_state.dart';
import '../widgets/notification_filter_tabs.dart';
import '../widgets/notification_skeleton.dart';

class NotificationsPage extends StatefulWidget {
  final NotificationRepository? repository;

  const NotificationsPage({super.key, this.repository});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  NotificationBloc? _internalBloc;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _internalBloc?.close();
    _searchController.dispose();
    super.dispose();
  }

  NotificationBloc _getOrCreateBloc(BuildContext context) {
    try {
      return BlocProvider.of<NotificationBloc>(context);
    } catch (_) {
      if (_internalBloc == null) {
        final repo = widget.repository ??
            NotificationRepositoryImpl(
              remoteDataSource: NotificationRemoteDataSourceImpl(),
              localDataSource: NotificationLocalDataSourceImpl(),
            );

        _internalBloc = NotificationBloc(
          getNotificationsUseCase: GetNotificationsUseCase(repo),
          markNotificationAsReadUseCase: MarkNotificationAsReadUseCase(repo),
          markAllNotificationsAsReadUseCase:
              MarkAllNotificationsAsReadUseCase(repo),
          deleteNotificationUseCase: DeleteNotificationUseCase(repo),
          repository: repo,
        );
      }
      return _internalBloc!;
    }
  }

  void _onNotificationTap(
      BuildContext context, NotificationItem item, NotificationBloc bloc) {
    if (!item.isRead) {
      bloc.add(NotificationMarkAsReadSubmitted(item.id));
    }

    final resi = item.metadata?['nomor_resi']?.toString();

    if (item.isShipment && (resi != null || item.shipmentId != null)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LiveTrackPage(
            initialTrackingNumber: resi,
          ),
        ),
      );
    } else {
      _showDetailBottomSheet(context, item);
    }
  }

  void _showDetailBottomSheet(BuildContext context, NotificationItem item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.type.label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        item.formattedTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.message,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Tutup',
              isFullWidth: true,
              size: ButtonSize.medium,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _confirmClearAll(BuildContext context, NotificationBloc bloc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Bersihkan Notifikasi?'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus seluruh riwayat pemberitahuan Anda? Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              bloc.add(const NotificationClearAllSubmitted());
            },
            child: const Text('Bersihkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _getOrCreateBloc(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocProvider<NotificationBloc>.value(
      value: bloc,
      child: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state.actionMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.actionMessage!),
                backgroundColor: AppColors.primary,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final grouped = state.groupedNotifications;

          return Scaffold(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            appBar: AppBar(
              centerTitle: true,
              elevation: 0,
              backgroundColor:
                  isDark ? AppColors.surfaceDark : Colors.white,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Pemberitahuan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (state.unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (state.hasUnread)
                  IconButton(
                    icon: const Icon(Icons.done_all_rounded),
                    tooltip: 'Tandai semua dibaca',
                    onPressed: () {
                      bloc.add(const NotificationMarkAllAsReadSubmitted());
                    },
                  ),
                PopupMenuButton<String>(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (value) {
                    if (value == 'read_all') {
                      bloc.add(const NotificationMarkAllAsReadSubmitted());
                    } else if (value == 'clear_all') {
                      _confirmClearAll(context, bloc);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'read_all',
                      child: Row(
                        children: [
                          Icon(Icons.mark_email_read_outlined, size: 18),
                          SizedBox(width: 10),
                          Text('Tandai Semua Dibaca',
                              style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_outlined,
                              size: 18, color: AppColors.error),
                          SizedBox(width: 10),
                          Text(
                            'Bersihkan Semua',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                // Kolom Pencarian Kata Kunci
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: CustomTextField(
                    hintText: 'Cari notifikasi, resi, pembayaran...',
                    controller: _searchController,
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              bloc.add(
                                  const NotificationSearchQueryChanged(''));
                            },
                          )
                        : null,
                    onChanged: (val) {
                      bloc.add(NotificationSearchQueryChanged(val));
                    },
                  ),
                ),

                // Tab Filter (Semua, Belum Dibaca, Pengiriman, Pembayaran)
                NotificationFilterTabs(
                  activeFilter: state.activeFilter,
                  unreadCount: state.unreadCount,
                  onFilterChanged: (filter) {
                    bloc.add(NotificationFilterChanged(filter));
                  },
                ),

                const Divider(height: 1),

                // Konten Daftar Notifikasi
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () async {
                      bloc.add(const NotificationLoadStarted(isRefresh: true));
                    },
                    child: state.isLoading && state.notifications.isEmpty
                        ? const NotificationSkeleton()
                        : state.isEmpty
                            ? NotificationEmptyState(
                                activeFilter: state.activeFilter,
                                onRefresh: () {
                                  bloc.add(const NotificationLoadStarted());
                                },
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                itemCount: grouped.keys.length,
                                itemBuilder: (context, groupIndex) {
                                  final groupKey =
                                      grouped.keys.elementAt(groupIndex);
                                  final itemsInGroup = grouped[groupKey]!;

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header Pengelompokan Tanggal
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 10,
                                          bottom: 6,
                                          left: 4,
                                        ),
                                        child: Text(
                                          groupKey.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.8,
                                            color: isDark
                                                ? AppColors.textMutedDark
                                                : AppColors.textMutedLight,
                                          ),
                                        ),
                                      ),

                                      // Daftar Kartu Notifikasi
                                      ...itemsInGroup.map(
                                        (item) => NotificationCard(
                                          item: item,
                                          onTap: (selected) =>
                                              _onNotificationTap(
                                                  context, selected, bloc),
                                          onMarkAsRead: (id) {
                                            bloc.add(
                                              NotificationMarkAsReadSubmitted(
                                                  id),
                                            );
                                          },
                                          onDelete: (id) {
                                            bloc.add(NotificationDeleted(id));
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
