import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';
import 'package:bokrah_retail/app/features/departments/data/services/departments_service.dart';
import 'package:bokrah_retail/app/features/departments/domain/entities/department_entity.dart';
import 'package:bokrah_retail/app/features/items/data/services/items_service.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/initialzation_dependencies.dart';

/// Index page for listing, searching, and managing departments.
class DepartmentsPage extends StatefulWidget {
  final bool showAppBar;
  final DepartmentsService? departmentsService;
  final ItemsService? itemsService;

  const DepartmentsPage({
    super.key,
    this.showAppBar = true,
    this.departmentsService,
    this.itemsService,
  });

  @override
  State<DepartmentsPage> createState() => _DepartmentsPageState();
}

class _DepartmentsPageState extends State<DepartmentsPage> {
  late final DepartmentsService _departmentsService;
  late final ItemsService _itemsService;
  final TextEditingController _searchController = TextEditingController();

  List<DepartmentEntity> _departments = [];
  List<ItemEntity> _items = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _departmentsService = widget.departmentsService ??
        (singelton.isRegistered<DepartmentsService>()
            ? singelton<DepartmentsService>()
            : DepartmentsService());
    _itemsService = widget.itemsService ??
        (singelton.isRegistered<ItemsService>()
            ? singelton<ItemsService>()
            : ItemsService());
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final depts = await _departmentsService.getAllDepartments();
    final items = await _itemsService.getAllItems();

    if (!mounted) return;
    setState(() {
      _departments = depts;
      _items = items;
      _isLoading = false;
    });
  }

  int _getItemCount(int departmentId) {
    return _items.where((i) => i.effectiveDepartmentId == departmentId).length;
  }

  List<DepartmentEntity> get _filteredDepartments {
    if (_searchQuery.trim().isEmpty) return _departments;
    final q = _searchQuery.trim().toLowerCase();
    return _departments.where((d) {
      final nameMatch = d.name.toLowerCase().contains(q);
      final codeMatch = d.code?.toLowerCase().contains(q) ?? false;
      final descMatch = d.description?.toLowerCase().contains(q) ?? false;
      return nameMatch || codeMatch || descMatch;
    }).toList();
  }

  Future<void> _navigateToAddDepartment() async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/departments',
    )) {
      return;
    }
    if (!mounted) return;

    final result = await context.push<bool>('/add-department');
    if (result == true && mounted) {
      _loadData();
    }
  }

  Future<void> _navigateToUpdateDepartment(DepartmentEntity department) async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/departments',
    )) {
      return;
    }
    if (!mounted) return;

    final result = await context.push<bool>(
      '/update-department',
      extra: {
        'department': department,
        'itemCount':
            department.id != null ? _getItemCount(department.id!) : 0,
      },
    );
    if (result == true && mounted) {
      _loadData();
    }
  }

  Future<void> _deleteDepartment(DepartmentEntity department) async {
    if (department.id == null) return;

    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/departments',
    )) {
      return;
    }
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final itemCount = _getItemCount(department.id!);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.confirmDeleteDepartmentTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${l10n.confirmDeleteDepartmentMessage} (${department.name})'),
            if (itemCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$itemCount ${l10n.departmentItemsCountLabel}',
                style: const TextStyle(
                  color: AppTheme.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _departmentsService.deleteDepartment(
        department.id!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? l10n.departmentDeletedSuccess : l10n.departmentDeleteError,
          ),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
        ),
      );
      if (success) {
        _loadData();
      }
    }
  }

  Widget _buildMetricsRow(AppLocalizations l10n) {
    final totalLinkedItems = _departments.fold<int>(
      0,
      (sum, dept) => sum + (dept.id != null ? _getItemCount(dept.id!) : 0),
    );

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: StatMetricCard(
              title: l10n.totalDepartments,
              value: '${_departments.length}',
              icon: Icons.category_outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatMetricCard(
              title: l10n.linkedItemsCount,
              value: '$totalLinkedItems',
              icon: Icons.inventory_2_outlined,
              style: const StatMetricStyle(color: AppTheme.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    final isSearching = _searchQuery.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 72,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching
                  ? l10n.noMatchingDepartments
                  : l10n.noDepartmentsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearching ? l10n.tryAnotherSearch : l10n.noDepartmentsSubtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _navigateToAddDepartment,
                icon: const Icon(Icons.add),
                label: Text(l10n.addDepartment),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentCard(AppLocalizations l10n, DepartmentEntity dept) {
    final itemCount = dept.id != null ? _getItemCount(dept.id!) : 0;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0.5,
      margin: const EdgeInsetsDirectional.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppTheme.actionBlue.withValues(alpha: 0.12),
          child: const Icon(
            Icons.category_rounded,
            color: AppTheme.actionBlue,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                dept.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (dept.code != null && dept.code!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  dept.code!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (dept.description != null && dept.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                dept.description!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: itemCount > 0
                    ? AppTheme.success.withValues(alpha: 0.1)
                    : colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$itemCount ${l10n.departmentItemsCountLabel}',
                style: TextStyle(
                  fontSize: 11,
                  color: itemCount > 0
                      ? AppTheme.success
                      : Theme.of(context).textTheme.bodySmall?.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 14),
              tooltip: l10n.viewDepartmentItems,
              onPressed: () {
                context.push('/items', extra: dept.id);
              },
            ),
            PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'add_item') {
                  context.push('/add-item', extra: {'departmentId': dept.id});
                } else if (action == 'view_items') {
                  context.push('/items', extra: dept.id);
                } else if (action == 'edit') {
                  _navigateToUpdateDepartment(dept);
                } else if (action == 'delete') {
                  _deleteDepartment(dept);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'add_item',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_box_outlined,
                        size: 18,
                        color: AppTheme.actionBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(l10n.addItemInDepartment),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'view_items',
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 18),
                      const SizedBox(width: 8),
                      Text(l10n.viewDepartmentItems),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit,
                        size: 18,
                        color: AppTheme.actionBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(l10n.editDepartment),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, size: 18, color: AppTheme.error),
                      const SizedBox(width: 8),
                      Text(l10n.deleteDepartment),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filteredDepartments;

    final bodyContent = Column(
      children: [
        SearchFilterToolbar(
          controller: _searchController,
          hintText: l10n.searchDepartmentsHint,
          onSearchChanged: (value) => setState(() => _searchQuery = value),
          onClear: () {
            _searchController.clear();
            setState(() => _searchQuery = '');
          },
          actions: [
            FilledButton.icon(
              onPressed: _navigateToAddDepartment,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addDepartment),
              style: FilledButton.styleFrom(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildMetricsRow(l10n),
                    Expanded(
                      child: filtered.isEmpty
                          ? _buildEmptyState(l10n)
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) =>
                                    _buildDepartmentCard(l10n, filtered[index]),
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );

    if (!widget.showAppBar) return bodyContent;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.departmentsManagementTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
            child: FilledButton.icon(
              onPressed: _navigateToAddDepartment,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addDepartment),
            ),
          ),
        ],
      ),
      body: bodyContent,
    );
  }
}
