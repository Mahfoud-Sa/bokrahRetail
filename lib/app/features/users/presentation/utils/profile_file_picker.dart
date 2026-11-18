import 'dart:io';
import 'package:flutter/foundation.dart';

class PickedProfileFile {
  final List<int> bytes;
  final String fileName;
  final String? path;

  const PickedProfileFile({
    required this.bytes,
    required this.fileName,
    this.path,
  });
}

class ProfileFilePicker {
  /// Opens a file dialog on Windows desktop to select an image.
  /// Returns null if cancelled, unsupported, or if an error occurs.
  static Future<PickedProfileFile?> pickImageFile() async {
    if (!kIsWeb && Platform.isWindows) {
      try {
        const script = r'''
Add-Type -AssemblyName System.Windows.Forms
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.Filter = "Image Files (*.png;*.jpg;*.jpeg;*.webp)|*.png;*.jpg;*.jpeg;*.webp|All Files (*.*)|*.*"
$dialog.Title = "اختر صورة الملف الشخصي"
$dialog.Multiselect = $false
if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  Write-Output $dialog.FileName
}
''';
        final result = await Process.run(
          'powershell',
          ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', script],
        );

        final rawOutput = result.stdout.toString().trim();
        if (rawOutput.isNotEmpty) {
          // In case PowerShell outputs multiple lines, take the last non-empty line
          final lines = rawOutput.split(RegExp(r'[\r\n]+')).where((l) => l.trim().isNotEmpty).toList();
          final filePath = lines.isNotEmpty ? lines.last.trim() : rawOutput;
          final file = File(filePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final fileName = file.uri.pathSegments.isNotEmpty
                ? file.uri.pathSegments.last
                : 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
            return PickedProfileFile(
              bytes: bytes,
              fileName: fileName,
              path: filePath,
            );
          }
        }
      } catch (e) {
        debugPrint('Windows file picker error: $e');
      }
    }
    return null;
  }

  /// Loads image from a manually provided local path.
  static Future<PickedProfileFile?> loadFromPath(String path) async {
    try {
      final cleanPath = path.trim().replaceAll('"', '').replaceAll("'", '');
      final file = File(cleanPath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final fileName = file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        return PickedProfileFile(
          bytes: bytes,
          fileName: fileName,
          path: cleanPath,
        );
      }
    } catch (e) {
      debugPrint('Error reading file from path: $e');
    }
    return null;
  }
}
