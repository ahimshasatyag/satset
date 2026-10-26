import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/courier_task_history_item_model.dart';

abstract class CourierTasksHistoryLocalDataSource {
  /// Mengambil daftar riwayat tugas tersimpan di cache lokal
  Future<List<CourierTaskHistoryItemModel>> getCachedHistoryTasks();

  /// Menyimpan daftar riwayat tugas ke cache lokal
  Future<void> cacheHistoryTasks(List<CourierTaskHistoryItemModel> tasks);

  /// Menghapus cache riwayat tugas
  Future<void> clearCache();
}

class CourierTasksHistoryLocalDataSourceImpl
    implements CourierTasksHistoryLocalDataSource {
  static const String _historyTasksCacheKey =
      'satset_courier_tasks_history_cache_v1';
  final SharedPreferences? prefs;

  CourierTasksHistoryLocalDataSourceImpl({this.prefs});

  Future<SharedPreferences> get _instance async =>
      prefs ?? await SharedPreferences.getInstance();

  @override
  Future<List<CourierTaskHistoryItemModel>> getCachedHistoryTasks() async {
    try {
      final prefs = await _instance;
      final raw = prefs.getString(_historyTasksCacheKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = json.decode(raw) as List<dynamic>;
      return decoded
          .map((item) =>
              CourierTaskHistoryItemModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> cacheHistoryTasks(List<CourierTaskHistoryItemModel> tasks) async {
    try {
      final prefs = await _instance;
      final encoded = json.encode(tasks.map((t) => t.toJson()).toList());
      await prefs.setString(_historyTasksCacheKey, encoded);
    } catch (_) {}
  }

  @override
  Future<void> clearCache() async {
    try {
      final prefs = await _instance;
      await prefs.remove(_historyTasksCacheKey);
    } catch (_) {}
  }
}
