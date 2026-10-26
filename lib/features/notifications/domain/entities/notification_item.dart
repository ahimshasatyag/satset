import 'package:equatable/equatable.dart';

/// Kategori / Tipe Notifikasi
enum NotificationType {
  shipment,
  payment,
  account,
  promo,
  system,
  taskAssignment,
  urgentTask;

  String get label {
    switch (this) {
      case NotificationType.shipment:
        return 'Pengiriman';
      case NotificationType.payment:
        return 'Pembayaran';
      case NotificationType.account:
        return 'Keamanan Akun';
      case NotificationType.promo:
        return 'Promo & Hadiah';
      case NotificationType.system:
        return 'Informasi Layanan';
      case NotificationType.taskAssignment:
        return 'Penugasan Tugas';
      case NotificationType.urgentTask:
        return 'Tugas Mendesak';
    }
  }

  static NotificationType fromString(String? typeStr) {
    if (typeStr == null) return NotificationType.system;
    final lower = typeStr.trim().toLowerCase();
    switch (lower) {
      case 'assignment':
      case 'task_assignment':
      case 'penugasan':
      case 'tugas_baru':
      case 'task':
        return NotificationType.taskAssignment;
      case 'urgent':
      case 'urgent_task':
      case 'mendesak':
      case 'prioritas':
        return NotificationType.urgentTask;
      case 'shipment':
      case 'pengiriman':
      case 'kurir':
      case 'delivery':
        return NotificationType.shipment;
      case 'payment':
      case 'pembayaran':
      case 'transaksi':
        return NotificationType.payment;
      case 'account':
      case 'profil':
      case 'keamanan':
        return NotificationType.account;
      case 'promo':
      case 'voucher':
      case 'diskon':
        return NotificationType.promo;
      case 'system':
      case 'info':
      default:
        return NotificationType.system;
    }
  }
}

/// Filter tab untuk tampilan daftar notifikasi
enum NotificationFilter {
  all,
  unread,
  shipment,
  payment,
  assignment,
  urgent,
  system;

  String get label {
    switch (this) {
      case NotificationFilter.all:
        return 'Semua';
      case NotificationFilter.unread:
        return 'Belum Dibaca';
      case NotificationFilter.shipment:
        return 'Pengiriman';
      case NotificationFilter.payment:
        return 'Pembayaran';
      case NotificationFilter.assignment:
        return 'Tugas Baru';
      case NotificationFilter.urgent:
        return 'Mendesak';
      case NotificationFilter.system:
        return 'Operasional';
    }
  }
}

/// Entity item notifikasi pelanggan dan kurir
class NotificationItem extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? shipmentId;
  final String? paymentId;
  final Map<String, dynamic>? metadata;

  const NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.shipmentId,
    this.paymentId,
    this.metadata,
  });

  bool get isShipment =>
      type == NotificationType.shipment ||
      type == NotificationType.taskAssignment ||
      type == NotificationType.urgentTask;
  bool get isPayment => type == NotificationType.payment;
  bool get isAssignment => type == NotificationType.taskAssignment;
  bool get isUrgent => type == NotificationType.urgentTask;

  /// Kategori pengelompokan tanggal untuk UI (Hari Ini, Kemarin, Minggu Ini, Terdahulu)
  String get dateCategory {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate =
        DateTime(createdAt.year, createdAt.month, createdAt.day);

    final differenceInDays = today.difference(notificationDate).inDays;

    if (differenceInDays == 0) {
      return 'Hari Ini';
    } else if (differenceInDays == 1) {
      return 'Kemarin';
    } else if (differenceInDays < 7) {
      return 'Minggu Ini';
    } else {
      return 'Terdahulu';
    }
  }

  /// Format waktu relatif ringkas (misal: "10 mnt lalu", "1 jam lalu", "Kemarin 14:30")
  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mnt lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays == 1) {
      final hour = createdAt.hour.toString().padLeft(2, '0');
      final minute = createdAt.minute.toString().padLeft(2, '0');
      return 'Kemarin, $hour:$minute';
    } else {
      final day = createdAt.day.toString().padLeft(2, '0');
      final month = createdAt.month.toString().padLeft(2, '0');
      final hour = createdAt.hour.toString().padLeft(2, '0');
      final minute = createdAt.minute.toString().padLeft(2, '0');
      return '$day/$month, $hour:$minute';
    }
  }

  NotificationItem copyWith({
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
    return NotificationItem(
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

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        message,
        type,
        isRead,
        createdAt,
        readAt,
        shipmentId,
        paymentId,
        metadata,
      ];
}
