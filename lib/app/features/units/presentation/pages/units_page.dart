import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';
import 'package:bokrah_retail/app/features/units/domain/entities/unit_entity.dart';
import 'package:bokrah_retail/app/features/units/domain/usecases/unit_usecases.dart';
import 'package:bokrah_retail/app/features/units/presentation/cubits/unit_cubit.dart';
import 'package:bokrah_retail/app/features/units/presentation/cubits/unit_state.dart';
import 'package:bokrah_retail/app/features/units/presentation/widgets/unit_card.dart';
import 'package:bokrah_retail/app/initialzation_dependencies.dart';

/// Management page for Units of Measurement (وحدات القياس).
class UnitsPage extends StatelessWidget {
  final bool showAppBar;

  const UnitsPage({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => singelton<UnitCubit>()..loadAllUnits(),
      child: _UnitsView(showAppBar: showAppBar),
    );
  }
}

class _UnitsView extends StatefulWidget {
  final bool showAppBar;

  const _UnitsView({required this.showAppBar});

  @override
  State<_UnitsView> createState() => _UnitsViewState();
}

class _UnitsViewState extends State<_UnitsView> {
  final TextEditingController _searchController = TextEditingController();
  final SearchUnitsUseCase _searchUnits = SearchUnitsUseCase();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showAddEditUnitDialog({UnitEntity? unit}) async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/units',
    )) {
      return;
    }
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<UnitCubit>();
    final isEditing = unit != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: unit?.name ?? '');
    final factorController = TextEditingController(
      text: unit != null ? unit.factor.toString() : '1.0',
    );
    final barcodesController = TextEditingController(
      text: unit?.barcodes.join(', ') ?? '',
    );

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          title: Text(
            isEditing ? l10n.editUnit : l10n.addUnit,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.unitName,
                      hintText: l10n.unitNameHint,
                      prefixIcon: const Icon(Icons.straighten_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? l10n.unitNameRequired
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: factorController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: l10n.conversionFactor,
                      hintText: l10n.conversionFactorHint,
                      prefixIcon: const Icon(Icons.calculate_outlined),
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed <= 0) {
                        return l10n.conversionFactorInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: barcodesController,
                    decoration: InputDecoration(
                      labelText: l10n.unitBarcodes,
                      prefixIcon: const Icon(Icons.qr_code_2_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final name = nameController.text.trim();
                final factor = double.parse(factorController.text.trim());
                final barcodes = barcodesController.text
                    .split(',')
                    .map((b) => b.trim())
                    .where((b) => b.isNotEmpty)
                    .toList();

                final bool success;
                if (isEditing) {
                  success = await cubit.updateUnit(
                    unit.copyWith(
                      name: name,
                      factor: factor,
                      barcodes: barcodes,
                    ),
                  );
                } else {
                  success = await cubit.saveUnit(
                    UnitEntity(
                      name: name,
                      factor: factor,
                      itemId: 0,
                      barcodes: barcodes,
                    ),
                  );
                }

                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (isEditing
                              ? l10n.unitUpdatedSuccess
                              : l10n.unitSavedSuccess)
                          : l10n.unitActionFailed,
                    ),
                    backgroundColor:
                        success ? AppTheme.success : AppTheme.error,
                  ),
                );
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      );
    } finally {
      nameController.dispose();
      factorController.dispose();
      barcodesController.dispose();
    }
  }

  Future<void> _confirmDeleteUnit(UnitEntity unit) async {
    if (unit.id == null) return;
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/units',
    )) {
      return;
    }
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<UnitCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.confirmDeleteUnitTitle),
        content: Text('${l10n.confirmDeleteUnitMessage} (${unit.name})'),
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
      final success = await cubit.deleteUnit(unit.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? l10n.unitDeletedSuccess : l10n.unitActionFailed,
          ),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
        ),
      );
    }
  }

  Widget _buildMetricsRow(AppLocalizations l10n, List<UnitEntity> units) {
    final baseCount = units.where((u) => u.factor == 1.0).length;
    final packagingCount = units.length - baseCount;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          final cards = [
            StatMetricCard(
              title: l10n.totalUnits,
              value: '${units.length}',
              icon: Icons.straighten_rounded,
            ),
            StatMetricCard(
              title: l10n.baseUnits,
              value: '$baseCount',
              icon: Icons.looks_one_outlined,
              style: const StatMetricStyle(color: AppTheme.success),
            ),
            StatMetricCard(
              title: l10n.packagingUnits,
              value: '$packagingCount',
              icon: Icons.inventory_2_outlined,
              style: const StatMetricStyle(color: AppTheme.deepCobalt),
            ),
          ];

          if (isWide) {
            return Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
                const SizedBox(width: 12),
                Expanded(child: cards[2]),
              ],
            );
          }

          return Column(
            children: [
              cards[0],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: cards[1]),
                  const SizedBox(width: 8),
                  Expanded(child: cards[2]),
                ],
              ),
            ],
          );
        },
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
              Icons.straighten_outlined,
              size: 72,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? l10n.noMatchingUnits : l10n.noUnitsTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearching ? l10n.tryAnotherSearch : l10n.noUnitsSubtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (!isSearching) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _showAddEditUnitDialog(),
                icon: const Icon(Icons.add),
                label: Text(l10n.addUnit),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final body = Column(
      children: [
        SearchFilterToolbar(
          controller: _searchController,
          hintText: l10n.searchUnitsHint,
          onSearchChanged: (value) => setState(() => _searchQuery = value),
          onClear: () {
            _searchController.clear();
            setState(() => _searchQuery = '');
          },
          actions: [
            FilledButton.icon(
              onPressed: () => _showAddEditUnitDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addUnit),
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
          child: BlocBuilder<UnitCubit, UnitState>(
            builder: (context, state) {
              if (state is UnitLoading || state is UnitInitial) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is UnitError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(state.message),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => context.read<UnitCubit>().refresh(),
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ),
                );
              }

              final units = state is UnitLoaded ? state.units : <UnitEntity>[];
              final filtered = _searchUnits(units, _searchQuery);

              return Column(
                children: [
                  _buildMetricsRow(l10n, units),
                  Expanded(
                    child: filtered.isEmpty
                        ? _buildEmptyState(l10n)
                        : RefreshIndicator(
                            onRefresh: () =>
                                context.read<UnitCubit>().refresh(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final unit = filtered[index];
                                return UnitCard(
                                  unit: unit,
                                  onEdit: () =>
                                      _showAddEditUnitDialog(unit: unit),
                                  onDelete: () => _confirmDeleteUnit(unit),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );

    if (!widget.showAppBar) return body;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.unitsManagementTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
            child: FilledButton.icon(
              onPressed: () => _showAddEditUnitDialog(),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.addUnit),
            ),
          ),
        ],
      ),
      body: body,
    );
  }
}
