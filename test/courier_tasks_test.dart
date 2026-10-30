import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/courier/tasks/data/datasources/courier_tasks_local_datasource.dart';
import 'package:satset/features/courier/tasks/data/datasources/courier_tasks_remote_datasource.dart';
import 'package:satset/features/courier/tasks/data/models/courier_task_model.dart';
import 'package:satset/features/courier/tasks/data/repositories/courier_tasks_repository_impl.dart';
import 'package:satset/features/courier/tasks/domain/entities/courier_task.dart';
import 'package:satset/features/courier/tasks/domain/usecases/get_courier_tasks_usecase.dart';
import 'package:satset/features/courier/tasks/domain/usecases/stream_courier_tasks_usecase.dart';
import 'package:satset/features/courier/tasks/domain/usecases/update_task_status_usecase.dart';
import 'package:satset/features/courier/tasks/presentation/bloc/courier_tasks_bloc.dart';
import 'package:satset/features/courier/tasks/presentation/bloc/courier_tasks_event.dart';
import 'package:satset/features/courier/tasks/presentation/bloc/courier_tasks_state.dart';
import 'package:satset/features/courier/tasks/presentation/pages/courier_tasks_page.dart';
import 'package:satset/features/courier/tasks/presentation/widgets/courier_task_card.dart';
import 'package:satset/features/courier/tasks/presentation/widgets/courier_tasks_skeleton.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Courier Tasks Clean Architecture & Database Model Tests', () {
    test('CourierTaskModel parses database join accurately', () {
      final now = DateTime.now().toIso8601String();
      final dbMap = {
        'id': 'ASN-999',
        'shipment_id': '555',
        'courier_id': '10',
        'assignment_type': 'PICKUP',
        'status': 'ASSIGNED',
        'assigned_at': now,
        't_shipments': {
          'id': '555',
          'nomor_resi': 'SST-20261023-999',
          'barcode_value': 'SST-20261023-999',
          'pengirim_nama': 'Budi Toko',
          'pengirim_no_hp': '0812345678',
          'pengirim_alamat': 'Jl. Asal No. 1',
          'pengirim_kota': 'Jakarta',
          'penerima_nama': 'Siti Pembeli',
          'penerima_no_hp': '0898765432',
          'penerima_alamat': 'Jl. Tujuan No. 2',
          'penerima_kota': 'Bekasi',
          'status_id': 3,
          'total_berat_gram': 2500,
          'catatan_pengiriman': 'Paket Elektronik',
          'm_shipment_statuses': {
            'id': 3,
            'kode': 'PICKUP_SCHEDULED',
            'nama_status': 'Dijadwalkan untuk Pickup',
          },
          'm_service_types': {
            'id': 2,
            'kode': 'EXP',
            'nama_layanan': 'Express',
          },
          't_shipment_payments': {
            'status_pembayaran': 'PAID',
          },
        },
      };

      final model = CourierTaskModel.fromDatabase(dbMap);

      expect(model.id, 'ASN-999');
      expect(model.shipmentId, '555');
      expect(model.trackingNumber, 'SST-20261023-999');
      expect(model.taskType, CourierTaskType.pickup);
      expect(model.taskGroup, CourierTaskGroup.pending);
      expect(model.isPaid, isTrue);
      expect(model.isWaitingPayment, isFalse);
      expect(model.senderName, 'Budi Toko');
      expect(model.receiverName, 'Siti Pembeli');
      expect(model.serviceTypeName, 'Express');
      expect(model.weightFormatted, '2.5 kg');
      expect(model.validNextStatuses, contains('PICKED_UP'));

      // Uji jika pesanan belum dibayar (non-COD)
      final unpaidTask = model.copyWith(paymentStatus: 'PENDING', paymentMethod: 'TRANSFER');
      expect(unpaidTask.isWaitingPayment, isTrue);
      expect(unpaidTask.validNextStatuses, isEmpty);

      final json = model.toJson();
      expect(json['id'], 'ASN-999');
      expect(json['taskType'], 'pickup');

      final fromJson = CourierTaskModel.fromJson(json);
      expect(fromJson.trackingNumber, 'SST-20261023-999');
      expect(fromJson.taskType, CourierTaskType.pickup);
    });

    test('CourierTasksRepository & UseCases work in offline mock mode', () async {
      final remote = CourierTasksRemoteDataSourceImpl();
      final local = CourierTasksLocalDataSourceImpl();
      final repo = CourierTasksRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );

      final getTasksUseCase = GetCourierTasksUseCase(repo);
      final updateStatusUseCase = UpdateTaskStatusUseCase(repo);

      final tasks = await getTasksUseCase(courierId: '1');
      expect(tasks.isNotEmpty, isTrue);

      final firstTask = tasks.first;
      final updated = await updateStatusUseCase(
        taskId: firstTask.id,
        shipmentId: firstTask.shipmentId,
        newStatusCode: 'PICKED_UP',
        notes: 'Sudah diambil dari pengirim',
      );

      expect(updated.statusCode, 'PICKED_UP');
      expect(updated.statusId, 4);

      final counts = await repo.getTaskCounts(courierId: '1');
      expect(counts.containsKey(CourierTaskGroup.pending), isTrue);
    });

    test('CourierTasksBloc handles fetch, search, filter, and status update', () async {
      final remote = CourierTasksRemoteDataSourceImpl();
      final local = CourierTasksLocalDataSourceImpl();
      final repo = CourierTasksRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );

      final bloc = CourierTasksBloc(
        getCourierTasksUseCase: GetCourierTasksUseCase(repo),
        updateTaskStatusUseCase: UpdateTaskStatusUseCase(repo),
        streamCourierTasksUseCase: StreamCourierTasksUseCase(repo),
      );
      addTearDown(bloc.close);

      bloc.add(const CourierTasksFetched());
      await Future.delayed(const Duration(milliseconds: 200));

      expect(bloc.state.status, CourierTasksStatus.success);
      expect(bloc.state.tasks.isNotEmpty, isTrue);

      // Filter per kelompok
      bloc.add(const CourierTasksGroupChanged(CourierTaskGroup.inProgress));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.selectedGroup, CourierTaskGroup.inProgress);

      // Search query
      bloc.add(const CourierTasksSearchChanged('SST-20261023-002'));
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.searchQuery, 'SST-20261023-002');
      expect(bloc.state.displayedTasks.length, 1);

      // Update status
      final taskToUpdate = bloc.state.displayedTasks.first;
      bloc.add(CourierTaskStatusUpdated(
        taskId: taskToUpdate.id,
        shipmentId: taskToUpdate.shipmentId,
        newStatusCode: 'DELIVERED',
        notes: 'Diserahkan langsung',
      ));
      await Future.delayed(const Duration(milliseconds: 200));

      expect(bloc.state.successMessage, isNotNull);
    });
  });

  group('CourierTasksPage Widget Tests', () {
    testWidgets('CourierTasksPage renders tabs, filter chips, and task list',
        (WidgetTester tester) async {
      final remote = CourierTasksRemoteDataSourceImpl();
      final local = CourierTasksLocalDataSourceImpl();
      final repo = CourierTasksRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
      );

      final bloc = CourierTasksBloc(
        getCourierTasksUseCase: GetCourierTasksUseCase(repo),
        updateTaskStatusUseCase: UpdateTaskStatusUseCase(repo),
        streamCourierTasksUseCase: StreamCourierTasksUseCase(repo),
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          home: CourierTasksPage(
            bloc: bloc,
            repository: repo,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tugas Kurir'), findsOneWidget);
      expect(find.text('Perlu Dikerjakan'), findsOneWidget);
      expect(find.text('Berlangsung'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Semua Tugas'), findsOneWidget);
      expect(find.text('Pengambilan (Pickup)'), findsOneWidget);
      expect(find.text('Pengantaran (Delivery)'), findsOneWidget);

      expect(find.byType(CourierTaskCard), findsWidgets);
    });

    testWidgets('CourierTasksSkeleton renders placeholders properly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CourierTasksSkeleton(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CourierTasksSkeleton), findsOneWidget);
      expect(find.byType(CourierTaskCardSkeleton), findsWidgets);
    });

    testWidgets('CourierTasksSkeleton.fullPage renders header and card placeholders',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CourierTasksSkeleton.fullPage(itemCount: 2),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CourierTasksSkeleton), findsOneWidget);
      expect(find.byType(CourierTaskCardSkeleton), findsNWidgets(2));
    });

    testWidgets('CourierTaskCardSkeleton renders solitary task card skeleton',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CourierTaskCardSkeleton(
              shimmerColor: Colors.grey,
              isDark: false,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CourierTaskCardSkeleton), findsOneWidget);
    });
  });
}
