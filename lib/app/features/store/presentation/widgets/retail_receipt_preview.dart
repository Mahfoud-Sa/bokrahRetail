import 'package:flutter/material.dart';
import '../../data/models/store_entity.dart';

class RetailReceiptPreview extends StatelessWidget {
  final StoreEntity store;

  const RetailReceiptPreview({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 380),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top receipt paper jagged edge decoration
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 14, color: Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Text(
                        isArabic
                            ? 'فاتورة ضريبية مبسطة - مبيعات وإلكترونيات'
                            : 'Simplified Tax Invoice - Retail',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Store Logo / Emblem
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.storefront_outlined,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),

                // Store Names
                Text(
                  store.nameAr.isNotEmpty
                      ? store.nameAr
                      : 'متجر بكرة للإلكترونيات والتجزئة',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (store.nameEn.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    store.nameEn,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],

                if (store.slogan.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    store.slogan,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const _ReceiptDivider(),
                const SizedBox(height: 10),

                // Tax & CR Information
                _buildInfoLine(
                  isArabic ? 'الرقم الضريبي:' : 'VAT Registration:',
                  store.taxNumber.isNotEmpty
                      ? store.taxNumber
                      : '310987654300003',
                ),
                _buildInfoLine(
                  isArabic ? 'السجل التجاري:' : 'C.R. Number:',
                  store.commercialRegistration.isNotEmpty
                      ? store.commercialRegistration
                      : '1010543210',
                ),
                _buildInfoLine(
                  isArabic ? 'العنوان:' : 'Address:',
                  store.fullAddress.isNotEmpty
                      ? store.fullAddress
                      : (isArabic ? 'الرياض - حي النخيل' : 'Riyadh - Al Nakheel'),
                ),
                if (store.phoneNumber.isNotEmpty)
                  _buildInfoLine(
                    isArabic ? 'الهاتف / المبيعات:' : 'Tel / Sales:',
                    store.phoneNumber,
                  ),

                const SizedBox(height: 10),
                const _ReceiptDivider(),
                const SizedBox(height: 10),

                // Invoice metadata
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isArabic ? 'رقم الفاتورة: #INV-2026-8841' : 'Invoice: #INV-2026-8841',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '2026-11-06 14:30',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Column Headers for Products
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        isArabic ? 'المنتج / الصنف' : 'Item Description',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                    ),
                    Text(
                      isArabic ? 'الكمية' : 'Qty',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      isArabic ? 'المجموع' : 'Total',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Electronics & Retail Sample Products
                _buildProductItem(
                  isArabic
                      ? 'سماعات لاسلكية Pro (S/N: 9841A)'
                      : 'Wireless Earbuds Pro (S/N: 9841A)',
                  '1',
                  '199.00 ${store.currency}',
                ),
                _buildProductItem(
                  isArabic
                      ? 'شاحن سريع GaN بقدرة 65W'
                      : '65W GaN Fast Charger',
                  '1',
                  '120.00 ${store.currency}',
                ),
                _buildProductItem(
                  isArabic
                      ? 'كابل USB-C مضفر 2 متر'
                      : 'Braided USB-C Cable 2M',
                  '2',
                  '60.00 ${store.currency}',
                ),

                const SizedBox(height: 10),
                const _ReceiptDivider(),
                const SizedBox(height: 8),

                // Totals
                _buildSummaryRow(
                  isArabic ? 'المجموع الفرعي:' : 'Subtotal:',
                  '379.00 ${store.currency}',
                ),
                if (store.isTaxEnabled)
                  _buildSummaryRow(
                    '${isArabic ? 'ضريبة القيمة المضافة' : 'VAT'} (${store.taxRate}%):',
                    '${(379.00 * (store.taxRate / 100)).toStringAsFixed(2)} ${store.currency}',
                  ),
                const SizedBox(height: 4),
                _buildSummaryRow(
                  isArabic ? 'الإجمالي الكلي:' : 'Grand Total:',
                  '${(379.00 * (1 + (store.isTaxEnabled ? store.taxRate / 100 : 0))).toStringAsFixed(2)} ${store.currency}',
                  isTotal: true,
                ),

                const SizedBox(height: 12),
                const _ReceiptDivider(),
                const SizedBox(height: 10),

                // Warranty & Return Policy (Essential for Electronics & Retail)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueGrey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified_outlined,
                              size: 14, color: Colors.blueGrey.shade800),
                          const SizedBox(width: 4),
                          Text(
                            isArabic ? 'سياسة الضمان والاسترجاع' : 'Warranty & Return Policy',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        store.warrantyPolicy,
                        style: TextStyle(fontSize: 9, color: Colors.blueGrey.shade800),
                      ),
                      Text(
                        store.returnPolicy,
                        style: TextStyle(fontSize: 9, color: Colors.blueGrey.shade800),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Simulated ZATCA / QR Code for electronic invoices
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_2,
                          size: 50, color: Colors.grey.shade800),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic
                                  ? 'رمز الاستجابة السريع المعتمد'
                                  : 'Certified E-Invoice QR',
                              style: const TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              isArabic
                                  ? 'متوافق مع متطلبات هيئة الزكاة والضريبة'
                                  : 'ZATCA E-Invoicing Phase 2 Compliant',
                              style: TextStyle(
                                  fontSize: 8.5, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Footer Note
                if (store.receiptFooterNote.isNotEmpty)
                  Text(
                    store.receiptFooterNote,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
              ],
            ),
          ),

          // Bottom receipt jagged edge decoration
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(String name, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(name,
                style: const TextStyle(fontSize: 10.5, color: Colors.black87)),
          ),
          Text(qty,
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade800)),
          const SizedBox(width: 16),
          Text(price,
              style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 12 : 10.5,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.black : Colors.grey.shade800,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 13 : 10.5,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.black : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptDivider extends StatelessWidget {
  const _ReceiptDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey.shade400),
              ),
            );
          }),
        );
      },
    );
  }
}

// Backward-compatible alias
class RestaurantReceiptPreview extends StatelessWidget {
  final dynamic restaurant;

  const RestaurantReceiptPreview({
    super.key,
    required this.restaurant,
  });

  @override
  Widget build(BuildContext context) {
    if (restaurant is StoreEntity) {
      return RetailReceiptPreview(store: restaurant as StoreEntity);
    }
    return RetailReceiptPreview(store: StoreEntity.defaultStore());
  }
}

