import 'package:bokrah_design_system/bokrah_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bokrah_retail/app/core/widgets/guards/permission_guard.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_rbac_cubit.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_rbac_state.dart';
import '../../data/models/permission_model.dart';
import '../../data/models/role_model.dart';
import '../cubits/roles_cubit.dart';
import '../cubits/roles_state.dart';

class RolesManagementView extends StatefulWidget {
  const RolesManagementView({super.key});

  @override
  State<RolesManagementView> createState() => _RolesManagementViewState();
}

class _RolesManagementViewState extends State<RolesManagementView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditRoleDialog({RoleModel? roleToEdit}) {
    final rolesCubit = context.read<RolesCubit>();
    final isEditing = roleToEdit != null;
    final nameController = TextEditingController(text: roleToEdit?.name ?? '');
    final formKey = GlobalKey<FormState>();

    // Initial selected permission IDs
    final selectedPermissionIds = <int>{
      if (roleToEdit != null) ...roleToEdit.permissionIds,
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            final state = rolesCubit.state;
            final grouped = state.groupedPermissions;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BkRadius.lg),
              ),
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.security_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'تعديل الدور والصلاحيات' : 'إضافة دور جديد وتخصيص صلاحياته',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              content: SizedBox(
                width: 600,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: nameController,
                          enabled: roleToEdit?.isSystemRole != true,
                          decoration: InputDecoration(
                            labelText: 'اسم الدور *',
                            hintText: 'مثال: مشرف مبيعات، أمين مستودع، كاشير...',
                            prefixIcon: const Icon(Icons.badge_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(BkRadius.md),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'يرجى إدخال اسم الدور';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'الصلاحيات الممنوحة (${selectedPermissionIds.length}/${state.permissions.length}):',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.select_all_rounded, size: 16),
                                  label: const Text('تحديد الكل'),
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedPermissionIds.addAll(
                                        state.permissions.map((p) => p.id),
                                      );
                                    });
                                  },
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.deselect_rounded, size: 16),
                                  label: const Text('إلغاء الكل'),
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedPermissionIds.clear();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(),
                        if (state.permissions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text('جاري تحميل الصلاحيات المتاحة...'),
                            ),
                          )
                        else
                          ...grouped.entries.map((entry) {
                            final categoryName = entry.key;
                            final perms = entry.value;
                            final allCategorySelected = perms.every(
                              (p) => selectedPermissionIds.contains(p.id),
                            );

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                                ),
                                borderRadius: BorderRadius.circular(BkRadius.md),
                              ),
                              child: ExpansionTile(
                                initiallyExpanded: true,
                                title: Row(
                                  children: [
                                    Text(
                                      categoryName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    BkBadge(
                                      label: '${perms.where((p) => selectedPermissionIds.contains(p.id)).length}/${perms.length}',
                                      tone: allCategorySelected ? BkTone.success : BkTone.neutral,
                                    ),
                                  ],
                                ),
                                trailing: Checkbox(
                                  value: allCategorySelected,
                                  tristate: perms.any((p) => selectedPermissionIds.contains(p.id)) && !allCategorySelected,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == true) {
                                        selectedPermissionIds.addAll(perms.map((p) => p.id));
                                      } else {
                                        selectedPermissionIds.removeAll(perms.map((p) => p.id));
                                      }
                                    });
                                  },
                                ),
                                children: perms.map((perm) {
                                  final isChecked = selectedPermissionIds.contains(perm.id);
                                  return CheckboxListTile(
                                    dense: true,
                                    value: isChecked,
                                    title: Text(
                                      perm.description,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    subtitle: Text(
                                      perm.code,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ),
                                    onChanged: (val) {
                                      setDialogState(() {
                                        if (val == true) {
                                          selectedPermissionIds.add(perm.id);
                                        } else {
                                          selectedPermissionIds.remove(perm.id);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                BkButton(
                  label: 'إلغاء',
                  variant: BkButtonVariant.secondary,
                  onPressed: () => Navigator.pop(dialogCtx),
                ),
                BkButton(
                  label: isEditing ? 'تحديث الدور' : 'حفظ الدور',
                  variant: BkButtonVariant.primary,
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final roleName = nameController.text.trim();
                      bool success = false;
                      if (isEditing) {
                        success = await rolesCubit.updateRole(
                          id: roleToEdit.id,
                          name: roleName,
                          permissionIds: selectedPermissionIds.toList(),
                        );
                      } else {
                        success = await rolesCubit.createRole(
                          name: roleName,
                          permissionIds: selectedPermissionIds.toList(),
                        );
                      }
                      if (dialogCtx.mounted && success) {
                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEditing
                                  ? 'تم تحديث الدور بنجاح'
                                  : 'تم إنشاء الدور الجديد بنجاح',
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RolesCubit, RolesState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        StoreRbacState? rbacState;
        try {
          rbacState = context.watch<StoreRbacCubit>().state;
        } catch (_) {}

        if (state.status == RolesStatus.loading && state.roles.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredRoles = state.roles.where((role) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return role.name.toLowerCase().contains(q) ||
              role.displayName.toLowerCase().contains(q);
        }).toList();

        return RefreshIndicator(
          onRefresh: () => context.read<RolesCubit>().loadRolesAndPermissions(),
          child: ListView(
            padding: const EdgeInsets.all(BkSpace.md),
            children: [
              // Header description & Action button
              Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(BkRadius.md),
                  side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(BkSpace.md),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: BkSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'إدارة أدوار وصلاحيات النظام',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'قم بتهيئة الأدوار وتعيين الصلاحيات للمهام المختلفة قبل تعيينها للمستخدمين.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: BkSpace.sm),
                      PermissionGuard(
                        userPermissions: rbacState?.currentPermissions ?? const [],
                        isOwner: rbacState?.isCurrentMemberOwner ?? true,
                        requiredPermission: 'store.roles.manage',
                        child: BkButton(
                          label: 'إضافة دور جديد',
                          icon: Icons.add_moderator_rounded,
                          variant: BkButtonVariant.primary,
                          onPressed: () => _showAddEditRoleDialog(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: BkSpace.md),

              // Search bar & role count summary
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'بحث في الأدوار...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(BkRadius.md),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    ),
                  ),
                  const SizedBox(width: BkSpace.md),
                  BkBadge(
                    label: '${filteredRoles.length} أدوار',
                    tone: BkTone.neutral,
                  ),
                ],
              ),

              const SizedBox(height: BkSpace.md),

              if (filteredRoles.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(BkSpace.xl),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: BkSpace.sm),
                        const Text(
                          'لا توجد أدوار مطابقة للبحث',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...filteredRoles.map((role) {
                  final assignedPerms = state.getPermissionsForRole(role);
                  final isSystem = role.isSystemRole;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: BkSpace.sm),
                    child: BkCard(
                      child: Padding(
                        padding: const EdgeInsets.all(BkSpace.sm),
                        child: ExpansionTile(
                          shape: const Border(),
                          leading: CircleAvatar(
                            backgroundColor: isSystem
                                ? Theme.of(context).colorScheme.primaryContainer
                                : Theme.of(context).colorScheme.secondaryContainer,
                            child: Icon(
                              isSystem ? Icons.lock_outline : Icons.badge_outlined,
                              color: isSystem
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                role.displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              if (isSystem)
                                const BkBadge(
                                  label: 'نظام',
                                  tone: BkTone.warning,
                                ),
                              const SizedBox(width: 8),
                              BkBadge(
                                label: '${assignedPerms.length} صلاحية',
                                tone: assignedPerms.isNotEmpty ? BkTone.info : BkTone.neutral,
                              ),
                            ],
                          ),
                          subtitle: Text(
                            'المعرّف: ${role.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.tune_rounded),
                                tooltip: 'تعديل الصلاحيات',
                                onPressed: () => _showAddEditRoleDialog(roleToEdit: role),
                              ),
                              if (!isSystem)
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  tooltip: 'حذف الدور',
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('حذف الدور'),
                                        content: Text('هل أنت متأكد من حذف الدور "${role.displayName}"؟'),
                                        actions: [
                                          BkButton(
                                            label: 'إلغاء',
                                            variant: BkButtonVariant.secondary,
                                            onPressed: () => Navigator.pop(ctx, false),
                                          ),
                                          BkButton(
                                            label: 'حذف',
                                            variant: BkButtonVariant.danger,
                                            onPressed: () => Navigator.pop(ctx, true),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true && context.mounted) {
                                      await context.read<RolesCubit>().deleteRole(role.id);
                                    }
                                  },
                                ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  const Text(
                                    'الصلاحيات المخصصة لهذا الدور:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (assignedPerms.isEmpty)
                                    Text(
                                      'لا توجد صلاحيات معينة لهذا الدور بعد. اضغط على أيقونة التعديل لإضافة صلاحيات.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).colorScheme.outline,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    )
                                  else
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: assignedPerms.map((perm) {
                                        return Chip(
                                          visualDensity: VisualDensity.compact,
                                          avatar: const Icon(Icons.check_circle_outline, size: 16),
                                          label: Text(
                                            perm.description,
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

