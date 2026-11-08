import 'package:flutter/material.dart';
import '../../../../config/l10n/app_localizations.dart';
import '../../../../config/theme.dart';

class TermsDialog extends StatelessWidget {
  final bool isPrivacy;

  const TermsDialog({super.key, this.isPrivacy = false});

  static void show(BuildContext context, {bool isPrivacy = false}) {
    showDialog(
      context: context,
      builder: (ctx) => TermsDialog(isPrivacy: isPrivacy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title =
        isPrivacy ? l10n.privacyPolicyTitle : l10n.termsOfServiceTitle;
    final content =
        isPrivacy ? l10n.privacyPolicyContent : l10n.termsOfServiceContent;

    return AlertDialog(
      backgroundColor: AppTheme.creamSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      title: Row(
        children: [
          Icon(
            isPrivacy ? Icons.privacy_tip_outlined : Icons.description_outlined,
            color: AppTheme.deepOrange,
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDarkBrown,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            color: AppTheme.textMediumBrown,
            height: 1.5,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.deepOrange,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}
