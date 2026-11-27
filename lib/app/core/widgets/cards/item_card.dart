import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/core/widgets/badges/item_status_badge.dart';
import 'package:bokrah_retail/app/core/widgets/views/item_image_view.dart';

/// A reusable card component representing an inventory item.
/// Can be used across items page, barcode linking, invoice creation, stock transfers, etc.
class ItemCard extends StatelessWidget {
  final ItemEntity item;
  final String? departmentName;
  final String? categoryPath;
  final String? baseUnitName;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Widget? trailing;
  final bool showPricing;
  final bool showBadges;
  final EdgeInsetsGeometry? margin;

  const ItemCard({
    super.key,
    required this.item,
    this.departmentName,
    this.categoryPath,
    this.baseUnitName,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.trailing,
    this.showPricing = true,
    this.showBadges = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final hasMainImage =
        item.effectiveMainImage != null &&
        item.effectiveMainImage!.trim().isNotEmpty;
    final subImagesCount = item.effectiveSubImages.length;
    final hasVideo = item.video != null && item.video!.trim().isNotEmpty;
    final hasMenu = onEdit != null || onDelete != null;

    return Card(
      elevation: 1,
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Image + Name + Status + Menu/Trailing
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image / Fallback Avatar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 56,
                      height: 56,
                      color: hasMainImage
                          ? Colors.transparent
                          : Colors.grey[200],
                      child: hasMainImage
                          ? ItemImageView(
                              source: item.effectiveMainImage,
                              fit: BoxFit.cover,
                              fallback: _buildFallbackAvatar(),
                            )
                          : _buildFallbackAvatar(),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and Subname
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.deepCobalt,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ItemStatusBadge(status: item.usageStatus),
                          ],
                        ),
                        if (item.effectiveSubname != null &&
                            item.effectiveSubname!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.effectiveSubname!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Trailing widget or Popup Menu
                  if (trailing != null)
                    trailing!
                  else if (hasMenu)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'view') {
                          onTap?.call();
                        } else if (value == 'edit') {
                          onEdit?.call();
                        } else if (value == 'delete') {
                          onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => [
                        if (onTap != null)
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('عرض التفاصيل'),
                              ],
                            ),
                          ),
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: AppTheme.actionBlue,
                                ),
                                SizedBox(width: 8),
                                Text('تعديل'),
                              ],
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: AppTheme.error,
                                ),
                                SizedBox(width: 8),
                                Text('حذف'),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),

              // Badges row: Department, Category Tree, Brand, Company, Year
              if (showBadges) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (departmentName != null &&
                        departmentName!.isNotEmpty &&
                        departmentName != 'بدون قسم')
                      _buildTagChip(
                        departmentName!,
                        Icons.apartment_outlined,
                        color: AppTheme.actionBlue,
                      ),
                    if (categoryPath != null &&
                        categoryPath!.isNotEmpty &&
                        categoryPath != 'بدون فئة')
                      _buildTagChip(
                        categoryPath!,
                        Icons.account_tree_outlined,
                        color: AppTheme.deepCobalt,
                      ),
                    if (item.brand != null && item.brand!.isNotEmpty)
                      _buildTagChip(
                        item.brand!,
                        Icons.branding_watermark_outlined,
                      ),
                    if (item.effectiveCompany != null &&
                        item.effectiveCompany!.isNotEmpty)
                      _buildTagChip(item.effectiveCompany!, Icons.business),
                    if (item.manufactureYear != null)
                      _buildTagChip(
                        'سنة: ${item.manufactureYear}',
                        Icons.calendar_today_outlined,
                      ),
                    if (subImagesCount > 0)
                      _buildTagChip(
                        '+$subImagesCount صور',
                        Icons.photo_library_outlined,
                      ),
                    if (hasVideo)
                      _buildTagChip(
                        'فيديو',
                        Icons.videocam_outlined,
                        color: AppTheme.actionBlue,
                      ),
                  ],
                ),
              ],

              // Short Description
              if (item.shortDescription != null &&
                  item.shortDescription!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  item.shortDescription!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Bottom Stats Row: Prices, Stock
              if (showPricing) ...[
                const Divider(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Buy Price
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          size: 15,
                          color: AppTheme.warmOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'شراء: ${item.purchasePrice.toStringAsFixed(2)} ر.س',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    // Sell Price
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.attach_money,
                          size: 15,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'بيع: ${item.sellPrice.toStringAsFixed(2)} ر.س',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.deepCobalt,
                          ),
                        ),
                      ],
                    ),

                    // Stock Quantity
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 15,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'الكمية: ${item.quantity} ${baseUnitName ?? ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      color: AppTheme.actionBlue.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          item.name.isNotEmpty ? item.name[0] : '؟',
          style: const TextStyle(
            color: AppTheme.actionBlue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip(String label, IconData icon, {Color? color}) {
    final effectiveColor = color ?? Colors.grey[700]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: effectiveColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: effectiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
