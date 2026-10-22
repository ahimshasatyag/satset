import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/utils/utils.dart';
import '../../data/datasources/order_local_datasource.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/entities/order_shipment.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/create_shipment_usecase.dart';
import '../../domain/usecases/get_orders_usecase.dart';
import '../bloc/order_bloc.dart';
import '../bloc/order_event.dart';
import '../bloc/order_state.dart';
import '../widgets/payment_skeleton.dart';

class PaymentPage extends StatefulWidget {
  final OrderShipment order;
  final bool enableCountdown;
  final bool isLoading;
  final OrderBloc? bloc;
  final OrderRepository? repository;

  const PaymentPage({
    super.key,
    required this.order,
    this.enableCountdown = true,
    this.isLoading = false,
    this.bloc,
    this.repository,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late OrderShipment _currentOrder;
  Timer? _countdownTimer;
  Duration _timeLeft = const Duration(hours: 23, minutes: 59, seconds: 59);
  bool _userTappedCheck = false;
  BankAccount? _matchedBank;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _initCountdown();
    _resolveBankDetails();
  }

  Future<void> _resolveBankDetails() async {
    if (_currentOrder.payment?.bankAccount != null) {
      setState(() {
        _matchedBank = _currentOrder.payment!.bankAccount;
      });
      return;
    }

    try {
      final repo = widget.repository ??
          OrderRepositoryImpl(
            remoteDataSource: OrderRemoteDataSourceImpl(),
            localDataSource: OrderLocalDataSourceImpl(),
          );
      final banks = await repo.getBanks();
      if (!mounted) return;

      final p = _currentOrder.payment;
      BankAccount? match;

      if (p?.jenisBankId != null && p!.jenisBankId!.isNotEmpty) {
        for (final b in banks) {
          if (b.jenisBankId == p.jenisBankId) {
            match = b;
            break;
          }
        }
      }

      if (match == null && p?.providerReference != null && p!.providerReference!.isNotEmpty) {
        for (final b in banks) {
          if (b.nomorRekening == p.providerReference) {
            match = b;
            break;
          }
        }
      }

      if (match == null && p?.provider != null) {
        final provUpper = p!.provider!.toUpperCase();
        for (final b in banks) {
          final bNameUpper = b.bankName.toUpperCase();
          if (provUpper.contains(bNameUpper) || bNameUpper.contains(provUpper)) {
            match = b;
            break;
          }
        }
      }

      match ??= (banks.isNotEmpty ? banks.first : null);

      if (mounted && match != null) {
        setState(() {
          _matchedBank = match;
        });
      }
    } catch (_) {}
  }

  void _initCountdown() {
    if (!widget.enableCountdown) return;

    final expiredAt = _currentOrder.payment?.expiredAt ??
        DateTime.now().add(const Duration(hours: 24));
    final diff = expiredAt.difference(DateTime.now());
    if (diff.isNegative) {
      _timeLeft = Duration.zero;
    } else {
      _timeLeft = diff;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_timeLeft.inSeconds > 0) {
            _timeLeft = _timeLeft - const Duration(seconds: 1);
          } else {
            timer.cancel();
          }
        });
      });
    }
  }

  OrderBloc? _internalBloc;

  OrderBloc _getOrCreateBloc(BuildContext context) {
    if (widget.bloc != null) {
      return widget.bloc!;
    }
    try {
      return BlocProvider.of<OrderBloc>(context);
    } catch (_) {
      if (_internalBloc == null) {
        final repo = widget.repository ??
            OrderRepositoryImpl(
              remoteDataSource: OrderRemoteDataSourceImpl(),
              localDataSource: OrderLocalDataSourceImpl(),
            );
        _internalBloc = OrderBloc(
          getOrdersUseCase: GetOrdersUseCase(repo),
          createShipmentUseCase: CreateShipmentUseCase(repo),
          repository: repo,
        );
      }
      return _internalBloc!;
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _internalBloc?.close();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours : $minutes : $seconds';
  }

  String _formatCurrency(num amount) {
    return CurrencyFormatter.formatCurrency(amount);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke clipboard'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final isPaid = _currentOrder.payment?.isPaid == true;
    if (isPaid) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Tinggalkan Halaman?'),
          ],
        ),
        content: const Text(
          'Pesanan Anda sudah tersimpan dengan aman di sistem. Anda dapat melanjutkan pembayaran kapan saja melalui daftar pesanan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tetap di Sini'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Keluar'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final bloc = _getOrCreateBloc(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider<OrderBloc>.value(
      value: bloc,
      child: PopScope(
        canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (widget.isLoading) {
          Navigator.of(context).pop();
          return;
        }
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: BlocConsumer<OrderBloc, OrderState>(
        listener: (context, state) {
          if (state.activePayment != null) {
            setState(() {
              _currentOrder = _currentOrder.copyWith(
                payment: state.activePayment,
                statusCode: state.activePayment!.isPaid ? 'CONFIRMED' : _currentOrder.statusCode,
              );
            });
          }
          if (state.message != null && (_userTappedCheck || state.activePayment?.isPaid == true)) {
            _userTappedCheck = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: state.activePayment?.isPaid == true
                    ? AppColors.success
                    : AppColors.primary,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isCod = _currentOrder.paymentMethod == 'COD';
          final isPaid = _currentOrder.payment?.isPaid == true;
          final paymentNumber = _currentOrder.payment?.paymentNumber ?? 'PAY-${_currentOrder.trackingNumber}';
          final providerRef = _currentOrder.payment?.providerReference ??
              (isCod ? 'BAYAR-TUNAI-KURIR' : '8801928374618293');

          return Scaffold(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            appBar: AppBar(
              title: const Text(
                'Pembayaran Pesanan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              centerTitle: true,
              elevation: 0,
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () async {
                  if (widget.isLoading) {
                    Navigator.of(context).pop();
                    return;
                  }
                  final shouldPop = await _onWillPop();
                  if (shouldPop && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            body: widget.isLoading
                ? const PaymentSkeleton()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Status Banner Card
                        _buildStatusBanner(isDark, isPaid, isCod),
                        const SizedBox(height: 16),

                  // 2. Barcode & No. Resi Pengiriman
                  _buildResiBarcodeCard(isDark),
                  const SizedBox(height: 16),

                  // 3. Detail Tagihan & Rincian Biaya
                  _buildBillSummaryCard(isDark),
                  const SizedBox(height: 16),

                  // 4. Instruksi Pembayaran (Transfer VA / QRIS / COD)
                  if (!isPaid)
                    isCod
                        ? _buildCodInstructions(isDark)
                        : _buildTransferInstructions(isDark, providerRef, paymentNumber),
                  const SizedBox(height: 24),

                  // 5. Tombol Aksi Verifikasi / Selesai
                  if (!isPaid && !isCod)
                    ElevatedButton.icon(
                      onPressed: state.isVerifyingPayment
                          ? null
                          : () {
                              setState(() => _userTappedCheck = true);
                              context.read<OrderBloc>().add(
                                    OrderPaymentVerifyRequested(_currentOrder.id),
                                  );
                            },
                      icon: state.isVerifyingPayment
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.verified_outlined),
                      label: Text(
                        state.isVerifyingPayment
                            ? 'Memeriksa ke Gateway...'
                            : 'Periksa Status Pembayaran',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  if (isPaid || isCod)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        isPaid ? 'Selesai & Lihat Pesanan' : 'Saya Mengerti, Kembali',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isPaid ? AppColors.success : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    ),
    );
  }

  Widget _buildStatusBanner(bool isDark, bool isPaid, bool isCod) {
    if (isPaid) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success, width: 1.5),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 36),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pembayaran Terverifikasi!',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Pesanan Anda sedang diproses oleh kurir terdekat SatSet.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (isCod) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary, width: 1.5),
        ),
        child: const Row(
          children: [
            Icon(Icons.handshake_outlined, color: AppColors.secondary, size: 36),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Metode Cash on Delivery (COD)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Pembayaran dilakukan secara tunai kepada kurir saat paket dijemput atau diserahkan.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppColors.warning, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Menunggu Pembayaran',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                    Text(
                      'Selesaikan pembayaran sebelum batas waktu berakhir',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2A3D) : Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.alarm, size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_timeLeft),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warning,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResiBarcodeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nomor Resi Pengiriman',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                onPressed: () => _copyToClipboard(
                  _currentOrder.trackingNumber,
                  'Nomor Resi',
                ),
                tooltip: 'Salin Resi',
              ),
            ],
          ),
          Text(
            _currentOrder.trackingNumber,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // Barcode visualization lines
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(35, (index) {
                final isThick = index % 3 == 0 || index % 7 == 0;
                return Container(
                  width: isThick ? 3.5 : 1.5,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  color: isDark ? Colors.white70 : Colors.black87,
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _currentOrder.barcodeValue,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Tagihan & Pengiriman',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Barang', _currentOrder.itemName, isDark),
          _buildSummaryRow('Layanan', _currentOrder.serviceType, isDark),
          _buildSummaryRow(
            'Berat Paket',
            '${(_currentOrder.weightGram / 1000).toStringAsFixed(1)} kg (${_currentOrder.lengthCm}x${_currentOrder.widthCm}x${_currentOrder.heightCm} cm)',
            isDark,
          ),
          _buildSummaryRow('Rute', '${_currentOrder.originCity} ➔ ${_currentOrder.destinationCity}', isDark),
          const Divider(height: 20),
          _buildSummaryRow('Biaya Pengiriman', _formatCurrency(_currentOrder.shippingFee > 0 ? _currentOrder.shippingFee : _currentOrder.totalPrice), isDark),
          if (_currentOrder.insuranceFee > 0)
            _buildSummaryRow('Asuransi Barang', _formatCurrency(_currentOrder.insuranceFee), isDark),
          if (_currentOrder.additionalFee > 0)
            _buildSummaryRow('Biaya Layanan', _formatCurrency(_currentOrder.additionalFee), isDark),
          if (_currentOrder.discount > 0)
            _buildSummaryRow('Diskon', '-${_formatCurrency(_currentOrder.discount)}', isDark, isHighlight: true),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                _formatCurrency(_currentOrder.totalPrice > 0 ? _currentOrder.totalPrice : _currentOrder.price),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isHighlight
                  ? AppColors.success
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferInstructions(bool isDark, String providerRef, String paymentNumber) {
    final bank = _matchedBank ?? _currentOrder.payment?.bankAccount;
    final bankName = bank?.bankName ??
        (_currentOrder.payment?.provider ?? 'Bank Transfer');
    final accountNumber = (bank != null && bank.nomorRekening.isNotEmpty)
        ? bank.nomorRekening
        : providerRef;
    final accountOwner = bank?.namaPemilik ??
        (_currentOrder.payment?.bankAccount?.namaPemilik ?? '');
    final totalNominal = _currentOrder.totalPrice > 0
        ? _currentOrder.totalPrice
        : _currentOrder.price.toDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Transfer Bank $bankName',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  bankName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Card Nomor Rekening Bank & Pemilik Rekening
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nomor Rekening Tujuan',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          accountNumber,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _copyToClipboard(accountNumber, 'Nomor Rekening'),
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Salin', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                if (accountOwner.isNotEmpty) ...[
                  const Divider(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 15,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Atas Nama: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      Text(
                        accountOwner,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Card Jumlah Transfer yang harus dibayar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Nominal Transfer',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatCurrency(totalNominal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(
                    totalNominal.toInt().toString(),
                    'Nominal Transfer',
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  label: const Text('Salin Jumlah', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Langkah Pembayaran
          const Text(
            'Panduan Pembayaran:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildStepRow(1, 'Buka aplikasi Mobile Banking atau ATM Bank $bankName pilihan Anda.'),
          _buildStepRow(2, 'Pilih menu Transfer > Ke Rekening Bank $bankName.'),
          _buildStepRow(3, 'Masukkan nomor rekening $accountNumber ${accountOwner.isNotEmpty ? '(a.n. $accountOwner)' : ''}.'),
          _buildStepRow(4, 'Masukkan nominal transfer tepat ${_formatCurrency(totalNominal)} dan selesaikan pembayaran.'),
          _buildStepRow(5, 'Tekan tombol "Periksa Status Pembayaran" di bawah setelah transfer berhasil.'),
        ],
      ),
    );
  }

  Widget _buildCodInstructions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: AppColors.secondary),
              SizedBox(width: 8),
              Text(
                'Ketentuan Pembayaran COD (Tunai)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStepRow(1, 'Siapkan uang pas sejumlah ${_formatCurrency(_currentOrder.totalPrice > 0 ? _currentOrder.totalPrice : _currentOrder.price)} saat kurir tiba.'),
          _buildStepRow(2, 'Serahkan uang tunai kepada kurir resmi SatSet yang bertugas.'),
          _buildStepRow(3, 'Kurir akan memverifikasi penerimaan uang melalui aplikasi kurir.'),
          _buildStepRow(4, 'Status transaksi Anda akan otomatis tercatat lunas setelah rekonsiliasi operasional.'),
        ],
      ),
    );
  }

  Widget _buildStepRow(int step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
