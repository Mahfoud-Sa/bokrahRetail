import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';
import 'package:bokrah_retail/app/features/companies/domain/entities/company_entity.dart';
import 'package:bokrah_retail/app/features/companies/presentation/bloc/companies_cubit.dart';
import 'package:bokrah_retail/app/features/companies/presentation/company_access.dart';
import 'package:bokrah_retail/app/features/companies/presentation/pages/update_company_page.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';

class CompanyDetailsPage extends StatefulWidget {
  final CompanyEntity company;

  const CompanyDetailsPage({super.key, required this.company});

  @override
  State<CompanyDetailsPage> createState() => _CompanyDetailsPageState();
}

class _CompanyDetailsPageState extends State<CompanyDetailsPage> {
  CompanyEntity get _company =>
      context.read<CompaniesCubit>().state.selectedCompany ?? widget.company;
  List<ItemEntity> get _linkedItems =>
      context.read<CompaniesCubit>().state.linkedItems;
  bool get _isLoading => context.read<CompaniesCubit>().state.isDetailsLoading;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() => context.read<CompaniesCubit>().loadCompanyDetails(
    widget.company.id ?? -1,
  );

  Future<void> _launch(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _navigateToEdit() async {
    if (!await CompanyAccess.requireManage(context)) return;
    if (!mounted) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CompaniesCubit>(),
          child: UpdateCompanyPage(company: _company),
        ),
      ),
    );

    if (result == true && mounted) {
      _loadData();
    }
  }

  Future<void> _confirmDelete() async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/company-details',
    )) {
      return;
    }
    if (!mounted) return;
    if (!await CompanyAccess.requireManage(context)) return;
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text('تأكيد حذف الشركة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'هل أنت متأكد من حذف شركة "${_company.arabicName.isNotEmpty ? _company.arabicName : _company.name}"؟',
                style: const TextStyle(fontSize: 14),
              ),
              if (_company.brands.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'سيتم أيضاً إزالة ربط العلامات التجارية (${_company.brands.join(', ')}).',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
              if (_linkedItems.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.errorSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تنبيه: يوجد ${_linkedItems.length} منتج مسجل في المخزون مرتبط بهذه الشركة.',
                          style: const TextStyle(
                            color: AppTheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('حذف نهائي'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && _company.id != null) {
      if (!mounted) return;
      if (!CompanyAccess.canManage(context)) return;
      final success = await context.read<CompaniesCubit>().deleteCompany(
        _company.id!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم حذف الشركة بنجاح' : 'تعذر حذف الشركة'),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
        if (success) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          } else {
            context.go('/companies');
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CompaniesCubit>().state;
    final canManage = CompanyAccess.canManage(context);
    final title = _company.arabicName.isNotEmpty
        ? _company.arabicName
        : _company.name;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.mainBackground,
        appBar: AppBar(
          title: Text('تفاصيل الشركة: $title'),
          backgroundColor: AppTheme.deepCobalt,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/companies');
              }
            },
          ),
          actions: canManage
              ? [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'تعديل بيانات الشركة',
                    onPressed: _navigateToEdit,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.white70,
                    ),
                    tooltip: 'حذف الشركة',
                    onPressed: _confirmDelete,
                  ),
                ]
              : const [],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : state.selectedCompany == null && state.errorMessage != null
            ? Center(child: Text(state.errorMessage!))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 860),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero Header Card
                        _buildHeroCard(),
                        const SizedBox(height: 20),

                        // Description Card
                        if (_company.description != null &&
                            _company.description!.isNotEmpty) ...[
                          FormSectionCard(
                            title: 'نبذة عن الشركة',
                            icon: Icons.notes_outlined,
                            children: [
                              Text(
                                _company.description!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.primaryText,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Brands Showcase Card
                        FormSectionCard(
                          title:
                              'العلامات التجارية المسجلة (${_company.brands.length})',
                          icon: Icons.branding_watermark_outlined,
                          children: [
                            _company.brands.isNotEmpty
                                ? Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _company.brands.map((b) {
                                      return Chip(
                                        avatar: const Icon(
                                          Icons.verified,
                                          size: 16,
                                          color: AppTheme.actionBlue,
                                        ),
                                        label: Text(
                                          b,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        backgroundColor: AppTheme.paleOrange
                                            .withValues(alpha: 0.4),
                                        side: BorderSide(
                                          color: AppTheme.warmOrange.withValues(
                                            alpha: 0.4,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  )
                                : const Text(
                                    'لا توجد علامات تجارية مسجلة تحت هذه الشركة حالياً.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.secondaryText,
                                    ),
                                  ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Contact Details Card
                        FormSectionCard(
                          title: 'معلومات التواصل والمقر',
                          icon: Icons.contact_mail_outlined,
                          children: [
                            Wrap(
                              spacing: 14,
                              runSpacing: 10,
                              children: [
                                if (_company.website != null &&
                                    _company.website!.isNotEmpty)
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.public,
                                      size: 18,
                                      color: AppTheme.actionBlue,
                                    ),
                                    label: Text(_company.website!),
                                    onPressed: () => _launch(_company.website!),
                                    backgroundColor: AppTheme.subtleSurface,
                                  ),
                                if (_company.email != null &&
                                    _company.email!.isNotEmpty)
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.email_outlined,
                                      size: 18,
                                      color: AppTheme.actionBlue,
                                    ),
                                    label: Text(_company.email!),
                                    onPressed: () =>
                                        _launch('mailto:${_company.email!}'),
                                    backgroundColor: AppTheme.subtleSurface,
                                  ),
                                if (_company.phone != null &&
                                    _company.phone!.isNotEmpty)
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.phone_outlined,
                                      size: 18,
                                      color: AppTheme.actionBlue,
                                    ),
                                    label: Text(_company.phone!),
                                    onPressed: () =>
                                        _launch('tel:${_company.phone!}'),
                                    backgroundColor: AppTheme.subtleSurface,
                                  ),
                                if (_company.address != null &&
                                    _company.address!.isNotEmpty)
                                  Chip(
                                    avatar: const Icon(
                                      Icons.location_on_outlined,
                                      size: 18,
                                      color: AppTheme.actionBlue,
                                    ),
                                    label: Text(_company.address!),
                                    backgroundColor: AppTheme.subtleSurface,
                                  ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Linked Catalog Items Card
                        FormSectionCard(
                          title:
                              'المنتجات المرتبطة في المخزون (${_linkedItems.length})',
                          icon: Icons.inventory_2_outlined,
                          children: [
                            _linkedItems.isNotEmpty
                                ? ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _linkedItems.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final item = _linkedItems[index];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppTheme.actionBlue
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.shopping_bag_outlined,
                                            color: AppTheme.actionBlue,
                                          ),
                                        ),
                                        title: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle:
                                            item.brand != null &&
                                                item.brand!.isNotEmpty
                                            ? Text(
                                                'العلامة التجارية: ${item.brand!}',
                                              )
                                            : null,
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.subtleSurface,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            'الكمية: ${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : const Text(
                                    'لا توجد منتجات مسجلة في المخزون تابعة لهذه الشركة حتى الآن.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.secondaryText,
                                    ),
                                  ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.deepCobalt, AppTheme.actionBlue],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepCobalt.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _company.image != null && _company.image!.isNotEmpty
                ? Image.network(
                    _company.image!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Text(
                        _company.name.isNotEmpty
                            ? _company.name[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.actionBlue,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      _company.name.isNotEmpty
                          ? _company.name[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.actionBlue,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _company.arabicName.isNotEmpty
                            ? _company.arabicName
                            : _company.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_company.code != null && _company.code!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _company.code!,
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
                  _company.englishName.isNotEmpty
                      ? _company.englishName
                      : _company.name,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textDirection: TextDirection.ltr,
                ),
                if (_company.address != null &&
                    _company.address!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 15,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _company.address!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
