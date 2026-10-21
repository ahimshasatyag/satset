import 'package:equatable/equatable.dart';
import '../../domain/entities/live_track_shipment.dart';

abstract class LiveTrackEvent extends Equatable {
  const LiveTrackEvent();

  @override
  List<Object?> get props => [];
}

/// Inisialisasi awal stream pelacakan live dengan filter direction dan resi opsional
class LiveTrackStarted extends LiveTrackEvent {
  final OrderDirection? initialDirection;
  final String? initialResi;

  const LiveTrackStarted({
    this.initialDirection,
    this.initialResi,
  });

  @override
  List<Object?> get props => [initialDirection, initialResi];
}

/// Pengguna berpindah tab atas: Kiriman Saya vs Paket Masuk
class LiveTrackDirectionChanged extends LiveTrackEvent {
  final OrderDirection direction;

  const LiveTrackDirectionChanged(this.direction);

  @override
  List<Object?> get props => [direction];
}

/// Pengguna memilih filter status chip (Semua, Menunggu Pickup, Sedang Diantar, Selesai)
class LiveTrackFilterChanged extends LiveTrackEvent {
  final OrderFilterStatus filterStatus;

  const LiveTrackFilterChanged(this.filterStatus);

  @override
  List<Object?> get props => [filterStatus];
}

/// Pembaruan data pengiriman live yang diterima dari Supabase Realtime stream
class LiveTrackOrdersReceived extends LiveTrackEvent {
  final List<LiveTrackShipment> shipments;

  const LiveTrackOrdersReceived(this.shipments);

  @override
  List<Object?> get props => [shipments];
}

/// Pengguna memilih pin kurir tertentu di peta atau kartu carousel
class LiveTrackOrderSelected extends LiveTrackEvent {
  final int selectedIndex;

  const LiveTrackOrderSelected(this.selectedIndex);

  @override
  List<Object?> get props => [selectedIndex];
}

/// Pengguna memilih pesanan spesifik berdasarkan nomor resi
class LiveTrackOrderSelectedByResi extends LiveTrackEvent {
  final String trackingNumber;

  const LiveTrackOrderSelectedByResi(this.trackingNumber);

  @override
  List<Object?> get props => [trackingNumber];
}

/// Pengguna mengetik atau melakukan pencarian nomor resi di search bar
class LiveTrackSearchQueryChanged extends LiveTrackEvent {
  final String query;

  const LiveTrackSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// Pengguna memperbesar/memperkecil peta
class LiveTrackZoomChanged extends LiveTrackEvent {
  final double zoomScale;

  const LiveTrackZoomChanged(this.zoomScale);

  @override
  List<Object?> get props => [zoomScale];
}

/// Pengguna menekan tombol pusatkan peta / titik fokus ke kurir atau tujuan
class LiveTrackResetCenter extends LiveTrackEvent {
  const LiveTrackResetCenter();
}

/// Pengguna memicu pemuatan ulang manual (pull to refresh atau tombol refresh)
class LiveTrackRefreshed extends LiveTrackEvent {
  const LiveTrackRefreshed();
}

/// Error saat koneksi atau query Supabase
class LiveTrackErrorOccurred extends LiveTrackEvent {
  final String message;

  const LiveTrackErrorOccurred(this.message);

  @override
  List<Object?> get props => [message];
}
