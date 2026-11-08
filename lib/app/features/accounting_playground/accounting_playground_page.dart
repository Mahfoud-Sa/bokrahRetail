import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import 'components.dart';
import 'mock_data.dart';
import 'playground_controller.dart';
import 'templates.dart';

class CodePreview extends StatelessWidget {
  const CodePreview(this.code, {super.key, this.style});
  final String code;
  final TextStyle? style;
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.ltr,
    child: SelectableText(code, style: style),
  );
}

class AccountingPlaygroundPage extends StatefulWidget {
  const AccountingPlaygroundPage({super.key});
  @override
  State<AccountingPlaygroundPage> createState() =>
      _AccountingPlaygroundPageState();
}

class _AccountingPlaygroundPageState extends State<AccountingPlaygroundPage> {
  final controller = PlaygroundController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Localizations.override(
      context: context,
      locale: Locale(controller.configuration.arabic ? 'ar' : 'en'),
      child: Directionality(
        textDirection: controller.configuration.arabic
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: tr(context, 'Back', 'رجوع'),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    try {
                      context.go('/home');
                    } catch (_) {}
                  }
                },
              ),
              title: Text(
                tr(
                  context,
                  'Accounting layout playground',
                  'مختبر التخطيطات المحاسبية',
                ),
              ),
              actions: [
                IconButton(
                  tooltip: tr(
                    context,
                    'Reset configuration',
                    'إعادة الإعدادات',
                  ),
                  onPressed: controller.reset,
                  icon: const Icon(Icons.restart_alt),
                ),
              ],
            ),
            body: LayoutBuilder(
              builder: (context, c) {
                final config = ConfigurationPanel(controller: controller),
                    canvas = PlaygroundPreview(controller: controller),
                    inspector = PlaygroundInspector(controller: controller);
                if (c.maxWidth < 1100) {
                  return DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        TabBar(
                          tabs: [
                            Tab(text: tr(context, 'Configure', 'الإعدادات')),
                            Tab(text: tr(context, 'Preview', 'المعاينة')),
                            Tab(text: tr(context, 'Inspector', 'الفاحص')),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [config, canvas, inspector],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 280, child: config),
                    const VerticalDivider(width: 1),
                    Expanded(child: canvas),
                    const VerticalDivider(width: 1),
                    SizedBox(width: 300, child: inspector),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class ConfigurationPanel extends StatelessWidget {
  const ConfigurationPanel({super.key, required this.controller});
  final PlaygroundController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller, q = c.configuration;
    void edit(VoidCallback action) => c.update(action);
    Widget select<T>(
      String en,
      String ar,
      T value,
      List<(T, String)> entries,
      ValueChanged<T> onChange,
    ) => DropdownButtonFormField<T>(
      key: ValueKey('$en-$value'),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: tr(context, en, ar)),
      items: [
        for (final e in entries)
          DropdownMenuItem(value: e.$1, child: Text(e.$2)),
      ],
      onChanged: (v) {
        if (v != null) onChange(v);
      },
    );
    Widget toggle(
      String en,
      String ar,
      bool value,
      ValueChanged<bool> onChange,
    ) => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(tr(context, en, ar)),
      value: value,
      onChanged: (v) => edit(() => onChange(v)),
    );
    Widget number(
      String en,
      String ar,
      double value,
      double minimum,
      double maximum,
      ValueChanged<double> change,
    ) => TextFormField(
      key: ValueKey('$en-$value'),
      initialValue: value.toInt().toString(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: tr(context, en, ar),
        helperText: '${minimum.toInt()}–${maximum.toInt()}',
      ),
      onFieldSubmitted: (v) {
        final n = double.tryParse(v);
        if (n != null && n >= minimum && n <= maximum) {
          edit(() => change(n));
        } else {
          accountingToast(
            context,
            tr(
              context,
              'Value is outside the allowed range.',
              'القيمة خارج النطاق المسموح.',
            ),
          );
        }
      },
    );
    return ListView(
      padding: const EdgeInsets.all(BkSpace.lg),
      children: [
        Text(
          tr(context, 'Configuration', 'الإعدادات'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: BkSpace.lg),
        select('Device preview', 'الجهاز', q.device, [
          (
            PreviewDevice.mobile,
            tr(context, 'Mobile · 390 × 844', 'هاتف · 390 × 844'),
          ),
          (
            PreviewDevice.tablet,
            tr(context, 'Tablet · 768 × 1024', 'جهاز لوحي · 768 × 1024'),
          ),
          (
            PreviewDevice.desktop,
            tr(context, 'Desktop · 1280 × 800', 'سطح مكتب · 1280 × 800'),
          ),
          (PreviewDevice.custom, tr(context, 'Custom', 'مخصص')),
        ], (v) => edit(() => q.device = v)),
        const SizedBox(height: BkSpace.lg),
        if (q.device == PreviewDevice.custom) ...[
          number('Width', 'العرض', q.width, 320, 1920, (v) => q.width = v),
          number(
            'Height',
            'الارتفاع',
            q.height,
            480,
            1400,
            (v) => q.height = v,
          ),
          Text(
            tr(
              context,
              'Press Enter to apply dimensions.',
              'اضغط إدخال لتطبيق الأبعاد.',
            ),
          ),
        ],
        select('Layout', 'التخطيط', q.layout, [
          for (final v in AccountingLayout.values)
            (v, layoutLabel(v, q.arabic)),
        ], (v) => edit(() => q.layout = v)),
        const SizedBox(height: BkSpace.lg),
        select('Appearance', 'المظهر', q.appearance, [
          (PreviewAppearance.light, tr(context, 'Light', 'فاتح')),
          (PreviewAppearance.dark, tr(context, 'Dark', 'داكن')),
          (PreviewAppearance.system, tr(context, 'System', 'النظام')),
          (
            PreviewAppearance.brand,
            tr(context, 'Primary brand', 'العلامة الأساسية'),
          ),
        ], (v) => edit(() => q.appearance = v)),
        toggle(
          'Compact density',
          'كثافة مدمجة',
          q.compact,
          (v) => q.compact = v,
        ),
        toggle('Arabic RTL', 'العربية RTL', q.arabic, (v) => q.arabic = v),
        select(
          'Sample data state',
          'حالة بيانات المثال',
          q.dataState,
          [
            (PreviewState.populated, tr(context, 'Populated', 'ممتلئة')),
            (PreviewState.loading, tr(context, 'Loading', 'تحميل')),
            (PreviewState.empty, tr(context, 'Empty', 'فارغة')),
            (PreviewState.error, tr(context, 'Error', 'خطأ')),
          ],
          (v) => edit(() => q.dataState = v),
        ),
        const BkDivider(),
        toggle(
          'Show sidebar',
          'إظهار الشريط الجانبي',
          q.sidebar,
          (v) => q.sidebar = v,
        ),
        toggle(
          'Collapse sidebar',
          'طي الشريط الجانبي',
          q.collapsed,
          (v) => q.collapsed = v,
        ),
        toggle('Show header', 'إظهار الترويسة', q.header, (v) => q.header = v),
        toggle(
          'Show breadcrumbs',
          'إظهار مسار التنقل',
          q.breadcrumbs,
          (v) => q.breadcrumbs = v,
        ),
        toggle(
          'Show page actions',
          'إظهار إجراءات الصفحة',
          q.actions,
          (v) => q.actions = v,
        ),
        toggle(
          'Bottom navigation',
          'التنقل السفلي',
          q.bottomNavigation,
          (v) => q.bottomNavigation = v,
        ),
        toggle(
          'Sticky action footer',
          'تثبيت تذييل الإجراءات',
          q.stickyFooter,
          (v) => q.stickyFooter = v,
        ),
        toggle(
          'Notifications',
          'الإشعارات',
          q.notifications,
          (v) => q.notifications = v,
        ),
        toggle(
          'Company selector',
          'اختيار الشركة',
          q.companySelector,
          (v) => q.companySelector = v,
        ),
        toggle(
          'Global search',
          'البحث العام',
          q.globalSearch,
          (v) => q.globalSearch = v,
        ),
        const BkDivider(),
        number(
          'Medium breakpoint',
          'حد العرض المتوسط',
          q.mediumBreakpoint,
          480,
          q.expandedBreakpoint - 1,
          (v) => q.mediumBreakpoint = v,
        ),
        number(
          'Expanded breakpoint',
          'حد العرض الموسع',
          q.expandedBreakpoint,
          q.mediumBreakpoint + 1,
          1400,
          (v) => q.expandedBreakpoint = v,
        ),
        const SizedBox(height: BkSpace.lg),
        BkButton(
          label: tr(context, 'Reset configuration', 'إعادة الإعدادات'),
          onPressed: c.reset,
        ),
      ],
    );
  }
}

class PlaygroundPreview extends StatefulWidget {
  const PlaygroundPreview({super.key, required this.controller});
  final PlaygroundController controller;
  @override
  State<PlaygroundPreview> createState() => _PlaygroundPreviewState();
}

class _PlaygroundPreviewState extends State<PlaygroundPreview> {
  bool fit = true;
  @override
  Widget build(BuildContext context) {
    final c = widget.controller, q = c.configuration, size = q.viewport;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(BkSpace.sm),
          child: Wrap(
            spacing: BkSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${size.width.toInt()} × ${size.height.toInt()}',
                textDirection: TextDirection.ltr,
              ),
              FilterChip(
                label: Text(tr(context, 'Fit canvas', 'ملاءمة اللوحة')),
                selected: fit,
                onSelected: (v) => setState(() => fit = v),
              ),
              Text(tr(context, 'Live Flutter widgets', 'عناصر فلاتر تفاعلية')),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, b) {
              final scale = fit
                  ? math.min(
                      1.0,
                      math.min(
                        b.maxWidth / size.width,
                        b.maxHeight / size.height,
                      ),
                    )
                  : 1.0;
              return SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: math.max(b.maxWidth, size.width * scale),
                    height: math.max(b.maxHeight, size.height * scale),
                    child: Center(
                      child: SizedBox(
                        width: size.width * scale,
                        height: size.height * scale,
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: SizedBox(
                            width: size.width,
                            height: size.height,
                            child: PreviewFrame(controller: c),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class PreviewFrame extends StatelessWidget {
  const PreviewFrame({super.key, required this.controller});
  final PlaygroundController controller;
  @override
  Widget build(BuildContext context) {
    final q = controller.configuration;
    final dark =
        q.appearance == PreviewAppearance.dark ||
        (q.appearance == PreviewAppearance.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    var theme = dark
        ? BkTheme.dark(arabic: q.arabic)
        : BkTheme.light(arabic: q.arabic);
    theme = theme.copyWith(
      visualDensity: q.compact ? VisualDensity.compact : VisualDensity.standard,
    );
    if (q.appearance == PreviewAppearance.brand) {
      theme = theme.copyWith(
        scaffoldBackgroundColor: theme.colorScheme.primaryContainer,
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      );
    }
    final media = MediaQuery.of(context).copyWith(
      size: q.viewport,
      padding: EdgeInsets.zero,
      viewPadding: EdgeInsets.zero,
    );
    return MediaQuery(
      data: media,
      child: Theme(
        data: theme,
        child: Directionality(
          textDirection: q.arabic ? TextDirection.rtl : TextDirection.ltr,
          child: Localizations.override(
            context: context,
            locale: Locale(q.arabic ? 'ar' : 'en'),
            child: ScaffoldMessenger(
              child: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (context) => ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) =>
                        AccountingPreviewContent(controller: controller),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccountingPreviewContent extends StatelessWidget {
  const AccountingPreviewContent({super.key, required this.controller});
  final PlaygroundController controller;
  @override
  Widget build(BuildContext context) {
    final c = controller, q = c.configuration;
    final icons = [
      Icons.dashboard_outlined,
      Icons.edit_note,
      Icons.receipt_long,
      Icons.account_tree_outlined,
      Icons.bar_chart,
      Icons.request_quote_outlined,
      Icons.lock_outline,
      Icons.view_sidebar_outlined,
    ];
    return AccountingAppShell(
      configuration: q,
      destinations: [
        for (final layout in AccountingLayout.values)
          AccountingDestination(
            layout,
            layoutLabel(layout, q.arabic),
            icons[layout.index],
            group: layout.index < 6
                ? tr(context, 'Accounting', 'المحاسبة')
                : tr(context, 'Patterns', 'الأنماط'),
          ),
      ],
      selected: q.layout,
      onSelected: (v) => c.update(() => q.layout = v),
      onCollapse: () => c.update(() => q.collapsed = !q.collapsed),
      title: layoutLabel(q.layout, q.arabic),
      headerActions: [
        if (q.companySelector)
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              initialValue: c.company,
              key: ValueKey(c.company),
              isExpanded: true,
              decoration: InputDecoration(
                labelText: tr(context, 'Company', 'الشركة'),
              ),
              items: [
                for (final company in AccountingMockData.companies)
                  DropdownMenuItem(
                    value: company.id,
                    child: Text(tr(context, company.name, company.arabicName)),
                  ),
              ],
              onChanged: (v) => c.loadPeriod(v!, c.period),
            ),
          ),
        Text(
          AccountingMockData.periods[c.period].id,
          textDirection: TextDirection.ltr,
        ),
        if (q.notifications)
          IconButton(
            tooltip: tr(context, 'Notifications', 'الإشعارات'),
            onPressed: () => showAccountingDocument(
              context,
              tr(context, 'Notifications', 'الإشعارات'),
              tr(
                context,
                'Six sample entries need approval.',
                'ستة قيود تجريبية تحتاج اعتماداً.',
              ),
            ),
            icon: const Badge(
              label: Text('6'),
              child: Icon(Icons.notifications_outlined),
            ),
          ),
        PopupMenuButton<String>(
          tooltip: tr(context, 'User profile', 'ملف المستخدم'),
          onSelected: (_) => showAccountingDocument(
            context,
            tr(context, 'Demo profile', 'ملف تجريبي'),
            tr(
              context,
              'Demo Owner · local preview only',
              'مالك تجريبي · معاينة محلية فقط',
            ),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Text(tr(context, 'View profile', 'عرض الملف')),
            ),
          ],
          child: const Padding(
            padding: EdgeInsets.all(BkSpace.sm),
            child: Icon(Icons.account_circle_outlined),
          ),
        ),
        if (q.globalSearch)
          SizedBox(
            width: 180,
            child: TextField(
              decoration: InputDecoration(
                labelText: tr(context, 'Global search', 'البحث العام'),
              ),
              onSubmitted: (v) => c.update(() {
                c.query = v;
                q.layout = AccountingLayout.transactions;
                c.page = 0;
              }),
            ),
          ),
      ],
      pageActions: [
        BkButton(
          label: tr(context, 'New journal', 'قيد جديد'),
          onPressed: () => c.update(() => q.layout = AccountingLayout.journal),
        ),
        BkButton(
          label: tr(context, 'Help', 'مساعدة'),
          variant: BkButtonVariant.secondary,
          onPressed: () => showAccountingDocument(
            context,
            tr(context, 'Playground help', 'مساعدة المختبر'),
            tr(
              context,
              'All changes are local. Use the configuration panel to inspect responsive states.',
              'جميع التغييرات محلية. استخدم لوحة الإعدادات لفحص حالات الاستجابة.',
            ),
          ),
        ),
      ],
      footer: Wrap(
        spacing: BkSpace.sm,
        runSpacing: BkSpace.sm,
        children: [
          BkButton(
            label: tr(context, 'Confirm sample', 'تأكيد المثال'),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (dialog) => AlertDialog(
                  title: Text(
                    tr(
                      context,
                      'Confirm local action?',
                      'تأكيد الإجراء المحلي؟',
                    ),
                  ),
                  content: Text(
                    tr(
                      context,
                      'No accounting data will be sent.',
                      'لن تُرسل بيانات محاسبية.',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: Text(tr(context, 'Cancel', 'إلغاء')),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: Text(tr(context, 'Confirm', 'تأكيد')),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                accountingToast(
                  context,
                  tr(
                    context,
                    'Local sample confirmed.',
                    'تم تأكيد المثال محلياً.',
                  ),
                );
              }
            },
          ),
          TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (sheet) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(BkSpace.xl),
                  child: BkColumn(
                    children: [
                      Text(tr(context, 'Action details', 'تفاصيل الإجراء')),
                      Text(
                        tr(
                          context,
                          'Local preview · no backend integration',
                          'معاينة محلية · دون اتصال بخادم',
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(sheet),
                        child: Text(tr(context, 'Close', 'إغلاق')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            child: Text(tr(context, 'Action details', 'تفاصيل الإجراء')),
          ),
        ],
      ),
      child: switch (q.dataState) {
        PreviewState.loading => const AppLoadingState(),
        PreviewState.empty => AppEmptyState(
          onReset: () => c.update(() => q.dataState = PreviewState.populated),
        ),
        PreviewState.error => AppErrorState(
          onRetry: () => c.update(() => q.dataState = PreviewState.populated),
        ),
        PreviewState.populated => accountingTemplate(c),
      },
    );
  }
}

String playgroundCode(PlaygroundConfiguration q) =>
    '''// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/features/accounting_playground/accounting.dart';

// Place inside MaterialApp with the catalogue's localization delegates.
class AccountingExample extends StatefulWidget {
  const AccountingExample({super.key});
  @override
  State<AccountingExample> createState() => _AccountingExampleState();
}

class _AccountingExampleState extends State<AccountingExample> {
  final controller = PlaygroundController();
  @override
  void initState() {
    super.initState();
    controller.configuration
      ..layout = AccountingLayout.${q.layout.name}
      ..device = PreviewDevice.${q.device.name}
      ..appearance = PreviewAppearance.${q.appearance.name}
      ..dataState = PreviewState.${q.dataState.name}
      ..arabic = ${q.arabic}
      ..compact = ${q.compact}
      ..sidebar = ${q.sidebar}
      ..collapsed = ${q.collapsed}
      ..header = ${q.header}
      ..breadcrumbs = ${q.breadcrumbs}
      ..actions = ${q.actions}
      ..bottomNavigation = ${q.bottomNavigation}
      ..stickyFooter = ${q.stickyFooter}
      ..notifications = ${q.notifications}
      ..companySelector = ${q.companySelector}
      ..globalSearch = ${q.globalSearch}
      ..width = ${q.width}
      ..height = ${q.height}
      ..mediumBreakpoint = ${q.mediumBreakpoint}
      ..expandedBreakpoint = ${q.expandedBreakpoint};
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => PreviewFrame(controller: controller),
  );
}
''';

class PlaygroundInspector extends StatelessWidget {
  const PlaygroundInspector({super.key, required this.controller});
  final PlaygroundController controller;
  @override
  Widget build(BuildContext context) {
    final q = controller.configuration;
    final component = [
      'DashboardPreview',
      'JournalEntryPreview',
      'TransactionListPreview',
      'ChartOfAccountsPreview',
      'FinancialReportsPreview',
      'InvoiceManagementPreview',
      'AuthenticationPreview',
      'MasterDetailPreview',
    ][q.layout.index];
    final descriptions = [
      (
        'Period-linked KPIs, approvals and revenue/expense chart.',
        'مؤشرات وموافقات ومخطط الإيرادات والمصروفات حسب الفترة.',
      ),
      (
        'Editable debit/credit rows with exact totals and balanced posting.',
        'سطور مدين ودائن قابلة للتحرير بإجماليات دقيقة وترحيل متوازن.',
      ),
      (
        'Combined filters, sorting, selection, approval, paging and CSV preview.',
        'مرشحات وترتيب وتحديد واعتماد وصفحات ومعاينة CSV.',
      ),
      (
        'Hierarchical account navigation with searchable master–detail data.',
        'حسابات هرمية قابلة للبحث مع قائمة وتفاصيل.',
      ),
      (
        'Four grouped financial reports with comparison snapshots.',
        'أربعة تقارير مالية مجمعة مع لقطات مقارنة.',
      ),
      (
        'Invoice list and calculated line, discount, tax and payment totals.',
        'قائمة فواتير وحساب البنود والخصم والضريبة والمدفوعات.',
      ),
      (
        'Validated demo credentials, visibility, loading and error simulation.',
        'تحقق تجريبي وإظهار كلمة المرور ومحاكاة التحميل والخطأ.',
      ),
      (
        'Side-by-side desktop records with separate mobile detail and back.',
        'سجلات وتفاصيل متجاورة على سطح المكتب وتفاصيل مستقلة للهاتف.',
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(BkSpace.lg),
      children: [
        Text(
          tr(context, 'Component inspector', 'فاحص المكونات'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: BkSpace.lg),
        Text(
          layoutLabel(q.layout, q.arabic),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        CodePreview(component),
        Text(
          tr(
            context,
            descriptions[q.layout.index].$1,
            descriptions[q.layout.index].$2,
          ),
        ),
        CodePreview(
          [
                AccountingLayout.accounts,
                AccountingLayout.invoices,
                AccountingLayout.authentication,
              ].contains(q.layout)
              ? '$component({Key? key})'
              : '$component({Key? key, required PlaygroundController controller})',
        ),
        Text(
          tr(
            context,
            'AccountingAppShell composes existing Bokrah primitives. Mock models and interactions remain outside the generic design-system package.',
            'يجمع AccountingAppShell مكونات بكرة. تبقى النماذج التجريبية والتفاعلات خارج حزمة التصميم العامة.',
          ),
        ),
        const BkDivider(),
        Text(
          tr(context, 'API / properties', 'الواجهة / الخصائص'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const CodePreview(
          'AccountingAppShell({\n required PlaygroundConfiguration configuration,\n required List<AccountingDestination> destinations,\n required AccountingLayout selected,\n required ValueChanged<AccountingLayout> onSelected,\n required String title,\n required Widget child,\n List<Widget> headerActions = const [],\n List<Widget> pageActions = const [],\n Widget? footer,\n VoidCallback? onCollapse,\n})',
        ),
        const BkDivider(),
        Text(
          '${tr(context, 'Current configuration', 'الإعدادات الحالية')}: ${q.viewport.width.toInt()} × ${q.viewport.height.toInt()}\n${q.appearance.name} · ${q.arabic ? 'RTL / العربية' : 'LTR / English'} · ${q.compact ? tr(context, 'Compact', 'مدمجة') : tr(context, 'Comfortable', 'مريحة')}\n${tr(context, 'State', 'الحالة')}: ${q.dataState.name}',
        ),
        Text(
          tr(
            context,
            'Variants: sidebar, rail, drawer, bottom navigation. Platforms: Flutter web, desktop, Android and iOS (no platform services required).',
            'الأنواع: شريط جانبي، مسار، درج وتنقل سفلي. المنصات: الويب وسطح المكتب وأندرويد وiOS دون خدمات خاصة.',
          ),
        ),
        const BkDivider(),
        Text(
          tr(context, 'Accessibility', 'إمكانية الوصول'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          tr(
            context,
            'Keyboard focus, native form semantics, localized labels, 48px touch targets, live validation messages, tabular financial digits. Test at 200% text scale. Canvas Fit visually scales the entire viewport; turn it off for native-size interaction.',
            'تركيز لوحة المفاتيح ودلالات النماذج وتسميات مترجمة وأهداف لمس ٤٨ بكسل ورسائل تحقق حية وأرقام مالية متساوية العرض. اختبر تكبير النص ٢٠٠٪. ألغِ ملاءمة اللوحة للتفاعل بالحجم الفعلي.',
          ),
        ),
        const BkDivider(),
        BkButton(
          label: tr(context, 'Copy Code', 'نسخ الكود'),
          icon: Icons.copy,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: playgroundCode(q)));
            if (context.mounted) {
              accountingToast(
                context,
                tr(context, 'Flutter example copied', 'نُسخ مثال فلاتر'),
              );
            }
          },
        ),
        const SizedBox(height: BkSpace.md),
        CodePreview(
          playgroundCode(q),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Standalone application shell for testing and launching the accounting playground directly.
class AccountingPlaygroundApp extends StatelessWidget {
  const AccountingPlaygroundApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Bokrah Accounting Playground',
    debugShowCheckedModeBanner: false,
    supportedLocales: const [Locale('en'), Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: BkTheme.light(),
    darkTheme: BkTheme.dark(),
    home: const AccountingPlaygroundPage(),
  );
}
