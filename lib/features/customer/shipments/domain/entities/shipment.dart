import 'package:equatable/equatable.dart';

/// Arah paket: Kiriman Saya (dikirim keluar) vs Paket Masuk (menuju ke pengguna)
enum OrderDirection {
  outgoing('Kiriman Saya'),
  incoming('Paket Masuk');

  final String label;
  const OrderDirection(this.label);
}

/// Status filter pesanan pengiriman
enum OrderFilterStatus {
  all('Semua'),
  waitingPickup('Menunggu Penjemputan'),
  inDelivery('Sedang Diantar Kurir'),
  completed('Pesanan Selesai');

  final String label;
  const OrderFilterStatus(this.label);
}

/// Status transaksi pembayaran
enum OrderPaymentStatus {
  pending('Menunggu Pembayaran'),
  paid('Pembayaran Berhasil'),
  settled('Lunas'),
  failed('Pembayaran Gagal'),
  expired('Kedaluwarsa'),
  cancelled('Dibatalkan');

  final String label;
  const OrderPaymentStatus(this.label);

  static OrderPaymentStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'PAID':
        return OrderPaymentStatus.paid;
      case 'SETTLED':
        return OrderPaymentStatus.settled;
      case 'FAILED':
        return OrderPaymentStatus.failed;
      case 'EXPIRED':
        return OrderPaymentStatus.expired;
      case 'CANCELLED':
      case 'CANCELED':
        return OrderPaymentStatus.cancelled;
      case 'PENDING':
      default:
        return OrderPaymentStatus.pending;
    }
  }

  bool get isSuccessful =>
      this == OrderPaymentStatus.paid || this == OrderPaymentStatus.settled;
}

/// Entity Master Jenis Bank (m_jenis_bank)
class JenisBank extends Equatable {
  final String id;
  final String namaJenis;
  final DateTime? createdAt;

  const JenisBank({
    required this.id,
    required this.namaJenis,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, namaJenis, createdAt];
}

/// Entity Master Bank Rekening (m_bank)
class BankAccount extends Equatable {
  final String id;
  final String namaPemilik; // Kolom: nm_bank (nama pemilik rekening)
  final String nomorRekening; // Kolom: nmr_rekening
  final String jenisBankId; // Kolom: jenis_bank_id
  final JenisBank? jenisBank; // Relasi ke m_jenis_bank
  final DateTime? createdAt;

  const BankAccount({
    required this.id,
    required this.namaPemilik,
    required this.nomorRekening,
    required this.jenisBankId,
    this.jenisBank,
    this.createdAt,
  });

  /// Nama bank (misal: BCA, BRI, Mandiri, BNI)
  String get bankName => jenisBank?.namaJenis ?? 'Bank Transfer';

  /// Label ringkas rekening untuk tampilan
  String get displayLabel => '$bankName - $nomorRekening ($namaPemilik)';

