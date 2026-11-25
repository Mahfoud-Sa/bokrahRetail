import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';
import 'package:bokrah_retail/app/features/companies/domain/entities/company_entity.dart';
import 'package:bokrah_retail/app/features/companies/domain/usecases/company_usecases.dart';
import 'package:bokrah_retail/app/features/companies/presentation/bloc/companies_cubit.dart';
import 'package:bokrah_retail/app/features/companies/presentation/bloc/companies_state.dart';
import 'package:bokrah_retail/app/features/companies/presentation/company_access.dart';
import 'package:bokrah_retail/app/features/companies/presentation/pages/add_company_page.dart';
import 'package:bokrah_retail/app/features/companies/presentation/pages/update_company_page.dart';
import 'package:bokrah_retail/app/features/companies/presentation/pages/company_details_page.dart';
import 'package:bokrah_retail/app/features/companies/presentation/widgets/company_card.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/initialzation_dependencies.dart';

/// The central Index page for Companies & Brands Management.
///
/// Provides its own [CompaniesCubit] via [BlocProvider].
class CompaniesPage extends StatelessWidget {
  final bool showAppBar;
  const CompaniesPage({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => singelton<CompaniesCubit>()..loadCompanies(),
      child: _CompaniesView(showAppBar: showAppBar),
    );
  }
}

// ---------------------------------------------------------------------------
// Private stateful view — owns only UI-local state (search query, view mode).
// All data state lives in CompaniesCubit.
// ---------------------------------------------------------------------------
class _CompaniesView extends StatefulWidget {
  final bool showAppBar;
  const _CompaniesView({required this.showAppBar});

  @override
  State<_CompaniesView> createState() => _CompaniesViewState();
}

