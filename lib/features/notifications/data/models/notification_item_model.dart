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
    final userId = row[NotificationTableColumns.userId]?.toString() ?? '';
    final title = row[NotificationTableColumns.title] as String? ?? '';
    final message = row[NotificationTableColumns.message] as String? ?? '';
    final typeStr = row[NotificationTableColumns.type] as String?;
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

  Map<String, dynamic> toDatabase() {
    return {
      NotificationTableColumns.id: id,
      NotificationTableColumns.userId: userId,
      NotificationTableColumns.title: title,
      NotificationTableColumns.message: message,
      NotificationTableColumns.type: type.name,
      NotificationTableColumns.isRead: isRead,
      NotificationTableColumns.readAt: readAt?.toIso8601String(),
      NotificationTableColumns.shipmentId: shipmentId,
      NotificationTableColumns.paymentId: paymentId,
      NotificationTableColumns.data: metadata,
      NotificationTableColumns.createdAt: createdAt.toIso8601String(),
    };
  }
}
