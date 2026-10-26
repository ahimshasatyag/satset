import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_status_detail_model.dart';

abstract class CourierTaskStatusLocalDataSource {
  Future<void> cacheTaskDetail(TaskStatusDetailModel model);
  Future<TaskStatusDetailModel?> getCachedTaskDetail(String shipmentId);
  Future<void> clearCachedTaskDetail(String shipmentId);
}

class CourierTaskStatusLocalDataSourceImpl implements CourierTaskStatusLocalDataSource {
  static const String _prefix = 'task_status_cache_';
  final SharedPreferences? _customPrefs;

  CourierTaskStatusLocalDataSourceImpl({SharedPreferences? prefs})
      : _customPrefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _customPrefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<void> cacheTaskDetail(TaskStatusDetailModel model) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString('$_prefix${model.shipmentId}', jsonEncode(model.toJson()));
    } catch (_) {}
  }

  @override
  Future<TaskStatusDetailModel?> getCachedTaskDetail(String shipmentId) async {
    try {
      final prefs = await _getPrefs();
      final str = prefs.getString('$_prefix$shipmentId');
      if (str == null) return null;
      final map = jsonDecode(str) as Map<String, dynamic>;
      return TaskStatusDetailModel.fromDatabase(map);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearCachedTaskDetail(String shipmentId) async {
    try {
      final prefs = await _getPrefs();
      await prefs.remove('$_prefix$shipmentId');
    } catch (_) {}
  }
}
