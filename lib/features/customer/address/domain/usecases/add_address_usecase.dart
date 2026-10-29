import 'package:satset/core/usecases/usecase.dart';
import '../entities/customer_address.dart';
import '../repositories/address_repository.dart';

class AddAddressUseCase implements UseCase<CustomerAddress, CustomerAddress> {
  final AddressRepository repository;

  const AddAddressUseCase(this.repository);

  @override
  Future<CustomerAddress> call(CustomerAddress address) {
    return repository.addAddress(address);
  }
}
