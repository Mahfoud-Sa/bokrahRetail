import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/config/theme.dart';

/// A card displaying pricing details, purchase/sell prices, profit margin,
/// and available stock quantity in base units.
class ItemFinancialOverview extends StatelessWidget {
  final double purchasePrice;
  final double sellPrice;
  final double profitMargin;
  final num quantity;
  final String? baseUnitName;

  const ItemFinancialOverview({
    super.key,
    required this.purchasePrice,
    required this.sellPrice,
    required this.profitMargin,
    required this.quantity,
    this.baseUnitName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'التسعير والمخزون',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppTheme.deepCobalt,
              ),
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  'سعر الشراء',
                  '${purchasePrice.toStringAsFixed(2)} ر.س',
                  AppTheme.warmOrange,
                ),
                _buildStatColumn(
                  'سعر البيع',
                  '${sellPrice.toStringAsFixed(2)} ر.س',
                  AppTheme.success,
                ),
                _buildStatColumn(
                  'هامش الربح',
                  '${profitMargin.toStringAsFixed(2)} ر.س',
                  profitMargin >= 0 ? AppTheme.success : AppTheme.error,
                ),
                _buildStatColumn(
                  'الكمية المتوفرة',
                  '$quantity ${baseUnitName ?? ''}',
                  AppTheme.deepCobalt,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}

