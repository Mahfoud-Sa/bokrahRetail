import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';
import 'package:bokrah_retail/app/features/departments/data/services/departments_service.dart';
import 'package:bokrah_retail/app/features/departments/domain/entities/department_entity.dart';
import 'package:bokrah_retail/app/initialzation_dependencies.dart';

/// Page for updating an existing department.
class UpdateDepartmentPage extends StatefulWidget {
  final DepartmentEntity department;
  final int? itemCount;
  final DepartmentsService? departmentsService;

  const UpdateDepartmentPage({
    super.key,
    required this.department,
    this.itemCount,
    this.departmentsService,
  });

  @override
  State<UpdateDepartmentPage> createState() => _UpdateDepartmentPageState();
}

class _UpdateDepartmentPageState extends State<UpdateDepartmentPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descController;
  late final DepartmentsService _departmentsService;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _departmentsService = widget.departmentsService ??
        (singelton.isRegistered<DepartmentsService>()
            ? singelton<DepartmentsService>()
            : DepartmentsService());
    _nameController = TextEditingController(text: widget.department.name);
    _codeController = TextEditingController(text: widget.department.code ?? '');
    _descController = TextEditingController(
      text: widget.department.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _navigateBack({bool saved = false}) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(saved);
    } else {
      try {
        context.go('/departments');
      } catch (_) {}
    }
  }

  Future<void> _submit() async {
    if (!await AppAccessGuard.requireStore(
      context: context,
      returnRoute: '/update-department',
    )) {
      return;
    }
    if (!mounted) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context)!;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim().isEmpty
        ? null
        : _codeController.text.trim().toUpperCase();
    final desc = _descController.text.trim().isEmpty
        ? null
        : _descController.text.trim();

    final updated = DepartmentEntity(
      id: widget.department.id,
      name: name,
      code: code,
      description: desc,
      createdAt: widget.department.createdAt,
    );

    try {
      final success = await _departmentsService.updateDepartment(updated);
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? l10n.departmentUpdatedSuccess : l10n.departmentSaveError,
          ),
          backgroundColor: success ? AppTheme.success : AppTheme.error,
        ),
      );

      if (success) {
        _navigateBack(saved: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.departmentSaveError),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('${l10n.editDepartment}: ${widget.department.name}'),
        backgroundColor: AppTheme.deepCobalt,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateBack(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: 24,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Form(
              key: _formKey,
              child: ResponsiveFormGrid(
                header: widget.itemCount != null
                    ? StatMetricCard(
                        title: l10n.linkedItemsCount,
                        value: '${widget.itemCount}',
                        icon: Icons.inventory_2_outlined,
                      )
                    : null,
                sections: [
                  FormSectionCard(
                    title: l10n.departmentBasicInfo,
                    icon: Icons.category_outlined,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.departmentName,
                          hintText: l10n.departmentNameHint,
                          prefixIcon: const Icon(Icons.category_outlined),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? l10n.departmentNameRequired
                                : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          labelText: l10n.departmentCode,
                          hintText: l10n.departmentCodeHint,
                          prefixIcon: const Icon(Icons.tag),
                        ),
                      ),
                    ],
                  ),
                  FormSectionCard(
                    title: l10n.departmentAdditionalDetails,
                    icon: Icons.description_outlined,
                    children: [
                      TextFormField(
                        controller: _descController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: l10n.departmentDescription,
                          hintText: l10n.departmentDescriptionHint,
                          prefixIcon: const Icon(Icons.notes_outlined),
                        ),
                      ),
                    ],
                  ),
                ],
                footer: FormActionBar(
                  isSubmitting: _isSaving,
                  submitLabel: l10n.saveChanges,
                  onSubmit: _submit,
                  onCancel: () => _navigateBack(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
