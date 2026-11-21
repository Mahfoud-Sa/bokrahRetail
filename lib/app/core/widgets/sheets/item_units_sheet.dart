import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/units/domain/entities/unit_entity.dart';

/// A reusable bottom sheet modal for managing item units and conversion factors.
class ItemUnitsSheet extends StatefulWidget {
  final List<UnitEntity> units;
  final int? itemId;
  final ValueChanged<List<UnitEntity>> onUnitsChanged;

  const ItemUnitsSheet({
    super.key,
    required this.units,
    this.itemId,
    required this.onUnitsChanged,
  });

  /// Displays the units management sheet.
  static Future<void> show(
    BuildContext context, {
    required List<UnitEntity> units,
    int? itemId,
    required ValueChanged<List<UnitEntity>> onUnitsChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ItemUnitsSheet(
        units: units,
        itemId: itemId,
        onUnitsChanged: onUnitsChanged,
      ),
    );
  }

  @override
  State<ItemUnitsSheet> createState() => _ItemUnitsSheetState();
}

class _ItemUnitsSheetState extends State<ItemUnitsSheet> {
  late List<UnitEntity> _currentUnits;

  @override
  void initState() {
    super.initState();
    _currentUnits = List.from(widget.units);
  }

  void _showAddUnitDialog() {
    final nameCtrl = TextEditingController();
    final factorCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة وحدة جديدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'اسم الوحدة'),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: factorCtrl,
                decoration: const InputDecoration(
                  labelText: 'معامل التحويل',
                  hintText: 'مثلاً: 12 للكرتون',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
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
                final name = nameCtrl.text.trim();
                final factorText = factorCtrl.text.trim();
                if (name.isNotEmpty && factorText.isNotEmpty) {
                  final factor = double.tryParse(factorText) ?? 1.0;
                  setState(() {
                    _currentUnits.add(
                      UnitEntity(
                        name: name,
                        factor: factor,
                        itemId: widget.itemId ?? 0,
                      ),
                    );
                  });
                  widget.onUnitsChanged(_currentUnits);
                  Navigator.pop(dialogCtx);
                }
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
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'إدارة الوحدات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepCobalt,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddUnitDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة وحدة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              Expanded(
                child: _currentUnits.isEmpty
                    ? const Center(
                        child: Text(
                          'لا توجد وحدات مضافة بعد',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: _currentUnits.length,
                        itemBuilder: (context, index) {
                          final unit = _currentUnits[index];
                          final isBase = unit.factor == 1.0;
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: const BorderSide(color: AppTheme.border),
                            ),
                            child: ListTile(
                              title: Text(
                                unit.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                isBase
                                    ? 'الوحدة الأساسية'
                                    : 'المعامل: ${unit.factor}',
                              ),
                              trailing: isBase
                                  ? const Tooltip(
                                      message: 'الوحدة الأساسية',
                                      child: Icon(
                                        Icons.star,
                                        color: AppTheme.warmOrange,
                                      ),
                                    )
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: AppTheme.error,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _currentUnits.removeAt(index);
                                        });
                                        widget.onUnitsChanged(_currentUnits);
                                      },
                                    ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

