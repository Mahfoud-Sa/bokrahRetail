/// Sample UI data only. Never use these role rules as server authorization.
class DemoRecord {
  const DemoRecord(this.id, this.name, this.amount, this.category);
  final int id;
  final String name, category;
  final double amount;
}

List<DemoRecord> demoRecords() => const [
  DemoRecord(1, 'Lunch / الغداء', 240, 'sales'),
  DemoRecord(2, 'Supplies / مستلزمات', 80, 'expenses'),
  DemoRecord(3, 'Dinner / العشاء', 1200, 'sales'),
  DemoRecord(4, 'Breakfast / الإفطار', 45, 'sales'),
  DemoRecord(5, 'Utilities / الخدمات', 200, 'expenses'),
];

bool canPerform(String role, String action) => switch (role) {
  'owner' => {'read', 'create', 'update', 'delete'}.contains(action),
  'cashier' => {'read', 'create', 'update'}.contains(action),
  'viewer' => action == 'read',
  _ => false,
};

bool validDraft(String name, String amount) {
  final value = double.tryParse(amount);
  return name.trim().isNotEmpty && value != null && value.isFinite && value > 0;
}

List<DemoRecord> queryRecords(
  List<DemoRecord> records, {
  String query = '',
  String category = 'all',
  bool sortAmount = false,
}) {
  final result = records
      .where(
        (record) =>
            (category == 'all' || record.category == category) &&
            record.name.toLowerCase().contains(query.trim().toLowerCase()),
      )
      .toList();
  result.sort(
    (a, b) =>
        sortAmount ? a.amount.compareTo(b.amount) : a.name.compareTo(b.name),
  );
  return result;
}
