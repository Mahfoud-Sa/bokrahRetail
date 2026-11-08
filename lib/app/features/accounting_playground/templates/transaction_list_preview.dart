import 'package:flutter/material.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import '../components.dart';
import '../models.dart';
import '../playground_controller.dart';

class TransactionListPreview extends StatelessWidget {
  const TransactionListPreview({super.key, required this.controller});
  final PlaygroundController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller;
    return BkColumn(
      children: [
        BoundSearchField(
          value: c.query,
          key: const ValueKey('transaction-search'),
          decoration: InputDecoration(
            labelText: tr(context, 'Search transactions', 'البحث في المعاملات'),
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (v) => c.update(() {
            c.query = v;
            c.page = 0;
          }),
        ),
        LayoutBuilder(
          builder: (context, b) => Wrap(
            spacing: BkSpace.sm,
            runSpacing: BkSpace.sm,
            children: [
              SizedBox(
                width: b.maxWidth < 420
                    ? b.maxWidth
                    : (b.maxWidth - BkSpace.sm) / 2,
                child: _filter(
                  context,
                  tr(context, 'Status', 'الحالة'),
                  c.status,
                  ['all', 'pending', 'posted'],
                  (v) => c.update(() {
                    c.status = v;
                    c.page = 0;
                  }),
                ),
              ),
              SizedBox(
                width: b.maxWidth < 420
                    ? b.maxWidth
                    : (b.maxWidth - BkSpace.sm) / 2,
                child: _filter(
                  context,
                  tr(context, 'Type', 'النوع'),
                  c.type,
                  ['all', 'income', 'expense'],
                  (v) => c.update(() {
                    c.type = v;
                    c.page = 0;
                  }),
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: BkSpace.sm,
          runSpacing: BkSpace.sm,
          children: [
            OutlinedButton(
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2026),
                  lastDate: DateTime(2026, 12, 31),
                  initialDateRange: c.from == null
                      ? null
                      : DateTimeRange(start: c.from!, end: c.to!),
                );
                if (range != null) {
                  c.update(() {
                    c.from = range.start;
                    c.to = range.end;
                    c.page = 0;
                  });
                }
              },
              child: Text(
                c.from == null
                    ? tr(context, 'Date range', 'نطاق التاريخ')
                    : '${dateLabel(context, c.from!)} – ${dateLabel(context, c.to!)}',
              ),
            ),
            TextButton(
              onPressed: () => c.update(() {
                c.from = null;
                c.to = null;
                c.query = '';
                c.status = 'all';
                c.type = 'all';
                c.page = 0;
              }),
              child: Text(tr(context, 'Clear filters', 'مسح المرشحات')),
            ),
            OutlinedButton(
              onPressed: () => showAccountingDocument(
                context,
                tr(context, 'CSV export demonstration', 'عرض تصدير CSV'),
                [
                  'reference,date,type,status,amount_minor,currency',
                  ...c.filtered.map(
                    (t) =>
                        '${t.id},${t.date.toIso8601String().substring(0, 10)},${t.type},${t.status},${t.amount.minor},${t.amount.currency}',
                  ),
                ].join('\n'),
              ),
              child: Text(
                tr(context, 'Export filtered CSV', 'تصدير CSV للنتائج'),
              ),
            ),
          ],
        ),
        if (c.selected.isNotEmpty)
          Wrap(
            spacing: BkSpace.sm,
            children: [
              Text('${c.selected.length} ${tr(context, 'selected', 'محدد')}'),
              BkButton(
                label: tr(context, 'Approve selected', 'اعتماد المحدد'),
                onPressed: c.approveSelected,
              ),
              TextButton(
                onPressed: () => c.update(c.selected.clear),
                child: Text(tr(context, 'Clear selection', 'مسح التحديد')),
              ),
            ],
          ),
        AccountingTransactionTable(controller: c),
        Wrap(
          spacing: BkSpace.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: tr(context, 'Previous page', 'الصفحة السابقة'),
              onPressed: c.page > 0 ? () => c.update(() => c.page--) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('${c.page.clamp(0, c.pages - 1) + 1} / ${c.pages}'),
            IconButton(
              tooltip: tr(context, 'Next page', 'الصفحة التالية'),
              onPressed: c.page < c.pages - 1
                  ? () => c.update(() => c.page++)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }

  Widget _filter(
    BuildContext context,
    String label,
    String value,
    List<String> values,
    ValueChanged<String> onChange,
  ) => DropdownButtonFormField<String>(
    key: ValueKey('$label-$value'),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final v in values)
        DropdownMenuItem(
          value: v,
          child: Text(
            v == 'all'
                ? tr(context, 'All', 'الكل')
                : accountingLabel(v, controller.configuration.arabic),
          ),
        ),
    ],
    onChanged: (v) => onChange(v!),
  );
}

class AccountingTransactionTable extends StatelessWidget {
  const AccountingTransactionTable({super.key, required this.controller});
  final PlaygroundController controller;
  void _details(BuildContext context, Transaction t) => showAccountingDocument(
    context,
    t.id,
    '${tr(context, t.description, t.arabicDescription)}\n${dateLabel(context, t.date)}\n${accountingLabel(t.status, controller.configuration.arabic)}\n${t.amount.format(arabic: controller.configuration.arabic)}',
  );
  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c.filtered.isEmpty) {
      return AppEmptyState(
        onReset: () => c.update(() {
          c.query = '';
          c.status = 'all';
          c.type = 'all';
          c.from = null;
          c.to = null;
          c.page = 0;
        }),
      );
    }
    return LayoutBuilder(
      builder: (context, b) {
        void sort(int col, bool asc) => c.update(() {
          c.sortColumn = col;
          c.ascending = asc;
          c.page = 0;
        });
        if (b.maxWidth < 700) {
          return BkColumn(
            gap: c.configuration.compact ? BkSpace.xs : BkSpace.lg,
            children: [
              DropdownButtonFormField<int>(
                initialValue: c.sortColumn,
                decoration: InputDecoration(
                  labelText: tr(context, 'Sort by', 'ترتيب حسب'),
                ),
                items: [
                  DropdownMenuItem(
                    value: 0,
                    child: Text(tr(context, 'Reference', 'المرجع')),
                  ),
                  DropdownMenuItem(
                    value: 1,
                    child: Text(tr(context, 'Amount', 'المبلغ')),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Text(tr(context, 'Date', 'التاريخ')),
                  ),
                ],
                onChanged: (v) => sort(v!, c.ascending),
              ),
              TextButton.icon(
                onPressed: () => sort(c.sortColumn, !c.ascending),
                icon: Icon(
                  c.ascending ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                label: Text(
                  tr(
                    context,
                    c.ascending ? 'Ascending' : 'Descending',
                    c.ascending ? 'تصاعدي' : 'تنازلي',
                  ),
                ),
              ),
              for (final t in c.paged)
                BkCard(
                  padding: EdgeInsets.all(
                    c.configuration.compact ? BkSpace.sm : BkSpace.lg,
                  ),
                  child: BkColumn(
                    gap: BkSpace.sm,
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: c.selected.contains(t.id),
                        title: Text(t.id, textDirection: TextDirection.ltr),
                        subtitle: Text(
                          tr(context, t.description, t.arabicDescription),
                        ),
                        onChanged: (v) => c.update(() {
                          v == true
                              ? c.selected.add(t.id)
                              : c.selected.remove(t.id);
                        }),
                      ),
                      Text(dateLabel(context, t.date)),
                      FinancialAmount(amount: t.amount),
                      ApprovalStatusBadge(status: t.status),
                      TextButton(
                        onPressed: () => _details(context, t),
                        child: Text(
                          tr(context, 'View details', 'عرض التفاصيل'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        }
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            dataRowMinHeight: c.configuration.compact ? 48 : 64,
            dataRowMaxHeight: c.configuration.compact ? 56 : 80,
            sortColumnIndex: c.sortColumn,
            sortAscending: c.ascending,
            columns: [
              DataColumn(
                label: Text(tr(context, 'Reference', 'المرجع')),
                onSort: sort,
              ),
              DataColumn(
                numeric: true,
                label: Text(tr(context, 'Amount', 'المبلغ')),
                onSort: sort,
              ),
              DataColumn(
                label: Text(tr(context, 'Date', 'التاريخ')),
                onSort: sort,
              ),
              DataColumn(label: Text(tr(context, 'Status', 'الحالة'))),
              DataColumn(label: Text(tr(context, 'Details', 'التفاصيل'))),
            ],
            rows: [
              for (final t in c.paged)
                DataRow(
                  selected: c.selected.contains(t.id),
                  onSelectChanged: (v) => c.update(() {
                    v == true ? c.selected.add(t.id) : c.selected.remove(t.id);
                  }),
                  cells: [
                    DataCell(Text(t.id, textDirection: TextDirection.ltr)),
                    DataCell(FinancialAmount(amount: t.amount)),
                    DataCell(Text(dateLabel(context, t.date))),
                    DataCell(ApprovalStatusBadge(status: t.status)),
                    DataCell(
                      IconButton(
                        tooltip: tr(context, 'View details', 'عرض التفاصيل'),
                        onPressed: () => _details(context, t),
                        icon: const Icon(Icons.open_in_new),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
