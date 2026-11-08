import 'package:flutter/material.dart';
import 'playground_controller.dart';
import 'templates/dashboard_preview.dart';
import 'templates/journal_entry_preview.dart';
import 'templates/transaction_list_preview.dart';
import 'templates/chart_of_accounts_preview.dart';
import 'templates/financial_reports_preview.dart';
import 'templates/invoice_management_preview.dart';
import 'templates/authentication_preview.dart';
import 'templates/master_detail_preview.dart';
export 'templates/dashboard_preview.dart';
export 'templates/journal_entry_preview.dart';
export 'templates/transaction_list_preview.dart';
export 'templates/chart_of_accounts_preview.dart';
export 'templates/financial_reports_preview.dart';
export 'templates/invoice_management_preview.dart';
export 'templates/authentication_preview.dart';
export 'templates/master_detail_preview.dart';

Widget accountingTemplate(
  PlaygroundController controller,
) => switch (controller.configuration.layout) {
  AccountingLayout.dashboard => DashboardPreview(controller: controller),
  AccountingLayout.journal => JournalEntryPreview(controller: controller),
  AccountingLayout.transactions => TransactionListPreview(
    controller: controller,
  ),
  AccountingLayout.accounts => const ChartOfAccountsPreview(),
  AccountingLayout.reports => FinancialReportsPreview(controller: controller),
  AccountingLayout.invoices => const InvoiceManagementPreview(),
  AccountingLayout.authentication => const AuthenticationPreview(),
  AccountingLayout.masterDetail => MasterDetailPreview(controller: controller),
};
