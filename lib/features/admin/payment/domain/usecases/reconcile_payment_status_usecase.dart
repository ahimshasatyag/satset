import '../repositories/admin_payment_repository.dart';

class ReconcilePaymentStatusUseCase {
  final AdminPaymentRepository repository;

  const ReconcilePaymentStatusUseCase(this.repository);

  Future<String> call({
    required int paymentId,
    required int shipmentId,
    String? notes,
  }) {
    return repository.reconcilePaymentStatus(
      paymentId: paymentId,
      shipmentId: shipmentId,
      notes: notes,
    );
  }
}

