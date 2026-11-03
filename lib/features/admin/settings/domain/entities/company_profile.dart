import 'package:equatable/equatable.dart';

class CompanyProfile extends Equatable {
  final String companyName;
  final String operationalAddress;
  final String contactPhone;
  final String contactEmail;
  final String websiteUrl;
  final String operationalHours;
  final String motto;
  final String legalEntityNumber;
  final bool isStoredLocally;
  final String backendNote;

  const CompanyProfile({
    this.companyName = 'PT SatSet Delivery Indonesia',
    this.operationalAddress =
        'Jl. Logistik Cepat No. 88, Kawasan Pergudangan Modern, Jakarta Pusat 10110',
    this.contactPhone = '+62 21 5550 8899',
    this.contactEmail = 'support@satset.id',
    this.websiteUrl = 'https://satset.id',
    this.operationalHours = 'Senin - Minggu: 24 Jam (Operasional Non-Stop)',
    this.motto = 'Sat-Set Sampai, Hati Pun Santai.',
    this.legalEntityNumber = 'AHU-0012948.AH.01.01.TAHUN.2024',
    this.isStoredLocally = true,
    this.backendNote =
        'Informasi profil perusahaan saat ini dikelola secara modular pada aplikasi. Skema database Supabase saat ini belum memiliki tabel khusus "m_company_profile" sehingga konfigurasi ini disimpan secara aman dan terisolasi.',
  });

  CompanyProfile copyWith({
    String? companyName,
    String? operationalAddress,
    String? contactPhone,
    String? contactEmail,
    String? websiteUrl,
    String? operationalHours,
    String? motto,
    String? legalEntityNumber,
    bool? isStoredLocally,
    String? backendNote,
  }) {
    return CompanyProfile(
      companyName: companyName ?? this.companyName,
      operationalAddress: operationalAddress ?? this.operationalAddress,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      operationalHours: operationalHours ?? this.operationalHours,
      motto: motto ?? this.motto,
      legalEntityNumber: legalEntityNumber ?? this.legalEntityNumber,
      isStoredLocally: isStoredLocally ?? this.isStoredLocally,
      backendNote: backendNote ?? this.backendNote,
    );
  }

  @override
  List<Object?> get props => [
        companyName,
        operationalAddress,
        contactPhone,
        contactEmail,
        websiteUrl,
        operationalHours,
        motto,
        legalEntityNumber,
        isStoredLocally,
        backendNote,
      ];
}

