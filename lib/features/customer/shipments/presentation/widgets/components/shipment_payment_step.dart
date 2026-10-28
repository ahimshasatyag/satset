import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';

import '../../../domain/entities/shipment.dart';
import 'shipment_form_card.dart';

/// Step 3: Pilihan metode pembayaran dan ringkasan rincian biaya pengiriman.
class ShipmentPaymentStep extends StatelessWidget {
  final bool isDark;
  final String paymentMethod;
  final String paymentChannel;
  final ValueChanged<String> onPaymentMethodChanged;
  final ValueChanged<String> onPaymentChannelChanged;
  final List<BankAccount> banks;
  final BankAccount? selectedBank;
  final ValueChanged<BankAccount>? onBankSelected;
  final Map<String, double> cost;
  final String senderLocation;
  final String receiverLocation;
  final OrderServiceType? selectedService;
  final String weightGramText;
  final bool useInsurance;

  const ShipmentPaymentStep({
    super.key,
    required this.isDark,
    required this.paymentMethod,
    required this.paymentChannel,
    required this.onPaymentMethodChanged,
    required this.onPaymentChannelChanged,
    this.banks = const [],
    this.selectedBank,
    this.onBankSelected,
    required this.cost,
    required this.senderLocation,
    required this.receiverLocation,
    required this.selectedService,
    required this.weightGramText,
    required this.useInsurance,
  });

  Widget _buildPaymentMethodCard({
    required String label,
    required IconData icon,
    required String method,
  }) {
    final isSelected = paymentMethod == method;
    return GestureDetector(
      onTap: () => onPaymentMethodChanged(method),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankCard(BankAccount bank) {
    final isSelected =
        selectedBank?.id == bank.id ||
        (selectedBank == null && paymentChannel == bank.bankName);
    return InkWell(
      onTap: () {
        onBankSelected?.call(bank);
        onPaymentChannelChanged(bank.bankName);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : (isDark ? const Color(0xFF1B2A3D) : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white12 : Colors.grey.shade200),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_rounded,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Bank ${bank.bankName}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          bank.nomorRekening,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'a.n. ${bank.namaPemilik}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.primary : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelChip(String label, String channelCode) {
    final isSelected = paymentChannel == channelCode;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      onSelected: (val) {
        if (val) onPaymentChannelChanged(channelCode);
      },
    );
  }

  Widget _buildSummaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billedKg = (cost['chargeableKg'] ?? 1.0).ceil();
    final goodsVal = cost['goodsValue'] ?? 0.0;
    final shippingFee = cost['shippingFee'] ?? 0.0;
    final insuranceFee = cost['insuranceFee'] ?? 0.0;
    final additionalFee = cost['additionalFee'] ?? 0.0;
    final total = cost['total'] ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // METODE PEMBAYARAN CARD
        ShipmentFormCard(
          title: 'Metode Pembayaran',
          subtitle: 'Pilih transfer gateway atau bayar di tempat (COD)',
          icon: Icons.payment_rounded,
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildPaymentMethodCard(
                      label: 'Transfer Gateway',
                      icon: Icons.account_balance_wallet_outlined,
                      method: 'TRANSFER',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPaymentMethodCard(
                      label: 'Cash on Delivery',
                      icon: Icons.payments_outlined,
                      method: 'COD',
                    ),
                  ),
                ],
              ),
              if (paymentMethod == 'TRANSFER') ...[
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(
                      Icons.account_balance_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Pilih Rekening Bank Transfer:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (banks.isNotEmpty) ...[
                  ...banks.map(_buildBankCard),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Atau bayar via QRIS:',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildChannelChip('QRIS Instan', 'QRIS'),
                    ],
                  ),
                ] else ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChannelChip('BCA Virtual Account', 'BCA'),
                      _buildChannelChip('Mandiri VA', 'Mandiri'),
                      _buildChannelChip('BRI VA', 'BRI'),
                      _buildChannelChip('BNI VA', 'BNI'),
                      _buildChannelChip('QRIS Instan', 'QRIS'),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),

        // RINGKASAN RINCIAN BIAYA CARD
        ShipmentFormCard(
          title: 'Ringkasan Rincian Biaya Pengiriman',
          subtitle: 'Rincian ongkos kirim dan total yang harus dibayar',
          icon: Icons.receipt_long_rounded,
          isDark: isDark,
          child: Column(
            children: [
              _buildSummaryLine('Asal', senderLocation),
              _buildSummaryLine('Tujuan', receiverLocation),
              _buildSummaryLine('Layanan', selectedService?.name ?? 'Reguler'),
              _buildSummaryLine(
                'Nilai / Harga Asli Barang',
                formatRupiah(goodsVal),
              ),
              _buildSummaryLine(
                'Berat Ditagih',
                '$billedKg kg ($weightGramText gr)',
              ),
              const Divider(height: 20),
              _buildSummaryLine('Biaya Pengiriman', formatRupiah(shippingFee)),
              if (useInsurance && insuranceFee > 0)
                _buildSummaryLine(
                  'Asuransi Barang (${selectedService?.insuranceRatePercentLabel ?? '0.2%'})',
                  formatRupiah(insuranceFee),
                ),
              if (!useInsurance)
                _buildSummaryLine(
                  'Proteksi Asuransi',
                  'Tidak Digunakan (Rp 0)',
                ),
              _buildSummaryLine(
                'Biaya Layanan Tambahan',
                formatRupiah(additionalFee),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    formatRupiah(total),
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
        ),
      ],
    );
  }
}
