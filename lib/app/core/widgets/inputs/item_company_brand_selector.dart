import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/widgets/inputs/app_form_text_field.dart';
import 'package:bokrah_retail/app/features/companies/domain/entities/company_entity.dart';
import 'package:flutter/material.dart';

/// Manufacturer company dropdown and brand input with selectable brand chips
/// sourced from the selected [CompanyEntity].
class ItemCompanyBrandSelector extends StatefulWidget {
  final List<CompanyEntity> companies;
  final int? selectedCompanyId;
  final bool isLoading;
  final bool isRequired;
  final TextEditingController companyController;
  final TextEditingController brandController;
  final ValueChanged<int?> onCompanyChanged;
  final VoidCallback onAddCompany;

  const ItemCompanyBrandSelector({
    super.key,
    required this.companies,
    required this.selectedCompanyId,
    required this.companyController,
    required this.brandController,
    required this.onCompanyChanged,
    required this.onAddCompany,
    this.isLoading = false,
    this.isRequired = true,
  });

  @override
  State<ItemCompanyBrandSelector> createState() =>
      _ItemCompanyBrandSelectorState();
}

class _ItemCompanyBrandSelectorState extends State<ItemCompanyBrandSelector> {
  CompanyEntity? _findMatchingCompany(String name) {
    for (final company in widget.companies) {
      if (company.matchesName(name)) return company;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final validCompanyId =
        widget.companies.any((c) => c.id == widget.selectedCompanyId)
        ? widget.selectedCompanyId
        : null;

    final matchedCompany = validCompanyId != null
        ? widget.companies.where((c) => c.id == validCompanyId).firstOrNull
        : (widget.companyController.text.trim().isEmpty
              ? null
              : _findMatchingCompany(widget.companyController.text.trim()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.manufacturerCompany,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            TextButton.icon(
              onPressed: widget.onAddCompany,
              icon: const Icon(Icons.add_circle_outline, size: 16),
              label: const Text('إضافة شركة', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey(validCompanyId),
                isExpanded: true,
                initialValue: validCompanyId,
                decoration: buildAppInputDecoration(
                  label: l10n.manufacturerCompany,
                  icon: Icons.domain,
                ),
                items: widget.companies
                    .where((company) => company.id != null)
                    .map(
                      (company) => DropdownMenuItem<int>(
                        value: company.id,
                        child: Text(
                          company.localizedName(isAr),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (id) {
                  final selected = widget.companies
                      .where((company) => company.id == id)
                      .firstOrNull;
                  if (selected != null) {
                    widget.companyController.text = selected.localizedName(
                      isAr,
                    );
                  } else {
                    widget.companyController.clear();
                  }
                  widget.onCompanyChanged(id);
                },
                validator: (id) => widget.isRequired && id == null
                    ? l10n.selectManufacturerCompany
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppFormTextField(
                controller: widget.brandController,
                label: 'العلامة التجارية (Brand)',
                icon: Icons.branding_watermark_outlined,
                hintText: 'مثال: Samsung, Apple, Sony',
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
        if (widget.companies.isEmpty && !widget.isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'لا توجد شركات مسجلة بعد — اضغط "إضافة شركة" لإضافة شركة جديدة.',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
        if (matchedCompany != null && matchedCompany.brands.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'العلامات المتاحة: ',
                    style: TextStyle(fontSize: 11, color: AppTheme.warmOrange),
                  ),
                ),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: matchedCompany.brands.map((brand) {
                      final isSelected =
                          widget.brandController.text.trim().toLowerCase() ==
                          brand.toLowerCase();
                      return InkWell(
                        onTap: () {
                          setState(() {
                            widget.brandController.text = brand;
                          });
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.warmOrange.withValues(alpha: 0.2)
                                : AppTheme.paleOrange.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.warmOrange
                                  : AppTheme.warmOrange.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            brand,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: AppTheme.primaryText,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
