import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:satset/features/auth/data/models/user_model.dart';

void main() {
  group('Google Auth and Supabase m_users sync tests', () {
    test('Simulated loginWithGoogle returns valid UserModel with googleId', () async {
      final remoteDataSource = AuthRemoteDataSourceImpl();
      final user = await remoteDataSource.loginWithGoogle();

      expect(user.googleId, isNotNull);
      expect(user.googleId!.isNotEmpty, isTrue);
      expect(user.email, isNotEmpty);
      expect(user.name, isNotEmpty);
      expect(user.role, equals('customer'));
    });

    test('UserModel serialization supports google_id correctly', () {
      final map = {
        'id': '10',
        'nama_lengkap': 'Google Tester',
        'email': 'tester@google.com',
        'no_hp': '08123456789',
        'google_id': 'gid_987654321',
        'role': 'customer',
      };

      final user = UserModel.fromDatabase(map);
      expect(user.googleId, equals('gid_987654321'));
      expect(user.name, equals('Google Tester'));
      expect(user.email, equals('tester@google.com'));

      final json = user.toJson();
      expect(json['google_id'], equals('gid_987654321'));

      final copy = user.copyWith(googleId: 'gid_updated');
      expect(copy.googleId, equals('gid_updated'));
      expect(copy.name, equals('Google Tester'));
    });

    test('UserModel.fromEntity retains google_id', () {
      const user = UserModel(
        id: 'uuid-123',
        name: 'Ahimsha',
        email: 'ahimsha@example.com',
        phone: '08123',
        googleId: 'gid_123456789',
      );

      final converted = UserModel.fromEntity(user);
      expect(converted.googleId, equals('gid_123456789'));
      expect(converted.name, equals('Ahimsha'));
    });
  });
}
