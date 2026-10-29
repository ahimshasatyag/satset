import 'package:satset/core/usecases/usecase.dart';
import '../entities/customer_address.dart';
import '../repositories/address_repository.dart';

class GetAddressesParams {
  final int? userId;
  const GetAddressesParams({this.userId});
}

class GetAddressesUseCase implements UseCase<List<CustomerAddress>, GetAddressesParams> {
  final AddressRepository repository;

  const GetAddressesUseCase(this.repository);

  @override
  Future<List<CustomerAddress>> call(GetAddressesParams params) {
    return repository.getAddresses(userId: params.userId);
  }
}
