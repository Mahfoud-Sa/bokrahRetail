import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/core/widgets/views/item_details_content.dart';

/// A reusable bottom sheet modal for inspecting complete item details.
class ItemDetailsSheet extends StatelessWidget {
  final ItemEntity item;
  final String? departmentName;
  final String? categoryPath;
  final String? baseUnitName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ItemDetailsSheet({
    super.key,
    required this.item,
    this.departmentName,
    this.categoryPath,
    this.baseUnitName,
    this.onEdit,
    this.onDelete,
  });

  /// Displays the [ItemDetailsSheet] in a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required ItemEntity item,
    String? departmentName,
    String? categoryPath,
    String? baseUnitName,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => ItemDetailsSheet(
        item: item,
        departmentName: departmentName,
        categoryPath: categoryPath,
        baseUnitName: baseUnitName,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ItemDetailsContent(
                item: item,
                departmentName: departmentName,
                categoryPath: categoryPath,
                baseUnitName: baseUnitName,
                onEdit: onEdit,
                onDelete: onDelete,
                onClose: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

