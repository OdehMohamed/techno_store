import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:techno_store/core/utils/app_colors.dart';
import 'package:techno_store/core/utils/user_role.dart';
import 'package:techno_store/core/widgets/main_button.dart';
import 'package:techno_store/core/widgets/message.dart';
import 'package:techno_store/features/staff_management/cubit/staff_management_cubit.dart';

/// Account creation folded into the Staff Management surface (a sheet
/// launched from the list), not a separate standalone destination — see
/// ADR-004's "NewUserAdminSide's disposition".
///
/// [_requestId] is generated exactly once per sheet instance and reused
/// unchanged across retries within that instance — it's what the backend's
/// idempotency contract is anchored to (see createStaffAccount, ADR-004).
/// Closing the sheet and reopening it is a genuinely new attempt and gets a
/// fresh id.
class CreateStaffAccountSheet extends StatefulWidget {
  const CreateStaffAccountSheet({super.key});

  @override
  State<CreateStaffAccountSheet> createState() =>
      _CreateStaffAccountSheetState();
}

class _CreateStaffAccountSheetState extends State<CreateStaffAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rePasswordController = TextEditingController();
  final String _requestId = const Uuid().v4();

  int _type = UserRole.reception;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _rePasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await context.read<StaffManagementCubit>().createStaffAccount(
            requestId: _requestId,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            type: _type,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      Message.showBottomMessage(context, 'Staff account created'.tr());
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      Message.showBottomMessage(
        context,
        e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString(),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'New Staff Account'.tr(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.perm_identity_outlined),
                  label: Text('Full name'.tr()),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? '${'Please Enter'.tr()} ${'Full name'.tr()}'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  label: Text('Email'.tr()),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return '${'Please Enter'.tr()} ${'Email'.tr()}';
                  }
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed)) {
                    return '${'Please Enter'.tr()} ${'valid Email'.tr()}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  label: Text('Password'.tr()),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '${'Please Enter'.tr()} ${'Password'.tr()}';
                  }
                  if (value.length < 8) return '${'Password'.tr()} ${'too short'.tr()}';
                  if (value.contains(' ')) {
                    return '${'Password'.tr()} ${"can't have spaces".tr()}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rePasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  label: Text('re-password'.tr()),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '${'Please Enter'.tr()} ${'re-password'.tr()}';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords does not match'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text('Role'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _RoleOptionTile(
                label: 'Reception'.tr(),
                icon: Icons.support_agent_outlined,
                selected: _type == UserRole.reception,
                onTap: () => setState(() => _type = UserRole.reception),
              ),
              const SizedBox(height: 8),
              _RoleOptionTile(
                label: 'Maintenance'.tr(),
                icon: Icons.build_outlined,
                selected: _type == UserRole.maintenance,
                onTap: () => setState(() => _type = UserRole.maintenance),
              ),
              const SizedBox(height: 8),
              _RoleOptionTile(
                label: 'Admin'.tr(),
                icon: Icons.admin_panel_settings_outlined,
                selected: _type == UserRole.admin,
                isAdmin: true,
                onTap: () => setState(() => _type = UserRole.admin),
              ),
              if (_type == UserRole.admin) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange.shade800, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This account will have full business authority — unrestricted admin access.'
                              .tr(),
                          style: TextStyle(
                              color: Colors.orange.shade900, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _isSaving
                  ? const Center(child: MainButton(isLoading: true))
                  : MainButton(
                      label: 'Create Account'.tr(),
                      onPressed: _submit,
                    ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleOptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool isAdmin;
  final VoidCallback onTap;

  const _RoleOptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isAdmin ? Colors.orange.shade700 : AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accent : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          color: selected && isAdmin ? Colors.orange.shade50 : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? accent : Colors.grey.shade600, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? accent : Colors.grey.shade800,
                ),
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: accent, size: 20),
          ],
        ),
      ),
    );
  }
}
