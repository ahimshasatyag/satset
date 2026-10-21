import '../../domain/entities/shipment.dart';

class ShipmentPaymentModel extends ShipmentPayment {
  const ShipmentPaymentModel({
    required super.id,
    required super.shipmentId,
    required super.paymentNumber,
    required super.paymentMethod,
    required super.amount,
    required super.status,
    super.provider,
    super.providerReference,
    super.receiptPath,
    super.paidAt,
    super.expiredAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ShipmentPaymentModel.fromDatabase(Map<String, dynamic> map) {
    return ShipmentPaymentModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      shipmentId: (map['shipment_id'] as num?)?.toInt() ?? 0,
      paymentNumber: map['nomor_pembayaran']?.toString() ?? '',
      paymentMethod: map['metode_pembayaran']?.toString() ?? 'TRANSFER',
      amount: (map['jumlah_bayar'] as num?)?.toDouble() ?? 0.0,
      status: OrderPaymentStatus.fromString(map['status_pembayaran']?.toString()),
      provider: map['provider']?.toString(),
      providerReference: map['provider_reference']?.toString(),
      receiptPath: map['bukti_pembayaran_path']?.toString(),
      paidAt: map['paid_at'] != null
          ? DateTime.tryParse(map['paid_at'].toString())
          : null,
      expiredAt: map['expired_at'] != null
          ? DateTime.tryParse(map['expired_at'].toString())
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipment_id': shipmentId,
      'nomor_pembayaran': paymentNumber,
      'metode_pembayaran': paymentMethod,
      'jumlah_bayar': amount,
      'status_pembayaran': status.name,
      'provider': provider,
      'provider_reference': providerReference,
      'bukti_pembayaran_path': receiptPath,
      'paid_at': paidAt?.toIso8601String(),
      'expired_at': expiredAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ServiceTypeModel extends OrderServiceType {
  const ServiceTypeModel({
    required super.id,
    required super.code,
    required super.name,
    required super.minDays,
    required super.maxDays,
    super.description,
    super.basePrice,
  });

  factory ServiceTypeModel.fromDatabase(Map<String, dynamic> map) {
    final id = (map['id'] as num?)?.toInt() ?? 1;
    final code = map['kode']?.toString() ?? 'REG';
    final name = map['nama_layanan']?.toString() ?? 'Reguler';
    final minDays = (map['estimasi_hari_min'] as num?)?.toInt() ?? 1;
    final maxDays = (map['estimasi_hari_max'] as num?)?.toInt() ?? 3;
    final desc = map['deskripsi']?.toString();

    double base = 15000;
    if (code == 'EXP') base = 25000;
    if (code == 'SAMEDAY') base = 20000;
    if (code == 'INST') base = 30000;

    return ServiceTypeModel(
      id: id,
      code: code,
      name: name,
      minDays: minDays,
      maxDays: maxDays,
      description: desc,
      basePrice: base,
    );
  }
}

class ProvinceModel extends Province {
  const ProvinceModel({required super.code, required super.name});

  factory ProvinceModel.fromDatabase(Map<String, dynamic> map) {
    return ProvinceModel(
      code: map['kode_provinsi']?.toString() ?? '',
      name: map['nama_provinsi']?.toString() ?? '',
    );
  }
}

class RegencyModel extends Regency {
  const RegencyModel({
    required super.code,
    required super.provinceCode,
    required super.name,
    required super.type,
  });

  factory RegencyModel.fromDatabase(Map<String, dynamic> map) {
    return RegencyModel(
      code: map['kode_kabkot']?.toString() ?? '',
      provinceCode: map['kode_provinsi']?.toString() ?? '',
      name: map['nama_kabkot']?.toString() ?? '',
      type: map['jenis']?.toString() ?? 'KABUPATEN',
    );
  }
}

class DistrictModel extends District {
  const DistrictModel({
    required super.code,
    required super.regencyCode,
    required super.name,
  });

  factory DistrictModel.fromDatabase(Map<String, dynamic> map) {
    return DistrictModel(
      code: map['kode_kecamatan']?.toString() ?? '',
      regencyCode: map['kode_kabkot']?.toString() ?? '',
      name: map['nama_kecamatan']?.toString() ?? '',
    );
  }
}

class VillageModel extends Village {
  const VillageModel({
    required super.code,
    required super.districtCode,
    required super.name,
    super.postalCode,
  });

  factory VillageModel.fromDatabase(Map<String, dynamic> map) {
    return VillageModel(
      code: map['kode_kelurahan']?.toString() ?? '',
      districtCode: map['kode_kecamatan']?.toString() ?? '',
      name: map['nama_kelurahan']?.toString() ?? '',
      postalCode: map['kodepos']?.toString(),
    );
  }
}

class OrderShipmentModel extends OrderShipment {
  const OrderShipmentModel({
    required super.id,
    required super.trackingNumber,
    super.barcodeValue,
    required super.itemName,
    required super.itemCategory,
    required super.serviceType,
    super.serviceTypeId,
    required super.direction,
    required super.filterStatus,
    super.statusCode,
    required super.senderName,
    super.senderPhone,
    super.senderAddress,
    super.senderPostalCode,
    super.senderLatitude,
    super.senderLongitude,
    required super.receiverName,
    super.receiverPhone,
    super.receiverAddress,
    super.receiverPostalCode,
    super.receiverLatitude,
    super.receiverLongitude,
    required super.originCity,
    required super.destinationCity,
    required super.statusDescription,
    required super.courierName,
    required super.courierPhone,
    required super.courierVehicle,
    required super.etaMinutes,
    required super.distanceKm,
    required super.price,
    super.weightGram,
    super.lengthCm,
    super.widthCm,
    super.heightCm,
    super.totalItems,
    super.goodsValue,
    super.shippingFee,
    super.insuranceFee,
    super.additionalFee,
    super.discount,
    super.totalPrice,
    super.paymentMethod,
    super.notes,
    super.payment,
    required super.createdAt,
    required super.updatedAt,
  });

  factory OrderShipmentModel.fromDatabase(
    Map<String, dynamic> map, {
    int? currentCustomerId,
  }) {
    final shipmentId = map['id']?.toString() ?? '';
    final trackingNo = map['nomor_resi']?.toString() ?? 'SST-$shipmentId';
    final barcodeVal = map['barcode_value']?.toString() ?? trackingNo;

    final serviceMap = map['m_service_types'] as Map<String, dynamic>?;
    final serviceTypeId = (map['service_type_id'] as num?)?.toInt() ?? 1;
    final serviceName = serviceMap?['nama_layanan']?.toString() ?? 'Reguler';

    final statusMap = map['m_shipment_statuses'] as Map<String, dynamic>?;
    final statusCode = statusMap?['kode']?.toString() ??
        map['status_code']?.toString() ??
        'PENDING';
    final statusDesc = statusMap?['nama_status']?.toString() ??
        _formatStatusName(statusCode);

    final rowCustomerId = (map['customer_id'] as num?)?.toInt();
    final direction = (currentCustomerId != null && rowCustomerId != null)
        ? (rowCustomerId == currentCustomerId
            ? OrderDirection.outgoing
            : OrderDirection.incoming)
        : OrderDirection.outgoing;

    final filterStatus = _resolveFilterStatus(statusCode);

    ShipmentPaymentModel? payment;
    final rawPayments = map['t_shipment_payments'];
    if (rawPayments is List && rawPayments.isNotEmpty) {
      final pMap = rawPayments.first as Map<String, dynamic>;
      payment = ShipmentPaymentModel.fromDatabase(pMap);
    } else if (rawPayments is Map<String, dynamic>) {
      payment = ShipmentPaymentModel.fromDatabase(rawPayments);
    }

    final totalBiaya = (map['total_biaya'] as num?)?.toDouble() ?? 0.0;
    final biayaPengiriman = (map['biaya_pengiriman'] as num?)?.toDouble() ?? totalBiaya;

    final catatan = map['catatan_pengiriman']?.toString() ?? '';
    final itemName = catatan.isNotEmpty ? catatan : 'Paket SatSet #$shipmentId';

    return OrderShipmentModel(
      id: shipmentId,
      trackingNumber: trackingNo,
      barcodeValue: barcodeVal,
      itemName: itemName,
      itemCategory: 'Paket Reguler',
      serviceType: serviceName,
      serviceTypeId: serviceTypeId,
      direction: direction,
      filterStatus: filterStatus,
      statusCode: statusCode,
      senderName: map['pengirim_nama']?.toString() ?? 'Pengirim',
      senderPhone: map['pengirim_no_hp']?.toString() ?? '',
      senderAddress: map['pengirim_alamat']?.toString() ?? '',
      senderPostalCode: map['pengirim_kode_pos']?.toString() ?? '',
      senderLatitude: (map['pengirim_latitude'] as num?)?.toDouble(),
      senderLongitude: (map['pengirim_longitude'] as num?)?.toDouble(),
      receiverName: map['penerima_nama']?.toString() ?? 'Penerima',
      receiverPhone: map['penerima_no_hp']?.toString() ?? '',
      receiverAddress: map['penerima_alamat']?.toString() ?? '',
      receiverPostalCode: map['penerima_kode_pos']?.toString() ?? '',
      receiverLatitude: (map['penerima_latitude'] as num?)?.toDouble(),
      receiverLongitude: (map['penerima_longitude'] as num?)?.toDouble(),
      originCity: map['pengirim_kota']?.toString() ?? 'Jakarta',
      destinationCity: map['penerima_kota']?.toString() ?? 'Jakarta',
      statusDescription: statusDesc,
      courierName: 'Kurir SatSet',
      courierPhone: '-',
      courierVehicle: 'SatSet Fleet',
      etaMinutes: 30,
      distanceKm: 5.0,
      price: totalBiaya.toInt(),
      weightGram: (map['total_berat_gram'] as num?)?.toInt() ?? 1000,
      lengthCm: (map['panjang_cm'] as num?)?.toInt() ?? 10,
      widthCm: (map['lebar_cm'] as num?)?.toInt() ?? 10,
      heightCm: (map['tinggi_cm'] as num?)?.toInt() ?? 10,
      totalItems: (map['total_barang'] as num?)?.toInt() ?? 1,
      goodsValue: (map['nilai_barang'] as num?)?.toDouble() ?? 0,
      shippingFee: biayaPengiriman,
      insuranceFee: (map['biaya_asuransi'] as num?)?.toDouble() ?? 0,
      additionalFee: (map['biaya_layanan_tambahan'] as num?)?.toDouble() ?? 0,
      discount: (map['diskon'] as num?)?.toDouble() ?? 0,
      totalPrice: totalBiaya,
      paymentMethod: map['metode_pembayaran']?.toString() ?? 'TRANSFER',
      notes: catatan,
      payment: payment,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory OrderShipmentModel.fromJson(Map<String, dynamic> json) {
    final dir = (json['direction'] as String? ?? 'outgoing') == 'incoming'
        ? OrderDirection.incoming
        : OrderDirection.outgoing;

    OrderFilterStatus status;
    switch ((json['filterStatus'] as String? ?? '').toLowerCase()) {
      case 'waitingpickup':
      case 'waiting_pickup':
        status = OrderFilterStatus.waitingPickup;
        break;
      case 'indelivery':
      case 'in_delivery':
        status = OrderFilterStatus.inDelivery;
        break;
      case 'completed':
        status = OrderFilterStatus.completed;
        break;
      default:
        status = OrderFilterStatus.all;
    }

    return OrderShipmentModel(
      id: json['id'] as String? ?? '',
      trackingNumber: json['trackingNumber'] as String? ?? '',
      barcodeValue: json['barcodeValue'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      itemCategory: json['itemCategory'] as String? ?? '',
      serviceType: json['serviceType'] as String? ?? 'SATSET Reguler',
      serviceTypeId: json['serviceTypeId'] as int? ?? 1,
      direction: dir,
      filterStatus: status,
      statusCode: json['statusCode'] as String? ?? 'PENDING',
      senderName: json['senderName'] as String? ?? '',
      senderPhone: json['senderPhone'] as String? ?? '',
      senderAddress: json['senderAddress'] as String? ?? '',
      senderPostalCode: json['senderPostalCode'] as String? ?? '',
      receiverName: json['receiverName'] as String? ?? '',
      receiverPhone: json['receiverPhone'] as String? ?? '',
      receiverAddress: json['receiverAddress'] as String? ?? '',
      receiverPostalCode: json['receiverPostalCode'] as String? ?? '',
      originCity: json['originCity'] as String? ?? '',
      destinationCity: json['destinationCity'] as String? ?? '',
      statusDescription: json['statusDescription'] as String? ?? '',
      courierName: json['courierName'] as String? ?? '',
      courierPhone: json['courierPhone'] as String? ?? '',
      courierVehicle: json['courierVehicle'] as String? ?? '',
      etaMinutes: json['etaMinutes'] as int? ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      price: json['price'] as int? ?? 15000,
      weightGram: json['weightGram'] as int? ?? 1000,
      totalItems: json['totalItems'] as int? ?? 1,
      goodsValue: (json['goodsValue'] as num?)?.toDouble() ?? 0,
      shippingFee: (json['shippingFee'] as num?)?.toDouble() ?? 15000,
      insuranceFee: (json['insuranceFee'] as num?)?.toDouble() ?? 0,
      additionalFee: (json['additionalFee'] as num?)?.toDouble() ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 15000,
      paymentMethod: json['paymentMethod'] as String? ?? 'TRANSFER',
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory OrderShipmentModel.fromEntity(OrderShipment entity) {
    return OrderShipmentModel(
      id: entity.id,
      trackingNumber: entity.trackingNumber,
      barcodeValue: entity.barcodeValue,
      itemName: entity.itemName,
      itemCategory: entity.itemCategory,
      serviceType: entity.serviceType,
      serviceTypeId: entity.serviceTypeId,
      direction: entity.direction,
      filterStatus: entity.filterStatus,
      statusCode: entity.statusCode,
      senderName: entity.senderName,
      senderPhone: entity.senderPhone,
      senderAddress: entity.senderAddress,
      senderPostalCode: entity.senderPostalCode,
      senderLatitude: entity.senderLatitude,
      senderLongitude: entity.senderLongitude,
      receiverName: entity.receiverName,
      receiverPhone: entity.receiverPhone,
      receiverAddress: entity.receiverAddress,
      receiverPostalCode: entity.receiverPostalCode,
      receiverLatitude: entity.receiverLatitude,
      receiverLongitude: entity.receiverLongitude,
      originCity: entity.originCity,
      destinationCity: entity.destinationCity,
      statusDescription: entity.statusDescription,
      courierName: entity.courierName,
      courierPhone: entity.courierPhone,
      courierVehicle: entity.courierVehicle,
      etaMinutes: entity.etaMinutes,
      distanceKm: entity.distanceKm,
      price: entity.price,
      weightGram: entity.weightGram,
      lengthCm: entity.lengthCm,
      widthCm: entity.widthCm,
      heightCm: entity.heightCm,
      totalItems: entity.totalItems,
      goodsValue: entity.goodsValue,
      shippingFee: entity.shippingFee,
      insuranceFee: entity.insuranceFee,
      additionalFee: entity.additionalFee,
      discount: entity.discount,
      totalPrice: entity.totalPrice,
      paymentMethod: entity.paymentMethod,
      notes: entity.notes,
      payment: entity.payment,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackingNumber': trackingNumber,
      'barcodeValue': barcodeValue,
      'itemName': itemName,
      'itemCategory': itemCategory,
      'serviceType': serviceType,
      'serviceTypeId': serviceTypeId,
      'direction': direction.name,
      'filterStatus': filterStatus.name,
      'statusCode': statusCode,
      'senderName': senderName,
      'senderPhone': senderPhone,
      'senderAddress': senderAddress,
      'senderPostalCode': senderPostalCode,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'receiverAddress': receiverAddress,
      'receiverPostalCode': receiverPostalCode,
      'originCity': originCity,
      'destinationCity': destinationCity,
      'statusDescription': statusDescription,
      'courierName': courierName,
      'courierPhone': courierPhone,
      'courierVehicle': courierVehicle,
      'etaMinutes': etaMinutes,
      'distanceKm': distanceKm,
      'price': price,
      'weightGram': weightGram,
      'totalItems': totalItems,
      'goodsValue': goodsValue,
      'shippingFee': shippingFee,
      'insuranceFee': insuranceFee,
      'additionalFee': additionalFee,
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static OrderFilterStatus _resolveFilterStatus(String code) {
    switch (code.toUpperCase()) {
      case 'PENDING':
      case 'CONFIRMED':
      case 'PICKUP_SCHEDULED':
        return OrderFilterStatus.waitingPickup;
      case 'PICKED_UP':
      case 'IN_TRANSIT':
      case 'OUT_FOR_DELIVERY':
        return OrderFilterStatus.inDelivery;
      case 'DELIVERED':
      case 'COMPLETED':
      case 'RETURNED':
      case 'CANCELLED':
        return OrderFilterStatus.completed;
      default:
        return OrderFilterStatus.all;
    }
  }

  static String _formatStatusName(String code) {
    switch (code.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu Konfirmasi & Pembayaran';
      case 'CONFIRMED':
        return 'Pesanan Dikonfirmasi';
      case 'PICKUP_SCHEDULED':
        return 'Menunggu Penjemputan Kurir';
      case 'PICKED_UP':
        return 'Paket Telah Dijemput Kurir';
      case 'IN_TRANSIT':
        return 'Sedang Dalam Perjalanan';
      case 'OUT_FOR_DELIVERY':
        return 'Sedang Diantar Menuju Penerima';
      case 'DELIVERED':
        return 'Pesanan Telah Diterima';
      case 'CANCELLED':
        return 'Pesanan Dibatalkan';
      default:
        return code;
    }
  }
}

typedef ShipmentModel = OrderShipmentModel;
