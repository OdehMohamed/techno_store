import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/model/user_data.dart';
import 'package:techno_store/core/utils/app_colors.dart';
import 'package:techno_store/core/utils/user_role.dart';
import 'package:techno_store/core/widgets/custom_dialogs.dart';
import 'package:techno_store/core/widgets/main_app_bar.dart';
import 'package:techno_store/core/widgets/message.dart';
import 'package:techno_store/features/maintenance_list/view/widgets/maintenance_states.dart';
import 'package:techno_store/features/staff_management/cubit/staff_management_cubit.dart';
import 'package:techno_store/features/staff_management/model/staff_member.dart';
import 'package:techno_store/features/staff_management/view/widgets/create_staff_account_sheet.dart';

/// Admin-only: create staff accounts (createStaffAccount) and
/// activate/deactivate existing ones (setStaffStatus, unmodified). See
/// docs/ai-workflow/ADR-004-admin-user-management-design.md. Route-guarded
/// like archivedDevices — defense-in-depth; the real enforcement is at the
/// data layer (both Cloud Functions' own Admin+active-staffStatus check).
class StaffManagementPage extends StatefulWidget {
  final UserData adminUserData;

  const StaffManagementPage({super.key, required this.adminUserData});

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  final _advancedDrawerController = AdvancedDrawerController();

  int? _roleFilter; // null = all
  bool? _activeFilter; // null = all, true = active, false = inactive

  @override
  void initState() {
    super.initState();
    context.read<StaffManagementCubit>().loadStaff();
  }

  List<StaffMember> _applyFilters(List<StaffMember> staff) {
    return staff.where((member) {
      if (_roleFilter != null && member.userData.type != _roleFilter) {
        return false;
      }
      if (_activeFilter != null && member.isActive != _activeFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _openCreateSheet() async {
    final cubit = context.read<StaffManagementCubit>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const CreateStaffAccountSheet(),
      ),
    );
  }

  Future<void> _toggleStatus(StaffMember member) async {
    final targetStatus = member.isActive ? 'inactive' : 'active';
    if (member.isActive) {
      // Deactivating live-revokes access (AuthCubit's staffStatus listener
      // forces an immediate sign-out) — deserves a pause. Activating is
      // lower-friction by design (see ADR-004: creation is itself the
      // grant), so no confirmation gate on that direction.
      CustomDialogs.showDialogConfirm(
        context: context,
        title: 'Deactivate Account',
        content:
            'This immediately signs ${member.userData.name ?? 'this account'} out '
            'and blocks sign-in until reactivated.',
        icon: Icons.person_off_outlined,
        iconColor: Colors.red,
        confirmText: 'Deactivate',
        cancelText: 'Cancel',
        onPressed: () {
          Navigator.of(context).pop();
          _setStatus(member, targetStatus);
        },
      );
    } else {
      _setStatus(member, targetStatus);
    }
  }

  Future<void> _setStatus(StaffMember member, String status) async {
    try {
      await context
          .read<StaffManagementCubit>()
          .setStaffStatus(uid: member.userData.uid, status: status);
      if (!mounted) return;
      Message.showBottomMessage(
        context,
        status == 'active'
            ? 'Account activated'.tr()
            : 'Account deactivated'.tr(),
      );
    } catch (e) {
      if (!mounted) return;
      Message.showBottomMessage(
        context,
        e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString(),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(width <= 500 ? height * 0.05 : height * 0.08),
        child: MainAppBar(
          haveLeading: false,
          advancedDrawerController: _advancedDrawerController,
          title: 'Staff Management'.tr(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        icon: const Icon(Icons.person_add_alt_1),
        label: Text('New Staff Account'.tr()),
      ),
      body: Column(
        children: [
          _FilterBar(
            roleFilter: _roleFilter,
            activeFilter: _activeFilter,
            onRoleChanged: (value) => setState(() => _roleFilter = value),
            onActiveChanged: (value) => setState(() => _activeFilter = value),
          ),
          Expanded(
            child: BlocBuilder<StaffManagementCubit, StaffManagementState>(
              builder: (context, state) {
                if (state is StaffManagementLoading ||
                    state is StaffManagementInitial) {
                  return const LoadingStateWidget();
                }
                if (state is StaffManagementError) {
                  return ErrorStateWidget(message: state.message);
                }
                final staff = (state as StaffManagementLoaded).staff;
                final filtered = _applyFilters(staff);
                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    getEmptyIcon: (_) => Icons.people_outline,
                    title: 'No staff accounts found'.tr(),
                    subtitle: 'Staff accounts will appear here'.tr(),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      context.read<StaffManagementCubit>().loadStaff(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _StaffMemberCard(
                      member: filtered[index],
                      isSelf:
                          filtered[index].userData.uid == widget.adminUserData.uid,
                      onToggleStatus: () => _toggleStatus(filtered[index]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final int? roleFilter;
  final bool? activeFilter;
  final ValueChanged<int?> onRoleChanged;
  final ValueChanged<bool?> onActiveChanged;

  const _FilterBar({
    required this.roleFilter,
    required this.activeFilter,
    required this.onRoleChanged,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All'.tr(),
                  selected: roleFilter == null,
                  onSelected: () => onRoleChanged(null),
                ),
                _FilterChip(
                  label: 'Admin'.tr(),
                  selected: roleFilter == UserRole.admin,
                  onSelected: () => onRoleChanged(UserRole.admin),
                ),
                _FilterChip(
                  label: 'Reception'.tr(),
                  selected: roleFilter == UserRole.reception,
                  onSelected: () => onRoleChanged(UserRole.reception),
                ),
                _FilterChip(
                  label: 'Maintenance'.tr(),
                  selected: roleFilter == UserRole.maintenance,
                  onSelected: () => onRoleChanged(UserRole.maintenance),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All Statuses'.tr(),
                  selected: activeFilter == null,
                  onSelected: () => onActiveChanged(null),
                ),
                _FilterChip(
                  label: 'Active'.tr(),
                  selected: activeFilter == true,
                  onSelected: () => onActiveChanged(true),
                ),
                _FilterChip(
                  label: 'Inactive'.tr(),
                  selected: activeFilter == false,
                  onSelected: () => onActiveChanged(false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.grey.shade800,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _StaffMemberCard extends StatelessWidget {
  final StaffMember member;
  final bool isSelf;
  final VoidCallback onToggleStatus;

  const _StaffMemberCard({
    required this.member,
    required this.isSelf,
    required this.onToggleStatus,
  });

  String _roleLabel(int type) {
    if (type == UserRole.admin) return 'Admin';
    if (type == UserRole.reception) return 'Reception';
    if (type == UserRole.maintenance) return 'Maintenance';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = member.userData.type == UserRole.admin;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor:
                isAdmin ? Colors.orange.shade50 : Colors.grey.shade100,
            child: Icon(
              isAdmin ? Icons.admin_panel_settings_outlined : Icons.person_outline,
              color: isAdmin ? Colors.orange.shade700 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.userData.name ?? member.userData.uid,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  member.userData.email ?? '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _Badge(
                      text: _roleLabel(member.userData.type).tr(),
                      color: isAdmin ? Colors.orange : AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    _Badge(
                      text: (member.isActive ? 'Active' : 'Inactive').tr(),
                      color: member.isActive ? Colors.green : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: member.isActive,
            onChanged: isSelf ? null : (_) => onToggleStatus(),
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
