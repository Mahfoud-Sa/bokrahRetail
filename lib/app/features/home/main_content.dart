import 'package:flutter/material.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import 'package:bokrah_retail/app/features/accounting_playground/accounting.dart';

/// Real Bokrah Accounting Dashboard featuring period-linked KPIs,
/// approvals, bank balances, recent invoices, entries, and revenue/expense charts.
class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key, this.controller});
  final PlaygroundController? controller;

  @override
  Widget build(BuildContext context) {
    final c = controller ?? PlaygroundController();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(BkSpace.lg),
      child: DashboardPreview(controller: c),
    );
  }
}