class _CompaniesViewState extends State<_CompaniesView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isGridView = true;
  final _searchUseCase = SearchCompaniesUseCase();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool _canManageCompanies() {
    return CompanyAccess.canManage(context);
  }

  Future<bool> _requireAdminPrivileges() async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/companies',
    )) {
      return false;
    }
    if (!mounted) return false;

    if (!await CompanyAccess.requireManage(context)) return false;
    if (!mounted) return false;
    return true;
  }

  List<ItemEntity> _getLinkedItems(
    List<ItemEntity> items,
    CompanyEntity company,
  ) {
    return items.where((item) {
      final itemComp = item.effectiveCompany ?? '';
      final itemBrand = item.brand ?? '';
      return (itemComp.isNotEmpty && company.matchesName(itemComp)) ||
          (itemBrand.isNotEmpty && company.hasBrand(itemBrand));
    }).toList();
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _navigateToAddCompany() async {
    if (!await _requireAdminPrivileges()) return;
    if (!mounted) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CompaniesCubit>(),
          child: const AddCompanyPage(),
        ),
      ),
    );
    if (result == true && mounted) {
      context.read<CompaniesCubit>().refresh();
    }
  }

  Future<void> _navigateToUpdateCompany(CompanyEntity company) async {
    if (!await _requireAdminPrivileges()) return;
    if (!mounted) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CompaniesCubit>(),
          child: UpdateCompanyPage(company: company),
        ),
      ),
    );
    if (result == true && mounted) {
      context.read<CompaniesCubit>().refresh();
    }
  }

  Future<void> _navigateToDetails(CompanyEntity company) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CompaniesCubit>(),
          child: CompanyDetailsPage(company: company),
        ),
      ),
    );
    if (result == true && mounted) {
      context.read<CompaniesCubit>().refresh();
    }
  }

  Future<void> _confirmDeleteCompany(
    CompanyEntity company,
    List<ItemEntity> items,
  ) async {
    if (!await _requireAdminPrivileges()) return;
    if (!mounted) return;

    final linked = _getLinkedItems(items, company);

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
                'هل أنت متأكد من حذف شركة "${company.arabicName.isNotEmpty ? company.arabicName : company.name}"؟',
                style: const TextStyle(fontSize: 14),
              ),
              if (company.brands.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'سيتم أيضاً إزالة ربط العلامات التجارية (${company.brands.join(', ')}).',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
              if (linked.isNotEmpty) ...[
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
                          'تنبيه: يوجد ${linked.length} منتج مسجل في المخزون مرتبط بهذه الشركة أو علاماتها.',
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

    if (confirmed == true && company.id != null && mounted) {
      final success = await context.read<CompaniesCubit>().deleteCompany(
        company.id!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'تم حذف الشركة بنجاح' : 'تعذر حذف الشركة'),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final body = Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.mainBackground,
        body: BlocBuilder<CompaniesCubit, CompaniesState>(
          builder: (context, state) {
            if (state.status == CompaniesStatus.loading ||
                state.status == CompaniesStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == CompaniesStatus.error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppTheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(state.errorMessage ?? '', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<CompaniesCubit>().loadCompanies(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              );
            }

            final filtered = _searchUseCase(state.companies, _searchQuery);

            return RefreshIndicator(
              onRefresh: () => context.read<CompaniesCubit>().loadCompanies(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildMetricsRow(state),
                    const SizedBox(height: 20),
                    _buildFilterBar(),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty)
                      _buildEmptyState()
                    else if (_isGridView)
                      _buildGridView(filtered, state.items)
                    else
                      _buildTableView(filtered, state.items),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    if (widget.showAppBar) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('إدارة الشركات والعلامات التجارية'),
            backgroundColor: AppTheme.deepCobalt,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go('/home');
                }
              },
            ),
          ),
          body: body,
        ),
      );
    }

    return body;
  }

  // ── Section builders ──────────────────────────────────────────────────────

  Widget _buildHeader() {
    final canManage = _canManageCompanies();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        final titleCol = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.deepCobalt.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: AppTheme.deepCobalt,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إدارة الشركات والعلامات التجارية',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    Text(
                      'سجل الشركات المصنعة والموردة، والعلامات التجارية التابعة لها',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        final addButton = FilledButton.icon(
          onPressed: canManage ? _navigateToAddCompany : null,
          icon: const Icon(Icons.add_business, size: 18),
          label: const Text('إضافة شركة جديدة'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.actionBlue,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [titleCol, const SizedBox(height: 14), addButton],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: titleCol),
            addButton,
          ],
        );
      },
    );
  }

  Widget _buildMetricsRow(CompaniesState state) {
    final totalBrands = <String>{};
    for (final c in state.companies) {
      totalBrands.addAll(c.brands);
    }
    final linkedItemsCount = state.items
        .where((i) => i.effectiveCompany != null || i.brand != null)
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 3 : 1;

        final cards = [
          StatMetricCard(
            title: 'إجمالي الشركات',
            value: '${state.companies.length}',
            icon: Icons.corporate_fare,
            style: const StatMetricStyle(
              subtitle: 'شركة مصنعة / موردة',
              color: AppTheme.deepCobalt,
            ),
          ),
          StatMetricCard(
            title: 'إجمالي العلامات التجارية',
            value: '${totalBrands.length}',
            icon: Icons.branding_watermark_outlined,
            style: const StatMetricStyle(
              subtitle: 'علامة تجارية مسجلة',
              color: AppTheme.warmOrange,
            ),
          ),
          StatMetricCard(
            title: 'منتجات مرتبطة بشركات',
            value: '$linkedItemsCount',
            icon: Icons.inventory_2_outlined,
            style: const StatMetricStyle(
              subtitle: 'عنصر في الكتالوج',
              color: AppTheme.actionBlue,
            ),
          ),
        ];

        if (crossCount == 1) {
          return Column(
            children: cards
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: c,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: cards
              .map(
                (c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: c,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    'ابحث باسم الشركة بالعربية أو الإنجليزية، أو بالعلامة التجارية، أو الكود...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppTheme.secondaryText,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: InputBorder.none,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          const SizedBox(width: 8),
          Container(height: 24, width: 1, color: AppTheme.border),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.grid_view_rounded,
              color: _isGridView ? AppTheme.actionBlue : AppTheme.secondaryText,
            ),
            tooltip: 'عرض الشبكة',
            onPressed: () => setState(() => _isGridView = true),
          ),
          IconButton(
            icon: Icon(
              Icons.view_list_rounded,
              color: !_isGridView
                  ? AppTheme.actionBlue
                  : AppTheme.secondaryText,
            ),
            tooltip: 'عرض الجدول',
            onPressed: () => setState(() => _isGridView = false),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(List<CompanyEntity> companies, List<ItemEntity> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 1;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 700) {
          crossAxisCount = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 260,
          ),
          itemCount: companies.length,
          itemBuilder: (context, index) {
            final company = companies[index];
            final linkedItems = _getLinkedItems(items, company);
            return CompanyCard(
              company: company,
              linkedItemsCount: linkedItems.length,
              actions: CompanyCardActions(
                onDetails: () => _navigateToDetails(company),
                onEdit: () => _navigateToUpdateCompany(company),
                onDelete: () => _confirmDeleteCompany(company, items),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTableView(
    List<CompanyEntity> companies,
    List<ItemEntity> items,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.all(AppTheme.subtleSurface),
          columns: const [
            DataColumn(
              label: Text(
                'الشركة',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'الاسم بالإنجليزية',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'الكود',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'العلامات التجارية',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'المنتجات',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'الإجراءات',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          rows: companies.map((company) {
            final linked = _getLinkedItems(items, company);
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.subtleSurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child:
                            company.image != null && company.image!.isNotEmpty
                            ? Image.network(
                                company.image!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    company.name.isNotEmpty
                                        ? company.name[0]
                                        : 'C',
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  company.name.isNotEmpty
                                      ? company.name[0]
                                      : 'C',
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        company.arabicName.isNotEmpty
                            ? company.arabicName
                            : company.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    company.englishName.isNotEmpty
                        ? company.englishName
                        : company.name,
                    textDirection: TextDirection.ltr,
                  ),
                ),
                DataCell(
                  company.code != null && company.code!.isNotEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.actionBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            company.code!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.actionBlue,
                            ),
                          ),
                        )
                      : const Text('-'),
                ),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: company.brands.isNotEmpty
                        ? Text(
                            company.brands.join('، '),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          )
                        : const Text(
                            '-',
                            style: TextStyle(color: AppTheme.mutedText),
                          ),
                  ),
                ),
                DataCell(Text('${linked.length} عنصر')),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.visibility_outlined,
                          size: 18,
                          color: AppTheme.actionBlue,
                        ),
                        tooltip: 'تفاصيل',
                        onPressed: () => _navigateToDetails(company),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: AppTheme.secondaryText,
                        ),
                        tooltip: 'تعديل',
                        onPressed: () => _navigateToUpdateCompany(company),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppTheme.error,
                        ),
                        tooltip: 'حذف',
                        onPressed: () => _confirmDeleteCompany(company, items),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: ItemsEmptyState(
        isFiltered: _searchQuery.isNotEmpty,
        icon: Icons.business_outlined,
        emptyTitle: 'لم يتم تسجيل أي شركات حتى الآن',
        emptySubtitle:
            'أضف الشركات المصنعة والموردة لتنظيم المنتجات وربط العلامات التجارية بها',
        filteredTitle: 'لا توجد نتائج مطابقة لبحثك',
        filteredSubtitle: 'جرب البحث بكلمات أخرى أو تحقق من تهجئة الاسم',
        buttonLabel: 'إضافة شركة الآن',
        onAddItem: _navigateToAddCompany,
      ),
    );
  }
}
