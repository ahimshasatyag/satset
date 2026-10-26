import 'package:equatable/equatable.dart';
import 'courier_task_history_item.dart';
import 'shipment_proof_history_item.dart';
import 'shipment_tracking_history_item.dart';

/// Detail lengkap riwayat tugas kurir beserta jejak tracking dan bukti pengiriman
class CourierTaskHistoryDetail extends Equatable {
  final CourierTaskHistoryItem task;
  final List<ShipmentTrackingHistoryItem> trackingTimeline;
  final List<ShipmentProofHistoryItem> proofs;

  const CourierTaskHistoryDetail({
    required this.task,
    required this.trackingTimeline,
    required this.proofs,
  });

  @override
  List<Object?> get props => [task, trackingTimeline, proofs];
}
