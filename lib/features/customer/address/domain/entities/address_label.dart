import 'package:equatable/equatable.dart';

/// Entity dan model untuk master data label alamat dari tabel `m_label` di Supabase.
class AddressLabel extends Equatable {
  final int id;
  final String name;

  const AddressLabel({
    required this.id,
    required this.name,
  });

  factory AddressLabel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final idInt = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;
    return AddressLabel(
      id: idInt,
      name: (json['nm_label'] ?? json['name'] ?? json['label'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nm_label': name,
      };

  /// Fallback label statis sesuai skema data tabel `m_label` di Supabase
  static const List<AddressLabel> defaultLabels = [
    AddressLabel(id: 1, name: 'Kantor'),
    AddressLabel(id: 2, name: 'Rumah'),
    AddressLabel(id: 3, name: 'Kos'),
    AddressLabel(id: 4, name: 'Apartemen'),
    AddressLabel(id: 5, name: 'Toko'),
    AddressLabel(id: 6, name: 'Gudang'),
    AddressLabel(id: 7, name: 'Institusi'),
  ];

  @override
  List<Object?> get props => [id, name];
}

