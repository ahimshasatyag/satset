import '../entities/admin_customer_detail.dart';
import '../repositories/admin_customer_repository.dart';

class GetAdminCustomerDetailUseCase {
  final AdminCustomerRepository repository;

  const GetAdminCustomerDetailUseCase(this.repository);

  Future<AdminCustomerDetail> call(int customerId) {
    return repository.getCustomerDetail(customerId);
  }
}

