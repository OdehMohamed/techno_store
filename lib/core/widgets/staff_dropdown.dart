import 'package:flutter/material.dart';
import 'package:techno_store/core/model/user_data.dart';
import 'package:techno_store/core/utils/app_colors.dart';

/// A dropdown sourced from real staff accounts (see
/// docs/ai-workflow/ADR-006-employee-attribution.md), used wherever a
/// device record needs to attribute an action to a real employee. The
/// underlying value is a uid; the displayed label is the account's name.
///
/// [options] should already include the currently-selected account even if
/// it's since become inactive — see [FirestoreServices.getActiveStaffByRoles]'s
/// `alwaysInclude` parameter, which is how callers satisfy this.
class StaffDropdown extends StatelessWidget {
  final String? selectedUid;
  final String label;
  final IconData icon;
  final List<UserData> options;
  final ValueChanged<UserData?> onChanged;
  final FormFieldValidator<String>? validator;

  const StaffDropdown({
    super.key,
    required this.selectedUid,
    required this.label,
    required this.icon,
    required this.options,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue =
        options.any((member) => member.uid == selectedUid) ? selectedUid : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: safeValue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
          border: InputBorder.none,
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: AppColors.primary),
        dropdownColor: Colors.white,
        items: options.map((member) {
          return DropdownMenuItem<String>(
            value: member.uid,
            child: Text(
              member.name ?? member.uid,
              style: const TextStyle(overflow: TextOverflow.ellipsis),
            ),
          );
        }).toList(),
        onChanged: (uid) {
          UserData? selected;
          for (final member in options) {
            if (member.uid == uid) {
              selected = member;
              break;
            }
          }
          onChanged(selected);
        },
        validator: validator,
      ),
    );
  }
}
