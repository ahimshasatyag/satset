import '../entities/admin_payment_detail.dart';
import '../repositories/admin_payment_repository.dart';

class GetAdminPaymentDetailUseCase {
  final AdminPaymentRepository repository;

  const GetAdminPaymentDetailUseCase(this.repository);

  Future<AdminPaymentDetail> call(int paymentId) {
    return repository.getPaymentDetail(paymentId);
  }
}

