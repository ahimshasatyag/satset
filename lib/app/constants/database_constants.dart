/// Konstanta skema basis data PostgreSQL Supabase SatSet
class DatabaseConstants {
  DatabaseConstants._();

  /// Nama tabel master pengguna
  static const String tableUsers = 'm_users';

  /// Nama tabel pengiriman
  static const String tableShipments = 't_shipments';

  /// Nama tabel jejak pelacakan pengiriman
  static const String tableShipmentTracking = 't_shipment_tracking';

  /// Nama tabel master status pengiriman
  static const String tableShipmentStatuses = 'm_shipment_statuses';

  /// Nama tabel master jenis layanan
  static const String tableServiceTypes = 'm_service_types';

  /// Nama tabel pembaruan lokasi kurir real-time
  static const String tableShipmentLocations = 't_shipment_locations';

  /// Nama tabel transaksi pembayaran pengiriman
  static const String tableShipmentPayments = 't_shipment_payments';

  /// Nama tabel master wilayah berjenjang
  static const String tableProvinsi = 'm_provinsi';
  static const String tableKabkot = 'm_kabkot';
  static const String tableKecamatan = 'm_kecamatan';
  static const String tableKelurahan = 'm_kelurahan';

  /// Nama tabel notifikasi pelanggan
  static const String tableNotifications = 't_notifications';

  /// Nama tabel master jenis bank & bank rekening
  static const String tableJenisBank = 'm_jenis_bank';
  static const String tableBank = 'm_bank';

  /// Kolom umum
  static const String colId = 'id';
  static const String colEmail = 'email';
  static const String colKode = 'kode';
  static const String colCreatedAt = 'created_at';
}

/// Kolom-kolom tabel m_users di Supabase
class UserTableColumns {
  UserTableColumns._();

  static const String id = 'id';
  static const String namaLengkap = 'nama_lengkap';
  static const String email = 'email';
  static const String noHp = 'no_hp';
  static const String password = 'password';
  static const String role = 'role';
  static const String googleId = 'google_id';
  static const String alamatLengkap = 'alamat_lengkap';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String resetToken = 'reset_token';
  static const String tokenExpiredAt = 'token_expired_at';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

/// Kolom-kolom tabel t_shipments di Supabase
class ShipmentTableColumns {
  ShipmentTableColumns._();

  static const String id = 'id';
  static const String nomorResi = 'nomor_resi';
  static const String barcodeValue = 'barcode_value';
  static const String customerId = 'customer_id';
  static const String serviceTypeId = 'service_type_id';
  static const String statusId = 'status_id';
  static const String pengirimNama = 'pengirim_nama';
  static const String pengirimNoHp = 'pengirim_no_hp';
  static const String pengirimAlamat = 'pengirim_alamat';
  static const String pengirimKota = 'pengirim_kota';
  static const String pengirimKodePos = 'pengirim_kode_pos';
  static const String pengirimLatitude = 'pengirim_latitude';
  static const String pengirimLongitude = 'pengirim_longitude';
  static const String penerimaNama = 'penerima_nama';
  static const String penerimaNoHp = 'penerima_no_hp';
  static const String penerimaAlamat = 'penerima_alamat';
  static const String penerimaKota = 'penerima_kota';
  static const String penerimaKodePos = 'penerima_kode_pos';
  static const String penerimaLatitude = 'penerima_latitude';
  static const String penerimaLongitude = 'penerima_longitude';
  static const String totalBeratGram = 'total_berat_gram';
  static const String panjangCm = 'panjang_cm';
  static const String lebarCm = 'lebar_cm';
  static const String tinggiCm = 'tinggi_cm';
  static const String totalBarang = 'total_barang';
  static const String nilaiBarang = 'nilai_barang';
  static const String biayaPengiriman = 'biaya_pengiriman';
  static const String biayaAsuransi = 'biaya_asuransi';
  static const String biayaLayananTambahan = 'biaya_layanan_tambahan';
  static const String diskon = 'diskon';
  static const String totalBiaya = 'total_biaya';
  static const String metodePembayaran = 'metode_pembayaran';
  static const String catatanPengiriman = 'catatan_pengiriman';
  static const String estimasiTiba = 'estimasi_tiba';
  static const String pickedUpAt = 'picked_up_at';
  static const String deliveredAt = 'delivered_at';
  static const String cancelledAt = 'cancelled_at';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

/// Kolom-kolom tabel t_shipment_tracking di Supabase
class ShipmentTrackingTableColumns {
  ShipmentTrackingTableColumns._();

