import 'package:flutter/material.dart';
import 'package:satset/shared/theme/theme.dart';
import '../../domain/entities/recipient_relationship.dart';

/// Kartu formulir data penyerahan: nama penerima aktual, relasi penerima,
/// catatan opsional, dan status koordinat lokasi GPS
class DeliveryProofFormCard extends StatefulWidget {
  final String initialRecipientName;
  final RecipientRelationship selectedRelationship;
  final String notes;
  final double? latitude;
  final double? longitude;
  final bool isCapturingGps;
  final ValueChanged<String> onRecipientNameChanged;
  final ValueChanged<RecipientRelationship> onRelationshipChanged;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback onRefreshGps;
  final bool hasNameError;

  const DeliveryProofFormCard({
    super.key,
    required this.initialRecipientName,
    required this.selectedRelationship,
    required this.notes,
    this.latitude,
    this.longitude,
    this.isCapturingGps = false,
    required this.onRecipientNameChanged,
    required this.onRelationshipChanged,
    required this.onNotesChanged,
    required this.onRefreshGps,
    this.hasNameError = false,
  });

  @override
  State<DeliveryProofFormCard> createState() => _DeliveryProofFormCardState();
}

class _DeliveryProofFormCardState extends State<DeliveryProofFormCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialRecipientName);
    _notesController = TextEditingController(text: widget.notes);
  }

  @override
  void didUpdateWidget(covariant DeliveryProofFormCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRecipientName != widget.initialRecipientName &&
        _nameController.text != widget.initialRecipientName) {
      _nameController.text = widget.initialRecipientName;
    }
    if (oldWidget.notes != widget.notes && _notesController.text != widget.notes) {
      _notesController.text = widget.notes;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasCoords = widget.latitude != null && widget.longitude != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul bagian
          Row(
            children: [
              const Icon(
                Icons.assignment_turned_in_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'DATA PENYERAHAN PAKET',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Input Nama Penerima Aktual
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nama Penerima Aktual *',
              hintText: 'Nama lengkap orang yang menerima paket',
              prefixIcon: const Icon(Icons.person_rounded, size: 20),
              errorText: widget.hasNameError ? 'Nama penerima wajib diisi' : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: widget.onRecipientNameChanged,
          ),
          const SizedBox(height: 16),

          // Pilihan Hubungan Penerima
          Text(
            'Hubungan Penerima dengan Tujuan:',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: RecipientRelationship.values.map((rel) {
              final isSelected = widget.selectedRelationship == rel;
              return ChoiceChip(
                label: Text(
                  rel.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariantLight,
                onSelected: (_) => widget.onRelationshipChanged(rel),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Input Catatan Opsional
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Catatan Penyerahan (Opsional)',
              hintText: 'Contoh: Diterima oleh satpam pos gerbang depan',
              prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: widget.onNotesChanged,
          ),
          const SizedBox(height: 16),

          // Status Lokasi GPS Penyerahan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight)
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasCoords ? Icons.my_location_rounded : Icons.location_searching_rounded,
                  size: 18,
                  color: hasCoords ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasCoords ? 'Koordinat Penyerahan Terkunci' : 'GPS Belum Terkunci',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: hasCoords ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      Text(
                        hasCoords
                            ? '${widget.latitude!.toStringAsFixed(5)}, ${widget.longitude!.toStringAsFixed(5)}'
                            : 'Koordinat akan ditautkan otomatis bila izin GPS aktif.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Perbarui Koordinat GPS',
                  icon: widget.isCapturingGps
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: widget.isCapturingGps ? null : widget.onRefreshGps,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
