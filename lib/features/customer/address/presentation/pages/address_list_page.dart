import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/app/config/supabase_config.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';

import '../../data/datasources/address_remote_datasource.dart';
import '../../data/repositories/address_repository_impl.dart';
import '../../domain/entities/customer_address.dart';
import '../../domain/repositories/address_repository.dart';
import '../../domain/usecases/add_address_usecase.dart';
import '../../domain/usecases/delete_address_usecase.dart';
import '../../domain/usecases/get_addresses_usecase.dart';
import '../../domain/usecases/set_primary_address_usecase.dart';
import '../../domain/usecases/update_address_usecase.dart';
import '../bloc/address_bloc.dart';
import '../bloc/address_event.dart';
import '../bloc/address_state.dart';
import '../widgets/address_card.dart';
import '../widgets/address_filter_bar.dart';
import '../widgets/address_form_dialog.dart';
import '../widgets/address_list_skeleton.dart';

export '../widgets/address_list_skeleton.dart';

class AddressListPage extends StatefulWidget {
  final bool isSelectionMode;
  final CustomerAddress? selectedAddress;
  final AddressRepository? repository;

  const AddressListPage({
    super.key,
    this.isSelectionMode = false,
    this.selectedAddress,
    this.repository,
  });

  /// Helper route untuk navigasi mudah ke halaman List Address dengan transisi halus
  static SmoothPageRoute<CustomerAddress?> route({
    bool isSelectionMode = false,
    CustomerAddress? selectedAddress,
    AddressRepository? repository,
  }) {
    return SmoothPageRoute<CustomerAddress?>(
      child: AddressListPage(
        isSelectionMode: isSelectionMode,
        selectedAddress: selectedAddress,
        repository: repository,
      ),
    );
  }

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  AddressRepository? _repo;
  AddressRepository get _repository =>
      _repo ??= widget.repository ??
          AddressRepositoryImpl(
            remoteDataSource: AddressRemoteDataSourceImpl(
              client: SupabaseConfig.client,
            ),
          );

  late final AddressBloc _addressBloc;
  final TextEditingController _searchController = TextEditingController();

  CustomerAddress? _currentSelected;

