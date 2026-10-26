/// Hubungan orang yang menerima paket dengan penerima yang tercatat pada resi
enum RecipientRelationship {
  /// Paket diterima langsung oleh pihak penerima yang bersangkutan
  self,

  /// Paket diterima oleh anggota keluarga serumah (orang tua, suami/istri, anak, saudara)
  family,

  /// Paket diterima oleh rekan kerja di kantor / instansi
  colleague,

  /// Paket dititipkan kepada petugas keamanan (Satpam / Security) atau staf resepsionis
  security,

  /// Paket dititipkan kepada tetangga sekitar rumah
  neighbor,

  /// Pihak penerima lainnya
  other,
}

extension RecipientRelationshipX on RecipientRelationship {
  /// Label bahasa Indonesia yang tampil pada formulir dan riwayat
  String get label {
    switch (this) {
      case RecipientRelationship.self:
        return 'Diri Sendiri (Penerima Asli)';
      case RecipientRelationship.family:
        return 'Keluarga / Serumah';
      case RecipientRelationship.colleague:
        return 'Rekan Kerja / Kantor';
      case RecipientRelationship.security:
        return 'Satpam / Security / Resepsionis';
      case RecipientRelationship.neighbor:
        return 'Tetangga';
      case RecipientRelationship.other:
        return 'Lainnya';
    }
  }

  /// Kode representasi singkat yang dapat disimpan ke metadata atau catatan
  String get code {
    switch (this) {
      case RecipientRelationship.self:
        return 'PENERIMA_LANGSUNG';
      case RecipientRelationship.family:
        return 'ANGGOTA_KELUARGA';
      case RecipientRelationship.colleague:
        return 'REKAN_KERJA';
      case RecipientRelationship.security:
        return 'SATPAM_SECURITY';
      case RecipientRelationship.neighbor:
        return 'TETANGGA';
      case RecipientRelationship.other:
        return 'LAINNYA';
    }
  }

  /// Konversi dari string code ke enum
  static RecipientRelationship fromCode(String? code) {
    if (code == null) return RecipientRelationship.self;
    final upper = code.toUpperCase();
    for (final val in RecipientRelationship.values) {
      if (val.code == upper || val.name.toUpperCase() == upper) {
        return val;
      }
    }
    return RecipientRelationship.self;
  }
}
