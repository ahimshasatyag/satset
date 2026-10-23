import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/barcode_scan_result.dart';
import '../../domain/repositories/courier_barcode_scanner_repository.dart';
import '../../domain/usecases/get_recent_scans_usecase.dart';
import '../../domain/usecases/process_scanned_shipment_usecase.dart';
import '../../domain/usecases/scan_barcode_usecase.dart';
import 'courier_barcode_scanner_event.dart';
import 'courier_barcode_scanner_state.dart';

class CourierBarcodeScannerBloc
    extends Bloc<CourierBarcodeScannerEvent, CourierBarcodeScannerState> {
  final ScanBarcodeUseCase _scanBarcodeUseCase;
  final ProcessScannedShipmentUseCase _processScannedShipmentUseCase;
  final GetRecentScansUseCase _getRecentScansUseCase;
  final CourierBarcodeScannerRepository _repository;

  CourierBarcodeScannerBloc({
    required ScanBarcodeUseCase scanBarcodeUseCase,
    required ProcessScannedShipmentUseCase processScannedShipmentUseCase,
    required GetRecentScansUseCase getRecentScansUseCase,
    required CourierBarcodeScannerRepository repository,
  })  : _scanBarcodeUseCase = scanBarcodeUseCase,
        _processScannedShipmentUseCase = processScannedShipmentUseCase,
        _getRecentScansUseCase = getRecentScansUseCase,
        _repository = repository,
        super(CourierBarcodeScannerState.initial()) {
    on<BarcodeScannerInitialized>(_onInitialized);
    on<BarcodeScanned>(_onBarcodeScanned);
    on<ShipmentActionConfirmed>(_onShipmentActionConfirmed);
    on<ScannerToggled>(_onScannerToggled);
    on<TorchToggled>(_onTorchToggled);
    on<CameraPermissionStatusChanged>(_onCameraPermissionChanged);
    on<ResetScannerForNextPackage>(_onResetForNextPackage);
    on<ClearScanHistory>(_onClearScanHistory);
    on<ScanErrorDismissed>(_onScanErrorDismissed);
  }

  Future<void> _onInitialized(
    BarcodeScannerInitialized event,
    Emitter<CourierBarcodeScannerState> emit,
  ) async {
    final courierId = await _repository.resolveCourierId(overrideId: event.courierId);
    final recentCodes = _getRecentScansUseCase.execute();

    emit(state.copyWith(
      activeCourierId: courierId,
      recentScannedCodes: recentCodes,
      isScanning: true,
      clearScannedShipment: true,
      clearErrorFeedback: true,
      clearSuccessFeedbackMessage: true,
    ));
  }

  Future<void> _onBarcodeScanned(
    BarcodeScanned event,
    Emitter<CourierBarcodeScannerState> emit,
  ) async {
    final rawCode = event.barcodeValue.trim();
    if (rawCode.isEmpty || state.isProcessing) return;

    emit(state.copyWith(
      isProcessing: true,
      clearErrorFeedback: true,
      clearSuccessFeedbackMessage: true,
    ));

    final result = await _scanBarcodeUseCase.execute(
      barcodeValue: rawCode,
      courierId: state.activeCourierId,
      force: event.force,
    );

    final recentCodes = _getRecentScansUseCase.execute();

    if (result.isSuccess && result.shipment != null) {
      emit(state.copyWith(
        isProcessing: false,
        isScanning: false, // Jeda kamera saat paket berhasil dipindai dan ditampilkan
        scannedShipment: result.shipment,
        lastScanResult: result,
        clearErrorFeedback: true,
        actionSuccess: false,
        recentScannedCodes: recentCodes,
      ));
    } else {
      emit(state.copyWith(
        isProcessing: false,
        errorFeedback: result,
        lastScanResult: result,
        clearScannedShipment: true,
        recentScannedCodes: recentCodes,
      ));
    }
  }

  Future<void> _onShipmentActionConfirmed(
    ShipmentActionConfirmed event,
    Emitter<CourierBarcodeScannerState> emit,
  ) async {
    final shipment = state.scannedShipment;
    if (shipment == null || state.isProcessing) return;

    emit(state.copyWith(isProcessing: true));

    final result = await _processScannedShipmentUseCase.execute(
      shipmentId: shipment.shipmentId,
      assignmentId: shipment.assignmentId,
      newStatusCode: event.newStatusCode,
      courierId: state.activeCourierId,
      notes: event.notes,
      latitude: event.latitude,
      longitude: event.longitude,
    );

    final recentCodes = _getRecentScansUseCase.execute();

    if (result.isSuccess && result.shipment != null) {
      emit(state.copyWith(
        isProcessing: false,
        scannedShipment: result.shipment,
        lastScanResult: result,
        actionSuccess: true,
        successFeedbackMessage: result.message,
        clearErrorFeedback: true,
        recentScannedCodes: recentCodes,
      ));
    } else {
      emit(state.copyWith(
        isProcessing: false,
        errorFeedback: result,
        actionSuccess: false,
      ));
    }
  }

  void _onScannerToggled(
    ScannerToggled event,
    Emitter<CourierBarcodeScannerState> emit,
  ) {
    emit(state.copyWith(isScanning: event.isScanning));
  }

  void _onTorchToggled(
    TorchToggled event,
    Emitter<CourierBarcodeScannerState> emit,
  ) {
    emit(state.copyWith(isTorchOn: !state.isTorchOn));
  }

  void _onCameraPermissionChanged(
    CameraPermissionStatusChanged event,
    Emitter<CourierBarcodeScannerState> emit,
  ) {
    BarcodeScanResult? feedback;
    if (!event.isGranted) {
      feedback = BarcodeScanResult.permissionDenied();
    } else if (!event.isCameraAvailable) {
      feedback = BarcodeScanResult.cameraUnavailable();
    }

    emit(state.copyWith(
      cameraPermissionGranted: event.isGranted,
      isCameraAvailable: event.isCameraAvailable,
      errorFeedback: feedback,
    ));
  }

  void _onResetForNextPackage(
    ResetScannerForNextPackage event,
    Emitter<CourierBarcodeScannerState> emit,
  ) {
    emit(state.copyWith(
      isScanning: true,
      clearScannedShipment: true,
      clearLastScanResult: true,
      clearErrorFeedback: true,
      clearSuccessFeedbackMessage: true,
      actionSuccess: false,
      isProcessing: false,
    ));
  }

  void _onClearScanHistory(
    ClearScanHistory event,
    Emitter<CourierBarcodeScannerState> emit,
  ) {
    _getRecentScansUseCase.clear();
    emit(state.copyWith(recentScannedCodes: const []));
  }

  void _onScanErrorDismissed(
    ScanErrorDismissed event,
    Emitter<CourierBarcodeScannerState> emit,
  ) {
    emit(state.copyWith(clearErrorFeedback: true));
  }
}
