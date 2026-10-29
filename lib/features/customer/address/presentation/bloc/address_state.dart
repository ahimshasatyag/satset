import 'package:equatable/equatable.dart';
import '../../domain/entities/customer_address.dart';
import 'address_event.dart';

abstract class AddressState extends Equatable {
  const AddressState();

  @override
  List<Object?> get props => [];
}

class AddressInitial extends AddressState {}

class AddressLoading extends AddressState {}

class AddressLoaded extends AddressState {
  final List<CustomerAddress> allAddresses;
  final List<CustomerAddress> filteredAddresses;
  final CustomerAddress? primaryAddress;
  final List<CustomerAddress> otherAddresses;
  final CustomerAddress? selectedAddress;
  final String searchQuery;
  final AddressFilterCategory activeFilter;
  final bool isActionLoading;
  final String? successMessage;

  const AddressLoaded({
    required this.allAddresses,
    required this.filteredAddresses,
    this.primaryAddress,
    this.otherAddresses = const [],
    this.selectedAddress,
    this.searchQuery = '',
    this.activeFilter = AddressFilterCategory.all,
    this.isActionLoading = false,
    this.successMessage,
  });

  AddressLoaded copyWith({
    List<CustomerAddress>? allAddresses,
    List<CustomerAddress>? filteredAddresses,
    CustomerAddress? primaryAddress,
    List<CustomerAddress>? otherAddresses,
    CustomerAddress? selectedAddress,
    String? searchQuery,
    AddressFilterCategory? activeFilter,
    bool? isActionLoading,
    String? successMessage,
    bool clearSuccessMessage = false,
  }) {
    return AddressLoaded(
      allAddresses: allAddresses ?? this.allAddresses,
      filteredAddresses: filteredAddresses ?? this.filteredAddresses,
      primaryAddress: primaryAddress ?? this.primaryAddress,
      otherAddresses: otherAddresses ?? this.otherAddresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
      isActionLoading: isActionLoading ?? this.isActionLoading,
      successMessage: clearSuccessMessage ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        allAddresses,
        filteredAddresses,
        primaryAddress,
        otherAddresses,
        selectedAddress,
        searchQuery,
        activeFilter,
        isActionLoading,
        successMessage,
      ];
}

class AddressError extends AddressState {
  final String message;

  const AddressError(this.message);

  @override
  List<Object?> get props => [message];
}
