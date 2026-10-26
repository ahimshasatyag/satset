import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/delivery_proof_item_model.dart';

abstract class CourierDeliveryProofLocalDataSource {
  Future<void> saveLastCompletedProof(DeliveryProofItemModel model);
  Future<DeliveryProofItemModel?> getLastCompletedProof();
}

class CourierDeliveryProofLocalDataSourceImpl
    implements CourierDeliveryProofLocalDataSource {
  static const String _lastProofKey = 'courier_last_completed_delivery_proof';

  final SharedPreferences? _customPrefs;

  CourierDeliveryProofLocalDataSourceImpl({SharedPreferences? prefs})
      : _customPrefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _customPrefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveLastCompletedProof(DeliveryProofItemModel model) async {
    try {
      final prefs = await _getPrefs();
      await prefs.setString(_lastProofKey, jsonEncode(model.toJson()));
    } catch (_) {}
  }

  @override
  Future<DeliveryProofItemModel?> getLastCompletedProof() async {
    try {
      final prefs = await _getPrefs();
      final str = prefs.getString(_lastProofKey);
      if (str == null) return null;
      final map = jsonDecode(str) as Map<String, dynamic>;
      return DeliveryProofItemModel.fromDatabase(map);
    } catch (_) {
      return null;
    }
  }
}
