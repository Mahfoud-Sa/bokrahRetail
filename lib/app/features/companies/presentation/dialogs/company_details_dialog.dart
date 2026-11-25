import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/companies/domain/entities/company_entity.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';

class CompanyDetailsDialog extends StatelessWidget {
  final CompanyEntity company;
  final List<ItemEntity> linkedItems;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CompanyDetailsDialog({
    super.key,
    required this.company,
    this.linkedItems = const [],
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _launch(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: AppTheme.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Cover / Brand Accent
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.deepCobalt, AppTheme.actionBlue],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    // Company Logo
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: company.image != null && company.image!.isNotEmpty
                          ? Image.network(
                              company.image!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  company.name.isNotEmpty ? company.name[0].toUpperCase() : 'C',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.actionBlue,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                company.name.isNotEmpty ? company.name[0].toUpperCase() : 'C',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.actionBlue,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  company.arabicName.isNotEmpty ? company.arabicName : company.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (company.code != null && company.code!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    company.code!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            company.englishName.isNotEmpty ? company.englishName : company.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                          if (company.address != null && company.address!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    company.address!,
                                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Content Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      if (company.description != null && company.description!.isNotEmpty) ...[
                        const Text(
                          'نبذة عن الشركة:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryText),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.subtleSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            company.description!,
                            style: const TextStyle(fontSize: 13, color: AppTheme.primaryText, height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Brands Section
                      Row(
                        children: [
                          const Icon(Icons.branding_watermark_outlined, size: 18, color: AppTheme.actionBlue),
                          const SizedBox(width: 8),
                          Text(
                            'العلامات التجارية (${company.brands.length}):',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (company.brands.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.paleOrange.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.warmOrange.withValues(alpha: 0.3)),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: company.brands.map((b) {
                              return Chip(
                                avatar: const Icon(Icons.verified, size: 14, color: AppTheme.actionBlue),
                                label: Text(b, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                backgroundColor: Colors.white,
                                side: BorderSide(color: AppTheme.border.withValues(alpha: 0.8)),
                              );
                            }).toList(),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.subtleSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'لا توجد علامات تجارية مسجلة تحت هذه الشركة حالياً.',
                            style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Contact Details
                      const Text(
                        'بيانات الاتصال والتواصل:',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.primaryText),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          if (company.website != null && company.website!.isNotEmpty)
                            ActionChip(
                              avatar: const Icon(Icons.public, size: 16, color: AppTheme.actionBlue),
                              label: Text(company.website!),
                              onPressed: () => _launch(company.website!),
                              backgroundColor: AppTheme.subtleSurface,
                            ),
                          if (company.email != null && company.email!.isNotEmpty)
                            ActionChip(
                              avatar: const Icon(Icons.email_outlined, size: 16, color: AppTheme.actionBlue),
                              label: Text(company.email!),
                              onPressed: () => _launch('mailto:${company.email!}'),
                              backgroundColor: AppTheme.subtleSurface,
                            ),
                          if (company.phone != null && company.phone!.isNotEmpty)
                            ActionChip(
                              avatar: const Icon(Icons.phone_outlined, size: 16, color: AppTheme.actionBlue),
                              label: Text(company.phone!),
                              onPressed: () => _launch('tel:${company.phone!}'),
                              backgroundColor: AppTheme.subtleSurface,
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Linked Catalog Items
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 18, color: AppTheme.warmOrange),
                          const SizedBox(width: 8),
                          Text(
                            'المنتجات المرتبطة بالمخزون (${linkedItems.length}):',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (linkedItems.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: linkedItems.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = linkedItems[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.shopping_bag_outlined, color: AppTheme.actionBlue),
                                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: item.brand != null && item.brand!.isNotEmpty
                                    ? Text('العلامة: ${item.brand!}')
                                    : null,
                                trailing: Text(
                                  'الكمية: ${item.quantity}',
                                  style: const TextStyle(color: AppTheme.secondaryText, fontSize: 12),
                                ),
                              );
                            },
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.subtleSurface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'لم يتم ربط أي منتجات في المخزون بهذه الشركة بعد.',
                            style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: const BoxDecoration(
                  color: AppTheme.subtleSurface,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(top: BorderSide(color: AppTheme.border)),
                ),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 18),
                      label: const Text('حذف الشركة', style: TextStyle(color: AppTheme.error)),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إغلاق'),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('تعديل البيانات'),
                      style: FilledButton.styleFrom(backgroundColor: AppTheme.actionBlue),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
