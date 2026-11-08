import 'package:flutter/material.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import '../components.dart';
import '../models.dart';
import '../mock_data.dart';
import '../playground_controller.dart';
import 'invoice_management_preview.dart';

class DashboardPreview extends StatelessWidget {
  const DashboardPreview({super.key, required this.controller});
  final PlaygroundController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    final metrics = [
      (tr(context, 'Total revenue', 'إجمالي الإيرادات'), c.revenue),
      (tr(context, 'Total expenses', 'إجمالي المصروفات'), c.expenses),
      (tr(context, 'Net profit', 'صافي الربح'), c.revenue - c.expenses),
      (
        tr(context, 'Receivables', 'الذمم المدينة'),
        AccountingMockData.invoices.fold(const Money(0), (a, b) => a + b.due),
      ),
      (tr(context, 'Payables', 'الذمم الدائنة'), const Money(390000)),
      (
        tr(context, 'Cash balance', 'رصيد النقد'),
        const Money(190000) + c.revenue - c.expenses,
      ),
      (tr(context, 'Bank balance', 'رصيد البنك'), const Money(700000)),
    ];
    return BkColumn(
      children: [
        FiscalPeriodSelector(
          value: c.period,
          onChanged: (p) => c.loadPeriod(c.company, p),
        ),
        LayoutBuilder(
          builder: (context, box) => Wrap(
            spacing: BkSpace.md,
            runSpacing: BkSpace.md,
            children: [
              for (final m in metrics)
                SizedBox(
                  width: box.maxWidth < 450
                      ? box.maxWidth
                      : (box.maxWidth - BkSpace.md) / 2,
                  child: FinancialKpiCard(label: m.$1, value: m.$2),
                ),
            ],
          ),
        ),
        BkBadge(
          label:
              '${tr(context, 'Pending approvals', 'موافقات معلقة')}: ${c.transactions.where((t) => t.status == 'pending').length}',
          tone: BkTone.warning,
        ),
        Directionality(
          textDirection: TextDirection.ltr,
          child: BkBarChart(
            label: tr(
              context,
              'Revenue versus expenses',
              'الإيرادات مقابل المصروفات',
            ),
            emptyLabel: tr(context, 'No data', 'لا توجد بيانات'),
            values: [
              BkChartValue(
                label: tr(context, 'Revenue', 'الإيرادات'),
                value: c.revenue.minor.toDouble(),
                displayValue: c.revenue.format(arabic: c.configuration.arabic),
              ),
              BkChartValue(
                label: tr(context, 'Expenses', 'المصروفات'),
                value: c.expenses.minor.toDouble(),
                displayValue: c.expenses.format(arabic: c.configuration.arabic),
              ),
            ],
          ),
        ),
        BkSectionHeader(title: tr(context, 'Quick actions', 'إجراءات سريعة')),
        Wrap(
          spacing: BkSpace.sm,
          runSpacing: BkSpace.sm,
          children: [
            for (final layout in [
              AccountingLayout.journal,
              AccountingLayout.invoices,
              AccountingLayout.reports,
            ])
              BkButton(
                label: layoutLabel(layout, c.configuration.arabic),
                onPressed: () =>
                    c.update(() => c.configuration.layout = layout),
              ),
          ],
        ),
        BkSectionHeader(
          title: tr(context, 'Recent journal entries', 'قيود اليومية الأخيرة'),
        ),
        for (final t in c.transactions.take(3))
          AccountingRecordTile(
            title: t.id,
            subtitle: tr(context, t.description, t.arabicDescription),
            trailing: FinancialAmount(amount: t.amount),
            onTap: () => showAccountingDocument(
              context,
              t.id,
              '${tr(context, t.description, t.arabicDescription)}\n${t.amount.format(arabic: c.configuration.arabic)}\n${dateLabel(context, t.date)}',
            ),
          ),
        BkSectionHeader(
          title: tr(context, 'Recent invoices', 'الفواتير الأخيرة'),
        ),
        for (final i in AccountingMockData.invoices)
          AccountingRecordTile(
            title: i.id,
            subtitle: tr(context, i.party, i.arabicParty),
            trailing: FinancialAmount(amount: i.total),
            onTap: () =>
                showAccountingDocument(context, i.id, invoiceText(context, i)),
          ),
      ],
    );
  }
}
