import 'package:flutter/material.dart';
import '../../../../shared/theme/theme.dart';

class AccountMenuCard extends StatelessWidget {
  final List<Widget> children;

  const AccountMenuCard({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: isDark ? 2 : 1,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
      child: Column(children: children),
    );
  }
}
