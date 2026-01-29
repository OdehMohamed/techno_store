import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/core2/utils/app_colors.dart';

class BuildTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool required;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  const BuildTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.required = false,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: required
            ? (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter $label'.tr();
                }
                return null;
              }
            : null,
      ),
    );
  }
}
