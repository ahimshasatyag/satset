import 'package:flutter/material.dart';

class AdminNavItem {
  final IconData icon;
  final String label;
  final String route;
  final int? badgeCount;

  const AdminNavItem({
    required this.icon,
    required this.label,
    required this.route,
    this.badgeCount,
  });

  static const List<AdminNavItem> defaultItems = [
    AdminNavItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      route: '/admin/dashboard',
    ),
    AdminNavItem(
      icon: Icons.local_shipping_rounded,
      label: 'Pengiriman',
      route: '/admin/shipments',
    ),
    AdminNavItem(
      icon: Icons.two_wheeler_rounded,
      label: 'Kurir SatSet',
      route: '/admin/couriers',
    ),
    AdminNavItem(
      icon: Icons.people_alt_rounded,
      label: 'Pelanggan',
      route: '/admin/customers',
    ),
    AdminNavItem(
      icon: Icons.account_balance_wallet_rounded,
      label: 'Pembayaran',
      route: '/admin/payments',
    ),
    AdminNavItem(
      icon: Icons.inventory_2_rounded,
      label: 'Jenis Layanan',
      route: '/admin/services',
    ),
    AdminNavItem(
      icon: Icons.analytics_rounded,
      label: 'Laporan',
      route: '/admin/reports',
    ),
    AdminNavItem(
      icon: Icons.settings_rounded,
      label: 'Pengaturan',
      route: '/admin/settings',
    ),
  ];
}

