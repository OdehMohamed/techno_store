import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:techno_store/core/model/maintenance_device_model.dart';
import 'package:techno_store/core/model/user_data.dart';
import 'package:techno_store/core/utils/app_colors.dart';
import 'package:techno_store/core/widgets/custom_dialogs.dart';
import 'package:techno_store/core/widgets/main_app_bar.dart';
import 'package:techno_store/core/widgets/message.dart';
import 'package:techno_store/features/maintenance_list/cubit/maintenance_list_cubit.dart';
import 'package:techno_store/features/maintenance_list/view/widgets/maintenance_states.dart';

/// Admin-only: browse archived devices, Restore them, or Permanently Delete
/// them. Deliberately simple for v1 — no search/filter, matching ADR-005's
/// scope. Restore and Permanent Delete are enforced Admin-only at the data
/// layer (Firestore rules / the permanentlyDeleteDevice Cloud Function) —
/// this screen being Admin-only is defense-in-depth, not the real gate. See
/// docs/ai-workflow/ADR-005-device-lifecycle-archive-deletion.md.
class ArchivedDevicesPage extends StatefulWidget {
  final UserData adminUserData;

  const ArchivedDevicesPage({super.key, required this.adminUserData});

  @override
  State<ArchivedDevicesPage> createState() => _ArchivedDevicesPageState();
}

class _ArchivedDevicesPageState extends State<ArchivedDevicesPage> {
  final _advancedDrawerController = AdvancedDrawerController();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final maintenanceListCubit = BlocProvider.of<MaintenanceListCubit>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(width <= 500 ? height * 0.05 : height * 0.08),
        child: MainAppBar(
          haveLeading: false,
          advancedDrawerController: _advancedDrawerController,
          title: 'Archived Devices'.tr(),
        ),
      ),
      body: StreamBuilder<List<MaintenanceDeviceModel>>(
        stream: maintenanceListCubit.maintenanceListServices
            .streamArchivedDevices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingStateWidget();
          }
          if (snapshot.hasError) {
            return ErrorStateWidget(message: snapshot.error.toString());
          }
          final devices = snapshot.data ?? [];
          if (devices.isEmpty) {
            return EmptyStateWidget(
              getEmptyIcon: (_) => Icons.archive_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _ArchivedDeviceCard(
              device: devices[index],
              onRestore: () => _restore(devices[index]),
              onPermanentlyDelete: () =>
                  _confirmPermanentDelete(devices[index]),
            ),
          );
        },
      ),
    );
  }

  Future<void> _restore(MaintenanceDeviceModel device) async {
    CustomDialogs.showDialogConfirm(
      context: context,
      title: 'Restore Device',
      content: 'This will return the device to its normal maintenance tab.'
          '\n\nCustomer: ${device.name} (${device.phoneNumber})\n'
          'Device: ${device.model}',
      icon: Icons.unarchive_outlined,
      iconColor: AppColors.primary,
      confirmText: 'Restore',
      cancelText: 'Cancel',
      onPressed: () async {
        Navigator.of(context).pop();
        final maintenanceListCubit = context.read<MaintenanceListCubit>();
        try {
          await maintenanceListCubit.restoreDevice(
            device.id!,
            widget.adminUserData.uid,
          );
          if (!mounted) return;
          Message.showBottomMessage(
            context,
            'Device restored successfully'.tr(),
          );
        } catch (_) {
          if (!mounted) return;
          Message.showBottomMessage(
            context,
            'Could not restore this device. Please try again.'.tr(),
            isError: true,
          );
        }
      },
    );
  }

  Future<void> _confirmPermanentDelete(MaintenanceDeviceModel device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PermanentDeleteDialog(device: device),
    );
    if (confirmed != true || !mounted) return;

    final maintenanceListCubit = context.read<MaintenanceListCubit>();
    try {
      await maintenanceListCubit.permanentlyDeleteDevice(device.id!);
      if (!mounted) return;
      Message.showBottomMessage(
        context,
        'Device permanently deleted'.tr(),
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
}

class _ArchivedDeviceCard extends StatelessWidget {
  final MaintenanceDeviceModel device;
  final VoidCallback onRestore;
  final VoidCallback onPermanentlyDelete;

  const _ArchivedDeviceCard({
    required this.device,
    required this.onRestore,
    required this.onPermanentlyDelete,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  device.status.tr(),
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  device.model,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${device.name} · ${device.phoneNumber}',
              style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onRestore,
                icon: const Icon(Icons.unarchive_outlined, size: 18),
                label: Text('Restore'.tr()),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onPermanentlyDelete,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                icon: const Icon(Icons.delete_forever, size: 18),
                label: Text('Permanently Delete'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Deliberately more friction than Restore or Archive: the confirm button
/// only enables once the operator types the device's exact model name.
/// Permanent Delete should feel like an exceptional administrative action,
/// never "the next button after Archive." See ADR-005.
class _PermanentDeleteDialog extends StatefulWidget {
  final MaintenanceDeviceModel device;

  const _PermanentDeleteDialog({required this.device});

  @override
  State<_PermanentDeleteDialog> createState() =>
      _PermanentDeleteDialogState();
}

class _PermanentDeleteDialogState extends State<_PermanentDeleteDialog> {
  final _confirmController = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() {
      final matches = _confirmController.text.trim() == widget.device.model;
      if (matches != _matches) setState(() => _matches = matches);
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Permanently Delete Device'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This permanently deletes the record, its photos, and its '
                    'sensitive data. This cannot be undone.\n\nCustomer: '
                    '${widget.device.name} (${widget.device.phoneNumber})\n'
                    'Device: ${widget.device.model}'
                .tr(),
          ),
          const SizedBox(height: 16),
          Text(
            'Type the device model below to confirm.'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmController,
            decoration: InputDecoration(
              hintText: widget.device.model,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text('Permanently Delete'.tr()),
        ),
      ],
    );
  }
}
