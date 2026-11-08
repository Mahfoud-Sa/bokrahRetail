import 'models.dart';

abstract final class AccountingMockData {
  static const companies = [
    Company('bokrah', 'Bokrah Restaurant', 'مطعم بكرة'),
    Company('branch', 'Bokrah Catering', 'بكرة للضيافة'),
  ];
  static final periods = [
    for (var m = 1; m <= 3; m++)
      FiscalPeriod(
        '2026-${m.toString().padLeft(2, '0')}',
        DateTime(2026, m),
        DateTime(2026, m + 1, 0),
      ),
  ];
  static const accounts = [
    Account('1000', 'Assets', 'الأصول', 'asset', Money(1390000)),
    Account('1001', 'Cash', 'النقد', 'asset', Money(190000), parent: '1000'),
    Account('1002', 'Bank', 'البنك', 'asset', Money(700000), parent: '1000'),
    Account(
      '1003',
      'Receivables',
      'الذمم المدينة',
      'asset',
      Money(500000),
      parent: '1000',
    ),
    Account('2000', 'Liabilities', 'الالتزامات', 'liability', Money(390000)),
    Account(
      '2001',
      'Payables',
      'الذمم الدائنة',
      'liability',
      Money(390000),
      parent: '2000',
    ),
    Account('3000', 'Equity', 'حقوق الملكية', 'equity', Money(1000000)),
    Account('4000', 'Revenue', 'الإيرادات', 'revenue', Money(1200000)),
    Account('5000', 'Expenses', 'المصروفات', 'expense', Money(800000)),
    Account(
      '5001',
      'Archived supplies',
      'مستلزمات مؤرشفة',
      'expense',
      Money(0),
      parent: '5000',
      active: false,
    ),
  ];
  static List<Transaction> transactions(String company, int month) => [
    for (var i = 1; i <= 24; i++)
      Transaction(
        'TX-${month.toString().padLeft(2, '0')}-${i.toString().padLeft(3, '0')}',
        DateTime(2026, month, (i % 27) + 1),
        i.isEven ? 'Restaurant sales $i' : 'Operating supplies $i',
        i.isEven ? 'مبيعات المطعم $i' : 'مستلزمات التشغيل $i',
        i.isEven ? 'income' : 'expense',
        i % 4 == 0 ? 'pending' : 'posted',
        Money(
          (i.isEven ? 100000 : 60000) +
              i * 1000 +
              month * 1000 +
              (company == 'branch' ? 2000 : 0),
        ),
      ),
  ];
  static const invoices = [
    Invoice(
      'INV-001',
      'Olive Catering',
      'ضيافة الزيتون',
      [
        InvoiceLine('Lunch service', 'خدمة الغداء', 20, Money(1500)),
        InvoiceLine('Delivery', 'التوصيل', 1, Money(2000)),
      ],
      discount: Money(2000),
      paid: Money(10000),
    ),
    Invoice('INV-002', 'Amman Office', 'مكتب عمّان', [
      InvoiceLine('Breakfast', 'إفطار', 10, Money(1000)),
    ], paid: Money(11000)),
    Invoice('INV-003', 'Market supplier', 'مورد السوق', [
      InvoiceLine('Supplies', 'مستلزمات', 4, Money(5000)),
    ]),
  ];
  static List<FinancialReport> reports(Money revenue, Money expenses) {
    final profit = revenue - expenses;
    return [
      FinancialReport('Balance Sheet', 'الميزانية العمومية', [
        const ReportRow(
          'Assets / الأصول',
          'Cash & bank',
          'النقد والبنك',
          Money(890000),
          Money(800000),
        ),
        const ReportRow(
          'Assets / الأصول',
          'Receivables',
          'الذمم المدينة',
          Money(500000),
          Money(450000),
        ),
        const ReportRow(
          'Liabilities & equity / الالتزامات والملكية',
          'Payables',
          'الذمم الدائنة',
          Money(390000),
          Money(350000),
        ),
        const ReportRow(
          'Liabilities & equity / الالتزامات والملكية',
          'Equity',
          'حقوق الملكية',
          Money(1000000),
          Money(900000),
        ),
      ]),
      FinancialReport('Profit and Loss', 'الأرباح والخسائر', [
        ReportRow(
          'Operating / التشغيل',
          'Revenue',
          'الإيرادات',
          revenue,
          revenue - const Money(10000),
        ),
        ReportRow(
          'Operating / التشغيل',
          'Expenses',
          'المصروفات',
          Money(-expenses.minor),
          Money(-expenses.minor + 10000),
        ),
        ReportRow(
          'Result / النتيجة',
          'Net profit',
          'صافي الربح',
          profit,
          profit,
        ),
      ]),
      const FinancialReport('Trial Balance', 'ميزان المراجعة', [
        ReportRow(
          'Debit / مدين',
          'Assets & expenses',
          'الأصول والمصروفات',
          Money(2190000),
          Money(2000000),
        ),
        ReportRow(
          'Credit / دائن',
          'Liabilities, equity & revenue',
          'الالتزامات والملكية والإيرادات',
          Money(2190000),
          Money(2000000),
        ),
      ]),
      FinancialReport('General Ledger', 'دفتر الأستاذ', [
        const ReportRow(
          'Cash / النقد',
          'Opening balance',
          'رصيد افتتاحي',
          Money(190000),
          Money(190000),
        ),
        ReportRow(
          'Cash / النقد',
          'Revenue',
          'الإيرادات',
          revenue,
          revenue - const Money(10000),
        ),
        ReportRow(
          'Cash / النقد',
          'Expenses',
          'المصروفات',
          Money(-expenses.minor),
          Money(-expenses.minor + 10000),
        ),
        ReportRow(
          'Closing / الختامي',
          'Closing balance',
          'الرصيد الختامي',
          const Money(190000) + profit,
          const Money(190000) + profit,
        ),
      ]),
    ];
  }
}
