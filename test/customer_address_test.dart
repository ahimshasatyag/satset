import 'package:flutter_test/flutter_test.dart';
import 'package:satset/features/customer/address/data/models/customer_address_model.dart';
import 'package:satset/features/customer/address/domain/entities/address_label.dart';
import 'package:satset/features/customer/address/domain/entities/customer_address.dart';

void main() {
  group('Customer Address with Supabase Schema Tests', () {
    test('AddressLabel model parses and defaults correctly', () {
      final label = AddressLabel.fromJson({
        'id': 2,
        'nm_label': 'Rumah',
      });
      expect(label.id, equals(2));
      expect(label.name, equals('Rumah'));

      expect(AddressLabel.defaultLabels.length, equals(7));
      expect(AddressLabel.defaultLabels.first.name, equals('Kantor'));
    });

    test('CustomerAddressModel serialization to m_address JSON contains all new fields', () {
      const address = CustomerAddressModel(
        id: 'addr_123',
        rawId: 10,
        userId: 4,
        title: 'Kantor',
        receiverName: 'Ahimsha Satya',
        phoneNumber: '081234567890',
        email: 'ahimsha@example.com',
        fullAddress: 'Jl. Merdeka Barat No. 10',
        provinceCode: '31',
        regencyCode: '31.73',
        villageCode: '31.73.05.1001',
        postalCode: '10110',
        latitude: -6.208800,
        longitude: 106.845600,
        labelId: 1,
        labelName: 'Kantor',
        isPrimary: true,
      );

      final json = address.toAddressTableJson();
      expect(json['id'], equals(10));
      expect(json['id_users'], equals(4));
      expect(json['nama_lengkap'], equals('Ahimsha Satya'));
      expect(json['no_telp'], equals('081234567890'));
      expect(json['email'], equals('ahimsha@example.com'));
      expect(json['latitude'], equals(-6.208800));
      expect(json['longitude'], equals(106.845600));
      expect(json['id_label'], equals(1));
      expect(json['alamat_lengkap'], equals('Jl. Merdeka Barat No. 10'));
      expect(json['is_utama'], isTrue);
    });

    test('CustomerAddressModel deserialization from m_address table handles joins and fallbacks', () {
      final dbRow = {
        'id': 15,
        'id_users': 4,
        'alamat_lengkap': 'Komplek Permata Hijau B3',
        'id_provinsi': '31',
        'id_kabkot': '31.73',
        'id_kelurahan': '31.73.05.1001',
        'kode_pos': '12210',
        'nama_lengkap': 'Budi Santoso',
        'no_telp': '08987654321',
        'email': 'budi@satset.id',
        'latitude': -6.221500,
        'longitude': 106.784200,
        'id_label': 2,
        'is_utama': false,
        'm_label': {
          'id': 2,
          'nm_label': 'Rumah',
        },
      };

      final model = CustomerAddressModel.fromAddressTable(
        dbRow,
        provinceName: 'DKI JAKARTA',
        regencyName: 'JAKARTA BARAT',
        districtName: 'KEBON JERUK',
        villageName: 'SUKABUMI UTARA',
      );

      expect(model.rawId, equals(15));
      expect(model.userId, equals(4));
      expect(model.receiverName, equals('Budi Santoso'));
      expect(model.phoneNumber, equals('08987654321'));
      expect(model.email, equals('budi@satset.id'));
      expect(model.latitude, equals(-6.221500));
      expect(model.longitude, equals(106.784200));
      expect(model.labelId, equals(2));
      expect(model.title, equals('Rumah'));
      expect(model.isPrimary, isFalse);
      expect(model.sourceType, equals(AddressSourceType.mAddress));
    });
  });
}
