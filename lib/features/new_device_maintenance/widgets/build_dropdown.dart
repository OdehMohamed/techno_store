import 'package:flutter/material.dart';
import 'package:techno_store/core2/utils/app_colors.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
          border: InputBorder.none,
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.primary),
        dropdownColor: Colors.white,
        items: items.map((String item) {
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
