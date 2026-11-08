import 'package:flutter/material.dart';
import 'models.dart';
import 'mock_data.dart';

enum AccountingLayout {
  dashboard,
  journal,
  transactions,
  accounts,
  reports,
  invoices,
  authentication,
  masterDetail,
}

enum PreviewDevice { mobile, tablet, desktop, custom }

enum PreviewAppearance { light, dark, system, brand }

enum PreviewState { populated, loading, empty, error }

class PlaygroundConfiguration {
  AccountingLayout layout = AccountingLayout.dashboard;
  PreviewDevice device = PreviewDevice.desktop;
  PreviewAppearance appearance = PreviewAppearance.light;
  PreviewState dataState = PreviewState.populated;
  bool arabic = false,
      compact = false,
      sidebar = true,
      collapsed = false,
      header = true,
      breadcrumbs = true,
      actions = true,
      bottomNavigation = true,
      stickyFooter = false,
      notifications = true,
      companySelector = true,
      globalSearch = false;
  double width = 1280,
      height = 800,
      mediumBreakpoint = 600,
      expandedBreakpoint = 840;
  Size get viewport => switch (device) {
    PreviewDevice.mobile => const Size(390, 844),
    PreviewDevice.tablet => const Size(768, 1024),
    PreviewDevice.desktop => const Size(1280, 800),
    PreviewDevice.custom => Size(width, height),
  };
}

String layoutLabel(AccountingLayout layout, bool ar) => (ar
    ? [
        'لوحة المحاسبة',
        'قيد يومية',
        'المعاملات',
        'دليل الحسابات',
        'التقارير المالية',
        'إدارة الفواتير',
        'تسجيل الدخول',
        'القائمة والتفاصيل',
      ]
    : [
        'Accounting Dashboard',
        'Journal Entry',
        'Transaction List',
        'Chart of Accounts',
        'Financial Reports',
        'Invoice Management',
        'Authentication',
        'Master–Detail',
      ])[layout.index];
String accountingLabel(String value, bool ar) => !ar
    ? value
    : const {
            'income': 'إيراد',
            'expense': 'مصروف',
            'pending': 'قيد الانتظار',
            'posted': 'مرحّل',
            'paid': 'مدفوع',
            'partial': 'مدفوع جزئياً',
            'asset': 'أصل',
            'liability': 'التزام',
            'equity': 'ملكية',
            'revenue': 'إيراد',
          }[value] ??
          value;

class PlaygroundController extends ChangeNotifier {
  PlaygroundConfiguration configuration = PlaygroundConfiguration();
  String company = 'bokrah';
  int period = 0;
  List<Transaction> transactions = AccountingMockData.transactions('bokrah', 1);
  String query = '', status = 'all', type = 'all';
  DateTime? from, to;
  bool ascending = true;
  int sortColumn = 0, page = 0;
  final Set<String> selected = {};
  JournalEntry journal = JournalEntry(
    reference: 'JE-2026-001',
    date: DateTime(2026, 1, 15),
    period: '2026-01',
    lines: [
      JournalEntryLine(debit: '100.00'),
      JournalEntryLine(account: '4000', credit: '100.00'),
    ],
  );
  bool journalPosted = false;
  String? journalMessage;
  JournalEntry? savedDraft;
  bool canPerformAccounting = true;
  String? restrictionMessage;

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  void reset() {
    configuration = PlaygroundConfiguration();
    query = '';
    status = 'all';
    type = 'all';
    from = null;
    to = null;
    page = 0;
    sortColumn = 0;
    ascending = true;
    selected.clear();
    loadPeriod('bokrah', 0);
  }

  void loadPeriod(String value, int month) {
    company = value;
    period = month;
    transactions = AccountingMockData.transactions(company, period + 1);
    selected.clear();
    page = 0;
    notifyListeners();
  }

  List<Transaction> get filtered {
    final items = transactions
        .where(
          (t) =>
              ('${t.id} ${t.description} ${t.arabicDescription}'
                  .toLowerCase()
                  .contains(query.toLowerCase())) &&
              (status == 'all' || t.status == status) &&
              (type == 'all' || t.type == type) &&
              (from == null || !t.date.isBefore(from!)) &&
              (to == null || !t.date.isAfter(to!)),
        )
        .toList();
    items.sort((a, b) {
      final v = sortColumn == 1
          ? a.amount.minor.compareTo(b.amount.minor)
          : sortColumn == 2
          ? a.date.compareTo(b.date)
          : a.id.compareTo(b.id);
      return ascending ? v : -v;
    });
    return items;
  }

