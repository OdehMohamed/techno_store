import 'package:flutter/material.dart';
import 'package:techno_store/core/utils/app_colors.dart';

class BuildDropdown extends StatelessWidget {
  final String? value;
  final String label;
  final IconData icon;
  final List<String> items;
  final Function(String?) onChanged;
  const BuildDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final uniqueItems = <String>[];
    for (final item in items) {
      if (!uniqueItems.contains(item)) {
        uniqueItems.add(item);
      }
    }

    final selectedValue = value?.trim();
    if (selectedValue != null &&
        selectedValue.isNotEmpty &&
        !uniqueItems.contains(selectedValue)) {
      uniqueItems.add(selectedValue);
    }

    final safeInitialValue =
        (selectedValue != null && uniqueItems.contains(selectedValue))
            ? selectedValue
            : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: safeInitialValue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
          border: InputBorder.none,
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.primary),
        dropdownColor: Colors.white,
        items: uniqueItems.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: const TextStyle(overflow: TextOverflow.ellipsis),
            ),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
