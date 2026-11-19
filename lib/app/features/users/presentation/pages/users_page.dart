import 'package:bokrah_retail/app/common/widgets/permission_guard.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_rbac_cubit.dart';
import 'package:bokrah_retail/app/features/store/presentation/cubits/store_rbac_state.dart';
import 'package:bokrah_retail/app/features/users/data/entities/user_entity.dart';
import 'package:bokrah_retail/app/features/users/data/models/role_model.dart';
import 'package:bokrah_retail/app/features/users/data/services/users_service.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/roles_cubit.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/roles_state.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/session_cubit.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/session_state.dart';
import 'package:bokrah_retail/app/features/users/presentation/widgets/roles_management_view.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UsersService _usersService = UsersService();
  List<UserEntity> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _usersService.getAllUsers();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  Future<void> _showAddEditDialog({UserEntity? user}) async {
    final isEditing = user != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final phoneController = TextEditingController(
      text: user?.phoneNumber ?? '',
    );
    final addressController = TextEditingController(text: user?.address ?? '');
    final birthDateController = TextEditingController(
      text: user?.birthDate ?? '',
    );

    String? selectedGender = user?.gender ?? 'ذكر';
    bool isActive = user?.isActive ?? true;

    // Resolve initial selected role name
    final rolesCubit = context.read<RolesCubit>();
    final availableRoles = rolesCubit.state.roles.isNotEmpty
        ? rolesCubit.state.roles
        : RoleModel.defaultRoles;

    String selectedRoleName = user?.customRoleName ??
        user?.role.nameEn ??
        (availableRoles.isNotEmpty ? availableRoles.first.name : 'Cashier');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final rolesState = rolesCubit.state;
          final currentRoles = rolesState.roles.isNotEmpty
              ? rolesState.roles
              : RoleModel.defaultRoles;

          // Find current selected role model to display its permissions preview
          final activeRoleModel = currentRoles.firstWhere(
            (r) =>
                r.name.trim().toLowerCase() ==
                selectedRoleName.trim().toLowerCase(),
            orElse: () => currentRoles.first,
          );
          final activePermissions =
              rolesState.getPermissionsForRole(activeRoleModel);

          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(BkRadius.lg),
              ),
              title: Row(
                children: [
                  Icon(
                    isEditing ? Icons.manage_accounts : Icons.person_add_alt_1,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEditing ? 'تعديل بيانات المستخدم' : 'إضافة مستخدم جديد للنظام',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          nameController,
                          'الاسم الكامل *',
                          Icons.person,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          emailController,
                          'البريد الإلكتروني *',
                          Icons.email,
                          isEmail: true,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          phoneController,
                          'رقم الهاتف',
                          Icons.phone,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          addressController,
                          'العنوان',
                          Icons.location_on,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          birthDateController,
                          'تاريخ الميلاد',
                          Icons.cake,
                          isDate: true,
                        ),
                        const SizedBox(height: 16),

                        // Gender Selection
                        Row(
                          children: [
                            const Text(
                              'الجنس:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 16),
                            ChoiceChip(
                              label: const Text('ذكر'),
                              selected: selectedGender == 'ذكر',
                              onSelected: (val) =>
                                  setDialogState(() => selectedGender = 'ذكر'),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('أنثى'),
                              selected: selectedGender == 'أنثى',
                              onSelected: (val) =>
                                  setDialogState(() => selectedGender = 'أنثى'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Role Selection from configured roles
                        const Text(
                          'الدور الوظيفي والصلاحيات:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(BkRadius.md),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: currentRoles.any((r) =>
                                      r.name.trim().toLowerCase() ==
                                      selectedRoleName.trim().toLowerCase())
                                  ? activeRoleModel.name
                                  : currentRoles.first.name,
                              items: currentRoles.map((role) {
                                return DropdownMenuItem<String>(
                                  value: role.name,
                                  child: Row(
                                    children: [
                                      Icon(
                                        role.isSystemRole
                                            ? Icons.security
                                            : Icons.badge_outlined,
                                        size: 18,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          role.displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      BkBadge(
                                        label: '${role.permissionIds.length} صلاحية',
                                        tone: role.permissionIds.isNotEmpty
                                            ? BkTone.info
                                            : BkTone.neutral,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => selectedRoleName = val);
                                }
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Preview of permissions inherited by this role
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(BkSpace.sm),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(BkRadius.sm),
                            border: Border.all(
                              color: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'الصلاحيات الممنوحة لهذا الدور (${activePermissions.length}):',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (activePermissions.isEmpty)
                                Text(
                                  'لا توجد صلاحيات معينة لهذا الدور. يمكنك تخصيص الصلاحيات من تبويب "الأدوار والصلاحيات".',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: activePermissions.take(6).map((p) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                            .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        p.description,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimaryContainer,
                                        ),
                                      ),
                                    );
                                  }).toList()
                                    ..addAll([
                                      if (activePermissions.length > 6)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '+${activePermissions.length - 6} أخرى',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        ),
                                    ]),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('حساب نشط ومفعّل'),
                          value: isActive,
                          onChanged: (val) =>
                              setDialogState(() => isActive = val),
                        ),
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
                  label: isEditing ? 'تحديث' : 'حفظ المستخدم',
                  variant: BkButtonVariant.primary,
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final newUser = UserEntity(
                        id: user?.id,
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        phoneNumber: phoneController.text.trim(),
                        address: addressController.text.trim(),
                        birthDate: birthDateController.text.trim(),
                        gender: selectedGender,
                        role: OperatorRole.fromString(selectedRoleName),
                        customRoleName: activeRoleModel.displayName,
                        isActive: isActive,
                        createdAt: user?.createdAt,
                      );

                      bool success = isEditing
                          ? await _usersService.updateUser(newUser)
                          : await _usersService.saveUser(newUser);

                      if (dialogCtx.mounted && success) {
                        try {
                          final sessionCubit = context.read<SessionCubit>();
                          final currentActive =
                              sessionCubit.state.currentOperator;
                          if (currentActive != null &&
                              ((newUser.id != null &&
                                      currentActive.id == newUser.id) ||
                                  currentActive.email == newUser.email)) {
                            sessionCubit.switchOperator(newUser);
                          }
                        } catch (_) {}
                        Navigator.pop(dialogCtx);
                        _loadUsers();
                      }
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isEmail = false,
    bool isDate = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: isDate,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BkRadius.md),
        ),
      ),
      onTap: isDate
          ? () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1950),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                controller.text =
                    "${pickedDate.year}-${pickedDate.month}-${pickedDate.day}";
              }
            }
          : null,
      validator: (v) {
        if (label.contains('*') && (v == null || v.trim().isEmpty)) {
          return 'هذا الحقل مطلوب';
        }
        if (isEmail && v != null && v.isNotEmpty && !v.contains('@')) {
          return 'بريد إلكتروني غير صحيح';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SessionState? sessionState;
    try {
      sessionState = context.watch<SessionCubit>().state;
    } catch (_) {}
    final activeOperator = sessionState?.currentOperator;

    StoreRbacState? rbacState;
    try {
      rbacState = context.watch<StoreRbacCubit>().state;
    } catch (_) {}

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إدارة المستخدمين والأدوار',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.people_alt_outlined),
                text: 'فريق العمل والمستخدمين',
              ),
              Tab(
                icon: Icon(Icons.admin_panel_settings_outlined),
                text: 'الأدوار والصلاحيات',
              ),
            ],
          ),
          actions: [
            PermissionGuard(
              userPermissions: rbacState?.currentPermissions ?? const [],
              isOwner: rbacState?.isCurrentMemberOwner ?? true,
              requiredPermission: 'store.members.manage',
              child: IconButton(
                icon: const Icon(Icons.person_add),
                tooltip: 'إضافة عضو جديد',
                onPressed: () => _showAddEditDialog(),
              ),
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Users List
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(BkSpace.xl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 80,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: BkSpace.md),
                              Text(
                                'لا يوجد مستخدمون بعد',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: BkSpace.sm),
                              Text(
                                'يمكنك إضافة أعضاء الفريق وتعيين الأدوار والصلاحيات المخصصة لهم.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              const SizedBox(height: BkSpace.xl),
                              BkButton(
                                label: 'إضافة أول مستخدم',
                                icon: Icons.person_add,
                                variant: BkButtonVariant.primary,
                                onPressed: () => _showAddEditDialog(),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(BkSpace.md),
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final isActiveOperator = activeOperator != null &&
                                ((user.id != null &&
                                        user.id == activeOperator.id) ||
                                    user.email == activeOperator.email);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: BkSpace.sm),
                              child: BkCard(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: user.isActive
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).disabledColor,
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          user.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      if (isActiveOperator) ...[
                                        const BkBadge(
                                          label: 'المشغّل الحالي',
                                          tone: BkTone.info,
                                        ),
                                        const SizedBox(width: BkSpace.sm),
                                      ],
                                      BkBadge(
                                        label: user.displayRoleName,
                                        tone: user.role == OperatorRole.admin
                                            ? BkTone.warning
                                            : user.role ==
                                                    OperatorRole.accountant
                                                ? BkTone.info
                                                : BkTone.success,
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(user.email),
                                      if (user.phoneNumber != null &&
                                          user.phoneNumber!.isNotEmpty)
                                        Text(
                                          user.phoneNumber!,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        tooltip: 'تعديل',
                                        onPressed: () =>
                                            _showAddEditDialog(user: user),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: isActiveOperator
                                              ? Theme.of(context).disabledColor
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                        ),
                                        tooltip: isActiveOperator
                                            ? 'المشغّل الحالي (لا يمكن حذفه)'
                                            : 'حذف',
                                        onPressed: isActiveOperator
                                            ? null
                                            : () async {
                                                final confirm =
                                                    await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                    title: const Text(
                                                        'حذف مستخدم'),
                                                    content: Text(
                                                      'هل أنت متأكد من حذف المستخدم "${user.name}"؟',
                                                    ),
                                                    actions: [
                                                      BkButton(
                                                        label: 'إلغاء',
                                                        variant:
                                                            BkButtonVariant
                                                                .secondary,
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, false),
                                                      ),
                                                      BkButton(
                                                        label: 'حذف',
                                                        variant:
                                                            BkButtonVariant
                                                                .danger,
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context, true),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (confirm == true) {
                                                  await _usersService
                                                      .deleteUser(user.id!);
                                                  _loadUsers();
                                                }
                                              },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

            // Tab 2: Roles & Permissions Management View
            const RolesManagementView(),
          ],
        ),
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton(
                onPressed: () => _showAddEditDialog(),
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.person_add, color: Colors.white),
              )
            : null,
      ),
    );
  }
}
