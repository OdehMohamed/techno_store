import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:techno_store/core2/utils/app_colors.dart';

class AccessoriesSectionWidget extends StatelessWidget {
  final List<bool> accessories;
  final ValueChanged<int> onAccessoryToggled;

  const AccessoriesSectionWidget({
    Key? key,
    required this.accessories,
    required this.onAccessoryToggled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accessoryList = [
      "Charger",
      "Headphones",
      "Case",
      "Screen Protector",
      "SIM 1",
      "SIM 2",
      "Memory Card",
      "Cable",
      "Other",
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined,
                  color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                "Accessories".tr(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(accessoryList.length, (index) {
              return FilterChip(
                label: Text(accessoryList[index].tr()),
                selected: accessories[index],
                onSelected: (selected) => onAccessoryToggled(index),
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: accessories[index]
                        ? AppColors.primary
                        : Colors.grey[300]!,
                  ),
                ),
                labelStyle: TextStyle(
                  color:
                      accessories[index] ? AppColors.primary : Colors.grey[700],
                  fontWeight:
                      accessories[index] ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
