import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/live_track_shipment.dart';

abstract class LiveTrackLocalDataSource {
  Future<String?> getLastTrackedResi();
  Future<void> saveLastTrackedResi(String resi);
  Future<double> getSavedMapZoom();
  Future<void> saveMapZoom(double zoom);
  Future<OrderDirection> getLastDirection();
  Future<void> saveLastDirection(OrderDirection direction);
}

class LiveTrackLocalDataSourceImpl implements LiveTrackLocalDataSource {
  static const String _keyLastTrackedResi = 'satset_last_tracked_resi';
  static const String _keyMapZoom = 'satset_livetrack_zoom';
  static const String _keyDirection = 'satset_livetrack_direction';

  @override
  Future<String?> getLastTrackedResi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastTrackedResi);
  }

  @override
  Future<void> saveLastTrackedResi(String resi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastTrackedResi, resi);
  }

  @override
  Future<double> getSavedMapZoom() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyMapZoom) ?? 15.0;
  }

  @override
  Future<void> saveMapZoom(double zoom) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMapZoom, zoom);
  }

  @override
  Future<OrderDirection> getLastDirection() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyDirection);
    if (saved == 'incoming') {
      return OrderDirection.incoming;
    }
    return OrderDirection.outgoing;
  }

  @override
  Future<void> saveLastDirection(OrderDirection direction) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDirection, direction.name);
  }
}
