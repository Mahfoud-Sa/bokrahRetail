import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:bokrah_retail/app/config/l10n/app_localizations.dart';
import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/core/auth/app_access_guard.dart';
import 'package:bokrah_retail/app/core/widgets/widgets.dart';
import 'package:bokrah_retail/app/features/departments/data/services/departments_service.dart';
import 'package:bokrah_retail/app/features/departments/domain/entities/department_entity.dart';
import 'package:bokrah_retail/app/initialzation_dependencies.dart';

/// Page for creating a new department.
class AddDepartmentPage extends StatefulWidget {
  final DepartmentsService? departmentsService;

  const AddDepartmentPage({super.key, this.departmentsService});

  @override
  State<AddDepartmentPage> createState() => _AddDepartmentPageState();
}

class _AddDepartmentPageState extends State<AddDepartmentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  late final DepartmentsService _departmentsService;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _departmentsService = widget.departmentsService ??
        (singelton.isRegistered<DepartmentsService>()
            ? singelton<DepartmentsService>()
            : DepartmentsService());
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
      returnRoute: '/add-department',
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

    try {
      final result = await _departmentsService.saveDepartment(
        DepartmentEntity(name: name, code: code, description: desc),
      );
      if (!mounted) return;
      setState(() => _isSaving = false);

      final success = result != null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? l10n.departmentAddedSuccess : l10n.departmentSaveError,
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
        title: Text(l10n.addDepartmentTitle),
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
                  submitLabel: l10n.saveDepartment,
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
