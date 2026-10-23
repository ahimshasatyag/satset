import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:satset/features/auth/domain/entities/user.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';
import '../../data/datasources/courier_barcode_scanner_local_datasource.dart';
import '../../data/datasources/courier_barcode_scanner_remote_datasource.dart';
import '../../data/repositories/courier_barcode_scanner_repository_impl.dart';
import '../../domain/repositories/courier_barcode_scanner_repository.dart';
import '../../domain/usecases/get_recent_scans_usecase.dart';
import '../../domain/usecases/process_scanned_shipment_usecase.dart';
import '../../domain/usecases/scan_barcode_usecase.dart';
import '../bloc/courier_barcode_scanner_bloc.dart';
import '../bloc/courier_barcode_scanner_event.dart';
import '../bloc/courier_barcode_scanner_state.dart';
import '../widgets/barcode_manual_input_dialog.dart';
import '../widgets/barcode_scanner_feedback_banner.dart';
import '../widgets/barcode_scanner_history_sheet.dart';
import '../widgets/barcode_scanner_viewfinder.dart';
import '../widgets/scanned_package_detail_card.dart';

/// Halaman utama Barcode Scanner Khusus Kurir pada aplikasi SatSet Delivery.
///
/// Berfungsi untuk memindai barcode/nomor resi paket saat tahapan pickup,
/// penerimaan, pemrosesan hub, dan pengantaran paket kepada penerima.
class CourierBarcodeScannerPage extends StatefulWidget {
  final User? user;
  final VoidCallback? onNavigateToTasks;
  final void Function(String shipmentId)? onOpenTaskDetail;
  final VoidCallback? onBack;
  final CourierBarcodeScannerBloc? customBloc;

  const CourierBarcodeScannerPage({
    super.key,
    this.user,
    this.onNavigateToTasks,
    this.onOpenTaskDetail,
    this.onBack,
    this.customBloc,
  });

  @override
  State<CourierBarcodeScannerPage> createState() => _CourierBarcodeScannerPageState();
}

class _CourierBarcodeScannerPageState extends State<CourierBarcodeScannerPage> {
  late final CourierBarcodeScannerBloc _bloc;
  bool _isLocalBloc = false;

  @override
  void initState() {
    super.initState();
    if (widget.customBloc != null) {
      _bloc = widget.customBloc!;
    } else {
      _isLocalBloc = true;
      final remoteDataSource = CourierBarcodeScannerRemoteDataSourceImpl(
        currentUser: widget.user,
      );
      final localDataSource = CourierBarcodeScannerLocalDataSourceImpl();
      final repository = CourierBarcodeScannerRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      _bloc = CourierBarcodeScannerBloc(
        scanBarcodeUseCase: ScanBarcodeUseCase(repository),
        processScannedShipmentUseCase: ProcessScannedShipmentUseCase(repository),
        getRecentScansUseCase: GetRecentScansUseCase(repository),
        repository: repository,
      );
    }

    _bloc.add(BarcodeScannerInitialized(courierId: widget.user?.id));
  }

  @override
  void dispose() {
    if (_isLocalBloc) {
      _bloc.close();
    }
    super.dispose();
  }

  void _openManualInputDialog(BuildContext context, List<String> recentCodes) async {
    final scannedCode = await BarcodeManualInputDialog.show(
      context,
      recentCodes: recentCodes,
    );
    if (scannedCode != null && scannedCode.isNotEmpty) {
      _bloc.add(BarcodeScanned(scannedCode, isManual: true));
    }
  }

