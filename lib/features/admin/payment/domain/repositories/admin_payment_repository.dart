import '../entities/admin_payment_detail.dart';
import '../entities/admin_payment_item.dart';

abstract class AdminPaymentRepository {
  Future<bool> verifyAdminAccess();

  Future<AdminPaymentsPaginatedResult> getPaginatedPayments({
    String tabCategory = AdminPaymentTab.all,
    String? searchQuery,
    String? methodFilter,
    String? statusFilter,
    String? jenisBankFilter,
    DateTime? startDate,
    DateTime? endDate,
    num? minAmount,
    num? maxAmount,
    String sortColumn = 'created_at',
    bool sortAscending = false,
    int page = 1,
    int pageSize = 10,
  });

  Future<AdminPaymentDetail> getPaymentDetail(int paymentId);

  Future<List<AdminBankReference>> getBankReferences();

  /// Melakukan sinkronisasi / rekonsiliasi status pembayaran gateway & validasi batas waktu/nominal
  /// melalui verifikasi backend / RPC Supabase dengan proteksi idempotensi dan pencatatan audit.
  Future<String> reconcilePaymentStatus({
    required int paymentId,
    required int shipmentId,
    String? notes,
  });

  /// Mengonfirmasi / memverifikasi penyelesaian setoran pembayaran Cash on Delivery (COD)
  /// oleh kurir/penerima setelah validasi nominal dan pencatatan audit ke database.
  Future<void> confirmCodPaymentSettlement({
    required int paymentId,
    required int shipmentId,
    required num verifiedAmount,
    String? settlementReference,
    String? notes,
  });
}