  @override
  void initState() {
    super.initState();
    _currentSelected = widget.selectedAddress;

    _addressBloc = AddressBloc(
      getAddressesUseCase: GetAddressesUseCase(_repository),
      addAddressUseCase: AddAddressUseCase(_repository),
      updateAddressUseCase: UpdateAddressUseCase(_repository),
      deleteAddressUseCase: DeleteAddressUseCase(_repository),
      setPrimaryAddressUseCase: SetPrimaryAddressUseCase(_repository),
    )..add(const LoadAddressesEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _addressBloc.close();
    super.dispose();
  }

  Future<void> _showAddAddressDialog() async {
    final state = _addressBloc.state;
    String? defaultName;
    String? defaultPhone;

    if (state is AddressLoaded && state.primaryAddress != null) {
      defaultName = state.primaryAddress!.receiverName;
      defaultPhone = state.primaryAddress!.phoneNumber;
    }

    final newAddress = await AddressFormDialog.show(
      context,
      repository: _repository,
      defaultName: defaultName,
      defaultPhone: defaultPhone,
    );

    if (newAddress != null && mounted) {
      _addressBloc.add(AddAddressEvent(newAddress));
    }
  }

  Future<void> _showEditAddressDialog(CustomerAddress address) async {
    final updated = await AddressFormDialog.show(
      context,
      initialAddress: address,
      repository: _repository,
    );

    if (updated != null && mounted) {
      _addressBloc.add(UpdateAddressEvent(updated));
    }
  }

  void _confirmDeleteAddress(CustomerAddress address) {
    CustomDialog.showWarning(
      context: context,
      title: 'Hapus Alamat?',
      message:
          'Apakah Anda yakin ingin menghapus alamat "${address.title}"? Tindakan ini tidak dapat dibatalkan.',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      onConfirm: () {
        _addressBloc.add(DeleteAddressEvent(address));
      },
    );
  }

  void _confirmSetPrimaryAddress(CustomerAddress address) {
    CustomDialog.show(
      context: context,
      title: 'Jadikan Alamat Utama?',
      message:
          'Alamat "${address.title}" akan ditetapkan sebagai alamat pengiriman utama Anda.',
      confirmText: 'Ya, Jadikan Utama',
      cancelText: 'Batal',
      icon: Icons.star_rounded,
      iconColor: AppColors.secondary,
      onConfirm: () {
        _addressBloc.add(SetPrimaryAddressEvent(address));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _addressBloc,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: CustomAppBar(
          title: widget.isSelectionMode
              ? 'Pilih Alamat Pengiriman'
              : 'Daftar Alamat',
          showBackButton: true,
          actions: [
            IconButton(
              tooltip: 'Muat Ulang',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                _addressBloc.add(const LoadAddressesEvent(refresh: true));
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddAddressDialog,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          icon: const Icon(Icons.add_location_alt_rounded),
          label: Text(
            'Tambah Alamat',
            style: AppTextStyles.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: BlocConsumer<AddressBloc, AddressState>(
          listener: (context, state) {
            if (state is AddressLoaded && state.successMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.successMessage!,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            } else if (state is AddressError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          state.message,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is AddressLoading) {
              return const AddressListSkeleton();
            }

            if (state is AddressLoaded) {
              final all = state.allAddresses;
              final filtered = state.filteredAddresses;
              final primaryCount = state.primaryAddress != null ? 1 : 0;
              final otherCount = state.otherAddresses.length;

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  _addressBloc.add(const LoadAddressesEvent(refresh: true));
                },
                child: Column(
                  children: [
                    // Filter & Search Bar
                    AddressFilterBar(
                      activeFilter: state.activeFilter,
                      totalCount: all.length,
                      primaryCount: primaryCount,
                      otherCount: otherCount,
                      searchController: _searchController,
                      onFilterSelected: (category) {
                        _addressBloc.add(FilterAddressCategoryEvent(category));
                      },
                      onSearchChanged: (query) {
                        _addressBloc.add(SearchAddressEvent(query));
                      },
                    ),

                    // Info Banner Penjelasan Alamat Utama via CustomCard
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: CustomCard(
                        variant: CardVariant.filled,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : AppColors.primary50.withValues(alpha: 0.7),
                        border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : AppColors.primary.withValues(alpha: 0.15),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Alamat Utama akan diprioritaskan saat pengiriman. Tekan lama atau klik tombol "Jadikan Utama" pada kartu mana saja untuk mengubahnya.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Address List / Empty State via CustomEmptyState
                    Expanded(
                      child: filtered.isEmpty
                          ? CustomEmptyState(
                              icon: state.searchQuery.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.location_off_rounded,
                              title: state.searchQuery.isNotEmpty
                                  ? 'Alamat Tidak Ditemukan'
                                  : 'Belum Ada Alamat Tersimpan',
                              description: state.searchQuery.isNotEmpty
                                  ? 'Coba gunakan kata kunci pencarian nama tempat, kelurahan, atau kota lainnya.'
                                  : 'Tambahkan alamat pengiriman rumah, kantor, atau gudang untuk mempermudah transaksi pengiriman Anda.',
                              buttonText: state.searchQuery.isNotEmpty
                                  ? null
                                  : 'Tambah Alamat Sekarang',
                              onButtonPressed: state.searchQuery.isNotEmpty
                                  ? null
                                  : _showAddAddressDialog,
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 96),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final address = filtered[index];
                                final isSelected =
                                    _currentSelected?.id == address.id;

                                return AddressCard(
                                  address: address,
                                  isSelectionMode: widget.isSelectionMode,
                                  isSelected: isSelected,
                                  onTap: () {
                                    if (widget.isSelectionMode) {
                                      setState(
                                          () => _currentSelected = address);
                                      Navigator.of(context).pop(address);
                                    }
                                  },
                                  onLongPress: () {
                                    if (!address.isPrimary) {
                                      HapticFeedback.heavyImpact();
                                      _confirmSetPrimaryAddress(address);
                                    } else {
                                      HapticFeedback.selectionClick();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Alamat ini sudah menjadi Alamat Utama profil akun Anda.',
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: AppColors.primary,
                                          behavior: SnackBarBehavior.floating,
                                          duration: const Duration(seconds: 2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  onEdit: () => _showEditAddressDialog(address),
                                  onDelete: () =>
                                      _confirmDeleteAddress(address),
                                  onSetPrimary: () =>
                                      _confirmSetPrimaryAddress(address),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            }

            if (state is AddressError) {
              return Center(
                child: CustomEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Terjadi Kesalahan',
                  description: state.message,
                  buttonText: 'Coba Lagi',
                  onButtonPressed: () {
                    _addressBloc.add(
                      const LoadAddressesEvent(refresh: true),
                    );
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
