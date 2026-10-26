import 'package:flutter/material.dart';
import 'package:satset/features/courier/delivery_proof/presentation/pages/courier_delivery_proof_page.dart';
import 'package:satset/shared/theme/theme.dart';
import 'package:satset/shared/widgets/widgets.dart';
import '../../domain/entities/status_transition_option.dart';
import '../../domain/entities/task_status_detail.dart';
import 'task_status_failure_dialog.dart';

class TaskStatusActionBar extends StatelessWidget {
  final TaskStatusDetail detail;
  final bool isUpdating;
  final Function(StatusTransitionOption transition, {String? failureReason, String? notes})
      onUpdateStatus;
  final VoidCallback? onDeliveryCompleted;

  const TaskStatusActionBar({
    super.key,
    required this.detail,
    required this.isUpdating,
    required this.onUpdateStatus,
    this.onDeliveryCompleted,
  });

  void _showConfirmationDialog({
    required BuildContext context,
    required StatusTransitionOption transition,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Konfirmasi Status',
              style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda yakin ingin mengubah status pengiriman menjadi "${transition.statusName}"?',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              transition.description,
              style: AppTextStyles.labelSmall.copyWith(
                color: textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onUpdateStatus(transition);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Perbarui'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    if (detail.isCompleted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: borderColor,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Text(
              'Tugas telah diselesaikan.',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    final transitions = detail.validNextTransitions;
    if (transitions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -3),
            blurRadius: 8,
          ),
        ],
        border: Border(
          top: BorderSide(
            color: borderColor,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isUpdating)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text('Menyimpan perubahan ke backend...'),
                  ],
                ),
              )
            else
              Row(
                children: transitions.map((transition) {
                  final isProof = transition.requiresProof;
                  final isFailure = transition.requiresFailureReason;

                  if (isFailure) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: OutlinedButton(
                          onPressed: () {
                            TaskStatusFailureDialog.show(
                              context: context,
                              onConfirm: (reason, notes) {
                                onUpdateStatus(
                                  transition,
                                  failureReason: reason,
                                  notes: notes,
                                );
                              },
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            transition.actionTitle,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  if (isProof) {
                    return Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: CustomButton(
                          text: transition.actionTitle,
                          prefixIcon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              SmoothPageRoute(
                                child: CourierDeliveryProofPage(
                                  initialShipmentId: detail.shipmentId,
                                ),
                              ),
                            );
                            onDeliveryCompleted?.call();
                          },
                        ),
                      ),
                    );
                  }

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: CustomButton(
                        text: transition.actionTitle,
                        isFullWidth: true,
                        onPressed: () {
                          _showConfirmationDialog(
                            context: context,
                            transition: transition,
                          );
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
