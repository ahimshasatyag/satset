import 'dart:convert';
import '../../domain/entities/company_profile.dart';

class CompanyProfileModel extends CompanyProfile {
  const CompanyProfileModel({
    super.companyName,
    super.operationalAddress,
    super.contactPhone,
    super.contactEmail,
    super.websiteUrl,
    super.operationalHours,
    super.motto,
    super.legalEntityNumber,
    super.isStoredLocally,
    super.backendNote,
  });

  factory CompanyProfileModel.fromJsonString(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) {
      return const CompanyProfileModel();
    }
    try {
      final Map<String, dynamic> map = jsonDecode(jsonStr);
      return CompanyProfileModel(
        companyName: map['company_name']?.toString() ??
            'PT SatSet Delivery Indonesia',
        operationalAddress: map['operational_address']?.toString() ??
            'Jl. Logistik Cepat No. 88, Kawasan Pergudangan Modern, Jakarta Pusat 10110',
        contactPhone:
            map['contact_phone']?.toString() ?? '+62 21 5550 8899',
        contactEmail:
            map['contact_email']?.toString() ?? 'support@satset.id',
        websiteUrl: map['website_url']?.toString() ?? 'https://satset.id',
        operationalHours: map['operational_hours']?.toString() ??
            'Senin - Minggu: 24 Jam (Operasional Non-Stop)',
        motto: map['motto']?.toString() ??
            'Sat-Set Sampai, Hati Pun Santai.',
        legalEntityNumber: map['legal_entity_number']?.toString() ??
            'AHU-0012948.AH.01.01.TAHUN.2024',
        isStoredLocally: true,
      );
    } catch (_) {
      return const CompanyProfileModel();
    }
  }

  String toJsonString() {
    return jsonEncode({
      'company_name': companyName,
      'operational_address': operationalAddress,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'website_url': websiteUrl,
      'operational_hours': operationalHours,
      'motto': motto,
      'legal_entity_number': legalEntityNumber,
    });
  }
}

