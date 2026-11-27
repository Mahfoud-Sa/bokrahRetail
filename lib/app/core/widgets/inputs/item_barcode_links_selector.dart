import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/widgets/inputs/app_form_text_field.dart';
import 'package:bokrah_retail/app/features/barcoders/domain/entities/barcode_entity.dart';
import 'package:bokrah_retail/app/features/items/presentation/widgets/barcode_scanner_dialog.dart';
import 'package:flutter/material.dart';

/// Multi-select M:M barcode linker for an item, allowing users to pick from
/// existing [BarcodeEntity] records or create and link a new barcode.
class ItemBarcodeLinksSelector extends StatelessWidget {
  final List<BarcodeEntity> availableBarcodes;
  final Set<int> selectedBarcodeIds;
  final ValueChanged<Set<int>> onSelectionChanged;
  final Future<BarcodeEntity?> Function(String code, String? label)
  onCreateBarcode;

  const ItemBarcodeLinksSelector({
    super.key,
    required this.availableBarcodes,
    required this.selectedBarcodeIds,
    required this.onSelectionChanged,
    required this.onCreateBarcode,
  });

  Future<void> _showPickBarcodesDialog(BuildContext context) async {
    var search = '';
    var tempSelected = Set<int>.from(selectedBarcodeIds);

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final filtered = availableBarcodes.where((b) {
            if (b.id == null) return false;
            final q = search.trim().toLowerCase();
            if (q.isEmpty) return true;
            return b.code.toLowerCase().contains(q) ||
                (b.label ?? '').toLowerCase().contains(q);
          }).toList();

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: const Text('ربط باركودات بالعنصر'),
              content: SizedBox(
                width: 420,
                height: 360,
                child: Column(
                  children: [
                    TextField(
                      decoration: buildAppInputDecoration(
                        label: 'بحث برمز الباركود أو التسمية...',
                        icon: Icons.search,
                      ),
                      onChanged: (v) => setDialogState(() => search = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('لا توجد باركودات متاحة'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final barcode = filtered[index];
                                final isChecked = tempSelected.contains(
                                  barcode.id,
                                );
                                final label = barcode.label?.trim();
                                return CheckboxListTile(
                                  value: isChecked,
                                  title: Text(barcode.code),
                                  subtitle: label != null && label.isNotEmpty
                                      ? Text(label)
                                      : null,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        tempSelected.add(barcode.id!);
                                      } else {
                                        tempSelected.remove(barcode.id!);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () {
                    onSelectionChanged(tempSelected);
                    Navigator.pop(dialogCtx);
                  },
                  child: const Text('تأكيد'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCreateBarcodeDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();
    final labelController = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: const Text('إضافة وربط باركود جديد'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppFormTextField(
                    controller: codeController,
                    label: 'رمز الباركود *',
                    icon: Icons.qr_code,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'يرجى إدخال الرمز'
                        : null,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: () async {
                        final scanned = await showDialog<String>(
                          context: dialogCtx,
                          builder: (_) => const BarcodeScannerDialog(),
                        );
                        if (scanned != null) {
                          codeController.text = scanned;
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppFormTextField(
                    controller: labelController,
                    label: 'التسمية (اختياري)',
                    icon: Icons.label_outline,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final created = await onCreateBarcode(
                    codeController.text.trim(),
                    labelController.text.trim().isEmpty
                        ? null
                        : labelController.text.trim(),
                  );
                  if (!dialogCtx.mounted) return;
                  if (created?.id != null) {
                    onSelectionChanged({...selectedBarcodeIds, created!.id!});
                  }
                  Navigator.pop(dialogCtx);
                },
                child: const Text('إضافة وربط'),
              ),
            ],
          ),
        ),
      );
    } finally {
      codeController.dispose();
      labelController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedBarcodes = availableBarcodes
        .where((b) => b.id != null && selectedBarcodeIds.contains(b.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'الباركودات المرتبطة (${selectedBarcodes.length})',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            Wrap(
              spacing: 4,
              children: [
                TextButton.icon(
                  onPressed: () => _showPickBarcodesDialog(context),
                  icon: const Icon(Icons.link, size: 17),
                  label: const Text('اختيار باركودات'),
                ),
                TextButton.icon(
                  onPressed: () => _showCreateBarcodeDialog(context),
                  icon: const Icon(Icons.add_circle_outline, size: 17),
                  label: const Text('باركود جديد'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (selectedBarcodes.isEmpty)
          Text(
            'لا توجد باركودات مرتبطة بهذا العنصر بعد',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: selectedBarcodes.map((b) {
              final label = b.label?.trim();
              final displayText = label != null && label.isNotEmpty
                  ? '${b.code} ($label)'
                  : b.code;
              return Chip(
                avatar: const Icon(
                  Icons.qr_code_2,
                  size: 16,
                  color: AppTheme.actionBlue,
                ),
                label: Text(displayText, style: const TextStyle(fontSize: 12)),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  final updated = Set<int>.from(selectedBarcodeIds)
                    ..remove(b.id);
                  onSelectionChanged(updated);
                },
                backgroundColor: Colors.grey[100],
              );
            }).toList(),
          ),
      ],
    );
  }
}
