import '../repositories/admin_customer_repository.dart';

class ToggleCustomerVerificationUseCase {
  final AdminCustomerRepository repository;

  const ToggleCustomerVerificationUseCase(this.repository);

  Future<void> call({
    required int customerId,
    required bool emailVerified,
  }) {
    return repository.toggleCustomerEmailVerification(
      customerId: customerId,
      emailVerified: emailVerified,
    );
  }
}

