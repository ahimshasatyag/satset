import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/courier_task_model.dart';

abstract class CourierTasksLocalDataSource {
  /// Mengambil daftar tugas tersimpan di penyimpanan lokal
  Future<List<CourierTaskModel>> getCachedTasks();

  /// Menyimpan daftar tugas ke penyimpanan lokal
  Future<void> cacheTasks(List<CourierTaskModel> tasks);

  /// Menghapus cache tugas
  Future<void> clearCache();
}

class CourierTasksLocalDataSourceImpl implements CourierTasksLocalDataSource {
  static const String _tasksCacheKey = 'satset_courier_tasks_cache_v1';
  final SharedPreferences? prefs;

  CourierTasksLocalDataSourceImpl({this.prefs});

  Future<SharedPreferences> get _instance async =>
      prefs ?? await SharedPreferences.getInstance();

  @override
  Future<List<CourierTaskModel>> getCachedTasks() async {
    try {
      final prefs = await _instance;
      final raw = prefs.getString(_tasksCacheKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = json.decode(raw) as List<dynamic>;
      return decoded
          .map((item) => CourierTaskModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> cacheTasks(List<CourierTaskModel> tasks) async {
    try {
      final prefs = await _instance;
      final encoded = json.encode(tasks.map((t) => t.toJson()).toList());
      await prefs.setString(_tasksCacheKey, encoded);
    } catch (_) {}
  }

  @override
  Future<void> clearCache() async {
    try {
      final prefs = await _instance;
      await prefs.remove(_tasksCacheKey);
    } catch (_) {}
  }
}
