import 'package:flutter/material.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import '../components.dart';
import '../models.dart';
import '../mock_data.dart';
import '../playground_controller.dart';

class ChartOfAccountsPreview extends StatefulWidget {
  const ChartOfAccountsPreview({super.key});
  @override
  State<ChartOfAccountsPreview> createState() => _ChartOfAccountsPreviewState();
}

class _ChartOfAccountsPreviewState extends State<ChartOfAccountsPreview> {
  String query = '', type = 'all';
  Account? selected;
  @override
  Widget build(BuildContext context) {
    final matches = AccountingMockData.accounts
        .where(
          (a) =>
              '${a.code} ${a.name} ${a.arabicName}'.toLowerCase().contains(
                query.toLowerCase(),
              ) &&
              (type == 'all' || a.type == type),
        )
        .toList();
    final included = <String>{for (final a in matches) a.code};
    for (final a in matches) {
      var p = a.parent;
      while (p != null) {
        included.add(p);
        p = AccountingMockData.accounts.firstWhere((a) => a.code == p).parent;
      }
    }
    final list = BkColumn(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: tr(context, 'Search accounts', 'البحث في الحسابات'),
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        DropdownButtonFormField<String>(
          initialValue: type,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: tr(context, 'Account type', 'نوع الحساب'),
          ),
          items: [
            for (final v in [
              'all',
              'asset',
              'liability',
              'equity',
              'revenue',
              'expense',
            ])
              DropdownMenuItem(
                value: v,
                child: Text(
                  v == 'all'
                      ? tr(context, 'All', 'الكل')
                      : accountingLabel(
                          v,
                          Directionality.of(context) == TextDirection.rtl,
                        ),
                ),
              ),
          ],
          onChanged: (v) => setState(() => type = v!),
        ),
        if (matches.isEmpty)
          Text(tr(context, 'No matching accounts', 'لا توجد حسابات مطابقة'))
        else
          AccountTreeView(
            accounts: AccountingMockData.accounts
                .where((a) => included.contains(a.code))
                .toList(),
            onSelected: (a) => setState(() => selected = a),
          ),
      ],
    );
    final details = selected == null
        ? Text(
            tr(
              context,
              'Select an account to inspect.',
              'اختر حساباً لعرض التفاصيل.',
            ),
          )
        : BkCard(
            child: BkColumn(
              children: [
                Text(
                  '${selected!.code} · ${tr(context, selected!.name, selected!.arabicName)}',
                ),
                Text(
                  accountingLabel(
                    selected!.type,
                    Directionality.of(context) == TextDirection.rtl,
                  ),
                ),
                Text(
                  '${tr(context, 'Parent account', 'الحساب الأب')}: ${selected!.parent ?? '—'}',
                ),
                FinancialAmount(amount: selected!.balance),
                BkBadge(
                  label: selected!.active
                      ? tr(context, 'Active', 'نشط')
                      : tr(context, 'Inactive', 'غير نشط'),
                ),
              ],
            ),
          );
    return LayoutBuilder(
      builder: (context, b) => b.maxWidth >= 700
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: list),
                const SizedBox(width: BkSpace.lg),
                Expanded(child: details),
              ],
            )
          : BkColumn(children: [list, details]),
    );
  }
}
