import 'package:flutter/material.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import '../components.dart';
import '../playground_controller.dart';

class MasterDetailPreview extends StatefulWidget {
  const MasterDetailPreview({super.key, required this.controller});
  final PlaygroundController controller;
  @override
  State<MasterDetailPreview> createState() => _MasterDetailPreviewState();
}

class _MasterDetailPreviewState extends State<MasterDetailPreview> {
  String? selectedId;
  @override
  Widget build(BuildContext context) {
    final entries = widget.controller.transactions;
    final selected = entries.where((t) => t.id == selectedId).firstOrNull;
    final list = BkColumn(
      children: [
        for (final t in entries.take(12))
          ListTile(
            selected: t.id == selectedId,
            title: Text(t.id),
            subtitle: Text(tr(context, t.description, t.arabicDescription)),
            onTap: () => setState(() => selectedId = t.id),
          ),
      ],
    );
    final detail = selected == null
        ? Text(tr(context, 'Select a transaction', 'اختر معاملة'))
        : BkCard(
            child: BkColumn(
              children: [
                Text(selected.id),
                Text(
                  tr(context, selected.description, selected.arabicDescription),
                ),
                Text(dateLabel(context, selected.date)),
                ApprovalStatusBadge(status: selected.status),
                FinancialAmount(amount: selected.amount),
              ],
            ),
          );
    return LayoutBuilder(
      builder: (context, b) {
        if (b.maxWidth >= 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: list),
              const SizedBox(width: BkSpace.lg),
              Expanded(child: detail),
            ],
          );
        }
        return selected == null
            ? list
            : BkColumn(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => selectedId = null),
                    icon: const BackButtonIcon(),
                    label: Text(tr(context, 'Back to list', 'العودة للقائمة')),
                  ),
                  detail,
                ],
              );
      },
    );
  }
}
