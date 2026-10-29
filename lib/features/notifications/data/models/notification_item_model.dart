import '../../../../app/constants/database_constants.dart';
import '../../domain/entities/notification_item.dart';

class NotificationItemModel extends NotificationItem {
  const NotificationItemModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.message,
    required super.type,
    super.isRead = false,
    required super.createdAt,
    super.readAt,
    super.shipmentId,
    super.paymentId,
    super.metadata,
  });

  factory NotificationItemModel.fromDatabase(Map<String, dynamic> row) {
    final id = row[NotificationTableColumns.id]?.toString() ?? '';
    final userId = row[NotificationTableColumns.userId]?.toString() ??
        row[NotificationTableColumns.employeeId]?.toString() ??
        '';
    final title = row[NotificationTableColumns.judul] as String? ??
        row['title'] as String? ??
        '';
    final message = row[NotificationTableColumns.pesan] as String? ??
        row['message'] as String? ??
        '';
    final typeStr = row[NotificationTableColumns.tipe] as String? ??
        row['type'] as String?;
    final isReadVal = row[NotificationTableColumns.isRead];
    final isRead = isReadVal == true || isReadVal == 1;

    final createdAtStr = row[NotificationTableColumns.createdAt]?.toString();
    final createdAt = createdAtStr != null
        ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
        : DateTime.now();

    final readAtStr = row[NotificationTableColumns.readAt]?.toString();
    final readAt = readAtStr != null ? DateTime.tryParse(readAtStr) : null;

    final shipmentId =
        row[NotificationTableColumns.shipmentId]?.toString();
    final paymentId =
        row[NotificationTableColumns.paymentId]?.toString();

    Map<String, dynamic>? metadata;
    final rawData = row[NotificationTableColumns.data];
    if (rawData is Map<String, dynamic>) {
      metadata = rawData;
    }

    return NotificationItemModel(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: NotificationType.fromString(typeStr),
      isRead: isRead || readAt != null,
      createdAt: createdAt,
      readAt: readAt,
      shipmentId: shipmentId,
      paymentId: paymentId,
      metadata: metadata,
    );
  }

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: NotificationType.fromString(json['type'] as String?),
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
      shipmentId: json['shipmentId'] as String?,
      paymentId: json['paymentId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  factory NotificationItemModel.fromEntity(NotificationItem entity) {
    return NotificationItemModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      message: entity.message,
      type: entity.type,
      isRead: entity.isRead,
      createdAt: entity.createdAt,
      readAt: entity.readAt,
      shipmentId: entity.shipmentId,
      paymentId: entity.paymentId,
      metadata: entity.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.name,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'shipmentId': shipmentId,
      'paymentId': paymentId,
      'metadata': metadata,
    };
  }

  @override
  NotificationItemModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? shipmentId,
    String? paymentId,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      shipmentId: shipmentId ?? this.shipmentId,
      paymentId: paymentId ?? this.paymentId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toDatabase({bool isCourier = false}) {
    final int? numId = int.tryParse(id);
    final int? numUserId = int.tryParse(userId);
    final int? numShipmentId =
        shipmentId != null ? int.tryParse(shipmentId!) : null;

    // Nilai valid check constraint tipe pada PostgreSQL: STATUS, PAYMENT, INFO, WARNING, ASSIGNMENT
    String dbType;
    switch (type) {
      case NotificationType.shipment:
        dbType = 'STATUS';
        break;
      case NotificationType.payment:
        dbType = 'PAYMENT';
        break;
      case NotificationType.taskAssignment:
        dbType = 'ASSIGNMENT';
        break;
      case NotificationType.urgentTask:
        dbType = 'WARNING';
        break;
      case NotificationType.system:
      case NotificationType.account:
      case NotificationType.promo:
        dbType = 'INFO';
        break;
    }

    final map = <String, dynamic>{
      NotificationTableColumns.judul: title,
      NotificationTableColumns.pesan: message,
      NotificationTableColumns.tipe: dbType,
      NotificationTableColumns.isRead: isRead,
      if (readAt != null)
        NotificationTableColumns.readAt: readAt!.toIso8601String(),
      NotificationTableColumns.createdAt: createdAt.toIso8601String(),
    };

    if (numId != null) {
      map[NotificationTableColumns.id] = numId;
    }

    if (numUserId != null) {
      if (isCourier) {
        map[NotificationTableColumns.employeeId] = numUserId;
      } else {
        map[NotificationTableColumns.userId] = numUserId;
      }
    }

    if (numShipmentId != null) {
      map[NotificationTableColumns.shipmentId] = numShipmentId;
    }

    return map;
  }
}
