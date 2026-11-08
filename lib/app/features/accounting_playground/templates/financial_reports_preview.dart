import 'package:flutter/material.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import '../components.dart';
import '../models.dart';
import '../mock_data.dart';
import '../playground_controller.dart';

class FinancialReportsPreview extends StatefulWidget {
  const FinancialReportsPreview({super.key, required this.controller});
  final PlaygroundController controller;
  @override
  State<FinancialReportsPreview> createState() =>
      _FinancialReportsPreviewState();
}

class _FinancialReportsPreviewState extends State<FinancialReportsPreview> {
  int report = 0;
  DateTime? from, to;
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final source = c.transactions.where(
      (t) =>
          (from == null || !t.date.isBefore(from!)) &&
          (to == null || !t.date.isAfter(to!)),
    );
    final revenue = source
            .where((t) => t.type == 'income')
            .fold(const Money(0), (a, b) => a + b.amount),
        expenses = source
            .where((t) => t.type == 'expense')
            .fold(const Money(0), (a, b) => a + b.amount);
    final reports = AccountingMockData.reports(revenue, expenses);
    final r = reports[report];
    return BkColumn(
      children: [
        FiscalPeriodSelector(
          value: c.period,
          onChanged: (p) => c.loadPeriod(c.company, p),
        ),
        DropdownButtonFormField<int>(
          initialValue: report,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: tr(context, 'Report', 'التقرير'),
          ),
          items: [
            for (var i = 0; i < reports.length; i++)
              DropdownMenuItem(
                value: i,
                child: Text(
                  tr(context, reports[i].name, reports[i].arabicName),
                ),
              ),
          ],
          onChanged: (v) => setState(() => report = v!),
        ),
        Wrap(
          spacing: BkSpace.sm,
          runSpacing: BkSpace.sm,
          children: [
            OutlinedButton(
              onPressed: () async {
                final d = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2026, 12, 31),
                );
                if (d != null) {
                  setState(() {
                    from = d.start;
                    to = d.end;
                  });
                }
              },
              child: Text(
                from == null
                    ? tr(context, 'Report date range', 'نطاق تاريخ التقرير')
                    : '${dateLabel(context, from!)} – ${dateLabel(context, to!)}',
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                from = null;
                to = null;
              }),
              child: Text(tr(context, 'Clear dates', 'مسح التواريخ')),
            ),
            BkButton(
              label: tr(
                context,
                'Print / export preview',
                'معاينة الطباعة / التصدير',
              ),
              onPressed: () => showAccountingDocument(
                context,
                tr(context, r.name, r.arabicName),
                reportText(context, r),
              ),
            ),
          ],
        ),
        Text(
          tr(
            context,
            'Comparison: prior snapshot. Balance Sheet and Trial Balance use fixed opening/closing snapshots; P&L and Ledger use the filtered period.',
            'المقارنة: لقطة سابقة. الميزانية وميزان المراجعة لقطات ثابتة؛ الأرباح والأستاذ حسب الفترة المحددة.',
          ),
        ),
        FinancialReportViewer(report: r),
      ],
    );
  }
}

String reportText(BuildContext context, FinancialReport r) =>
    '${tr(context, r.name, r.arabicName)}\n${r.rows.map((row) => '${row.group} | ${tr(context, row.label, row.arabicLabel)} | ${row.current.format()} | ${row.comparison.format()}').join('\n')}';

class FinancialReportViewer extends StatelessWidget {
  const FinancialReportViewer({super.key, required this.report});
  final FinancialReport report;
  @override
  Widget build(BuildContext context) => BkColumn(
    children: [
      for (final group in report.rows.map((r) => r.group).toSet())
        BkCard(
          padding: const EdgeInsets.all(BkSpace.lg),
          child: BkColumn(
            children: [
              Text(group, style: Theme.of(context).textTheme.titleMedium),
              for (final r in report.rows.where((r) => r.group == group))
                BkColumn(
                  gap: BkSpace.xs,
                  children: [
                    Text(tr(context, r.label, r.arabicLabel)),
                    Wrap(
                      spacing: BkSpace.xl,
                      runSpacing: BkSpace.sm,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr(context, 'Current', 'الحالي')),
                            FinancialAmount(amount: r.current),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tr(context, 'Comparison', 'المقارنة')),
                            FinancialAmount(amount: r.comparison),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              if (report.rows.where((r) => r.group == group).length > 1) ...[
                const BkDivider(),
                Text(tr(context, 'Group total', 'إجمالي المجموعة')),
                FinancialAmount(
                  amount: report.rows
                      .where((r) => r.group == group)
                      .fold(const Money(0), (a, b) => a + b.current),
                ),
              ],
            ],
          ),
        ),
    ],
  );
}
