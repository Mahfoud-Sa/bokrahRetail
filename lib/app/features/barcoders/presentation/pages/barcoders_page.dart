import 'package:bokrah_retail/app/features/barcoders/domain/entities/barcode_entity.dart';
import 'package:bokrah_retail/app/features/barcoders/data/services/barcodes_service.dart';
import 'package:bokrah_retail/app/features/items/data/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodesPage extends StatefulWidget {
  const BarcodesPage({super.key});

  @override
  State<BarcodesPage> createState() => _BarcodesPageState();
}

class _BarcodesPageState extends State<BarcodesPage> {
  final BarcodesService _barcodesService = BarcodesService();
  final ItemsService _itemsService = ItemsService();
  List<BarcodeEntity> _barcodes = [];
  Map<int, List<ItemEntity>> _barcodeRelatedItems = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final barcodes = await _barcodesService.getAllBarcodes();
    final allItems = await _itemsService.getAllItems();
    final allLinks = await _barcodesService.getAllLinks();

    final Map<int, List<ItemEntity>> relatedItems = {};
    for (var barcode in barcodes) {
      final itemIds = allLinks
          .where((l) => l.barcodeId == barcode.id)
          .map((l) => l.itemId)
          .toSet();
      relatedItems[barcode.id!] = allItems
          .where((it) => itemIds.contains(it.id))
          .toList();
    }

    setState(() {
      _barcodes = barcodes;
      _barcodeRelatedItems = relatedItems;
      _isLoading = false;
    });
  }

  Future<void> _openCameraScanner(TextEditingController controller) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            AppBar(
              title: const Text('مسح الباركود'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    controller.text = barcodes.first.rawValue ?? '';
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddEditDialog({BarcodeEntity? barcode}) async {
    final isEditing = barcode != null;
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController(text: barcode?.code ?? '');
    final labelController = TextEditingController(text: barcode?.label ?? '');

    await showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(isEditing ? 'تعديل الباركود' : 'إضافة باركود جديد'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: 'رمز الباركود *',
                          hintText: 'أدخل الرمز الرقمي',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'يرجى إدخال الرمز'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Color(0xFF2E7D64),
                      ),
                      onPressed: () => _openCameraScanner(codeController),
                      tooltip: 'مسح باستخدام الكاميرا',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'وصف/تسمية (اختياري)',
                    hintText: 'مثلاً: باركود المصنع',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newBarcode = BarcodeEntity(
                    id: barcode?.id,
                    code: codeController.text.trim(),
                    label: labelController.text.trim(),
                    createdAt: barcode?.createdAt,
                  );

                  bool success = isEditing
                      ? await _barcodesService.updateBarcode(newBarcode)
                      : await _barcodesService.saveBarcode(newBarcode);

                  if (success) {
                    Navigator.pop(context);
                    _loadData();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D64),
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'تحديث' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _manageLinkedItems(BarcodeEntity barcode) async {
    final allItems = await _itemsService.getAllItems();
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final currentlyLinkedIds =
              _barcodeRelatedItems[barcode.id!]?.map((it) => it.id).toSet() ??
              {};

          return Directionality(
            textDirection: TextDirection.rtl,
            child: _SearchableItemSelectionDialog(
              allItems: allItems,
              currentlyLinkedIds: currentlyLinkedIds,
              barcode: barcode,
              onToggle: (item, val) async {
                if (val == true) {
                  await _barcodesService.linkItemToBarcode(
                    item.id!,
                    barcode.id!,
                  );
                } else {
                  await _barcodesService.unlinkItemFromBarcode(
                    item.id!,
                    barcode.id!,
                  );
                }
                await _loadData();
                setDialogState(() {});
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'الباركودات',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF2E7D64),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddEditDialog(),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _barcodes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد باركودات بعد',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة باركود'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D64),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _barcodes.length,
                  itemBuilder: (context, index) {
                    final barcode = _barcodes[index];
                    final related = _barcodeRelatedItems[barcode.id!] ?? [];

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: const Icon(
                          Icons.qr_code,
                          color: Color(0xFF2E7D64),
                        ),
                        title: Text(
                          barcode.code,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          '${barcode.label ?? 'بدون تسمية'} • ${related.length} عناصر',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showAddEditDialog(barcode: barcode);
                            }
                            if (value == 'delete') {
                              _barcodesService
                                  .deleteBarcode(barcode.id!)
                                  .then((_) => _loadData());
                            }
                            if (value == 'manage') _manageLinkedItems(barcode);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'manage',
                              child: Row(
                                children: [
                                  Icon(Icons.link, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('ربط عناصر'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Color(0xFF2E7D64)),
                                  SizedBox(width: 8),
                                  Text('تعديل'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('حذف'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        children: related.isEmpty
                            ? [
                                const ListTile(
                                  title: Text(
                                    'لا توجد عناصر مرتبطة',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ]
                            : related
                                  .map(
                                    (it) => ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.inventory_2,
                                        size: 18,
                                      ),
                                      title: Text(it.name),
                                      subtitle: Text('ID: ${it.id}'),
                                    ),
                                  )
                                  .toList(),
                      ),
                    );
                  },
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddEditDialog(),
          backgroundColor: const Color(0xFF2E7D64),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

class _SearchableItemSelectionDialog extends StatefulWidget {
  final List<ItemEntity> allItems;
  final Set<int?> currentlyLinkedIds;
  final BarcodeEntity barcode;
  final Function(ItemEntity, bool?) onToggle;

  const _SearchableItemSelectionDialog({
    required this.allItems,
    required this.currentlyLinkedIds,
    required this.barcode,
    required this.onToggle,
  });

  @override
  State<_SearchableItemSelectionDialog> createState() =>
      _SearchableItemSelectionDialogState();
}

class _SearchableItemSelectionDialogState
    extends State<_SearchableItemSelectionDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.allItems
        .where(
          (item) =>
              item.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return AlertDialog(
      title: Text('إدارة العناصر لباركود: ${widget.barcode.code}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400, // Fixed height for better scrolling
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'بحث عن عنصر...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(child: Text('لا توجد عناصر تطابق البحث'))
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isLinked = widget.currentlyLinkedIds.contains(
                          item.id,
                        );

                        return CheckboxListTile(
                          title: Text(item.name),
                          subtitle: Text('ID: ${item.id}'),
                          value: isLinked,
                          onChanged: (val) => widget.onToggle(item, val),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}
