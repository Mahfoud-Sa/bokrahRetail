import 'package:flutter/material.dart';
import '../../../../config/l10n/app_localizations.dart';
import '../../../../config/theme.dart';
import '../../data/models/country_code_model.dart';

class CountryCodePickerDialog extends StatefulWidget {
  final CountryCodeModel selectedCountry;
  final ValueChanged<CountryCodeModel> onSelect;

  const CountryCodePickerDialog({
    super.key,
    required this.selectedCountry,
    required this.onSelect,
  });

  static Future<CountryCodeModel?> show(
    BuildContext context, {
    required CountryCodeModel selectedCountry,
  }) {
    return showModalBottomSheet<CountryCodeModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CountryCodePickerDialog(
        selectedCountry: selectedCountry,
        onSelect: (country) => Navigator.of(ctx).pop(country),
      ),
    );
  }

  @override
  State<CountryCodePickerDialog> createState() =>
      _CountryCodePickerDialogState();
}

class _CountryCodePickerDialogState extends State<CountryCodePickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<CountryCodeModel> _filteredCountries =
      CountryCodeModel.supportedCountries;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final lower = query.toLowerCase().trim();
    setState(() {
      if (lower.isEmpty) {
        _filteredCountries = CountryCodeModel.supportedCountries;
      } else {
        _filteredCountries = CountryCodeModel.supportedCountries.where((c) {
          return c.nameEn.toLowerCase().contains(lower) ||
              c.nameAr.contains(lower) ||
              c.dialCode.contains(lower) ||
              c.isoCode.toLowerCase().contains(lower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langCode = Localizations.localeOf(context).languageCode;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.75,
      ),
      margin: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.creamSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowWarm,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderWarm,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.countryCode,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDarkBrown,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textMediumBrown),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: _filter,
              style: const TextStyle(color: AppTheme.textDarkBrown),
              decoration: InputDecoration(
                hintText: l10n.searchCountry,
                hintStyle: const TextStyle(color: AppTheme.textMutedBrown),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.deepOrange,
                ),
                filled: true,
                fillColor: AppTheme.creamInputFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const Divider(color: AppTheme.borderWarm, height: 16),

          // List of countries
          Flexible(
            child: Material(
              color: Colors.transparent,
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _filteredCountries.length,
                separatorBuilder: (context, index) => const Divider(
                  color: AppTheme.borderWarm,
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected =
                    country.isoCode == widget.selectedCountry.isoCode;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: Text(
                    country.flagEmoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                  title: Text(
                    country.localizedName(langCode),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.deepOrange
                          : AppTheme.textDarkBrown,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          country.dialCode,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppTheme.deepOrange
                                : AppTheme.textMediumBrown,
                          ),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle,
                          color: AppTheme.deepOrange,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  onTap: () => widget.onSelect(country),
                );
              },
            ),
          ),
        ),
      ],
      ),
    );
  }
}
