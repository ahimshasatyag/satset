import 'package:shared_preferences/shared_preferences.dart';

abstract class CourierBarcodeScannerLocalDataSource {
  /// Cek apakah barcode sudah dipindai dalam sesi kurir saat ini
  bool isAlreadyScanned(String barcode);

  /// Menambahkan barcode ke dalam cache sesi aktif
  void addScannedBarcode(String barcode);

  /// Mengambil daftar seluruh barcode yang telah dipindai sesi ini
  List<String> getRecentScannedBarcodes();

  /// Menghapus jejak sesi pemindaian
  void clearScannedHistory();

  /// Mendapatkan preferensi flash/torch kurir
  Future<bool> getTorchPreference();

  /// Menyimpan preferensi flash/torch kurir
  Future<void> saveTorchPreference(bool isEnabled);
}

class CourierBarcodeScannerLocalDataSourceImpl implements CourierBarcodeScannerLocalDataSource {
  final SharedPreferences? _prefs;
  final List<String> _sessionScannedBarcodes = [];
  static const String _keyTorchPref = 'courier_scanner_torch_pref';

  CourierBarcodeScannerLocalDataSourceImpl({SharedPreferences? prefs}) : _prefs = prefs;

  @override
  bool isAlreadyScanned(String barcode) {
    final clean = barcode.trim().toUpperCase();
    if (clean.isEmpty) return false;
    return _sessionScannedBarcodes.contains(clean);
  }

  @override
  void addScannedBarcode(String barcode) {
    final clean = barcode.trim().toUpperCase();
    if (clean.isNotEmpty && !_sessionScannedBarcodes.contains(clean)) {
      _sessionScannedBarcodes.insert(0, clean);
      if (_sessionScannedBarcodes.length > 50) {
        _sessionScannedBarcodes.removeLast();
      }
    }
  }

  @override
  List<String> getRecentScannedBarcodes() {
    return List.unmodifiable(_sessionScannedBarcodes);
  }

  @override
  void clearScannedHistory() {
    _sessionScannedBarcodes.clear();
  }

  @override
  Future<bool> getTorchPreference() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    return p.getBool(_keyTorchPref) ?? false;
  }

  @override
  Future<void> saveTorchPreference(bool isEnabled) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setBool(_keyTorchPref, isEnabled);
  }
}
