import 'package:flutter/material.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import '../components.dart';
import '../models.dart';
import '../mock_data.dart';
import '../playground_controller.dart';

class JournalEntryPreview extends StatelessWidget {
  const JournalEntryPreview({super.key, required this.controller});
  final PlaygroundController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    Money? debit, credit;
    try {
      debit = c.debit;
      credit = c.credit;
    } on FormatException {
      /* Invalid text stays editable and is explained below. */
    }
    return BkColumn(
      children: [
        Text(c.journal.reference, textDirection: TextDirection.ltr),
        Wrap(
          spacing: BkSpace.sm,
          runSpacing: BkSpace.sm,
          children: [
            OutlinedButton(
              onPressed: c.journalPosted
                  ? null
                  : () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: c.journal.date,
                        firstDate: DateTime(2026),
                        lastDate: DateTime(2026, 12, 31),
                      );
                      if (d != null) {
                        c.update(
                          () => c.journal = JournalEntry(
                            reference: c.journal.reference,
                            date: d,
                            period:
                                '2026-${d.month.toString().padLeft(2, '0')}',
                            description: c.journal.description,
                            lines: c.journal.lines,
                          ),
                        );
                      }
                    },
              child: Text(dateLabel(context, c.journal.date)),
            ),
            Text(
              '${tr(context, 'Fiscal period', 'الفترة المالية')}: ${c.journal.period}',
            ),
          ],
        ),
        TextFormField(
          key: ValueKey(c.journal),
          initialValue: c.journal.description,
          enabled: !c.journalPosted,
          decoration: InputDecoration(
            labelText: tr(context, 'Journal description', 'وصف القيد'),
          ),
          onChanged: (v) => c.update(() => c.journal.description = v),
        ),
        JournalEntryGrid(controller: c),
        if (debit != null && credit != null)
          BalanceSummary(debit: debit, credit: credit)
        else
          Text(
            tr(
              context,
              'Invalid amount. Use at most 2 decimal places.',
              'مبلغ غير صالح. استخدم منزلتين عشريتين كحد أقصى.',
            ),
          ),
        if (c.journalMessage != null)
          Semantics(liveRegion: true, child: Text(c.journalMessage!)),
        Wrap(
          spacing: BkSpace.sm,
          runSpacing: BkSpace.sm,
          children: [
            BkButton(
              label: tr(context, 'Save draft', 'حفظ مسودة'),
              onPressed: c.journalPosted
                  ? null
                  : () async {
                      if (!await AppAccessGuard.requireStore(
                        context: context,
                        returnRoute: '/home',
                      )) {
                        return;
                      }
                      c.saveDraft();
                    },
              variant: BkButtonVariant.secondary,
            ),
            BkButton(
              label: tr(context, 'Post entry', 'ترحيل القيد'),
              onPressed: c.journalPosted
                  ? null
                  : () async {
                      if (!await AppAccessGuard.requireStore(
                        context: context,
                        returnRoute: '/home',
                      )) {
                        return;
                      }
                      c.postJournal();
                    },
            ),
            BkButton(
              label: tr(context, 'Cancel / reset', 'إلغاء / إعادة تعيين'),
              onPressed: c.cancelJournal,
              variant: BkButtonVariant.tertiary,
            ),
          ],
        ),
        if (!c.journalPosted &&
            c.validateJournal(c.configuration.arabic) != null)
          Text(
            c.validateJournal(c.configuration.arabic)!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}

class JournalEntryGrid extends StatelessWidget {
  const JournalEntryGrid({super.key, required this.controller});
  final PlaygroundController controller;
  @override
  Widget build(BuildContext context) => BkColumn(
    children: [
      for (var i = 0; i < controller.journal.lines.length; i++)
        _line(context, controller.journal.lines[i], i),
      BkButton(
        label: tr(context, 'Add entry row', 'إضافة سطر'),
        icon: Icons.add,
        onPressed: controller.journalPosted
            ? null
            : () => controller.update(
                () => controller.journal.lines.add(JournalEntryLine()),
              ),
      ),
    ],
  );
  Widget _line(
    BuildContext context,
    JournalEntryLine line,
    int index,
  ) => BkCard(
    key: ObjectKey(line),
    padding: const EdgeInsets.all(BkSpace.md),
    child: BkColumn(
      children: [
        DropdownButtonFormField<String>(
          initialValue: line.account,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: '${tr(context, 'Account', 'الحساب')} ${index + 1}',
          ),
          items: [
            for (final a in AccountingMockData.accounts.where((a) => a.active))
              DropdownMenuItem(
                value: a.code,
                child: Text('${a.code} · ${tr(context, a.name, a.arabicName)}'),
              ),
          ],
          onChanged: controller.journalPosted
              ? null
              : (v) => controller.update(() => line.account = v!),
        ),
        Row(
          children: [
            Expanded(
              child: DebitCreditInput(
                label: '${tr(context, 'Debit', 'مدين')} ${index + 1}',
                value: line.debit,
                enabled: !controller.journalPosted,
                onChanged: (v) => controller.update(() => line.debit = v),
              ),
            ),
            const SizedBox(width: BkSpace.sm),
            Expanded(
              child: DebitCreditInput(
                label: '${tr(context, 'Credit', 'دائن')} ${index + 1}',
                value: line.credit,
                enabled: !controller.journalPosted,
                onChanged: (v) => controller.update(() => line.credit = v),
              ),
            ),
          ],
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: IconButton(
            tooltip: '${tr(context, 'Remove row', 'حذف السطر')} ${index + 1}',
            onPressed: controller.journalPosted
                ? null
                : () => controller.update(
                    () => controller.journal.lines.remove(line),
                  ),
            icon: const Icon(Icons.delete_outline),
          ),
        ),
      ],
    ),
  );
}
