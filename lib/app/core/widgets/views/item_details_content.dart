import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/core/widgets/cards/item_financial_overview.dart';
import 'package:bokrah_retail/app/core/widgets/views/item_gallery_viewer.dart';
import 'package:bokrah_retail/app/core/widgets/badges/item_status_badge.dart';

/// The core content view of an item's details.
/// Can be embedded inside a Modal BottomSheet ([ItemDetailsSheet]) or a full Page ([ItemDetailsPage]).
class ItemDetailsContent extends StatelessWidget {
  final ItemEntity item;
  final String? departmentName;
  final String? categoryPath;
  final String? baseUnitName;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onClose;
  final bool showActionButtons;

  const ItemDetailsContent({
    super.key,
    required this.item,
    this.departmentName,
    this.categoryPath,
    this.baseUnitName,
    this.onEdit,
    this.onDelete,
    this.onClose,
    this.showActionButtons = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top Header Row: Name, Subname, and Status Badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepCobalt,
                    ),
                  ),
                  if (item.effectiveSubname != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.effectiveSubname!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ItemStatusBadge(status: item.usageStatus),
          ],
        ),
        const SizedBox(height: 16),

        // 2. Image Gallery
        ItemGalleryViewer(
          mainImage: item.effectiveMainImage,
          subImages: item.effectiveSubImages,
        ),
        const SizedBox(height: 20),

        // 3. Video Banner (if available)
        if (item.video != null && item.video!.trim().isNotEmpty) ...[
          _buildVideoBanner(context),
          const SizedBox(height: 16),
        ],

        // 4. Metadata Pills
        _buildMetadataWrap(),
        const SizedBox(height: 20),

        // 5. Short Description
        if (item.shortDescription != null &&
            item.shortDescription!.isNotEmpty) ...[
          const Text(
            'الوصف المختصر',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.deepCobalt,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.shortDescription!,
              style: TextStyle(color: Colors.grey[800], fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 6. Full Description & Specifications
        if (item.effectiveFullDescription != null &&
            item.effectiveFullDescription!.isNotEmpty) ...[
          const Text(
            'الوصف الكامل والمواصفات',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.deepCobalt,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              item.effectiveFullDescription!,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // 7. Advantages
        if (item.advantages.isNotEmpty) ...[
          const Text(
            'المميزات',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.deepCobalt,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.advantages.map((advantage) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.success.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 15,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      advantage,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // 8. Financial & Inventory Overview
        ItemFinancialOverview(
          purchasePrice: item.purchasePrice,
          sellPrice: item.sellPrice,
          profitMargin: item.profitMargin,
          quantity: item.quantity,
          baseUnitName: baseUnitName,
        ),

        // 8. Action Buttons
        if (showActionButtons) ...[
          const SizedBox(height: 24),
          _buildActionButtons(context),
        ],
      ],
    );
  }

  Widget _buildVideoBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.actionBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.actionBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.play_circle_fill,
            color: AppTheme.actionBlue,
            size: 32,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'يوجد فيديو توضيحي للعنصر',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'اضغط لمشاهدة الفيديو عبر الرابط المرفق',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: () async {
              try {
                final raw = item.video!.trim();
                final uri = File(raw).existsSync()
                    ? Uri.file(raw)
                    : Uri.tryParse(raw);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تعذر فتح رابط الفيديو'),
                      backgroundColor: AppTheme.error,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('فتح'),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataWrap() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (departmentName != null &&
            departmentName!.isNotEmpty &&
            departmentName != 'بدون قسم')
          _buildInfoPill('القسم', departmentName!, Icons.apartment_outlined),
        if (categoryPath != null &&
            categoryPath!.isNotEmpty &&
            categoryPath != 'بدون فئة')
          _buildInfoPill('الفئة', categoryPath!, Icons.account_tree_outlined),
        if (item.brand != null && item.brand!.isNotEmpty)
          _buildInfoPill(
            'العلامة التجارية',
            item.brand!,
            Icons.branding_watermark_outlined,
          ),
        if (item.effectiveCompany != null && item.effectiveCompany!.isNotEmpty)
          _buildInfoPill('الشركة', item.effectiveCompany!, Icons.business),
        if (item.manufactureYear != null)
          _buildInfoPill(
            'سنة الصنع',
            item.manufactureYear.toString(),
            Icons.calendar_today_outlined,
          ),
        if (item.color != null && item.color!.isNotEmpty)
          _buildInfoPill('اللون', item.color!, Icons.palette_outlined),
        if (item.size != null && item.size!.isNotEmpty)
          _buildInfoPill('المقاس', item.size!, Icons.aspect_ratio_outlined),
      ],
    );
  }

  Widget _buildInfoPill(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.actionBlue),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.deepCobalt,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final hasEditOrDelete = onEdit != null || onDelete != null;

    if (!hasEditOrDelete) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onClose ?? () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      );
    }

    return Row(
      children: [
        if (onEdit != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                onClose?.call();
                onEdit!();
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('تعديل البيانات'),
            ),
          ),
        if (onEdit != null && onDelete != null) const SizedBox(width: 12),
        if (onDelete != null)
          IconButton.filledTonal(
            onPressed: () {
              onClose?.call();
              onDelete!();
            },
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
            tooltip: 'حذف العنصر',
          ),
      ],
    );
  }
}
