// ignore_for_file: file_names
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
      ..layout = AccountingLayout.invoices
      ..device = PreviewDevice.desktop
      ..appearance = PreviewAppearance.light
      ..dataState = PreviewState.populated
      ..arabic = false
      ..compact = false
      ..sidebar = true
      ..collapsed = false
      ..header = true
      ..breadcrumbs = true
      ..actions = true
      ..bottomNavigation = true
      ..stickyFooter = false
      ..notifications = true
      ..companySelector = true
      ..globalSearch = false
      ..width = 1280.0
      ..height = 800.0
      ..mediumBreakpoint = 600.0
      ..expandedBreakpoint = 840.0;
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
