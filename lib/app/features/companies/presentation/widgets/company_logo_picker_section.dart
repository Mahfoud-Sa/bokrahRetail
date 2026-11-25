import 'dart:io';
import 'dart:typed_data';

import 'package:bokrah_retail/app/config/theme.dart';
import 'package:bokrah_retail/app/features/companies/presentation/widgets/company_logo_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Reusable logo upload & preview section allowing the user to pick an actual
/// image file from their computer and store its bytes locally.
class CompanyLogoPickerSection extends StatelessWidget {
  final Uint8List? imageBytes;
  final String? fallbackImageUrl;
  final ValueChanged<Uint8List?> onImageChanged;

  const CompanyLogoPickerSection({
    super.key,
    this.imageBytes,
    this.fallbackImageUrl,
    required this.onImageChanged,
  });

  Future<void> _pickFromComputer(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      Uint8List? bytes = file.bytes;
      if ((bytes == null || bytes.isEmpty) && file.path != null) {
        bytes = await File(file.path!).readAsBytes();
      }
      if (bytes != null && bytes.isNotEmpty) {
        onImageChanged(bytes);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر اختيار الصورة: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  bool get _hasAnyImage =>
      (imageBytes != null && imageBytes!.isNotEmpty) ||
      (fallbackImageUrl != null && fallbackImageUrl!.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final kb = imageBytes != null
        ? (imageBytes!.lengthInBytes / 1024).toStringAsFixed(1)
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            color: AppTheme.subtleSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: CompanyLogoImage(
            imageBytes: imageBytes,
            imageUrl: fallbackImageUrl,
            fallback: const Center(
              child: Icon(
                Icons.business,
                color: AppTheme.secondaryText,
                size: 36,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _pickFromComputer(context),
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(
                      _hasAnyImage ? 'تغيير الصورة من الجهاز' : 'رفع صورة من الجهاز',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.actionBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  if (_hasAnyImage)
                    OutlinedButton.icon(
                      onPressed: () => onImageChanged(null),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: AppTheme.error,
                      ),
                      label: const Text(
                        'إزالة',
                        style: TextStyle(color: AppTheme.error),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                kb != null
                    ? 'تم تحميل الصورة وحفظها محلياً ($kb كيلوبايت) — جاهزة للمزامنة مع السحابة'
                    : 'اختر صورة شعار الشركة (PNG, JPG, WEBP) من جهازك ليتم حفظها محلياً ومزامنتها.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
