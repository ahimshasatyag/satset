import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Komponen Dropdown interaktif dengan fitur pencarian teks real-time,
/// animasi ekspansi, tombol clear pencarian ('X'), ikon panah dinamis (^/v),
/// dan estetika modern berstandar SatSet (rounded card, soft shadow, dark mode support).
class SearchableDropdown<T> extends StatefulWidget {
  /// Label judul di atas dropdown (opsional)
  final String? label;

  /// Penanda apakah field ini wajib diisi (*)
  final bool isRequired;

  /// Teks placeholder di baris header saat belum ada opsi yang dipilih (e.g. 'Select job role' atau 'Pilih Provinsi')
  final String hintText;

  /// Teks placeholder di dalam kolom pencarian (default 'Search')
  final String searchHint;

  /// Nilai opsi yang saat ini sedang terpilih
  final T? value;

  /// Daftar seluruh opsi yang dapat dipilih
  final List<T> items;

  /// Fungsi untuk menghasilkan teks tampilan dari objek opsi [T]
  final String Function(T) itemLabel;

  /// Fungsi opsional untuk menghasilkan teks sub-label dari objek opsi [T]
  final String Function(T)? itemSubtitle;

  /// Callback yang dipanggil saat pengguna memilih sebuah opsi
  final ValueChanged<T?>? onChanged;

  /// Status apakah dropdown aktif dapat diklik
  final bool enabled;

  /// Ketinggian maksimum area daftar opsi saat dropdown terbuka
  final double maxListHeight;

  /// Pesan yang ditampilkan jika pencarian tidak menemukan hasil
  final String emptyMessage;

  /// Fungsi filter pencarian kustom (opsional)
  final bool Function(T item, String query)? onSearch;

  /// Penimpa mode gelap (opsional, jika null akan dideteksi otomatis dari theme)
  final bool? isDark;

  const SearchableDropdown({
    super.key,
    this.label,
    this.isRequired = false,
    this.hintText = 'Select job role',
    this.searchHint = 'Search',
    required this.value,
    required this.items,
    required this.itemLabel,
    this.itemSubtitle,
    this.onChanged,
    this.enabled = true,
    this.maxListHeight = 220.0,
    this.emptyMessage = 'Tidak ada data ditemukan',
    this.onSearch,
    this.isDark,
  });

  @override
  State<SearchableDropdown<T>> createState() => _SearchableDropdownState<T>();
}

class _SearchableDropdownState<T> extends State<SearchableDropdown<T>> {
  bool _isExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (!widget.enabled || widget.items.isEmpty) return;

    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        // Otomatis fokus ke kolom pencarian setelah animasi terbuka
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _searchFocusNode.requestFocus();
          }
        });
      } else {
        _searchController.clear();
        _searchFocusNode.unfocus();
      }
    });
  }

  void _selectItem(T item) {
    widget.onChanged?.call(item);
    setState(() {
      _isExpanded = false;
      _searchController.clear();
      _searchFocusNode.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = widget.isDark ?? (theme.brightness == Brightness.dark);

    final query = _searchController.text.trim().toLowerCase();
    final filteredItems = query.isEmpty
        ? widget.items
        : widget.items.where((item) {
            if (widget.onSearch != null) {
              return widget.onSearch!(item, query);
            }
            return widget.itemLabel(item).toLowerCase().contains(query);
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label di atas container (jika ada)
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkTheme
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
              if (widget.isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],

        // Container Card Dropdown Utama
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isDarkTheme ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isExpanded
                  ? AppColors.primary
                  : (isDarkTheme
                      ? AppColors.borderDark
                      : const Color(0xFFE2E8F0)),
              width: _isExpanded ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDarkTheme ? 0.35 : (_isExpanded ? 0.08 : 0.03),
                ),
                blurRadius: _isExpanded ? 16 : 8,
                offset: Offset(0, _isExpanded ? 4 : 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Baris Header: Teks Nilai Terpilih / Hint + Ikon Chevron Panah (^/v)
              InkWell(
                onTap: _toggleDropdown,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.value != null
                            ? widget.itemLabel(widget.value as T)
                            : widget.hintText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: widget.value != null
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: widget.value != null
                              ? (isDarkTheme
                                  ? Colors.white
                                  : AppColors.textPrimaryLight)
                              : (isDarkTheme
                                  ? Colors.white38
                                  : const Color(0xFF94A3B8)),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: isDarkTheme
                          ? Colors.white70
                          : const Color(0xFF1E293B),
                    ),
                  ],
                ),
              ),

              // Bagian yang Terbuka: Search Field & Daftar Opsi
              if (_isExpanded) ...[
                const SizedBox(height: 12),

                // Kolom Input Pencarian dengan Ikon Kaca Pembesar & Tombol 'X'
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDarkTheme
                        ? const Color(0xFF1B2A3D)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDarkTheme
                          ? AppColors.borderDark
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkTheme
                                ? Colors.white
                                : AppColors.textPrimaryLight,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.searchHint,
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_searchController.text.isNotEmpty) {
                            _searchController.clear();
                            setState(() {});
                          }
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: _searchController.text.isNotEmpty
                              ? (isDarkTheme
                                  ? Colors.white70
                                  : const Color(0xFF64748B))
                              : (isDarkTheme
                                  ? Colors.white24
                                  : const Color(0xFFCBD5E1)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Daftar Opsi yang Ditemukan
                if (filteredItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        widget.emptyMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkTheme
                              ? Colors.white54
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: widget.maxListHeight,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: isDarkTheme
                            ? AppColors.borderDark.withValues(alpha: 0.5)
                            : const Color(0xFFF1F5F9),
                      ),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isSelected = widget.value == item;

                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _selectItem(item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 11,
                              horizontal: 6,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.itemLabel(item),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.primary
                                              : (isDarkTheme
                                                  ? Colors.white
                                                  : const Color(0xFF1E293B)),
                                        ),
                                      ),
                                      if (widget.itemSubtitle != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          widget.itemSubtitle!(item),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDarkTheme
                                                ? Colors.white54
                                                : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
