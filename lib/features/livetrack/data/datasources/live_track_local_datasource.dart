import 'package:shared_preferences/shared_preferences.dart';

abstract class LiveTrackLocalDataSource {
  Future<String?> getLastTrackedShipmentId();
  Future<void> saveLastTrackedShipmentId(String id);
  Future<double> getSavedMapZoom();
  Future<void> saveMapZoom(double zoom);
}

class LiveTrackLocalDataSourceImpl implements LiveTrackLocalDataSource {
  static const String _keyLastTrackedId = 'satset_last_tracked_shipment_id';
  static const String _keyMapZoom = 'satset_livetrack_zoom';

  @override
  Future<String?> getLastTrackedShipmentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastTrackedId);
  }

  @override
  Future<void> saveLastTrackedShipmentId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastTrackedId, id);
  }

  @override
  Future<double> getSavedMapZoom() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyMapZoom) ?? 1.0;
  }

  @override
  Future<void> saveMapZoom(double zoom) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMapZoom, zoom);
  }
}