  @override
  List<Object?> get props => [
        id,
        namaPemilik,
        nomorRekening,
        jenisBankId,
        jenisBank,
        createdAt,
      ];
}

typedef Bank = BankAccount;

/// Entity data transaksi pembayaran pengiriman
class ShipmentPayment extends Equatable {
  final int id;
  final int shipmentId;
  final String paymentNumber;
  final String paymentMethod;
  final double amount;
  final OrderPaymentStatus status;
  final String? provider;
  final String? providerReference;
  final String? receiptPath;
  final String? jenisBankId;
  final BankAccount? bankAccount;
  final DateTime? paidAt;
  final DateTime? expiredAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ShipmentPayment({
    required this.id,
    required this.shipmentId,
    required this.paymentNumber,
    required this.paymentMethod,
    required this.amount,
    required this.status,
    this.provider,
    this.providerReference,
    this.receiptPath,
    this.jenisBankId,
    this.bankAccount,
    this.paidAt,
    this.expiredAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPaid => status.isSuccessful;

  @override
  List<Object?> get props => [
        id,
        shipmentId,
        paymentNumber,
        paymentMethod,
        amount,
        status,
        provider,
        providerReference,
        jenisBankId,
        bankAccount,
        paidAt,
        expiredAt,
      ];
}

/// Entity data jenis layanan pengiriman
class OrderServiceType extends Equatable {
  final int id;
  final String code;
  final String name;
  final int minDays;
  final int maxDays;
  final String? description;
  final double basePrice;
  final double insuranceRate;

  const OrderServiceType({
    required this.id,
    required this.code,
    required this.name,
    required this.minDays,
    required this.maxDays,
    this.description,
    this.basePrice = 15000,
    this.insuranceRate = 0.002,
  });

  String get estimationLabel {
    if (minDays == 0 && maxDays == 0) return 'Hari ini (6-8 jam)';
    if (minDays == maxDays) return '$minDays Hari';
    return '$minDays - $maxDays Hari';
  }

  String get insuranceRatePercentLabel {
    final pct = insuranceRate * 100;
    return '${pct.toStringAsFixed(pct.truncateToDouble() == pct ? 0 : 1)}%';
  }

  @override
  List<Object?> get props => [id, code, name, minDays, maxDays, basePrice, insuranceRate];
}

typedef ShipmentServiceType = OrderServiceType;

/// Entity Wilayah Provinsi
class Province extends Equatable {
  final String code;
  final String name;

  const Province({required this.code, required this.name});

  @override
  List<Object?> get props => [code, name];
}

/// Entity Wilayah Kabupaten / Kota
class Regency extends Equatable {
  final String code;
  final String provinceCode;
  final String name;
  final String type;

  const Regency({
    required this.code,
    required this.provinceCode,
    required this.name,
    required this.type,
  });

  @override
  List<Object?> get props => [code, provinceCode, name, type];
}

/// Entity Wilayah Kecamatan
class District extends Equatable {
  final String code;
  final String regencyCode;
  final String name;

  const District({
    required this.code,
    required this.regencyCode,
    required this.name,
  });

  @override
  List<Object?> get props => [code, regencyCode, name];
}

/// Entity Wilayah Kelurahan / Desa
class Village extends Equatable {
  final String code;
  final String districtCode;
  final String name;
  final String? postalCode;

  const Village({
    required this.code,
    required this.districtCode,
    required this.name,
    this.postalCode,
  });

  @override
  List<Object?> get props => [code, districtCode, name, postalCode];
}

/// Entity data pengiriman (Shipment / OrderShipment)
class OrderShipment extends Equatable {
  final String id;
  final String trackingNumber;
  final String barcodeValue;
  final String itemName;
  final String itemCategory;
  final String serviceType;
  final int serviceTypeId;
  final OrderDirection direction;
  final OrderFilterStatus filterStatus;
  final String statusCode;
  final String senderName;
  final String senderPhone;
  final String senderAddress;
  final String senderPostalCode;
  final double? senderLatitude;
  final double? senderLongitude;
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress;
  final String receiverPostalCode;
  final double? receiverLatitude;
  final double? receiverLongitude;
  final String originCity;
  final String destinationCity;
  final String statusDescription;
  final String courierName;
  final String courierPhone;
  final String courierVehicle;
  final int etaMinutes;
  final double distanceKm;
  final int price;
  final int weightGram;
  final int lengthCm;
  final int widthCm;
  final int heightCm;
  final int totalItems;
  final double goodsValue;
  final double shippingFee;
  final double insuranceFee;
  final double additionalFee;
  final double discount;
  final double totalPrice;
  final String paymentMethod;
  final String notes;
  final ShipmentPayment? payment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderShipment({
    required this.id,
    required this.trackingNumber,
    this.barcodeValue = '',
    required this.itemName,
    required this.itemCategory,
    required this.serviceType,
    this.serviceTypeId = 1,
    required this.direction,
    required this.filterStatus,
    this.statusCode = 'PENDING',
    required this.senderName,
    this.senderPhone = '',
    this.senderAddress = '',
    this.senderPostalCode = '',
    this.senderLatitude,
    this.senderLongitude,
    required this.receiverName,
    this.receiverPhone = '',
    this.receiverAddress = '',
    this.receiverPostalCode = '',
    this.receiverLatitude,
    this.receiverLongitude,
    required this.originCity,
    required this.destinationCity,
    required this.statusDescription,
    required this.courierName,
    required this.courierPhone,
    required this.courierVehicle,
    required this.etaMinutes,
    required this.distanceKm,
    required this.price,
    this.weightGram = 1000,
    this.lengthCm = 10,
    this.widthCm = 10,
    this.heightCm = 10,
    this.totalItems = 1,
    this.goodsValue = 0,
    this.shippingFee = 0,
    this.insuranceFee = 0,
    this.additionalFee = 0,
    this.discount = 0,
    this.totalPrice = 0,
    this.paymentMethod = 'TRANSFER',
    this.notes = '',
    this.payment,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive =>
      filterStatus == OrderFilterStatus.waitingPickup ||
      filterStatus == OrderFilterStatus.inDelivery;

  bool get isPaymentPending =>
      paymentMethod == 'TRANSFER' &&
      (payment == null || payment!.status == OrderPaymentStatus.pending);

  OrderShipment copyWith({
    String? id,
    String? trackingNumber,
    String? barcodeValue,
    String? itemName,
    String? itemCategory,
    String? serviceType,
    int? serviceTypeId,
    OrderDirection? direction,
    OrderFilterStatus? filterStatus,
    String? statusCode,
    String? senderName,
    String? senderPhone,
    String? senderAddress,
    String? senderPostalCode,
    double? senderLatitude,
    double? senderLongitude,
    String? receiverName,
    String? receiverPhone,
    String? receiverAddress,
    String? receiverPostalCode,
    double? receiverLatitude,
    double? receiverLongitude,
    String? originCity,
    String? destinationCity,
    String? statusDescription,
    String? courierName,
    String? courierPhone,
    String? courierVehicle,
    int? etaMinutes,
    double? distanceKm,
    int? price,
    int weightGram = 1000,
    int lengthCm = 10,
    int widthCm = 10,
    int heightCm = 10,
    int totalItems = 1,
    double goodsValue = 0,
    double shippingFee = 0,
    double insuranceFee = 0,
    double additionalFee = 0,
    double discount = 0,
    double totalPrice = 0,
    String? paymentMethod,
    String? notes,
    ShipmentPayment? payment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderShipment(
      id: id ?? this.id,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      barcodeValue: barcodeValue ?? this.barcodeValue,
      itemName: itemName ?? this.itemName,
      itemCategory: itemCategory ?? this.itemCategory,
      serviceType: serviceType ?? this.serviceType,
      serviceTypeId: serviceTypeId ?? this.serviceTypeId,
      direction: direction ?? this.direction,
      filterStatus: filterStatus ?? this.filterStatus,
      statusCode: statusCode ?? this.statusCode,
      senderName: senderName ?? this.senderName,
      senderPhone: senderPhone ?? this.senderPhone,
      senderAddress: senderAddress ?? this.senderAddress,
      senderPostalCode: senderPostalCode ?? this.senderPostalCode,
      senderLatitude: senderLatitude ?? this.senderLatitude,
      senderLongitude: senderLongitude ?? this.senderLongitude,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      receiverAddress: receiverAddress ?? this.receiverAddress,
      receiverPostalCode: receiverPostalCode ?? this.receiverPostalCode,
      receiverLatitude: receiverLatitude ?? this.receiverLatitude,
      receiverLongitude: receiverLongitude ?? this.receiverLongitude,
      originCity: originCity ?? this.originCity,
      destinationCity: destinationCity ?? this.destinationCity,
      statusDescription: statusDescription ?? this.statusDescription,
      courierName: courierName ?? this.courierName,
      courierPhone: courierPhone ?? this.courierPhone,
      courierVehicle: courierVehicle ?? this.courierVehicle,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
      price: price ?? this.price,
      weightGram: weightGram,
      lengthCm: lengthCm,
      widthCm: widthCm,
      heightCm: heightCm,
      totalItems: totalItems,
      goodsValue: goodsValue,
      shippingFee: shippingFee,
      insuranceFee: insuranceFee,
      additionalFee: additionalFee,
      discount: discount,
      totalPrice: totalPrice,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      payment: payment ?? this.payment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        trackingNumber,
        barcodeValue,
        itemName,
        direction,
        filterStatus,
        statusCode,
        senderName,
        receiverName,
        courierName,
        courierVehicle,
        etaMinutes,
        price,
        totalPrice,
        paymentMethod,
        payment,
        updatedAt,
      ];
}

typedef Shipment = OrderShipment;
