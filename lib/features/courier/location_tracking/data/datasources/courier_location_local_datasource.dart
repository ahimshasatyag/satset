import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/courier_location_model.dart';

abstract class CourierLocationLocalDataSource {
  /// Membaca status preferensi apakah tracking sedang diaktifkan oleh kurir
  Future<bool> isTrackingEnabled();

  /// Menyimpan status preferensi aktif/tidaknya tracking
  Future<void> setTrackingEnabled(bool enabled);

  /// Mengambil cache lokasi terakhir kurir
  Future<CourierLocationModel?> getLastKnownLocation();

  /// Menyimpan cache lokasi terakhir kurir
  Future<void> saveLastKnownLocation(CourierLocationModel location);

  /// Menghapus cache pelacakan
  Future<void> clearCache();
}

class CourierLocationLocalDataSourceImpl
    implements CourierLocationLocalDataSource {
  static const String _trackingEnabledKey =
      'satset_courier_tracking_enabled_v1';
  static const String _lastKnownLocationKey =
      'satset_courier_last_known_location_v1';

  final SharedPreferences? prefs;

  CourierLocationLocalDataSourceImpl({this.prefs});

  Future<SharedPreferences> get _instance async =>
      prefs ?? await SharedPreferences.getInstance();

  @override
  Future<bool> isTrackingEnabled() async {
    try {
      final p = await _instance;
      return p.getBool(_trackingEnabledKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setTrackingEnabled(bool enabled) async {
    try {
      final p = await _instance;
      await p.setBool(_trackingEnabledKey, enabled);
    } catch (_) {}
  }

  @override
  Future<CourierLocationModel?> getLastKnownLocation() async {
    try {
      final p = await _instance;
      final raw = p.getString(_lastKnownLocationKey);
      if (raw == null || raw.isEmpty) return null;
      final map = json.decode(raw) as Map<String, dynamic>;
      return CourierLocationModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveLastKnownLocation(CourierLocationModel location) async {
    try {
      final p = await _instance;
      final raw = json.encode(location.toJson());
      await p.setString(_lastKnownLocationKey, raw);
    } catch (_) {}
  }

  @override
  Future<void> clearCache() async {
    try {
      final p = await _instance;
      await p.remove(_trackingEnabledKey);
      await p.remove(_lastKnownLocationKey);
    } catch (_) {}
  }
}
