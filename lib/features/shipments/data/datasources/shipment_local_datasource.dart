import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ShipmentLocalDataSource {
  Future<void> saveShipmentDraft(Map<String, dynamic> draft);
  Future<Map<String, dynamic>?> getShipmentDraft();
  Future<void> clearShipmentDraft();
}

class ShipmentLocalDataSourceImpl implements ShipmentLocalDataSource {
  static const String _draftKey = 'satset_shipment_draft_cache';

  @override
  Future<void> saveShipmentDraft(Map<String, dynamic> draft) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_draftKey, jsonEncode(draft));
  }

  @override
  Future<Map<String, dynamic>?> getShipmentDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_draftKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearShipmentDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }
}
