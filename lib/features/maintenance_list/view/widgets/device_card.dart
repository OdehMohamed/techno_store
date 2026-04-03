import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:techno_store/core/model/maintenance_device_model.dart';

class DeviceCard extends StatelessWidget {
  final MaintenanceDeviceModel device;
  final String status;
  final bool isEmployee;
  final VoidCallback onTap;
  final Color Function(String) getStatusColor;
  final String Function(String) getStatusIcon;
  final List<SlidableAction> Function(MaintenanceDeviceModel, String)
      buildSlidableActions;
  final String? heroTagPrefix; // لتمييز الـ Hero في كل صفحة

  const DeviceCard({
    Key? key,
    required this.device,
    required this.status,
    required this.isEmployee,
    required this.onTap,
    required this.getStatusColor,
    required this.getStatusIcon,
    required this.buildSlidableActions,
    this.heroTagPrefix, // اختياري
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final heroTag = heroTagPrefix != null
        ? '${heroTagPrefix}_${status}_device_${device.id}_$hashCode'
        : '${status}_device_${device.id}_$hashCode';

    final card = Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: getStatusColor(status).withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              getStatusColor(status),
                              getStatusColor(status).withValues(alpha: 0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  getStatusColor(status).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          getStatusIcon(status),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.model,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[900],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (device.brand != null)
                              Text(
                                device.brand!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Customer Info
                  _buildInfoRow(
                    Icons.person_outline,
                    device.name,
                    Colors.blue,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.phone_outlined,
                    device.phoneNumber,
                    Colors.green,
                  ),

                  const Spacer(),

                  // Footer
                  Row(
                    children: [
                      // Date
                      Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(device.receivedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      if (device.updatedAt != null)
                        Icon(Icons.update, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      if (device.updatedAt != null)
                        Text(
                          _formatDate(device.updatedAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      const Spacer(),
                      // Price
                      if (device.price != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${device.price} \$',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Wrap with Slidable only for employees
    if (!isEmployee) return card;

    return Slidable(
      key: ValueKey(device.id),
      groupTag: 'maintenance_devices',
      endActionPane: ActionPane(
        extentRatio: 0.6,
        motion: const ScrollMotion(),
        children: buildSlidableActions(device, status),
      ),
      child: card,
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No date'.tr();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today'.tr();
    } else if (difference.inDays == 1) {
      return 'Yesterday'.tr();
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${'days ago'.tr()}';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}