  static const String id = 'id';
  static const String shipmentId = 'shipment_id';
  static const String statusId = 'status_id';
  static const String employeeId = 'employee_id';
  static const String barcodeValue = 'barcode_value';
  static const String lokasiNama = 'lokasi_nama';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String catatan = 'catatan';
  static const String eventSource = 'event_source';
  static const String createdAt = 'created_at';
}

/// Kolom-kolom tabel t_shipment_locations di Supabase
class ShipmentLocationTableColumns {
  ShipmentLocationTableColumns._();

  static const String id = 'id';
  static const String shipmentId = 'shipment_id';
  static const String employeeId = 'employee_id';
  static const String latitude = 'latitude';
  static const String longitude = 'longitude';
  static const String speed = 'speed';
  static const String heading = 'heading';
  static const String accuracy = 'accuracy';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

/// Kolom-kolom tabel t_shipment_payments di Supabase
class ShipmentPaymentTableColumns {
  ShipmentPaymentTableColumns._();

  static const String id = 'id';
  static const String shipmentId = 'shipment_id';
  static const String nomorPembayaran = 'nomor_pembayaran';
  static const String metodePembayaran = 'metode_pembayaran';
  static const String jumlahBayar = 'jumlah_bayar';
  static const String statusPembayaran = 'status_pembayaran';
  static const String provider = 'provider';
  static const String providerReference = 'provider_reference';
  static const String buktiPembayaranPath = 'bukti_pembayaran_path';
  static const String jenisBankId = 'jenis_bank_id';
  static const String paidAt = 'paid_at';
  static const String expiredAt = 'expired_at';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
}

/// Kolom-kolom tabel m_provinsi di Supabase
class ProvinsiTableColumns {
  ProvinsiTableColumns._();

  static const String kodeProvinsi = 'kode_provinsi';
  static const String namaProvinsi = 'nama_provinsi';
  static const String createdAt = 'created_at';
}

/// Kolom-kolom tabel m_kabkot di Supabase
class KabkotTableColumns {
  KabkotTableColumns._();

  static const String kodeKabkot = 'kode_kabkot';
  static const String kodeProvinsi = 'kode_provinsi';
  static const String namaKabkot = 'nama_kabkot';
  static const String jenis = 'jenis';
  static const String createdAt = 'created_at';
}

/// Kolom-kolom tabel m_kecamatan di Supabase
class KecamatanTableColumns {
  KecamatanTableColumns._();

  static const String kodeKecamatan = 'kode_kecamatan';
  static const String kodeKabkot = 'kode_kabkot';
  static const String namaKecamatan = 'nama_kecamatan';
  static const String createdAt = 'created_at';
}

/// Kolom-kolom tabel m_kelurahan di Supabase
class KelurahanTableColumns {
  KelurahanTableColumns._();

  static const String kodeKelurahan = 'kode_kelurahan';
  static const String kodeKecamatan = 'kode_kecamatan';
  static const String namaKelurahan = 'nama_kelurahan';
  static const String kodepos = 'kodepos';
  static const String createdAt = 'created_at';
}

/// Kolom-kolom tabel m_service_types di Supabase
class ServiceTypeTableColumns {
  ServiceTypeTableColumns._();

  static const String id = 'id';
  static const String kode = 'kode';
  static const String namaLayanan = 'nama_layanan';
  static const String estimasiHariMin = 'estimasi_hari_min';
  static const String estimasiHariMax = 'estimasi_hari_max';
  static const String deskripsi = 'deskripsi';
  static const String isActive = 'is_active';
  static const String createdAt = 'created_at';
}

/// Kolom-kolom tabel t_notifications di Supabase
class NotificationTableColumns {
  NotificationTableColumns._();

  static const String id = 'id';
  static const String userId = 'user_id';
  static const String title = 'title';
  static const String message = 'message';
  static const String type = 'type';
  static const String isRead = 'is_read';
  static const String readAt = 'read_at';
  static const String shipmentId = 'shipment_id';
  static const String paymentId = 'payment_id';
  static const String data = 'data';
  static const String createdAt = 'created_at';
}

/// Kolom-kolom tabel m_jenis_bank di Supabase
class JenisBankTableColumns {
  JenisBankTableColumns._();

  static const String id = 'id';
  static const String namaJenis = 'nama_jenis';
  static const String createdAt = 'created_at';
}

/// Kolom-kolom tabel m_bank di Supabase
class BankTableColumns {
  BankTableColumns._();

  static const String id = 'id';
  static const String nmBank = 'nm_bank';
  static const String nmrRekening = 'nmr_rekening';
  static const String jenisBankId = 'jenis_bank_id';
  static const String createdAt = 'created_at';
}


