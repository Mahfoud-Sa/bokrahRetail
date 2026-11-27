import 'package:bokrah_retail/app/config/theme.dart';
import 'package:flutter/material.dart';

/// Builds a standardized [InputDecoration] for item and form inputs.
InputDecoration buildAppInputDecoration({
  required String label,
  required IconData icon,
  String? hintText,
  String? suffixText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hintText,
    suffixText: suffixText,
    suffixIcon: suffixIcon,
    prefixIcon: Icon(icon, color: AppTheme.actionBlue),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppTheme.actionBlue, width: 2),
    ),
    filled: true,
    fillColor: Colors.white,
  );
}

/// Standardized [TextFormField] using [buildAppInputDecoration].
class AppFormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? suffixText;
  final String? hintText;
  final int maxLines;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;

  const AppFormTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.suffixText,
    this.hintText,
    this.maxLines = 1,
    this.suffixIcon,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
      decoration: buildAppInputDecoration(
        label: label,
        icon: icon,
        hintText: hintText,
        suffixText: suffixText,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
