import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/items/presentation/widgets/barcode_scanner_dialog.dart';

/// A reusable widget to display and manage a list of item barcodes with camera scanner integration.
class ItemBarcodesSection extends StatelessWidget {
  final List<String> barcodes;
  final ValueChanged<List<String>> onBarcodesChanged;

  const ItemBarcodesSection({
    super.key,
    required this.barcodes,
    required this.onBarcodesChanged,
  });

  void _showAddBarcodeDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة باركود'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'الباركود',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () async {
                      final scanned = await showDialog<String>(
                        context: dialogCtx,
                        builder: (scannerCtx) => const BarcodeScannerDialog(),
                      );
                      if (scanned != null) {
                        controller.text = scanned;
                      }
                    },
                  ),
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty) {
                  final updated = List<String>.from(barcodes);
                  if (!updated.contains(text)) {
                    updated.add(text);
                    onBarcodesChanged(updated);
                  }
                }
                Navigator.pop(dialogCtx);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'باركودات إضافية',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
            TextButton.icon(
              onPressed: () => _showAddBarcodeDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('إضافة باركود'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.actionBlue,
              ),
            ),
          ],
        ),
        if (barcodes.isEmpty)
          Text(
            'لا توجد باركودات مضافة',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: barcodes.map((b) {
              return Chip(
                label: Text(b, style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  final updated = List<String>.from(barcodes)..remove(b);
                  onBarcodesChanged(updated);
                },
                backgroundColor: Colors.grey[100],
              );
            }).toList(),
          ),
      ],
    );
  }
}

