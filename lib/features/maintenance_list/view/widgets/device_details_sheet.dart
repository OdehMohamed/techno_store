import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/core/model/maintenance_device_model.dart';
import 'package:techno_store/core/model/maintenance_device_sensitive_data.dart';
import 'package:techno_store/core/services/maintenance_device_sensitive_data_service.dart';
import 'package:techno_store/core/utils/app_colors.dart';
import 'package:techno_store/features/maintenance_list/view/widgets/full_screen_image_viewer.dart';

class DeviceDetailsSheet extends StatelessWidget {
  final MaintenanceDeviceModel device;
  final bool isEmployee;

  const DeviceDetailsSheet({
    Key? key,
    required this.device,
    required this.isEmployee,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // pin/patternLock/notesHidden are no longer on MaintenanceDeviceModel
    // (see docs/ai-workflow/ADR-001-sensitive-data-separation.md) — fetch
    // them separately, and only for staff. A customer viewing their own
    // device should never even attempt this read.
    final sensitiveDataFuture = (isEmployee && device.id != null)
        ? MaintenanceDeviceSensitiveDataService.instance.fetch(device.id!)
        : Future<MaintenanceDeviceSensitiveData?>.value(null);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: FutureBuilder<MaintenanceDeviceSensitiveData?>(
                  future: sensitiveDataFuture,
                  builder: (context, snapshot) {
                    final sensitiveData = snapshot.data;
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(24),
                      children: [
                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primary.withValues(alpha: 0.7),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.smartphone,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device.model,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (device.brand != null)
                                    Text(
                                      device.brand!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Details Sections
                        _buildDetailSection(
                          'Customer Information'.tr(),
                          Icons.person,
                          [
                            _buildDetailRow('Name'.tr(), device.name),
                            _buildDetailRow('Phone'.tr(), device.phoneNumber),
                          ],
                        ),

                        // Device Specifications
                        _buildDetailSection(
                          'Device Specifications'.tr(),
                          Icons.smartphone_outlined,
                          [
                            if (device.brand != null)
                              _buildDetailRow('Brand'.tr(), device.brand!),
                            _buildDetailRow('Model'.tr(), device.model),
                            _buildColorRow('Color'.tr(), device.colorHex),
                          ],
                        ),

                        if (device.imeiNumber != null ||
                            sensitiveData?.pin != null ||
                            sensitiveData?.patternLock != null)
                          _buildDetailSection(
                            'Device Security'.tr(),
                            Icons.security,
                            [
                              if (device.imeiNumber != null)
                                _buildDetailRow(
                                    'IMEI'.tr(), device.imeiNumber!),
                              if (isEmployee && sensitiveData?.pin != null)
                                _buildDetailRow(
                                    'PIN'.tr(), sensitiveData!.pin!),
                              if (isEmployee &&
                                  sensitiveData?.patternLock != null)
                                _buildPatternLock(sensitiveData!.patternLock!),
                            ],
                          ),

                        if (device.deviceStatusReceived.isNotEmpty)
                          _buildDetailSection(
                            'Device Status When Received'.tr(),
                            Icons.fact_check_outlined,
                            [
                              _buildChipsList(
                                device.deviceStatusReceived,
                                Colors.purple,
                              ),
                            ],
                          ),

                        if (device.problems.isNotEmpty)
                          _buildDetailSection(
                            'Problems'.tr(),
                            Icons.error_outline,
                            [
                              _buildChipsList(device.problems, Colors.red),
                            ],
                          ),

                        if (device.accessories.isNotEmpty)
                          _buildDetailSection(
                            'Accessories'.tr(),
                            Icons.inventory_2_outlined,
                            [
                              _buildChipsList(device.accessories, Colors.blue),
                            ],
                          ),

                        if ((device.installedPartCodes?.isNotEmpty ?? false) &&
                            isEmployee)
                          _buildDetailSection(
                            'Installed Part Codes'.tr(),
                            Icons.qr_code,
                            [
                              _buildChipsList(
                                device.installedPartCodes!,
                                Colors.deepPurple,
                              ),
                            ],
                          ),

                        // Employee Information (Only for employees)
                        if (isEmployee)
                          _buildDetailSection(
                            'Staff Assignment'.tr(),
                            Icons.badge_outlined,
                            [
                              _buildDetailRow(
                                'Received By'.tr(),
                                device.receivedByEmployee,
                                valueColor: Colors.indigo,
                              ),
                              if (device.maintenanceEmployee != null)
                                _buildDetailRow(
                                  'Maintenance By'.tr(),
                                  device.maintenanceEmployee!,
                                  valueColor: Colors.teal,
                                ),
                              if (device.deliveredByEmployee != null)
                                _buildDetailRow(
                                  'Delivered By'.tr(),
                                  device.deliveredByEmployee!,
                                  valueColor: Colors.green,
                                ),
                            ],
                          ),

                        _buildDetailSection(
                          'Timeline'.tr(),
                          Icons.schedule,
                          [
                            _buildDetailRow(
                              'Received'.tr(),
                              DateFormat('dd MMM yyyy, HH:mm')
                                  .format(device.receivedAt),
                            ),
                            if (device.updatedAt != null)
                              _buildDetailRow(
                                'Last Updated'.tr(),
                                DateFormat('dd MMM yyyy, HH:mm')
                                    .format(device.updatedAt!),
                              ),
                            if (device.deliveredAt != null)
                              _buildDetailRow(
                                'Delivered'.tr(),
                                DateFormat('dd MMM yyyy, HH:mm')
                                    .format(device.deliveredAt!),
                                valueColor: Colors.green,
                              ),
                            if (device.estimatedTime != null)
                              _buildDetailRow(
                                'Estimated Time'.tr(),
                                device.estimatedTime!,
                              ),
                          ],
                        ),

                        if (device.price != null)
                          _buildDetailSection(
                            'Pricing'.tr(),
                            Icons.payments,
                            [
                              _buildDetailRow(
                                'Price'.tr(),
                                '${device.price} \$',
                                valueColor: Colors.green,
                              ),
                            ],
                          ),

                        // Images Before Receiving
                        if (device.imagesBeforeReceiving?.isNotEmpty ?? false)
                          _buildImageSection(
                            'Images Before Receiving'.tr(),
                            device.imagesBeforeReceiving!,
                            context,
                          ),

                        // Images After Delivery
                        if (device.imagesAfterDelivery?.isNotEmpty ?? false)
                          _buildImageSection(
                            'Images After Delivery'.tr(),
                            device.imagesAfterDelivery!,
                            context,
                          ),

                        if (sensitiveData?.notesHidden != null ||
                            device.additionalNotes != null)
                          _buildDetailSection(
                            'Notes'.tr(),
                            Icons.notes,
                            [
                              if (isEmployee &&
                                  sensitiveData?.notesHidden != null)
                                _buildNoteCard(
                                  'Hidden Notes'.tr(),
                                  sensitiveData!.notesHidden!,
                                ),
                              if (device.additionalNotes != null)
                                _buildNoteCard(
                                  'Additional Notes'.tr(),
                                  device.additionalNotes!,
                                ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.grey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipsList(List<String> items, Color color) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            item,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoteCard(String title, String note) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRow(String label, String colorHex) {
    Color deviceColor;
    try {
      String normalized = colorHex.trim().replaceFirst('#', '');

      // Support both RRGGBB and AARRGGBB formats.
      if (normalized.length == 6) {
        normalized = 'ff$normalized';
      }

      deviceColor = Color(int.parse(normalized, radix: 16));
    } catch (e) {
      deviceColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: deviceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!, width: 2),
              boxShadow: [
                BoxShadow(
                  color: deviceColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            colorHex.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternLock(List<int> pattern) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pattern Lock'.tr(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: _buildPatternGrid(pattern),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternGrid(List<int> pattern) {
    return SizedBox(
      width: 120,
      height: 120,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final isInPattern = pattern.contains(index);
          final patternIndex = isInPattern ? pattern.indexOf(index) + 1 : null;

          return Container(
            decoration: BoxDecoration(
              color: isInPattern
                  ? Colors.blue.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isInPattern ? Colors.blue : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                patternIndex?.toString() ?? '',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isInPattern ? Colors.blue : Colors.transparent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSection(
    String title,
    List<String> imageUrls,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.photo_library,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageViewer(
                          imageUrls: imageUrls,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imageUrls[index],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: progress.expectedTotalBytes != null
                                        ? progress.cumulativeBytesLoaded /
                                            progress.expectedTotalBytes!
                                        : null,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey[400],
                                  size: 32,
                                ),
                              );
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                            child: const Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
