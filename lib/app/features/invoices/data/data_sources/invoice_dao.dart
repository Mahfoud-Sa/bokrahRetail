import 'package:bokrah_retail/app/features/invoices/data/modules/invoice_module.dart';

abstract class InvoiceDao {
  Future<int> InsertInvoice(InvoiceModel invoice);
  Future<int> UpdateInvoice(InvoiceModel invoice);
  Future<int> DeleteInvoice(InvoiceModel invoice);
  Future<InvoiceModel> getInvoices(int id);
  Future<List<InvoiceModel>> getnvoice();
}
