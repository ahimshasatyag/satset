import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';

class SettingsTabItem {
  final int index;
  final String label;
  final String subtitle;
  final IconData icon;

  const SettingsTabItem({
    required this.index,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}

class SettingsTabNavigation extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTabSelected;

  const SettingsTabNavigation({
    super.key,
    required this.activeIndex,
    required this.onTabSelected,
  });

  static const List<SettingsTabItem> tabs = [
    SettingsTabItem(
      index: 0,
      label: 'Profil Administrator',
      subtitle: 'm_employee (id_users_role = 1)',
      icon: Icons.person_outline_rounded,
    ),
    SettingsTabItem(
      index: 1,
      label: 'Informasi Perusahaan',
      subtitle: 'Identitas & kontak resmi SatSet',
      icon: Icons.business_outlined,
    ),
    SettingsTabItem(
      index: 2,
      label: 'Operasional Pengiriman',
      subtitle: 'm_service_types & SLA pengiriman',
      icon: Icons.local_shipping_outlined,
    ),
    SettingsTabItem(
      index: 3,
      label: 'Preferensi Notifikasi',
      subtitle: 't_notifications & pemberitahuan',
      icon: Icons.notifications_none_rounded,
    ),
    SettingsTabItem(
      index: 4,
      label: 'Keamanan & Sesi Akun',
      subtitle: 'Kata sandi & Supabase Auth',
      icon: Icons.shield_outlined,
    ),
    SettingsTabItem(
      index: 5,
      label: 'Informasi Sistem',
      subtitle: 'Spesifikasi & koneksi database',
      icon: Icons.info_outline_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isHorizontal = constraints.maxWidth > 900;

          if (isHorizontal) {
            return Row(
              children: tabs.map((tab) {
                final isSelected = activeIndex == tab.index;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _TabButton(
                      tab: tab,
                      isSelected: isSelected,
                      colorScheme: colorScheme,
                      theme: theme,
                      onTap: () => onTabSelected(tab.index),
                    ),
                  ),
                );
              }).toList(),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: tabs.map((tab) {
                final isSelected = activeIndex == tab.index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 200,
                    child: _TabButton(
                      tab: tab,
                      isSelected: isSelected,
                      colorScheme: colorScheme,
                      theme: theme,
                      onTap: () => onTabSelected(tab.index),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final SettingsTabItem tab;
  final bool isSelected;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onTap;

  const _TabButton({
    required this.tab,
    required this.isSelected,
    required this.colorScheme,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.08)
              : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colorScheme.primary : theme.dividerColor,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              tab.icon,
              size: 20,
              color: isSelected ? colorScheme.primary : theme.iconTheme.color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tab.label,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tab.subtitle,
                    style: AppTextStyles.bodySmall.copyWith(fontSize: 10.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

