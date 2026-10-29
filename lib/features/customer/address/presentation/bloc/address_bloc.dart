import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/customer_address.dart';
import '../../domain/usecases/add_address_usecase.dart';
import '../../domain/usecases/delete_address_usecase.dart';
import '../../domain/usecases/get_addresses_usecase.dart';
import '../../domain/usecases/set_primary_address_usecase.dart';
import '../../domain/usecases/update_address_usecase.dart';
import 'address_event.dart';
import 'address_state.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final GetAddressesUseCase getAddressesUseCase;
  final AddAddressUseCase addAddressUseCase;
  final UpdateAddressUseCase updateAddressUseCase;
  final DeleteAddressUseCase deleteAddressUseCase;
  final SetPrimaryAddressUseCase setPrimaryAddressUseCase;

  AddressBloc({
    required this.getAddressesUseCase,
    required this.addAddressUseCase,
    required this.updateAddressUseCase,
    required this.deleteAddressUseCase,
    required this.setPrimaryAddressUseCase,
  }) : super(AddressInitial()) {
    on<LoadAddressesEvent>(_onLoadAddresses);
    on<AddAddressEvent>(_onAddAddress);
    on<UpdateAddressEvent>(_onUpdateAddress);
    on<DeleteAddressEvent>(_onDeleteAddress);
    on<SetPrimaryAddressEvent>(_onSetPrimaryAddress);
    on<SelectAddressEvent>(_onSelectAddress);
    on<SearchAddressEvent>(_onSearchAddress);
    on<FilterAddressCategoryEvent>(_onFilterAddressCategory);
  }

  Future<void> _onLoadAddresses(
    LoadAddressesEvent event,
    Emitter<AddressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AddressLoaded || event.refresh) {
      emit(AddressLoading());
    }

    try {
      final list = await getAddressesUseCase(GetAddressesParams(userId: event.userId));
      _emitLoaded(emit, list, successMessage: event.refresh ? 'Daftar alamat berhasil diperbarui' : null);
    } catch (e) {
      emit(AddressError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAddAddress(
    AddAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    final currentState = state;
    if (currentState is AddressLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await addAddressUseCase(event.address);
      final list = await getAddressesUseCase(const GetAddressesParams());
      _emitLoaded(emit, list, successMessage: 'Alamat berhasil ditambahkan!');
    } catch (e) {
      if (currentState is AddressLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(AddressError('Gagal menambah alamat: $e'));
    }
  }

  Future<void> _onUpdateAddress(
    UpdateAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    final currentState = state;
    if (currentState is AddressLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await updateAddressUseCase(event.address);
      final list = await getAddressesUseCase(const GetAddressesParams());
      _emitLoaded(emit, list, successMessage: 'Alamat berhasil diperbarui!');
    } catch (e) {
      if (currentState is AddressLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(AddressError('Gagal memperbarui alamat: $e'));
    }
  }

  Future<void> _onDeleteAddress(
    DeleteAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    final currentState = state;
    if (currentState is AddressLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await deleteAddressUseCase(event.address);
      final list = await getAddressesUseCase(const GetAddressesParams());
      _emitLoaded(emit, list, successMessage: 'Alamat berhasil dihapus.');
    } catch (e) {
      if (currentState is AddressLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(AddressError('Gagal menghapus alamat: $e'));
    }
  }

  Future<void> _onSetPrimaryAddress(
    SetPrimaryAddressEvent event,
    Emitter<AddressState> emit,
  ) async {
    final currentState = state;
    if (currentState is AddressLoaded) {
      emit(currentState.copyWith(isActionLoading: true));
    }

    try {
      await setPrimaryAddressUseCase(event.address);
      final list = await getAddressesUseCase(const GetAddressesParams());
      _emitLoaded(emit, list, successMessage: 'Alamat utama berhasil diubah!');
    } catch (e) {
      if (currentState is AddressLoaded) {
        emit(currentState.copyWith(isActionLoading: false));
      }
      emit(AddressError('Gagal mengatur alamat utama: $e'));
    }
  }

  void _onSelectAddress(
    SelectAddressEvent event,
    Emitter<AddressState> emit,
  ) {
    if (state is AddressLoaded) {
      final loaded = state as AddressLoaded;
      emit(loaded.copyWith(selectedAddress: event.address));
    }
  }

  void _onSearchAddress(
    SearchAddressEvent event,
    Emitter<AddressState> emit,
  ) {
    if (state is AddressLoaded) {
      final loaded = state as AddressLoaded;
      final filtered = _applyFilter(
        loaded.allAddresses,
        event.query,
        loaded.activeFilter,
      );
      emit(loaded.copyWith(
        searchQuery: event.query,
        filteredAddresses: filtered,
      ));
    }
  }

  void _onFilterAddressCategory(
    FilterAddressCategoryEvent event,
    Emitter<AddressState> emit,
  ) {
    if (state is AddressLoaded) {
      final loaded = state as AddressLoaded;
      final filtered = _applyFilter(
        loaded.allAddresses,
        loaded.searchQuery,
        event.category,
      );
      emit(loaded.copyWith(
        activeFilter: event.category,
        filteredAddresses: filtered,
      ));
    }
  }

  void _emitLoaded(
    Emitter<AddressState> emit,
    List<CustomerAddress> all, {
    String? successMessage,
  }) {
    CustomerAddress? primary;
    final others = <CustomerAddress>[];

    for (final addr in all) {
      if (addr.isPrimary && primary == null) {
        primary = addr;
      } else {
        others.add(addr);
      }
    }

    final query = (state is AddressLoaded) ? (state as AddressLoaded).searchQuery : '';
    final category = (state is AddressLoaded)
        ? (state as AddressLoaded).activeFilter
        : AddressFilterCategory.all;

    final filtered = _applyFilter(all, query, category);

    emit(AddressLoaded(
      allAddresses: all,
      filteredAddresses: filtered,
      primaryAddress: primary,
      otherAddresses: others,
      searchQuery: query,
      activeFilter: category,
      isActionLoading: false,
      successMessage: successMessage,
    ));
  }

  List<CustomerAddress> _applyFilter(
    List<CustomerAddress> list,
    String query,
    AddressFilterCategory category,
  ) {
    var result = list;

    // Filter Kategori
    if (category == AddressFilterCategory.primary) {
      result = result.where((a) => a.isPrimary).toList();
    } else if (category == AddressFilterCategory.others) {
      result = result.where((a) => !a.isPrimary).toList();
    }

    // Filter Query Pencarian
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      result = result.where((a) {
        return a.title.toLowerCase().contains(q) ||
            a.receiverName.toLowerCase().contains(q) ||
            a.phoneNumber.toLowerCase().contains(q) ||
            a.fullAddress.toLowerCase().contains(q) ||
            (a.provinceName ?? '').toLowerCase().contains(q) ||
            (a.regencyName ?? '').toLowerCase().contains(q) ||
            (a.districtName ?? '').toLowerCase().contains(q) ||
            (a.villageName ?? '').toLowerCase().contains(q) ||
            (a.postalCode ?? '').toLowerCase().contains(q);
      }).toList();
    }

    return result;
  }
}
