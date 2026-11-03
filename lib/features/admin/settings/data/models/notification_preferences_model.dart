import 'dart:convert';
import '../../domain/entities/notification_preferences.dart';

class NotificationPreferencesModel extends NotificationPreferences {
  const NotificationPreferencesModel({
    super.notifyNewShipmentOrders,
    super.notifyShipmentStatusChanges,
    super.notifyCourierAssignments,
    super.notifyPaymentTransactions,
    super.notifyFailedDeliveries,
    super.soundAlertEnabled,
    super.totalExistingNotifications,
    super.unreadNotificationsCount,
    super.backendNote,
  });

  factory NotificationPreferencesModel.fromJsonString(
    String? jsonStr, {
    int totalCount = 0,
    int unreadCount = 0,
  }) {
    if (jsonStr == null || jsonStr.isEmpty) {
      return NotificationPreferencesModel(
        totalExistingNotifications: totalCount,
        unreadNotificationsCount: unreadCount,
      );
    }
    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return NotificationPreferencesModel(
        notifyNewShipmentOrders: map['notify_new_shipment_orders'] != false,
        notifyShipmentStatusChanges:
            map['notify_shipment_status_changes'] != false,
        notifyCourierAssignments: map['notify_courier_assignments'] != false,
        notifyPaymentTransactions:
            map['notify_payment_transactions'] != false,
        notifyFailedDeliveries: map['notify_failed_deliveries'] != false,
        soundAlertEnabled: map['sound_alert_enabled'] == true,
        totalExistingNotifications: totalCount,
        unreadNotificationsCount: unreadCount,
      );
    } catch (_) {
      return NotificationPreferencesModel(
        totalExistingNotifications: totalCount,
        unreadNotificationsCount: unreadCount,
      );
    }
  }

  String toJsonString() {
    return jsonEncode({
      'notify_new_shipment_orders': notifyNewShipmentOrders,
      'notify_shipment_status_changes': notifyShipmentStatusChanges,
      'notify_courier_assignments': notifyCourierAssignments,
      'notify_payment_transactions': notifyPaymentTransactions,
      'notify_failed_deliveries': notifyFailedDeliveries,
      'sound_alert_enabled': soundAlertEnabled,
    });
  }
}