  void _openHistorySheet(BuildContext context, List<String> recentCodes) {
    BarcodeScannerHistorySheet.show(
      context,
      recentCodes: recentCodes,
      onSelectCode: (code) {
        _bloc.add(BarcodeScanned(code, force: true));
      },
      onClearHistory: () {
        _bloc.add(const ClearScanHistory());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider.value(
      value: _bloc,
      child: BlocConsumer<CourierBarcodeScannerBloc, CourierBarcodeScannerState>(
        listener: (context, state) {
          // Umpan balik snackbar jika ada pesan sukses
          if (state.actionSuccess && state.successFeedbackMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.successFeedbackMessage!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: CustomAppBar(
              title: 'Barcode Scanner Kurir',
              showBackButton: widget.onBack != null,
              onBackTap: widget.onBack,
              actions: [
                // Tombol Buka Riwayat Sesi
                IconButton(
                  tooltip: 'Riwayat Sesi',
                  icon: const Icon(Icons.history_rounded),
                  onPressed: () => _openHistorySheet(context, state.recentScannedCodes),
                ),
                // Tombol Buka Input Manual
                IconButton(
                  tooltip: 'Input Manual',
                  icon: const Icon(Icons.keyboard_alt_rounded),
                  onPressed: () => _openManualInputDialog(context, state.recentScannedCodes),
                ),
              ],
            ),
            body: Stack(
              children: [
                // 1. Area Viewfinder Kamera & Kontrol Pemindaian
                Positioned.fill(
                  child: BarcodeScannerViewfinder(
                    isScanning: state.isScanning,
                    isTorchOn: state.isTorchOn,
                    isCameraAvailable: state.isCameraAvailable,
                    isPermissionGranted: state.cameraPermissionGranted,
                    sessionCount: state.recentScannedCodes.length,
                    onToggleScan: () {
                      _bloc.add(ScannerToggled(!state.isScanning));
                    },
                    onToggleTorch: () {
                      _bloc.add(const TorchToggled());
                    },
                    onManualInputTap: () {
                      _openManualInputDialog(context, state.recentScannedCodes);
                    },
                    onRetryPermission: () {
                      _bloc.add(const CameraPermissionStatusChanged(
                        isGranted: true,
                        isCameraAvailable: true,
                      ));
                    },
                    onOpenHistory: () {
                      _openHistorySheet(context, state.recentScannedCodes);
                    },
                  ),
                ),

                // 2. Banner Umpan Balik Error / Penolakan / Peringatan
                if (state.errorFeedback != null)
                  Positioned(
                    top: 10,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: BarcodeScannerFeedbackBanner(
                        result: state.errorFeedback!,
                        onDismiss: () {
                          _bloc.add(const ScanErrorDismissed());
                        },
                        onRetry: () {
                          _bloc.add(const ResetScannerForNextPackage());
                        },
                        onManualInput: () {
                          _openManualInputDialog(context, state.recentScannedCodes);
                        },
                        onForceScan: () {
                          final code = state.errorFeedback?.rawBarcode;
                          if (code != null && code.isNotEmpty) {
                            _bloc.add(BarcodeScanned(code, force: true));
                          }
                        },
                      ),
                    ),
                  ),

                // 3. Card Detail Identitas Paket Terpindai (Bottom Card / Sheet)
                if (state.scannedShipment != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: ScannedPackageDetailCard(
                      shipment: state.scannedShipment!,
                      isProcessing: state.isProcessing,
                      actionSuccess: state.actionSuccess,
                      successMessage: state.successFeedbackMessage,
                      onConfirmAction: ({required newStatusCode, notes}) {
                        _bloc.add(ShipmentActionConfirmed(
                          newStatusCode: newStatusCode,
                          notes: notes,
                        ));
                      },
                      onScanNext: () {
                        _bloc.add(const ResetScannerForNextPackage());
                      },
                      onOpenTaskDetail: widget.onOpenTaskDetail != null
                          ? () => widget.onOpenTaskDetail!(state.scannedShipment!.shipmentId)
                          : widget.onNavigateToTasks != null
                              ? widget.onNavigateToTasks
                              : null,
                    ),
                  ),

                // 4. Indikator Loading Transparan saat Memproses
                if (state.isProcessing && state.scannedShipment == null)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black45,
                      child: const Center(
                        child: CustomLoading(
                          message: 'Memvalidasi barcode paket...',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
