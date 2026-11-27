import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';
import 'package:bokrah_retail/app/features/barcoders/domain/entities/barcode_entity.dart';
import 'package:bokrah_retail/app/features/barcoders/presentation/bloc/barcodes_cubit.dart';
import 'package:bokrah_retail/app/features/barcoders/presentation/bloc/barcodes_state.dart';
import 'package:bokrah_retail/app/features/items/domain/entities/item_entity.dart';
import 'package:bokrah_retail/app/features/items/presentation/widgets/barcode_scanner_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BarcodesPage extends StatelessWidget {
  final bool showAppBar;
  final BarcodesCubit? cubit;

  const BarcodesPage({super.key, this.showAppBar = true, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<BarcodesCubit>.value(
        value: cubit!..loadBarcodes(),
        child: _BarcodesView(showAppBar: showAppBar),
      );
    }
    return BlocProvider(
      create: (_) => BarcodesCubit()..loadBarcodes(),
      child: _BarcodesView(showAppBar: showAppBar),
    );
  }
}

class _BarcodesView extends StatefulWidget {
  final bool showAppBar;

  const _BarcodesView({required this.showAppBar});

  @override
  State<_BarcodesView> createState() => _BarcodesViewState();
}

class _BarcodesViewState extends State<_BarcodesView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<BarcodeEntity> _filterBarcodes(BarcodesState state) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return state.barcodes;

    return state.barcodes.where((barcode) {
      if (barcode.code.toLowerCase().contains(q)) return true;
      if ((barcode.label ?? '').toLowerCase().contains(q)) return true;
      final linked = state.relatedItems[barcode.id] ?? const [];
      return linked.any((item) => item.name.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _showAddEditDialog(
    BuildContext context, {
    BarcodeEntity? barcode,
  }) async {
    final cubit = context.read<BarcodesCubit>();
    final isEditing = barcode != null;
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController(text: barcode?.code ?? '');
    final labelController = TextEditingController(text: barcode?.label ?? '');

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            title: Text(isEditing ? 'تعديل الباركود' : 'إضافة باركود جديد'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppFormTextField(
                    controller: codeController,
                    label: 'رمز الباركود *',
                    icon: Icons.qr_code,
                    hintText: 'أدخل الرمز الرقمي',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'يرجى إدخال الرمز'
                        : null,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      tooltip: 'مسح باستخدام الكاميرا',
                      onPressed: () async {
                        final scanned = await showDialog<String>(
                          context: dialogCtx,
                          builder: (_) => const BarcodeScannerDialog(),
                        );
                        if (scanned != null) {
                          codeController.text = scanned;
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppFormTextField(
                    controller: labelController,
                    label: 'وصف/تسمية (اختياري)',
                    icon: Icons.label_outline,
                    hintText: 'مثلاً: باركود المصنع',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final newBarcode = BarcodeEntity(
                    id: barcode?.id,
                    code: codeController.text.trim(),
                    label: labelController.text.trim().isEmpty
                        ? null
                        : labelController.text.trim(),
                    createdAt: barcode?.createdAt,
                  );

                  final success = isEditing
                      ? await cubit.updateBarcode(newBarcode)
                      : await cubit.saveBarcode(newBarcode);

                  if (!dialogCtx.mounted) return;
                  if (success) {
                    Navigator.pop(dialogCtx);
                  }
                },
                child: Text(isEditing ? 'تحديث' : 'حفظ'),
              ),
            ],
          ),
        ),
      );
    } finally {
      codeController.dispose();
      labelController.dispose();
    }
  }

  Future<void> _confirmDeleteBarcode(
    BuildContext context,
    BarcodeEntity barcode,
  ) async {
    if (barcode.id == null) return;
    final cubit = context.read<BarcodesCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف الباركود "${barcode.code}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final success = await cubit.deleteBarcode(barcode.id!);
      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الباركود بنجاح'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  Future<void> _manageLinkedItems(
    BuildContext context,
    BarcodeEntity barcode,
  ) async {
    if (barcode.id == null) return;
    final cubit = context.read<BarcodesCubit>();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => BlocProvider<BarcodesCubit>.value(
        value: cubit,
        child: BlocBuilder<BarcodesCubit, BarcodesState>(
          builder: (ctx, state) {
            final currentlyLinkedIds =
                state.relatedItems[barcode.id!]?.map((it) => it.id).toSet() ??
                {};

            return Directionality(
              textDirection: TextDirection.rtl,
              child: _SearchableItemSelectionDialog(
                allItems: state.allItems,
                currentlyLinkedIds: currentlyLinkedIds,
                barcode: barcode,
                onToggle: (item, val) async {
                  if (item.id == null) return;
                  await cubit.toggleItemLink(
                    itemId: item.id!,
                    barcodeId: barcode.id!,
                    link: val == true,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BarcodesCubit, BarcodesState>(
      builder: (context, state) {
        final filtered = _filterBarcodes(state);

        final content = Column(
          children: [
            SearchFilterToolbar(
              controller: _searchController,
              hintText: 'البحث برمز الباركود أو التسمية أو اسم العنصر...',
              onSearchChanged: (v) => setState(() => _searchQuery = v),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              actions: [
                if (!widget.showAppBar)
                  FilledButton.icon(
                    onPressed: () => _showAddEditDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('إضافة باركود'),
                  ),
              ],
            ),
            if (state.status == BarcodesStatus.loaded &&
                state.barcodes.isNotEmpty)
              _buildMetricsRow(state),
            Expanded(child: _buildBody(context, state, filtered)),
          ],
        );

        return Directionality(
          textDirection: TextDirection.rtl,
          child: widget.showAppBar
              ? Scaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  appBar: AppBar(
                    title: const Text(
                      'الباركودات',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8.0),
                        child: FilledButton.icon(
                          onPressed: () => _showAddEditDialog(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('إضافة باركود'),
                        ),
                      ),
                    ],
                  ),
                  body: content,
                )
              : content,
        );
      },
    );
  }

  Widget _buildMetricsRow(BarcodesState state) {
    final linkedBarcodesCount = state.barcodes
        .where((b) => (state.relatedItems[b.id] ?? const []).isNotEmpty)
        .length;
    final totalLinkedItems = state.relatedItems.values.fold<int>(
      0,
      (sum, list) => sum + list.length,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: StatMetricCard(
              title: 'إجمالي الباركودات',
              value: state.barcodes.length.toString(),
              icon: Icons.qr_code_2,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatMetricCard(
              title: 'مرتبطة بعناصر',
              value: linkedBarcodesCount.toString(),
              icon: Icons.link,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatMetricCard(
              title: 'روابط العناصر',
              value: totalLinkedItems.toString(),
              icon: Icons.inventory_2_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    BarcodesState state,
    List<BarcodeEntity> filtered,
  ) {
    if (state.status == BarcodesStatus.loading && state.barcodes.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == BarcodesStatus.error && state.barcodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(state.errorMessage ?? 'حدث خطأ أثناء تحميل الباركودات'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.read<BarcodesCubit>().loadBarcodes(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return ItemsEmptyState(
        isFiltered: _searchQuery.trim().isNotEmpty,
        icon: Icons.qr_code_outlined,
        emptyTitle: 'لا توجد باركودات بعد',
        emptySubtitle: 'أضف باركودات واربطها بالعناصر لتسهيل البحث والبيع',
        filteredTitle: 'لا توجد باركودات مطابقة للبحث',
        filteredSubtitle: 'جرّب البحث برمز أو تسمية أخرى',
        buttonLabel: 'إضافة باركود',
        onAddItem: () => _showAddEditDialog(context),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<BarcodesCubit>().loadBarcodes(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 1;
          if (constraints.maxWidth > 1200) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth > 700) {
            crossAxisCount = 2;
          }

          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 205,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final barcode = filtered[index];
              final related = state.relatedItems[barcode.id] ?? const [];
              return _BarcodeCard(
                barcode: barcode,
                relatedItems: related,
                onManageLinks: () => _manageLinkedItems(context, barcode),
                onEdit: () => _showAddEditDialog(context, barcode: barcode),
                onDelete: () => _confirmDeleteBarcode(context, barcode),
              );
            },
          );
        },
      ),
    );
  }
}

class _BarcodeCard extends StatelessWidget {
  final BarcodeEntity barcode;
  final List<ItemEntity> relatedItems;
  final VoidCallback onManageLinks;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BarcodeCard({
    required this.barcode,
    required this.relatedItems,
    required this.onManageLinks,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final label = barcode.label?.trim();

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.actionBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    color: AppTheme.actionBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barcode.code,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.deepCobalt,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label != null && label.isNotEmpty
                            ? label
                            : 'بدون تسمية',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'manage') {
                      onManageLinks();
                    } else if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'manage',
                      child: Row(
                        children: [
                          Icon(
                            Icons.link,
                            color: AppTheme.actionBlue,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text('ربط عناصر'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            color: AppTheme.actionBlue,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text('تعديل'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppTheme.error, size: 18),
                          SizedBox(width: 8),
                          Text('حذف'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (relatedItems.isEmpty)
              Text(
                'لا توجد عناصر مرتبطة',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ...relatedItems
                      .take(3)
                      .map(
                        (item) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.deepCobalt.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.deepCobalt,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  if (relatedItems.length > 3)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '+${relatedItems.length - 3}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            const Spacer(),
            const Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${relatedItems.length} عناصر مرتبطة',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton.icon(
                  onPressed: onManageLinks,
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text(
                    'ربط عناصر',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchableItemSelectionDialog extends StatefulWidget {
  final List<ItemEntity> allItems;
  final Set<int?> currentlyLinkedIds;
  final BarcodeEntity barcode;
  final Future<void> Function(ItemEntity, bool?) onToggle;

  const _SearchableItemSelectionDialog({
    required this.allItems,
    required this.currentlyLinkedIds,
    required this.barcode,
    required this.onToggle,
  });

  @override
  State<_SearchableItemSelectionDialog> createState() =>
      _SearchableItemSelectionDialogState();
}

class _SearchableItemSelectionDialogState
    extends State<_SearchableItemSelectionDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.allItems
        .where(
          (item) =>
              item.name.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

    return AlertDialog(
      title: Text('إدارة العناصر لباركود: ${widget.barcode.code}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'بحث عن عنصر...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(child: Text('لا توجد عناصر تطابق البحث'))
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isLinked = widget.currentlyLinkedIds.contains(
                          item.id,
                        );

                        return CheckboxListTile(
                          title: Text(item.name),
                          subtitle: Text('ID: ${item.id}'),
                          value: isLinked,
                          onChanged: (val) => widget.onToggle(item, val),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}
