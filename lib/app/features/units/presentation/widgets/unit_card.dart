import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/units/domain/entities/unit_entity.dart';

/// Displays a single measurement unit with its conversion factor and actions.
class UnitCard extends StatelessWidget {
  final UnitEntity unit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const UnitCard({
    super.key,
    required this.unit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isBaseUnit = unit.factor == 1.0;

    return Card(
      elevation: 0.5,
      margin: const EdgeInsetsDirectional.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.actionBlue.withValues(alpha: 0.12),
          child: const Icon(
            Icons.straighten_rounded,
            color: AppTheme.actionBlue,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                unit.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isBaseUnit) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.baseUnitBadge,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.success,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsetsDirectional.only(top: 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${l10n.factorPrefix} ${unit.factor}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (unit.barcodes.isNotEmpty)
                Container(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.actionBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${unit.barcodes.length} ${l10n.barcodesCountLabel}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.actionBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: l10n.editUnit,
              color: AppTheme.actionBlue,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: l10n.deleteUnit,
              color: AppTheme.error,
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
