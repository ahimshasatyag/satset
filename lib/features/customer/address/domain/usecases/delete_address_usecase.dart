import 'package:satset/core/usecases/usecase.dart';
import '../entities/customer_address.dart';
import '../repositories/address_repository.dart';

class DeleteAddressUseCase implements UseCase<void, CustomerAddress> {
  final AddressRepository repository;

  const DeleteAddressUseCase(this.repository);

  @override
  Future<void> call(CustomerAddress address) {
    return repository.deleteAddress(address);
  }
}
