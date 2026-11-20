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
  final TextEditingController _searchController = TextEditingController();

  List<UserEntity> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedRoleFilter = 'all'; // 'all', 'admin', 'cashier', 'accountant'
  bool _onlyActiveFilter = false;

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
    _searchController.dispose();
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

  List<UserEntity> get _filteredUsers {
    return _users.where((user) {
      // Role filter
      if (_selectedRoleFilter != 'all') {
        if (_selectedRoleFilter == 'admin' &&
            user.role != OperatorRole.admin) {
          return false;
        }
        if (_selectedRoleFilter == 'cashier' &&
            user.role != OperatorRole.cashier) {
          return false;
        }
        if (_selectedRoleFilter == 'accountant' &&
            user.role != OperatorRole.accountant) {
          return false;
        }
      }

      // Active status filter
      if (_onlyActiveFilter && !user.isActive) {
        return false;
      }

      // Search query filter
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchesName = user.name.toLowerCase().contains(q);
        final matchesEmail = user.email.toLowerCase().contains(q);
        final matchesPhone =
            user.phoneNumber != null && user.phoneNumber!.contains(q);
        final matchesRole =
            user.displayRoleName.toLowerCase().contains(q);

        return matchesName || matchesEmail || matchesPhone || matchesRole;
      }

      return true;
    }).toList();
  }

  Future<void> _showAddEditDialog({UserEntity? user}) async {
    final isEditing = user != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final phoneController = TextEditingController(
      text: user?.phoneNumber ?? '',
    );
    final addressController = TextEditingController(text: user?.address ?? '');
    final birthDateController = TextEditingController(
      text: user?.birthDate ?? '',
    );

    String? selectedGender = user?.gender ?? 'ذكر';
    bool isActive = user?.isActive ?? true;
    bool obscurePassword = true;
    bool obscureConfirmPassword = true;
    bool isSubmitting = false;
    String? dialogError;

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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(BkRadius.md),
                    ),
                    child: Icon(
                      isEditing
                          ? Icons.manage_accounts_rounded
                          : Icons.person_add_alt_1_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'تعديل بيانات المستخدم'
                              : 'إضافة مستخدم جديد للنظام',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          isEditing
                              ? 'قم بتحديث المعلومات أو الصلاحيات الممنوحة'
                              : 'أدخل معلومات الحساب وعين الدور الوظيفي المناسب',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dialogError != null) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .errorContainer
                                  .withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(BkRadius.sm),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Theme.of(context).colorScheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    dialogError!,
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // SECTION 1: الأساسيات
                        const Text(
                          'المعلومات الأساسية وبيانات الدخول',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          nameController,
                          'الاسم الكامل *',
                          Icons.person_outline,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          emailController,
                          'البريد الإلكتروني *',
                          Icons.email_outlined,
                          isEmail: true,
                        ),
                        const SizedBox(height: 12),

                        // Password Field
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: isEditing
                                ? 'كلمة المرور الجديدة (اختياري)'
                                : 'كلمة المرور *',
                            hintText: isEditing
                                ? 'اتركها فارغة للإبقاء على الحالية'
                                : '6 أحرف على الأقل',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setDialogState(
                                () => obscurePassword = !obscurePassword,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(BkRadius.md),
                            ),
                          ),
                          validator: (v) {
                            if (!isEditing &&
                                (v == null || v.trim().isEmpty)) {
                              return 'يرجى إدخال كلمة المرور';
                            }
                            if (v != null &&
                                v.isNotEmpty &&
                                v.trim().length < 6) {
                              return 'يجب أن لا تقل كلمة المرور عن 6 أحرف';
                            }
                            return null;
                          },
                        ),

                        if (!isEditing) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'تأكيد كلمة المرور *',
                              prefixIcon:
                                  const Icon(Icons.lock_reset_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  obscureConfirmPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () => setDialogState(
                                  () => obscureConfirmPassword =
                                      !obscureConfirmPassword,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(BkRadius.md),
                              ),
                            ),
                            validator: (v) {
                              if (!isEditing &&
                                  (v == null || v.trim().isEmpty)) {
                                return 'يرجى تأكيد كلمة المرور';
                              }
                              if (v != passwordController.text) {
                                return 'كلمتا المرور غير متطابقتين';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),

                        // SECTION 2: الدور والصلاحيات
                        const Text(
                          'الدور الوظيفي والصلاحيات الممنوحة',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                                            ? Icons.shield_outlined
                                            : Icons.badge_outlined,
                                        size: 18,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          role.displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      BkBadge(
                                        label:
                                            '${role.permissionIds.length} صلاحية',
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
                                  setDialogState(
                                      () => selectedRoleName = val);
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'الصلاحيات الفعلية لهذا الدور (${activePermissions.length}):',
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
                                    color:
                                        Theme.of(context).colorScheme.outline,
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
                                        borderRadius:
                                            BorderRadius.circular(4),
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
                                          padding:
                                              const EdgeInsets.symmetric(
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
                                            style: const TextStyle(
                                                fontSize: 10),
                                          ),
                                        ),
                                    ]),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),

                        // SECTION 3: تفاصيل الاتصال والمعلومات الإضافية
                        const Text(
                          'معلومات إضافية (اختياري)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          phoneController,
                          'رقم الهاتف',
                          Icons.phone_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          addressController,
                          'العنوان / المدينة',
                          Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          birthDateController,
                          'تاريخ الميلاد',
                          Icons.cake_outlined,
                          isDate: true,
                        ),
                        const SizedBox(height: 14),

                        // Gender Selection
                        Row(
                          children: [
                            const Text(
                              'الجنس:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 16),
                            ChoiceChip(
                              avatar: const Icon(Icons.male, size: 16),
                              label: const Text('ذكر'),
                              selected: selectedGender == 'ذكر',
                              onSelected: (val) => setDialogState(
                                  () => selectedGender = 'ذكر'),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              avatar: const Icon(Icons.female, size: 16),
                              label: const Text('أنثى'),
                              selected: selectedGender == 'أنثى',
                              onSelected: (val) => setDialogState(
                                  () => selectedGender = 'أنثى'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'حساب نشط ومفعّل في النظام',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            isActive
                                ? 'يمكن لهذا المستخدم تسجيل الدخول واستخدام النظام'
                                : 'الحساب معطّل مؤقتاً ولا يمكن استخدامه للدخول',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
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
                  onPressed:
                      isSubmitting ? null : () => Navigator.pop(dialogCtx),
                ),
                BkButton(
                  label: isSubmitting
                      ? 'جاري الحفظ...'
                      : (isEditing ? 'تحديث البيانات' : 'حفظ وإضافة المستخدم'),
                  variant: BkButtonVariant.primary,
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          final cleanEmail = emailController.text.trim();

                          // Check for duplicate email
                          final emailTaken = await _usersService.isEmailTaken(
                            cleanEmail,
                            excludeId: user?.id,
                          );
                          if (emailTaken) {
                            setDialogState(() {
                              dialogError =
                                  'البريد الإلكتروني "$cleanEmail" مسجل لمستخدم آخر بالفعل.';
                            });
                            return;
                          }

                          setDialogState(() {
                            isSubmitting = true;
                            dialogError = null;
                          });

                          try {
                            final enteredPass =
                                passwordController.text.trim();
                            final finalPassword = enteredPass.isNotEmpty
                                ? enteredPass
                                : user?.password;

                            final newUser = UserEntity(
                              id: user?.id,
                              name: nameController.text.trim(),
                              email: cleanEmail,
                              phoneNumber: phoneController.text.trim().isNotEmpty
                                  ? phoneController.text.trim()
                                  : null,
                              address: addressController.text.trim().isNotEmpty
                                  ? addressController.text.trim()
                                  : null,
                              birthDate:
                                  birthDateController.text.trim().isNotEmpty
                                      ? birthDateController.text.trim()
                                      : null,
                              gender: selectedGender,
                              role: OperatorRole.fromString(selectedRoleName),
                              customRoleName: activeRoleModel.displayName,
                              isActive: isActive,
                              password: finalPassword,
                              createdAt: user?.createdAt,
                            );

                            // 1. Save user locally
                            final bool success = isEditing
                                ? await _usersService.updateUser(newUser)
                                : await _usersService.saveUser(newUser);

                            // 2. Synchronize / Provision to Store RBAC backend if store context exists
                            if (success) {
                              try {
                                final storeRbacCubit =
                                    context.read<StoreRbacCubit>();
                                if (storeRbacCubit.state.storeId != null) {
                                  if (!isEditing) {
                                    await storeRbacCubit.provisionMember(
                                      email: cleanEmail,
                                      fullName: newUser.name,
                                      password: finalPassword ?? 'P@ssword123',
                                      role: selectedRoleName,
                                      roleIds: [activeRoleModel.id],
                                    );
                                  } else if (user.id != null) {
                                    await storeRbacCubit.updateMemberRoles(
                                      userId: user.id!,
                                      roleIds: [activeRoleModel.id],
                                    );
                                  }
                                }
                              } catch (_) {
                                // Silent fallback to offline local persistence
                              }

                              if (dialogCtx.mounted) {
                                // If the updated user is the active operator, update session state
                                try {
                                  final sessionCubit =
                                      context.read<SessionCubit>();
                                  final currentActive =
                                      sessionCubit.state.currentOperator;
                                  if (currentActive != null &&
                                      ((newUser.id != null &&
                                              currentActive.id == newUser.id) ||
                                          currentActive.email ==
                                              newUser.email)) {
                                    sessionCubit.switchOperator(newUser);
                                  }
                                } catch (_) {}

                                Navigator.pop(dialogCtx);
                                await _loadUsers();

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isEditing
                                            ? 'تم تحديث بيانات المستخدم "${newUser.name}" بنجاح'
                                            : 'تمت إضافة المستخدم "${newUser.name}" بنجاح',
                                      ),
                                      backgroundColor: Colors.green.shade700,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            } else {
                              setDialogState(() {
                                isSubmitting = false;
                                dialogError =
                                    'حدث خطأ أثناء حفظ البيانات، يرجى المحاولة مرة أخرى.';
                              });
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSubmitting = false;
                              dialogError = 'فشل في حفظ المستخدم: $e';
                            });
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
                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
              }
            }
          : null,
      validator: (v) {
        if (label.contains('*') && (v == null || v.trim().isEmpty)) {
          return 'هذا الحقل مطلوب';
        }
        if (isEmail && v != null && v.isNotEmpty && !v.contains('@')) {
          return 'يرجى إدخال بريد إلكتروني صحيح';
        }
        return null;
      },
    );
  }

  Widget _buildMetricBadge(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(BkRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
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

    // Check if current user is an Admin or Store Owner
    final bool canManageUsers = (activeOperator?.role == OperatorRole.admin) ||
        (rbacState?.isCurrentMemberOwner ?? true) ||
        (rbacState?.can('store.members.manage') ?? false);

    final filteredList = _filteredUsers;
    final totalCount = _users.length;
    final activeCount = _users.where((u) => u.isActive).length;
    final adminCount =
        _users.where((u) => u.role == OperatorRole.admin).length;

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
            if (canManageUsers)
              IconButton(
                icon: const Icon(Icons.person_add_alt_1),
                tooltip: 'إضافة مستخدم جديد',
                onPressed: () => _showAddEditDialog(),
              ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Users List & Management
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(BkSpace.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Metrics Summary Header
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _buildMetricBadge(
                                'إجمالي المستخدمين',
                                '$totalCount',
                                Icons.people,
                                Theme.of(context).colorScheme.primary,
                              ),
                              _buildMetricBadge(
                                'المستخدمين النشطين',
                                '$activeCount',
                                Icons.check_circle_outline,
                                Colors.green,
                              ),
                              _buildMetricBadge(
                                'المسؤولين',
                                '$adminCount',
                                Icons.security,
                                Colors.amber.shade800,
                              ),
                            ],
                          ),

                          const SizedBox(height: BkSpace.md),

                          // Search and Filters Toolbar
                          BkCard(
                            child: Padding(
                              padding: const EdgeInsets.all(BkSpace.sm),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            hintText:
                                                'البحث بالاسم، البريد، أو الهاتف...',
                                            prefixIcon:
                                                const Icon(Icons.search),
                                            suffixIcon:
                                                _searchQuery.isNotEmpty
                                                    ? IconButton(
                                                        icon: const Icon(
                                                            Icons.clear),
                                                        onPressed: () {
                                                          _searchController
                                                              .clear();
                                                          setState(() =>
                                                              _searchQuery =
                                                                  '');
                                                        },
                                                      )
                                                    : null,
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      BkRadius.md),
                                              borderSide: BorderSide.none,
                                            ),
                                            filled: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 16),
                                          ),
                                          onChanged: (v) => setState(
                                              () => _searchQuery = v),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (canManageUsers)
                                        BkButton(
                                          label: 'إضافة مستخدم',
                                          icon: Icons.person_add,
                                          variant: BkButtonVariant.primary,
                                          onPressed: () =>
                                              _showAddEditDialog(),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),

                                  // Filter Chips
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        const Text(
                                          'تصفية حسب:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ChoiceChip(
                                          label: const Text('الكل'),
                                          selected:
                                              _selectedRoleFilter == 'all',
                                          onSelected: (selected) {
                                            if (selected) {
                                              setState(() =>
                                                  _selectedRoleFilter =
                                                      'all');
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 6),
                                        ChoiceChip(
                                          label: const Text('المسؤولين'),
                                          selected:
                                              _selectedRoleFilter == 'admin',
                                          onSelected: (selected) {
                                            if (selected) {
                                              setState(() =>
                                                  _selectedRoleFilter =
                                                      'admin');
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 6),
                                        ChoiceChip(
                                          label: const Text('الكاشير'),
                                          selected:
                                              _selectedRoleFilter == 'cashier',
                                          onSelected: (selected) {
                                            if (selected) {
                                              setState(() =>
                                                  _selectedRoleFilter =
                                                      'cashier');
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 6),
                                        ChoiceChip(
                                          label: const Text('المحاسبين'),
                                          selected: _selectedRoleFilter ==
                                              'accountant',
                                          onSelected: (selected) {
                                            if (selected) {
                                              setState(() =>
                                                  _selectedRoleFilter =
                                                      'accountant');
                                            }
                                          },
                                        ),
                                        const SizedBox(width: 12),
                                        FilterChip(
                                          label: const Text('النشطين فقط'),
                                          selected: _onlyActiveFilter,
                                          onSelected: (val) => setState(
                                              () => _onlyActiveFilter = val),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: BkSpace.md),

                          // Users List
                          if (_users.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(BkSpace.xl),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 80,
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                                    const SizedBox(height: BkSpace.md),
                                    Text(
                                      'لا يوجد مستخدمون بعد',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: BkSpace.sm),
                                    Text(
                                      'يمكن للمسؤول إضافة أعضاء الفريق وتعيين الصلاحيات وكلمات المرور الخاصة بهم.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .outline,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: BkSpace.xl),
                                    if (canManageUsers)
                                      BkButton(
                                        label: 'إضافة أول مستخدم للنظام',
                                        icon: Icons.person_add,
                                        variant: BkButtonVariant.primary,
                                        onPressed: () =>
                                            _showAddEditDialog(),
                                      ),
                                  ],
                                ),
                              ),
                            )
                          else if (filteredList.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(BkSpace.xl),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color:
                                          Theme.of(context).colorScheme.outline,
                                    ),
                                    const SizedBox(height: BkSpace.md),
                                    const Text(
                                      'لا توجد نتائج مطابقة لبحثك',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: BkSpace.sm),
                                    TextButton(
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                          _selectedRoleFilter = 'all';
                                          _onlyActiveFilter = false;
                                        });
                                      },
                                      child: const Text('إعادة ضبط الفلاتر'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final user = filteredList[index];
                                final isActiveOperator = activeOperator !=
                                        null &&
                                    ((user.id != null &&
                                            user.id == activeOperator.id) ||
                                        user.email == activeOperator.email);

                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: BkSpace.sm),
                                  child: BkCard(
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      leading: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: user.isActive
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context).disabledColor,
                                        child: Text(
                                          user.name.isNotEmpty
                                              ? user.name[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    user.name,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                BkBadge(
                                                  label: user.isActive
                                                      ? 'نشط'
                                                      : 'معطّل',
                                                  tone: user.isActive
                                                      ? BkTone.success
                                                      : BkTone.neutral,
                                                ),
                                              ],
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
                                            tone: user.role ==
                                                    OperatorRole.admin
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
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.email_outlined,
                                                size: 14,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .outline,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                user.email,
                                                style: const TextStyle(
                                                    fontSize: 13),
                                              ),
                                              if (user.phoneNumber != null &&
                                                  user.phoneNumber!.isNotEmpty) ...[
                                                const SizedBox(width: 12),
                                                Icon(
                                                  Icons.phone_outlined,
                                                  size: 14,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .outline,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  user.phoneNumber!,
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (user.address != null &&
                                              user.address!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on_outlined,
                                                  size: 14,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .outline,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  user.address!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .outline,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Set as active operator button if not already
                                          if (!isActiveOperator && user.isActive)
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.login_rounded),
                                              tooltip: 'التبديل إلى هذا المشغّل',
                                              onPressed: () {
                                                try {
                                                  context
                                                      .read<SessionCubit>()
                                                      .switchOperator(user);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'تم التبديل إلى المشغّل "${user.name}"',
                                                      ),
                                                      duration: const Duration(
                                                          seconds: 2),
                                                    ),
                                                  );
                                                } catch (_) {}
                                              },
                                            ),

                                          // Edit Button
                                          if (canManageUsers)
                                            IconButton(
                                              icon: Icon(
                                                Icons.edit_outlined,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                              tooltip: 'تعديل',
                                              onPressed: () =>
                                                  _showAddEditDialog(user: user),
                                            ),

                                          // Delete Button
                                          if (canManageUsers)
                                            IconButton(
                                              icon: Icon(
                                                Icons.delete_outline,
                                                color: isActiveOperator
                                                    ? Theme.of(context)
                                                        .disabledColor
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .error,
                                              ),
                                              tooltip: isActiveOperator
                                                  ? 'المشغّل الحالي (لا يمكن حذفه)'
                                                  : 'حذف المستخدم',
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
                                                            'هل أنت متأكد من حذف المستخدم "${user.name}"؟ لن يتمكن من تسجيل الدخول للنظام بعد ذلك.',
                                                          ),
                                                          actions: [
                                                            BkButton(
                                                              label: 'إلغاء',
                                                              variant:
                                                                  BkButtonVariant
                                                                      .secondary,
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      false),
                                                            ),
                                                            BkButton(
                                                              label: 'تأكيد الحذف',
                                                              variant:
                                                                  BkButtonVariant
                                                                      .danger,
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                      context,
                                                                      true),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                      if (confirm == true) {
                                                        if (user.id != null) {
                                                          await _usersService
                                                              .deleteUser(
                                                                  user.id!);
                                                        }
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
                        ],
                      ),
                    ),
                  ),

            // Tab 2: Roles & Permissions Management View
            const RolesManagementView(),
          ],
        ),
        floatingActionButton: _tabController.index == 0 && canManageUsers
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
