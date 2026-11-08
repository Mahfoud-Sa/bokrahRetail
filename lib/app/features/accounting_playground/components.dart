import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import 'models.dart';
import 'mock_data.dart';
import 'playground_controller.dart';

/// Keeps externally cleared filters in sync without replacing focus on each key.
class BoundSearchField extends StatefulWidget {
  const BoundSearchField({
    super.key,
    required this.value,
    required this.decoration,
    required this.onChanged,
  });
  final String value;
  final InputDecoration decoration;
  final ValueChanged<String> onChanged;
  @override
  State<BoundSearchField> createState() => _BoundSearchFieldState();
}

class _BoundSearchFieldState extends State<BoundSearchField> {
  late final text = TextEditingController(text: widget.value);
  @override
  void didUpdateWidget(covariant BoundSearchField old) {
    super.didUpdateWidget(old);
    if (text.text != widget.value) {
      text.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: text,
    decoration: widget.decoration,
    onChanged: widget.onChanged,
  );
}

/// Reuses BkListTile when space permits; stacks metadata for narrow/large text.
class AccountingRecordTile extends StatelessWidget {
  const AccountingRecordTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      if (c.maxWidth >= 600 &&
          MediaQuery.textScalerOf(context).scale(16) <= 24) {
        return BkListTile(
          title: title,
          subtitle: subtitle,
          trailing: trailing,
          onTap: onTap,
        );
      }
      return BkCard(
        padding: const EdgeInsets.all(BkSpace.lg),
        child: InkWell(
          onTap: onTap,
          child: BkColumn(
            gap: BkSpace.sm,
            children: [
              Text(title),
              if (subtitle != null) Text(subtitle!),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      );
    },
  );
}

String tr(BuildContext context, String en, String ar) =>
    Directionality.of(context) == TextDirection.rtl ? ar : en;
String dateLabel(BuildContext context, DateTime value) =>
    MaterialLocalizations.of(context).formatMediumDate(value);
void accountingToast(BuildContext context, String message) =>
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
Future<void> showAccountingDocument(
  BuildContext context,
  String title,
  String body,
) => showDialog<void>(
  context: context,
  builder: (dialog) => AlertDialog(
    title: Text(title),
    content: SizedBox(
      width: 560,
      child: SingleChildScrollView(child: SelectableText(body)),
    ),
    actions: [
      TextButton(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: body));
          if (dialog.mounted) {
            accountingToast(
              dialog,
              tr(dialog, 'Copied document', 'نُسخ المستند'),
            );
          }
        },
        child: Text(tr(dialog, 'Copy / export', 'نسخ / تصدير')),
      ),
      TextButton(
        onPressed: () => Navigator.pop(dialog),
        child: Text(tr(dialog, 'Close', 'إغلاق')),
      ),
    ],
  ),
);

class FinancialAmount extends StatelessWidget {
  const FinancialAmount({
    super.key,
    required this.amount,
    this.symbol = false,
    this.dashZero = false,
  });
  final Money amount;
  final bool symbol, dashZero;
  @override
  Widget build(BuildContext context) => Semantics(
    excludeSemantics: true,
    label: amount.format(
      arabic: Directionality.of(context) == TextDirection.rtl,
      symbol: symbol,
      dashZero: dashZero,
    ),
    child: Text(
      amount.format(
        arabic: Directionality.of(context) == TextDirection.rtl,
        symbol: symbol,
        dashZero: dashZero,
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
      style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    ),
  );
}

class FiscalPeriodSelector extends StatelessWidget {
  const FiscalPeriodSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
    initialValue: value,
    key: ValueKey('period-$value'),
    isExpanded: true,
    decoration: InputDecoration(
      labelText: tr(context, 'Fiscal period', 'الفترة المالية'),
    ),
    items: [
      for (var i = 0; i < AccountingMockData.periods.length; i++)
        DropdownMenuItem(
          value: i,
          child: Text(
            MaterialLocalizations.of(
              context,
            ).formatMonthYear(AccountingMockData.periods[i].start),
          ),
        ),
    ],
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

class FinancialKpiCard extends StatelessWidget {
  const FinancialKpiCard({super.key, required this.label, required this.value});
  final String label;
  final Money value;
  @override
  Widget build(BuildContext context) => BkCard(
    padding: const EdgeInsets.all(BkSpace.lg),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: BkSpace.sm),
        FinancialAmount(amount: value),
      ],
    ),
  );
}

class ApprovalStatusBadge extends StatelessWidget {
  const ApprovalStatusBadge({super.key, required this.status});
  final String status;
  @override
  Widget build(BuildContext context) => BkBadge(
    label: accountingLabel(
      status,
      Directionality.of(context) == TextDirection.rtl,
    ),
    tone: status == 'pending'
        ? BkTone.warning
        : status == 'partial'
        ? BkTone.info
        : BkTone.success,
  );
}

