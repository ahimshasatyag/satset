import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';

class AdminDropdownOption<T> {
  final T value;
  final String label;

  const AdminDropdownOption({
    required this.value,
    required this.label,
  });
}

/// Widget Dropdown bergaya Select2 (memiliki kotak input pencarian di bagian atas daftar pilihan
/// yang muncul tepat di bawah kotak utama saat diklik, sesuai referensi gambar).
class AdminSearchableDropdown<T> extends StatefulWidget {
  final T value;
  final List<AdminDropdownOption<T>> options;
  final ValueChanged<T> onChanged;
  final String? hintText;
  final String searchHintText;
  final double? width;
  final double menuMaxHeight;
  final String? labelText;

  const AdminSearchableDropdown({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.hintText,
    this.searchHintText = 'Cari...',
    this.width,
    this.menuMaxHeight = 260,
    this.labelText,
  });

  @override
  State<AdminSearchableDropdown<T>> createState() =>
      _AdminSearchableDropdownState<T>();
}

class _AdminSearchableDropdownState<T>
    extends State<AdminSearchableDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _portalController = OverlayPortalController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey _triggerKey = GlobalKey();

  String _searchQuery = '';
  double _triggerWidth = 200;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_portalController.isShowing) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final renderBox =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      _triggerWidth = renderBox.size.width;
    }
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    _portalController.show();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _closeDropdown() {
    if (_portalController.isShowing) {
      _portalController.hide();
      setState(() {});
    }
  }

  String _getSelectedLabel() {
    for (final opt in widget.options) {
      if (opt.value == widget.value) {
        return opt.label;
      }
    }
    return widget.hintText ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOpen = _portalController.isShowing;

    final filteredOptions = widget.options.where((opt) {
      if (_searchQuery.trim().isEmpty) return true;
      return opt.label
          .toLowerCase()
          .contains(_searchQuery.trim().toLowerCase());
    }).toList();

    final activeFocusColor =
        isDark ? AppColors.borderFocusDark : AppColors.borderFocusLight;

    Widget dropdownTrigger = CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: (overlayContext) {
          // Lebar popup mengikuti lebar kotak trigger persis agar sejajar (tidak melebar melebihi kotak)
          final popupWidth = _triggerWidth;
          return Stack(
            children: [
              // Area transparan penutup saat klik di luar dropdown
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _closeDropdown,
                  child: const SizedBox.expand(),
                ),
              ),
              CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 2),
                child: Material(
                  elevation: 6,
                  color: isDark ? AppColors.surfaceDark : AppColors.white,
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: SizedBox(
                    width: popupWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Kotak Input Pencarian di bagian atas dalam dropdown (sesuai gambar & theme)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: SizedBox(
                            height: 36,
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              cursorColor: activeFocusColor,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: widget.searchHintText,
                                hintStyle: AppTextStyles.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: activeFocusColor.withValues(alpha: 0.7),
                                    width: 1.2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: activeFocusColor,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Daftar Pilihan di bawah kotak input pencarian
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: widget.menuMaxHeight,
                          ),
                          child: filteredOptions.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                  child: Text(
                                    'Data tidak ditemukan',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.only(bottom: 6),
                                  shrinkWrap: true,
                                  itemCount: filteredOptions.length,
                                  itemBuilder: (ctx, index) {
                                    final item = filteredOptions[index];
                                    final isSelected =
                                        item.value == widget.value;

                                    return InkWell(
                                      onTap: () {
                                        widget.onChanged(item.value);
                                        _closeDropdown();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        color: isSelected
                                            ? AppColors.primary.withValues(
                                                alpha: isDark ? 0.22 : 0.1,
                                              )
                                            : Colors.transparent,
                                        child: Text(
                                          item.label,
                                          style:
                                              AppTextStyles.bodySmall.copyWith(
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? activeFocusColor
                                                : (isDark
                                                    ? AppColors.textPrimaryDark
                                                    : AppColors
                                                        .textPrimaryLight),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: InkWell(
          key: _triggerKey,
          onTap: _toggleDropdown,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: widget.width,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isOpen
                    ? activeFocusColor
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                width: isOpen ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize:
                  widget.width != null ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _getSelectedLabel(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isOpen
                      ? Icons.arrow_drop_up_rounded
                      : Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: isOpen
                      ? activeFocusColor
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.labelText != null && widget.labelText!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.labelText!,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          dropdownTrigger,
        ],
      );
    }

    return dropdownTrigger;
  }
}

