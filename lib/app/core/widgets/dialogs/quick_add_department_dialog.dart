import 'package:flutter/material.dart';
import 'package:bokrah_retail/app/features/departments/domain/entities/department_entity.dart';
import 'package:bokrah_retail/app/features/departments/data/services/departments_service.dart';

/// A quick modal dialog to create a new department and return the created entity.
class QuickAddDepartmentDialog extends StatelessWidget {
  final DepartmentsService departmentsService;

  const QuickAddDepartmentDialog({
    super.key,
    required this.departmentsService,
  });

  static Future<DepartmentEntity?> show(
    BuildContext context, {
    required DepartmentsService departmentsService,
  }) {
    return showDialog<DepartmentEntity?>(
      context: context,
      builder: (dialogCtx) => QuickAddDepartmentDialog(
        departmentsService: departmentsService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text(
          'إضافة قسم جديد',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'اسم القسم *',
                hintText: 'مثلاً: الهواتف الذكية أو العطور',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                labelText: 'كود القسم (اختياري)',
                hintText: 'مثلاً: PHONE',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              final code = codeCtrl.text.trim();
              final newDept = await departmentsService.saveDepartment(
                DepartmentEntity(
                  name: name,
                  code: code.isEmpty ? null : code,
                ),
              );

              if (!context.mounted) return;
              Navigator.pop(context, newDept);
            },
            child: const Text('إضافة وتحديد'),
          ),
        ],
      ),
    );
  }
}

