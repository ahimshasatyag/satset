import 'package:equatable/equatable.dart';
import '../../domain/entities/barcode_scan_result.dart';
import '../../domain/entities/scanned_shipment.dart';

class CourierBarcodeScannerState extends Equatable {
  /// Apakah viewfinder kamera aktif memindai
  final bool isScanning;

  /// Status lampu senter / flash
  final bool isTorchOn;

  /// Status izin kamera perangkat
  final bool cameraPermissionGranted;

  /// Ketersediaan modul kamera perangkat
  final bool isCameraAvailable;

  /// Sedang memproses query ke server atau update status
  final bool isProcessing;

  /// ID kurir yang aktif saat ini
  final String activeCourierId;

  /// Paket yang berhasil dikenali dan menunggu tindakan kurir
  final ScannedShipment? scannedShipment;

  /// Hasil evaluasi pemindaian terakhir
  final BarcodeScanResult? lastScanResult;

  /// Banner umpan balik kegagalan/penolakan (unregistered, notAssigned, duplicate, etc.)
  final BarcodeScanResult? errorFeedback;

  /// Flag penanda tindakan status berhasil diselesaikan
  final bool actionSuccess;

  /// Pesan sukses setelah tindakan berhasil diproses
  final String? successFeedbackMessage;

  /// Daftar nilai barcode yang berhasil dipindai dalam sesi kurir saat ini
  final List<String> recentScannedCodes;

  const CourierBarcodeScannerState({
    required this.isScanning,
    required this.isTorchOn,
    required this.cameraPermissionGranted,
    required this.isCameraAvailable,
    required this.isProcessing,
    required this.activeCourierId,
    this.scannedShipment,
    this.lastScanResult,
    this.errorFeedback,
    required this.actionSuccess,
    this.successFeedbackMessage,
    required this.recentScannedCodes,
  });

  factory CourierBarcodeScannerState.initial() {
    return const CourierBarcodeScannerState(
      isScanning: true,
      isTorchOn: false,
      cameraPermissionGranted: true,
      isCameraAvailable: true,
      isProcessing: false,
      activeCourierId: '',
      scannedShipment: null,
      lastScanResult: null,
      errorFeedback: null,
      actionSuccess: false,
      successFeedbackMessage: null,
      recentScannedCodes: [],
    );
  }

  CourierBarcodeScannerState copyWith({
    bool? isScanning,
    bool? isTorchOn,
    bool? cameraPermissionGranted,
    bool? isCameraAvailable,
    bool? isProcessing,
    String? activeCourierId,
    ScannedShipment? scannedShipment,
    bool clearScannedShipment = false,
    BarcodeScanResult? lastScanResult,
    bool clearLastScanResult = false,
    BarcodeScanResult? errorFeedback,
    bool clearErrorFeedback = false,
    bool? actionSuccess,
    String? successFeedbackMessage,
    bool clearSuccessFeedbackMessage = false,
    List<String>? recentScannedCodes,
  }) {
    return CourierBarcodeScannerState(
      isScanning: isScanning ?? this.isScanning,
      isTorchOn: isTorchOn ?? this.isTorchOn,
      cameraPermissionGranted:
          cameraPermissionGranted ?? this.cameraPermissionGranted,
      isCameraAvailable: isCameraAvailable ?? this.isCameraAvailable,
      isProcessing: isProcessing ?? this.isProcessing,
      activeCourierId: activeCourierId ?? this.activeCourierId,
      scannedShipment: clearScannedShipment
          ? null
          : (scannedShipment ?? this.scannedShipment),
      lastScanResult: clearLastScanResult
          ? null
          : (lastScanResult ?? this.lastScanResult),
      errorFeedback: clearErrorFeedback
          ? null
          : (errorFeedback ?? this.errorFeedback),
      actionSuccess: actionSuccess ?? this.actionSuccess,
      successFeedbackMessage: clearSuccessFeedbackMessage
          ? null
          : (successFeedbackMessage ?? this.successFeedbackMessage),
      recentScannedCodes: recentScannedCodes ?? this.recentScannedCodes,
    );
  }

  @override
  List<Object?> get props => [
        isScanning,
        isTorchOn,
        cameraPermissionGranted,
        isCameraAvailable,
        isProcessing,
        activeCourierId,
        scannedShipment,
        lastScanResult,
        errorFeedback,
        actionSuccess,
        successFeedbackMessage,
        recentScannedCodes,
      ];
}
