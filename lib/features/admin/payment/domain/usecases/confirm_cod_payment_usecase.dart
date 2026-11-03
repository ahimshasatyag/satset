import '../repositories/admin_payment_repository.dart';

class ConfirmCodPaymentUseCase {
  final AdminPaymentRepository repository;

  const ConfirmCodPaymentUseCase(this.repository);

  Future<void> call({
    required int paymentId,
    required int shipmentId,
    required num verifiedAmount,
    String? settlementReference,
    String? notes,
  }) {
    return repository.confirmCodPaymentSettlement(
      paymentId: paymentId,
      shipmentId: shipmentId,
      verifiedAmount: verifiedAmount,
      settlementReference: settlementReference,
      notes: notes,
    );
  }
}

