import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';

/// A full-page screen displaying an item's comprehensive specifications and details.
class ItemDetailsPage extends StatelessWidget {
  final ItemEntity item;
  final String? departmentName;
  final String? categoryPath;
  final String? baseUnitName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ItemDetailsPage({
    super.key,
    required this.item,
    this.departmentName,
    this.categoryPath,
    this.baseUnitName,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppTheme.actionBlue),
                tooltip: 'تعديل',
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                tooltip: 'حذف',
                onPressed: onDelete,
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ItemDetailsContent(
            item: item,
            departmentName: departmentName,
            categoryPath: categoryPath,
            baseUnitName: baseUnitName,
            onEdit: onEdit,
            onDelete: onDelete,
            onClose: () => Navigator.pop(context),
            showActionButtons: false, // Actions are in the AppBar
          ),
        ),
      ),
    );
  }
}

