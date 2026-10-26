import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

abstract class CourierDeliveryProofDeviceDataSource {
  /// Mengambil gambar foto bukti dari kamera atau galeri
  Future<({Uint8List bytes, String fileName, int sizeBytes})?> pickImage({
    required bool fromCamera,
  });

  /// Mengambil posisi koordinat latitude & longitude perangkat saat ini
  Future<({double latitude, double longitude})?> getCurrentLocation();
}

class CourierDeliveryProofDeviceDataSourceImpl
    implements CourierDeliveryProofDeviceDataSource {
  final ImagePicker _picker;

  CourierDeliveryProofDeviceDataSourceImpl({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  @override
  Future<({Uint8List bytes, String fileName, int sizeBytes})?> pickImage({
    required bool fromCamera,
  }) async {
    try {
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 82,
      );

      if (file == null) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final size = bytes.lengthInBytes;

      // Validasi batas ukuran maksimum berkas (10 MB)
      if (size > 10 * 1024 * 1024) {
        throw ArgumentError(
          'Ukuran foto terlalu besar (${(size / (1024 * 1024)).toStringAsFixed(1)} MB). Maksimal ukuran berkas adalah 10 MB.',
        );
      }

      final name = file.name.isNotEmpty
          ? file.name
          : 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg';

      return (bytes: bytes, fileName: name, sizeBytes: size);
    } catch (e) {
      if (e is ArgumentError) rethrow;
      throw Exception('Gagal mengakses kamera atau galeri perangkat: $e');
    }
  }

  @override
  Future<({double latitude, double longitude})?> getCurrentLocation() async {
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );

      return (latitude: position.latitude, longitude: position.longitude);
    } catch (_) {
      // Tidak mengarang koordinat jika GPS gagal diperoleh
      return null;
    }
  }
}
