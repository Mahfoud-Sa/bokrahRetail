import 'package:flutter/material.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import '../components.dart';
import '../models.dart';
import '../mock_data.dart';

String invoiceText(BuildContext context, Invoice i) =>
    '${i.id} · ${tr(context, i.party, i.arabicParty)}\n${i.lines.map((l) => '${tr(context, l.name, l.arabicName)} × ${l.quantity} = ${l.total.format()}').join('\n')}\n${tr(context, 'Subtotal', 'المجموع الفرعي')}: ${i.subtotal.format()}\n${tr(context, 'Discount', 'الخصم')}: ${i.discount.format()}\n${tr(context, 'Tax', 'الضريبة')}: ${i.tax.format()}\n${tr(context, 'Grand total', 'الإجمالي')}: ${i.total.format()}\n${tr(context, 'Paid', 'المدفوع')}: ${i.paid.format()}\n${tr(context, 'Due', 'المستحق')}: ${i.due.format()}';

class InvoiceManagementPreview extends StatefulWidget {
  const InvoiceManagementPreview({super.key});
  @override
  State<InvoiceManagementPreview> createState() =>
      _InvoiceManagementPreviewState();
}

class _InvoiceManagementPreviewState extends State<InvoiceManagementPreview> {
  Invoice selected = AccountingMockData.invoices.first;
  @override
  Widget build(BuildContext context) => BkColumn(
    children: [
      for (final i in AccountingMockData.invoices)
        AccountingRecordTile(
          title: i.id,
          subtitle: tr(context, i.party, i.arabicParty),
          trailing: ApprovalStatusBadge(status: i.status),
          onTap: () => setState(() => selected = i),
        ),
      InvoiceDetails(invoice: selected),
    ],
  );
}

class InvoiceDetails extends StatelessWidget {
  const InvoiceDetails({super.key, required this.invoice});
  final Invoice invoice;
  @override
  Widget build(BuildContext context) {
    final i = invoice;
    return BkCard(
      child: BkColumn(
        children: [
          Text(
            '${i.id} · ${tr(context, i.party, i.arabicParty)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ApprovalStatusBadge(status: i.status),
          for (final l in i.lines)
            BkColumn(
              gap: BkSpace.xs,
              children: [
                Text('${tr(context, l.name, l.arabicName)} × ${l.quantity}'),
                FinancialAmount(amount: l.unitPrice),
                FinancialAmount(amount: l.total),
              ],
            ),
          const BkDivider(),
          for (final value in [
            (tr(context, 'Subtotal', 'المجموع الفرعي'), i.subtotal),
            (tr(context, 'Discount', 'الخصم'), i.discount),
            (tr(context, 'Tax (10%)', 'الضريبة (١٠٪)'), i.tax),
            (tr(context, 'Grand total', 'الإجمالي'), i.total),
            (tr(context, 'Paid', 'المدفوع'), i.paid),
            (tr(context, 'Due', 'المستحق'), i.due),
          ])
            Wrap(
              spacing: BkSpace.lg,
              children: [
                Text(value.$1),
                FinancialAmount(amount: value.$2),
              ],
            ),
          BkButton(
            label: tr(
              context,
              'Preview / print document',
              'معاينة / طباعة المستند',
            ),
            onPressed: () =>
                showAccountingDocument(context, i.id, invoiceText(context, i)),
          ),
        ],
      ),
    );
  }
}
