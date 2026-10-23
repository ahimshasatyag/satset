import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/shipment_repository.dart';
import '../../domain/usecases/create_shipment_usecase.dart';
import 'shipment_event.dart';
import 'shipment_state.dart';

class ShipmentBloc extends Bloc<ShipmentEvent, ShipmentState> {
  final CreateShipmentUseCase createShipmentUseCase;
  final ShipmentRepository repository;

  ShipmentBloc({
    required this.createShipmentUseCase,
    required this.repository,
  }) : super(const ShipmentState()) {
    on<ShipmentInitMasterDataRequested>(_onInitMasterData);
    on<ShipmentCreateSubmitted>(_onCreateSubmitted);
    on<ShipmentCreatedReset>(_onCreatedReset);
  }

  Future<void> _onInitMasterData(
    ShipmentInitMasterDataRequested event,
    Emitter<ShipmentState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final results = await Future.wait([
        repository.getProvinces(),
        repository.getServiceTypes(),
      ]);
      emit(state.copyWith(
        isLoading: false,
        provinces: results[0] as dynamic,
        serviceTypes: results[1] as dynamic,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat data master pengiriman: $e',
      ));
    }
  }

  Future<void> _onCreateSubmitted(
    ShipmentCreateSubmitted event,
    Emitter<ShipmentState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, errorMessage: null));
    try {
      final shipment = await createShipmentUseCase(event.payload);
      emit(state.copyWith(
        isSubmitting: false,
        createdShipment: shipment,
        successMessage: 'Pesanan pengiriman berhasil dibuat!',
      ));
    } catch (e) {
      emit(state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  void _onCreatedReset(
    ShipmentCreatedReset event,
    Emitter<ShipmentState> emit,
  ) {
    emit(state.copyWith(clearCreatedShipment: true));
  }
}
