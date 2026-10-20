import 'package:equatable/equatable.dart';
import '../../domain/entities/live_track_shipment.dart';

abstract class LiveTrackEvent extends Equatable {
  const LiveTrackEvent();

  @override
  List<Object?> get props => [];
}

/// Inisialisasi awal stream pelacakan live
class LiveTrackStarted extends LiveTrackEvent {
  final OrderDirection? initialDirection;

  const LiveTrackStarted({this.initialDirection});

  @override
  List<Object?> get props => [initialDirection];
}

/// Pengguna berpindah tab atas: Kiriman Saya vs Paket Masuk
class LiveTrackDirectionChanged extends LiveTrackEvent {
  final OrderDirection direction;

  const LiveTrackDirectionChanged(this.direction);

  @override
  List<Object?> get props => [direction];
}

/// Pengguna memilih filter status chip (Semua, Menunggu Penjemputan, Sedang Diantar, Selesai)
class LiveTrackFilterChanged extends LiveTrackEvent {
  final OrderFilterStatus filterStatus;

  const LiveTrackFilterChanged(this.filterStatus);

  @override
  List<Object?> get props => [filterStatus];
}

/// Pembaruan paket data posisi live kurir yang diterima dari stream
class LiveTrackOrdersReceived extends LiveTrackEvent {
  final List<LiveTrackShipment> shipments;

  const LiveTrackOrdersReceived(this.shipments);

  @override
  List<Object?> get props => [shipments];
}

/// Pengguna memilih pin kurir tertentu di peta atau kartu
class LiveTrackOrderSelected extends LiveTrackEvent {
  final int selectedIndex;

  const LiveTrackOrderSelected(this.selectedIndex);

  @override
  List<Object?> get props => [selectedIndex];
}

/// Pengguna memperbesar/memperkecil peta
class LiveTrackZoomChanged extends LiveTrackEvent {
  final double zoomScale;

  const LiveTrackZoomChanged(this.zoomScale);

  @override
  List<Object?> get props => [zoomScale];
}

/// Pengguna menekan tombol pusatkan peta / GPS
class LiveTrackResetCenter extends LiveTrackEvent {
  const LiveTrackResetCenter();
}

/// Pengguna memicu pemuatan ulang manual
class LiveTrackRefreshed extends LiveTrackEvent {
  const LiveTrackRefreshed();
}