class BalanceSummary extends StatelessWidget {
  const BalanceSummary({super.key, required this.debit, required this.credit});
  final Money debit, credit;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: BkSpace.lg,
    runSpacing: BkSpace.md,
    children: [
      for (final item in [
        (tr(context, 'Total debit', 'إجمالي المدين'), debit),
        (tr(context, 'Total credit', 'إجمالي الدائن'), credit),
        (tr(context, 'Difference', 'الفرق'), debit - credit),
      ])
        Semantics(
          liveRegion: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.$1),
              FinancialAmount(amount: item.$2),
            ],
          ),
        ),
    ],
  );
}

class DebitCreditInput extends StatelessWidget {
  const DebitCreditInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });
  final String label, value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => TextFormField(
    initialValue: value,
    enabled: enabled,
    decoration: InputDecoration(labelText: label),
    textDirection: TextDirection.ltr,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    onChanged: onChanged,
  );
}

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label: tr(context, 'Loading sample data', 'تحميل بيانات المثال'),
    child: const Center(
      child: Padding(
        padding: EdgeInsets.all(BkSpace.xl),
        child: CircularProgressIndicator(),
      ),
    ),
  );
}

class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => BkColumn(
    children: [
      Text(
        tr(
          context,
          'Sample connection failed. Your draft is preserved.',
          'تعذر الاتصال التجريبي. مسودتك محفوظة.',
        ),
      ),
      BkButton(
        label: tr(context, 'Retry', 'إعادة المحاولة'),
        onPressed: onRetry,
      ),
    ],
  );
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({super.key, required this.onReset});
  final VoidCallback onReset;
  @override
  Widget build(BuildContext context) => BkNoResults(
    title: tr(context, 'No records', 'لا توجد سجلات'),
    message: tr(
      context,
      'Change the filters or restore sample data.',
      'غيّر المرشحات أو استعد بيانات المثال.',
    ),
    clearLabel: tr(context, 'Restore sample', 'استعادة المثال'),
    onClear: onReset,
  );
}

class PageContainer extends StatelessWidget {
  const PageContainer({super.key, required this.child, this.compact = false});
  final Widget child;
  final bool compact;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(compact ? BkSpace.md : BkSpace.xl),
    child: child,
  );
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.description,
    this.actions = const [],
  });
  final String title, description;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => BkColumn(
    children: [
      BkSectionHeader(title: title, description: description),
      if (actions.isNotEmpty)
        Wrap(spacing: BkSpace.sm, runSpacing: BkSpace.sm, children: actions),
    ],
  );
}

class AccountingDestination {
  const AccountingDestination(
    this.id,
    this.label,
    this.icon, {
    this.group = 'Workspace',
  });
  final AccountingLayout id;
  final String label, group;
  final IconData icon;
}

