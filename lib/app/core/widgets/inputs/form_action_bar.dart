import 'package:flutter/material.dart';

/// Standardized action bar for form pages providing Cancel and Submit buttons
/// with uniform padding, disabled states, and saving spinner.
class FormActionBar extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onSubmit;
  final String cancelLabel;
  final String submitLabel;
  final String submittingLabel;
  final IconData submitIcon;
  final bool isSubmitting;
  final MainAxisAlignment alignment;

  const FormActionBar({
    super.key,
    this.onCancel,
    required this.onSubmit,
    this.cancelLabel = 'إلغاء',
    this.submitLabel = 'حفظ',
    this.submittingLabel = 'جارٍ الحفظ...',
    this.submitIcon = Icons.save_outlined,
    this.isSubmitting = false,
    this.alignment = MainAxisAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        if (onCancel != null) ...[
          OutlinedButton(
            onPressed: isSubmitting ? null : onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: Text(cancelLabel),
          ),
          const SizedBox(width: 16),
        ],
        FilledButton.icon(
          onPressed: isSubmitting ? null : onSubmit,
          icon: isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(submitIcon),
          label: Text(isSubmitting ? submittingLabel : submitLabel),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          ),
        ),
      ],
    );
  }
}
