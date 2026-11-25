import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/companies/domain/entities/company_entity.dart';
import 'package:bokrah_retail/app/features/companies/presentation/widgets/company_logo_image.dart';

/// Callbacks for actions performed on a [CompanyCard].
class CompanyCardActions {
  final VoidCallback? onDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CompanyCardActions({
    this.onDetails,
    this.onEdit,
    this.onDelete,
  });
}

/// A decoupled presentation card representing a [CompanyEntity] with its branding,
/// stats, brands list, and quick actions.
/// Adheres strictly to the <= 3 constructor arguments rule:
/// 1. [company] (CompanyEntity)
/// 2. [linkedItemsCount] (int)
/// 3. [actions] (CompanyCardActions)
class CompanyCard extends StatelessWidget {
  final CompanyEntity company;
  final int linkedItemsCount;
  final CompanyCardActions actions;

  const CompanyCard({
    super.key,
    required this.company,
    this.linkedItemsCount = 0,
    this.actions = const CompanyCardActions(),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(),
                const SizedBox(width: 12),
                Expanded(child: _buildDetails()),
                _buildPopupMenu(),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(child: _buildBrandsSection()),
          const Divider(height: 1, color: AppTheme.border),
          _buildFooterActions(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppTheme.subtleSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: CompanyLogoImage(
        imageBytes: company.imageBytes,
        imageUrl: company.image,
        fallback: _buildFallbackInitial(),
      ),
    );
  }

  Widget _buildFallbackInitial() {
    return Center(
      child: Text(
        company.name.isNotEmpty ? company.name[0].toUpperCase() : 'C',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppTheme.deepCobalt,
        ),
      ),
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                company.arabicName.isNotEmpty ? company.arabicName : company.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (company.code != null && company.code!.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.actionBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  company.code!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.actionBlue,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          company.englishName.isNotEmpty ? company.englishName : company.name,
          style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText),
          overflow: TextOverflow.ellipsis,
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 13, color: AppTheme.mutedText),
            const SizedBox(width: 4),
            Text(
              '$linkedItemsCount عنصر مسجل',
              style: const TextStyle(fontSize: 11, color: AppTheme.mutedText),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20, color: AppTheme.secondaryText),
      padding: EdgeInsets.zero,
      onSelected: (action) {
        if (action == 'details') actions.onDetails?.call();
        if (action == 'edit') actions.onEdit?.call();
        if (action == 'delete') actions.onDelete?.call();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18, color: AppTheme.actionBlue),
              SizedBox(width: 8),
              Text('عرض التفاصيل'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 18, color: AppTheme.secondaryText),
              SizedBox(width: 8),
              Text('تعديل البيانات'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
              SizedBox(width: 8),
              Text('حذف الشركة', style: TextStyle(color: AppTheme.error)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBrandsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.branding_watermark_outlined, size: 13, color: AppTheme.warmOrange),
              const SizedBox(width: 6),
              Text(
                'العلامات التجارية (${company.brands.length}):',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: company.brands.isNotEmpty
                ? SingleChildScrollView(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: company.brands.map((brand) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.paleOrange.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.warmOrange.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            brand,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryText,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                : const Center(
                    child: Text(
                      'لا توجد علامات تجارية مسجلة',
                      style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: actions.onDetails,
            icon: const Icon(Icons.info_outline, size: 15),
            label: const Text('التفاصيل', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: AppTheme.actionBlue,
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'تعديل',
                color: AppTheme.secondaryText,
                onPressed: actions.onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: 'حذف',
                color: AppTheme.error,
                onPressed: actions.onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
