/// Status operasional pelacakan lokasi kurir
enum TrackingGpsStatus {
  /// Pelacakan belum dimulai atau sedang siap
  idle,

  /// Pelacakan GPS aktif dan mengirim pembaruan berkala ke Supabase
  active,

  /// Pelacakan dijeda secara manual oleh kurir
  paused,

  /// Sedang meminta sinyal atau koordinat GPS terkini
  acquiring,

  /// Layanan lokasi / GPS pada perangkat dimatikan
  gpsDisabled,

  /// Izin lokasi perangkat belum diberikan atau ditolak
  permissionDenied,

  /// Izin lokasi ditolak permanen (perlu dibuka via pengaturan aplikasi)
  permissionDeniedForever,

  /// Kurir tidak memiliki tugas penjemputan/pengantaran aktif saat ini
  noActiveTask,

  /// Koneksi internet terputus
  offline,

  /// Terjadi kesalahan internal
  error,
}

extension TrackingGpsStatusX on TrackingGpsStatus {
  /// Label ramah pengguna berbahasa Indonesia
  String get label {
    switch (this) {
      case TrackingGpsStatus.active:
        return 'Pelacakan Aktif';
      case TrackingGpsStatus.paused:
        return 'Pelacakan Dijeda';
      case TrackingGpsStatus.acquiring:
        return 'Mencari Sinyal GPS...';
      case TrackingGpsStatus.gpsDisabled:
        return 'GPS Perangkat Nonaktif';
      case TrackingGpsStatus.permissionDenied:
      case TrackingGpsStatus.permissionDeniedForever:
        return 'Izin Lokasi Diperlukan';
      case TrackingGpsStatus.noActiveTask:
        return 'Tidak Ada Tugas Aktif';
      case TrackingGpsStatus.offline:
        return 'Koneksi Terputus';
      case TrackingGpsStatus.error:
        return 'Gangguan Pelacakan';
      case TrackingGpsStatus.idle:
        return 'Siap Melacak';
    }
  }

  /// True jika pelacakan sedang berjalan
  bool get isTracking => this == TrackingGpsStatus.active;
}
