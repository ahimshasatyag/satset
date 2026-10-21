import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_shipment_model.dart';

abstract class OrderLocalDataSource {
  Future<List<OrderShipmentModel>> getCachedOrders();
  Future<void> cacheOrders(List<OrderShipmentModel> orders);
  Future<void> clearCache();
  Future<Map<String, dynamic>?> getLastSenderAddress();
  Future<void> saveLastSenderAddress(Map<String, dynamic> address);
}

class OrderLocalDataSourceImpl implements OrderLocalDataSource {
  static const String _keyOrders = 'satset_cached_orders';
  static const String _keySenderAddress = 'satset_last_sender_address';

  @override
  Future<List<OrderShipmentModel>> getCachedOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonListStr = prefs.getStringList(_keyOrders);
    if (jsonListStr == null) return [];
    try {
      return jsonListStr.map((item) {
        return OrderShipmentModel.fromJson(
          jsonDecode(item) as Map<String, dynamic>,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> cacheOrders(List<OrderShipmentModel> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final listStr = orders.map((o) => jsonEncode(o.toJson())).toList();
    await prefs.setStringList(_keyOrders, listStr);
  }

  @override
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOrders);
  }

  @override
  Future<Map<String, dynamic>?> getLastSenderAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keySenderAddress);
    if (str == null) return null;
    try {
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveLastSenderAddress(Map<String, dynamic> address) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySenderAddress, jsonEncode(address));
  }
}