/// Router-independent shell; available constraints select sidebar, rail or drawer.
class AccountingAppShell extends StatelessWidget {
  const AccountingAppShell({
    super.key,
    required this.configuration,
    required this.destinations,
    required this.selected,
    required this.onSelected,
    required this.title,
    required this.child,
    this.headerActions = const [],
    this.pageActions = const [],
    this.footer,
    this.onCollapse,
  });
  final PlaygroundConfiguration configuration;
  final List<AccountingDestination> destinations;
  final AccountingLayout selected;
  final ValueChanged<AccountingLayout> onSelected;
  final String title;
  final Widget child;
  final List<Widget> headerActions, pageActions;
  final Widget? footer;
  final VoidCallback? onCollapse;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final compact = c.maxWidth < configuration.mediumBreakpoint,
          expanded = c.maxWidth >= configuration.expandedBreakpoint;
      final nav = AppSidebar(
        destinations: destinations,
        selected: selected,
        onSelected: onSelected,
        collapsed: configuration.collapsed || !expanded,
        onCollapse: expanded ? onCollapse : null,
      );
      final main = Column(
        children: [
          if (configuration.header)
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(BkSpace.sm),
                  child: Wrap(
                    spacing: BkSpace.sm,
                    runSpacing: BkSpace.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (compact && configuration.sidebar)
                        Builder(
                          builder: (context) => IconButton(
                            tooltip: tr(
                              context,
                              'Open navigation',
                              'افتح التنقل',
                            ),
                            onPressed: () => Scaffold.of(context).openDrawer(),
                            icon: const Icon(Icons.menu),
                          ),
                        ),
                      Text(
                        'Bokrah',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      ...headerActions,
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              key: const PageStorageKey('accounting-content'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: PageContainer(
                compact: configuration.compact,
                child: BkColumn(
                  children: [
                    if (configuration.breadcrumbs)
                      Text(
                        '${tr(context, 'Workspace', 'مساحة العمل')} / $title',
                      ),
                    PageHeader(
                      title: title,
                      description: tr(
                        context,
                        'Interactive local accounting sample · no data is sent',
                        'مثال محاسبي محلي تفاعلي · لا تُرسل بيانات',
                      ),
                      actions: configuration.actions ? pageActions : [],
                    ),
                    child,
                  ],
                ),
              ),
            ),
          ),
          if (configuration.stickyFooter && footer != null)
            SafeArea(
              top: false,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(BkSpace.sm),
                  child: footer!,
                ),
              ),
            ),
        ],
      );
      return BkPageScaffold(
        drawer: compact && configuration.sidebar
            ? Drawer(
                child: SafeArea(
                  child: AppSidebar(
                    destinations: destinations,
                    selected: selected,
                    onSelected: (id) {
                      Navigator.pop(context);
                      onSelected(id);
                    },
                    collapsed: false,
                  ),
                ),
              )
            : null,
        bottomNavigationBar: compact && configuration.bottomNavigation
            ? AppBottomNavigation(
                destinations: destinations,
                selected: selected,
                onSelected: onSelected,
              )
            : null,
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!compact && configuration.sidebar)
              SizedBox(
                width: configuration.collapsed || !expanded ? 88 : 220,
                child: nav,
              ),
            Expanded(child: main),
          ],
        ),
      );
    },
  );
}

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.destinations,
    required this.selected,
    required this.onSelected,
    required this.collapsed,
    this.onCollapse,
  });
  final List<AccountingDestination> destinations;
  final AccountingLayout selected;
  final ValueChanged<AccountingLayout> onSelected;
  final bool collapsed;
  final VoidCallback? onCollapse;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    child: ListView(
      padding: const EdgeInsets.all(BkSpace.sm),
      children: [
        if (onCollapse != null)
          IconButton(
            tooltip: tr(
              context,
              collapsed ? 'Expand sidebar' : 'Collapse sidebar',
              collapsed ? 'توسيع الشريط' : 'طي الشريط',
            ),
            onPressed: onCollapse,
            icon: Icon(collapsed ? Icons.chevron_right : Icons.chevron_left),
          ),
        for (final group in destinations.map((d) => d.group).toSet()) ...[
          if (!collapsed)
            ExpansionTile(
              key: PageStorageKey('nav-$group'),
              title: Text(group),
              initiallyExpanded: true,
              children: [
                for (final d in destinations.where((d) => d.group == group))
                  ListTile(
                    selected: d.id == selected,
                    leading: Icon(d.icon),
                    title: Text(d.label),
                    onTap: () => onSelected(d.id),
                  ),
              ],
            )
          else
            for (final d in destinations.where((d) => d.group == group))
              Padding(
                padding: const EdgeInsets.only(bottom: BkSpace.sm),
                child: IconButton.filledTonal(
                  isSelected: d.id == selected,
                  tooltip: d.label,
                  onPressed: () => onSelected(d.id),
                  icon: Icon(d.icon),
                ),
              ),
        ],
      ],
    ),
  );
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.destinations,
    required this.selected,
    required this.onSelected,
  });
  final List<AccountingDestination> destinations;
  final AccountingLayout selected;
  final ValueChanged<AccountingLayout> onSelected;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SizedBox(
        height: 64,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            for (final d in destinations)
              SizedBox(
                width: 88,
                child: Semantics(
                  selected: d.id == selected,
                  child: IconButton(
                    tooltip: d.label,
                    isSelected: d.id == selected,
                    onPressed: () => onSelected(d.id),
                    icon: Icon(d.icon),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class AccountTreeView extends StatelessWidget {
  const AccountTreeView({
    super.key,
    required this.accounts,
    required this.onSelected,
    this.parent,
  });
  final List<Account> accounts;
  final ValueChanged<Account> onSelected;
  final String? parent;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final a in accounts.where((a) => a.parent == parent))
        if (accounts.any((b) => b.parent == a.code))
          ExpansionTile(
            key: PageStorageKey(a.code),
            title: Text('${a.code} · ${tr(context, a.name, a.arabicName)}'),
            initiallyExpanded: true,
            children: [
              TextButton(
                onPressed: () => onSelected(a),
                child: Text(tr(context, 'Account details', 'تفاصيل الحساب')),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: BkSpace.lg),
                child: AccountTreeView(
                  accounts: accounts,
                  onSelected: onSelected,
                  parent: a.code,
                ),
              ),
            ],
          )
        else
          ListTile(
            title: Text('${a.code} · ${tr(context, a.name, a.arabicName)}'),
            subtitle: Text(
              accountingLabel(
                a.type,
                Directionality.of(context) == TextDirection.rtl,
              ),
            ),
            onTap: () => onSelected(a),
          ),
    ],
  );
}
