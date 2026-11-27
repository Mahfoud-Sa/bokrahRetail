import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';
import 'package:bokrah_retail/app/features/categories/presentation/bloc/categories_cubit.dart';
import 'package:bokrah_retail/app/features/categories/presentation/bloc/categories_state.dart';
import 'package:bokrah_retail/app/features/categories/presentation/widgets/category_tree_node.dart';
import 'package:bokrah_retail/app/initialzation_dependencies.dart';

/// The central Index page for Categories Management.
///
/// Provides its own [CategoriesCubit] via [BlocProvider].
class CategoriesPage extends StatelessWidget {
  final bool showAppBar;
  const CategoriesPage({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => singelton<CategoriesCubit>()..loadCategories(),
      child: _CategoriesView(showAppBar: showAppBar),
    );
  }
}

// ---------------------------------------------------------------------------
// Private stateful view — owns only UI-local state (search query).
// All data state lives in CategoriesCubit.
// ---------------------------------------------------------------------------
class _CategoriesView extends StatefulWidget {
  final bool showAppBar;
  const _CategoriesView({required this.showAppBar});

  @override
  State<_CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<_CategoriesView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CategoriesCubit>();

    return BlocBuilder<CategoriesCubit, CategoriesState>(
      builder: (context, state) {
        final filteredRoots = cubit.filterCategories(_searchQuery);

        final bodyContent = Column(
          children: [
            _buildHeaderToolbar(context, cubit),
            Expanded(child: _buildBody(context, cubit, state, filteredRoots)),
          ],
        );

        if (!widget.showAppBar) {
          return bodyContent;
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text(
              'شجرة الفئات والتصنيفات',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                tooltip: 'توسيع الكل',
                icon: const Icon(Icons.unfold_more),
                onPressed: () => cubit.expandAll(),
              ),
              IconButton(
                tooltip: 'طي الكل',
                icon: const Icon(Icons.unfold_less),
                onPressed: () => cubit.collapseAll(),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8.0, start: 4.0),
                child: FilledButton.icon(
                  onPressed: () async {
                    final res = await context.push('/add-category');
                    if (res == true) {
                      cubit.loadCategories();
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة فئة رئيسية'),
                ),
              ),
            ],
          ),
          body: bodyContent,
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    CategoriesCubit cubit,
    CategoriesState state,
    List dynamicRoots,
  ) {
    if (state.status == CategoriesStatus.loading && state.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == CategoriesStatus.error && state.categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(
              state.errorMessage ?? 'حدث خطأ أثناء تحميل الفئات',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => cubit.loadCategories(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (dynamicRoots.isEmpty) {
      return _buildEmptyState(context, cubit);
    }

    return RefreshIndicator(
      onRefresh: () => cubit.loadCategories(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dynamicRoots.length,
        itemBuilder: (context, index) {
          final root = dynamicRoots[index];
          return CategoryTreeNode(category: root, cubit: cubit, depth: 0);
        },
      ),
    );
  }

  Widget _buildHeaderToolbar(BuildContext context, CategoriesCubit cubit) {
    return SearchFilterToolbar(
      controller: _searchController,
      hintText: 'البحث في شجرة الفئات بالاسم أو الكود...',
      onSearchChanged: (v) => setState(() => _searchQuery = v),
      onClear: () {
        _searchController.clear();
        setState(() => _searchQuery = '');
      },
      actions: [
        FilledButton.icon(
          onPressed: () async {
            final res = await context.push('/add-category');
            if (res == true) {
              cubit.loadCategories();
            }
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('إضافة فئة رئيسية'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, CategoriesCubit cubit) {
    return ItemsEmptyState(
      isFiltered: _searchQuery.isNotEmpty,
      icon: Icons.account_tree_outlined,
      emptyTitle: 'لا توجد فئات مسجلة في شجرة التصنيف بعد',
      emptySubtitle:
          'ابدأ ببناء شجرة الفئات عبر إضافة فئات رئيسية وفرعية متفرعة',
      filteredTitle: 'لا توجد فئات مطابقة لمعايير البحث',
      filteredSubtitle: 'جرّب كتابة كلمة بحث أخرى أو إلغاء التصفية',
      buttonLabel: 'إضافة أول فئة رئيسية',
      onAddItem: () async {
        final res = await context.push('/add-category');
        if (res == true) {
          cubit.loadCategories();
        }
      },
    );
  }
}
