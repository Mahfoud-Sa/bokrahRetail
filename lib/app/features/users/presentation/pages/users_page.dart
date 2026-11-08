import 'package:bokrah_retail/app/features/users/data/entities/user_entity.dart';
import 'package:bokrah_retail/app/features/users/data/services/users_service.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/session_cubit.dart';
import 'package:bokrah_retail/app/features/users/presentation/cubits/session_state.dart';
import 'package:bokrah_design_system/bokrah_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final UsersService _usersService = UsersService();
  List<UserEntity> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
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
    OperatorRole selectedRole = user?.role ?? OperatorRole.cashier;
    bool isActive = user?.isActive ?? true;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              title: Text(isEditing ? 'تعديل مستخدم' : 'إضافة مستخدم جديد'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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

                      // Role Selection
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'الدور:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      RadioListTile<OperatorRole>(
                        title: const Text('مسؤول (Admin)'),
                        subtitle:
                            const Text('صلاحيات كاملة لكافة أقسام النظام'),
                        value: OperatorRole.admin,
                        groupValue: selectedRole,
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedRole = val);
                          }
                        },
                      ),
                      RadioListTile<OperatorRole>(
                        title: const Text('كاشير (Cashier)'),
                        subtitle:
                            const Text('عمليات البيع، المنتجات والفواتير'),
                        value: OperatorRole.cashier,
                        groupValue: selectedRole,
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedRole = val);
                          }
                        },
                      ),
                      RadioListTile<OperatorRole>(
                        title: const Text('محاسب (Accountant)'),
                        subtitle:
                            const Text('الفواتير، المحاسبة والتقارير المالية'),
                        value: OperatorRole.accountant,
                        groupValue: selectedRole,
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedRole = val);
                          }
                        },
                      ),

                      SwitchListTile(
                        title: const Text('حساب نشط'),
                        value: isActive,
                        onChanged: (val) =>
                            setDialogState(() => isActive = val),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                BkButton(
                  label: 'إلغاء',
                  variant: BkButtonVariant.secondary,
                  onPressed: () => Navigator.pop(context),
                ),
                BkButton(
                  label: isEditing ? 'تحديث' : 'حفظ',
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
                        role: selectedRole,
                        isActive: isActive,
                        createdAt: user?.createdAt,
                      );

                      bool success = isEditing
                          ? await _usersService.updateUser(newUser)
                          : await _usersService.saveUser(newUser);

                      if (context.mounted && success) {
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
                        Navigator.pop(context);
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
        border: const OutlineInputBorder(),
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
        if (label.contains('*') && (v == null || v.isEmpty)) {
          return 'هذا الحقل مطلوب';
        }
        if (isEmail && v != null && v.isNotEmpty && !v.contains('@')) {
          return 'بريد غير صحيح';
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

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'إدارة المستخدمين',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: 'إضافة مستخدم جديد',
              onPressed: () => _showAddEditDialog(),
            ),
          ],
        ),
        body: _isLoading
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: BkSpace.xl),
                      BkButton(
                        label: 'إضافة مستخدم',
                        variant: BkButtonVariant.primary,
                        onPressed: () => _showAddEditDialog(),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(BkSpace.md),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final isActiveOperator = activeOperator != null &&
                      ((user.id != null && user.id == activeOperator.id) ||
                          user.email == activeOperator.email);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: BkSpace.sm),
                    child: BkCard(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).disabledColor,
                          child: const Icon(Icons.person, color: Colors.white),
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
                              label: user.role.displayName,
                              tone: user.role == OperatorRole.admin
                                  ? BkTone.warning
                                  : user.role == OperatorRole.accountant
                                      ? BkTone.info
                                      : BkTone.success,
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              tooltip: 'تعديل',
                              onPressed: () => _showAddEditDialog(user: user),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_outline,
                                color: isActiveOperator
                                    ? Theme.of(context).disabledColor
                                    : Theme.of(context).colorScheme.error,
                              ),
                              tooltip: isActiveOperator
                                  ? 'المشغّل الحالي (لا يمكن حذفه)'
                                  : 'حذف',
                              onPressed: isActiveOperator
                                  ? null
                                  : () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('حذف مستخدم'),
                                          content: Text(
                                            'هل أنت متأكد من حذف المستخدم "${user.name}"؟',
                                          ),
                                          actions: [
                                            BkButton(
                                              label: 'إلغاء',
                                              variant:
                                                  BkButtonVariant.secondary,
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                            ),
                                            BkButton(
                                              label: 'حذف',
                                              variant: BkButtonVariant.danger,
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await _usersService.deleteUser(user.id!);
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
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddEditDialog(),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.person_add, color: Colors.white),
        ),
      ),
    );
  }
}