  int get pages => ((filtered.length + 5) ~/ 6).clamp(1, 1000);
  List<Transaction> get paged =>
      filtered.skip(page.clamp(0, pages - 1) * 6).take(6).toList();
  Money get revenue => transactions
      .where((t) => t.type == 'income')
      .fold(const Money(0), (a, b) => a + b.amount);
  Money get expenses => transactions
      .where((t) => t.type == 'expense')
      .fold(const Money(0), (a, b) => a + b.amount);
  Money get debit => journal.lines.fold(
    const Money(0),
    (sum, line) => sum + Money.parse(line.debit),
  );
  Money get credit => journal.lines.fold(
    const Money(0),
    (sum, line) => sum + Money.parse(line.credit),
  );
  String? validateJournal(bool ar) {
    String t(String en, String arabic) => ar ? arabic : en;
    if (journal.description.trim().isEmpty) {
      return t('Enter a description.', 'أدخل وصفاً للقيد.');
    }
    if (journal.lines.length < 2) {
      return t('At least two lines are required.', 'يلزم سطران على الأقل.');
    }
    try {
      for (final line in journal.lines) {
        final d = Money.parse(line.debit).minor,
            c = Money.parse(line.credit).minor;
        if (d < 0 || c < 0 || (d == 0 && c == 0) || (d > 0 && c > 0)) {
          return t(
            'Each line needs a positive debit OR credit.',
            'كل سطر يحتاج مديناً أو دائناً موجباً.',
          );
        }
      }
      if (debit.minor == 0 || debit.minor != credit.minor) {
        return t(
          'Debits and credits must balance.',
          'يجب تساوي المدين والدائن.',
        );
      }
    } on FormatException {
      return t(
        'Use valid amounts with at most 2 decimal places.',
        'استخدم مبالغ صحيحة بمنزلتين عشريتين كحد أقصى.',
      );
    }
    return null;
  }

  bool postJournal() {
    if (!canPerformAccounting) {
      journalMessage = restrictionMessage ??
          (configuration.arabic
              ? 'يُرجى إضافة بيانات مطعمك قبل متابعة هذه العملية.'
              : 'Please add your restaurant details before continuing with this operation.');
      notifyListeners();
      return false;
    }
    journalMessage = validateJournal(configuration.arabic);
    if (journalMessage == null) {
      journalPosted = true;
      journalMessage = configuration.arabic
          ? 'تم ترحيل القيد محلياً.'
          : 'Entry posted locally.';
    }
    notifyListeners();
    return journalPosted;
  }

  void saveDraft() {
    if (!canPerformAccounting) {
      journalMessage = restrictionMessage ??
          (configuration.arabic
              ? 'يُرجى إضافة بيانات مطعمك قبل متابعة هذه العملية.'
              : 'Please add your restaurant details before continuing with this operation.');
      notifyListeners();
      return;
    }
    savedDraft = JournalEntry(
      reference: journal.reference,
      date: journal.date,
      period: journal.period,
      description: journal.description,
      lines: [
        for (final l in journal.lines)
          JournalEntryLine(
            account: l.account,
            debit: l.debit,
            credit: l.credit,
          ),
      ],
    );
    journalMessage = configuration.arabic
        ? 'حُفظت المسودة في الذاكرة.'
        : 'Draft saved in memory.';
    notifyListeners();
  }

  void cancelJournal() {
    journal = JournalEntry(
      reference: 'JE-2026-001',
      date: DateTime(2026, 1, 15),
      period: '2026-01',
      lines: [
        JournalEntryLine(debit: '100.00'),
        JournalEntryLine(account: '4000', credit: '100.00'),
      ],
    );
    journalPosted = false;
    journalMessage = null;
    notifyListeners();
  }

  void approveSelected() {
    transactions = [
      for (final t in transactions)
        selected.contains(t.id) ? t.withStatus('posted') : t,
    ];
    selected.clear();
    notifyListeners();
  }
}
