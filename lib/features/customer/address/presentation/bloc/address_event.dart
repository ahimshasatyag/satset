import 'package:equatable/equatable.dart';
import '../../domain/entities/customer_address.dart';

enum AddressFilterCategory {
  all('Semua Alamat'),
  primary('Alamat Utama'),
  others('Alamat Lain');

  final String label;
  const AddressFilterCategory(this.label);
}

abstract class AddressEvent extends Equatable {
  const AddressEvent();

  @override
  List<Object?> get props => [];
}

class LoadAddressesEvent extends AddressEvent {
  final bool refresh;
  final int? userId;

  const LoadAddressesEvent({this.refresh = false, this.userId});

  @override
  List<Object?> get props => [refresh, userId];
}

class AddAddressEvent extends AddressEvent {
  final CustomerAddress address;

  const AddAddressEvent(this.address);

  @override
  List<Object?> get props => [address];
}

class UpdateAddressEvent extends AddressEvent {
  final CustomerAddress address;

  const UpdateAddressEvent(this.address);

  @override
  List<Object?> get props => [address];
}

class DeleteAddressEvent extends AddressEvent {
  final CustomerAddress address;

  const DeleteAddressEvent(this.address);

  @override
  List<Object?> get props => [address];
}

class SetPrimaryAddressEvent extends AddressEvent {
  final CustomerAddress address;

  const SetPrimaryAddressEvent(this.address);

  @override
  List<Object?> get props => [address];
}

class SelectAddressEvent extends AddressEvent {
  final CustomerAddress address;

  const SelectAddressEvent(this.address);

  @override
  List<Object?> get props => [address];
}

class SearchAddressEvent extends AddressEvent {
  final String query;

  const SearchAddressEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterAddressCategoryEvent extends AddressEvent {
  final AddressFilterCategory category;

  const FilterAddressCategoryEvent(this.category);

  @override
  List<Object?> get props => [category];
}
